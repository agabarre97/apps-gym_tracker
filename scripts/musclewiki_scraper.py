#!/usr/bin/env python3
"""
MuscleWiki scraper for equipment categories and muscle-highlight exports.

Features:
- Dynamic scraping from the directory page using Playwright.
- Category filtering for: barbell, machine, smith-machine, dumbbell, cable, kettlebell.
- Exercise detail extraction in ES and EN.
- Numbered short description from <li> tags.
- Muscle detection via highlighted SVG groups (text-mw-red).
- Bilingual JSON export partitioned by muscle.
- SVG template consistency hashing across exercises.
- Manual validation artifacts, including SVG rendering from JSON muscles.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import time
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from playwright.sync_api import TimeoutError as PlaywrightTimeoutError
from playwright.sync_api import sync_playwright


BASE_ES_DIRECTORY = "https://musclewiki.com/es-es/directory"
BASE_ES_EXERCISE = "https://musclewiki.com/es-es/exercise/{key}"
BASE_EN_EXERCISE = "https://musclewiki.com/en-us/exercise/{key}"

CATEGORY_TEXT_VARIANTS = {
    "barbell": ["Barra olímpica", "Barbell"],
    "machine": ["Máquina", "Machine"],
    "smith-machine": ["Smith Machine", "Smith"],
    "dumbbell": ["Mancuernas", "Dumbbell"],
    "cable": ["Cables", "Cable"],
    "kettlebell": ["Kettlebells", "Kettlebell"],
}

KNOWN_MUSCLE_IDS = {
    "abdominals",
    "biceps",
    "calves",
    "chest",
    "forearms",
    "front-shoulders",
    "glutes",
    "hamstrings",
    "lats",
    "lowerback",
    "obliques",
    "quads",
    "rear-shoulders",
    "traps",
    "traps-middle",
    "triceps",
}

MUSCLE_TEXT_TO_ID = {
    "chest": "chest",
    "pectoral": "chest",
    "pecho": "chest",
    "biceps": "biceps",
    "bicep": "biceps",
    "triceps": "triceps",
    "tricep": "triceps",
    "front shoulders": "front-shoulders",
    "deltoide anterior": "front-shoulders",
    "anterior deltoid": "front-shoulders",
    "rear shoulders": "rear-shoulders",
    "deltoide posterior": "rear-shoulders",
    "posterior deltoid": "rear-shoulders",
    "forearms": "forearms",
    "antebrazos": "forearms",
    "abdominals": "abdominals",
    "abs": "abdominals",
    "abdominales": "abdominals",
    "obliques": "obliques",
    "oblicuos": "obliques",
    "lats": "lats",
    "dorsales": "lats",
    "lower back": "lowerback",
    "lumbar": "lowerback",
    "glutes": "glutes",
    "gluteos": "glutes",
    "glúteos": "glutes",
    "hamstrings": "hamstrings",
    "isquios": "hamstrings",
    "quads": "quads",
    "quadriceps": "quads",
    "cuadriceps": "quads",
    "cuádriceps": "quads",
    "calves": "calves",
    "gemelos": "calves",
    "traps": "traps",
    "trapecio": "traps",
    "trapezius": "traps",
    "traps middle": "traps-middle",
}

MANUAL_VALIDATION_URLS = [
    "https://musclewiki.com/es-es/exercise/smith-machine-standing-shrugs",
    "https://musclewiki.com/es-es/exercises/quads",
]

DEFAULT_HIGHLIGHT_COLOR = "#448AFF"
DEFAULT_NEUTRAL_COLOR = "#9CA3AF"


@dataclass
class ExerciseRecord:
    key: str
    name_es: str
    name_en: str
    short_description_es: str
    short_description_en: str
    muscles_involved: list[str]
    general_categories: list[str]
    source_url_es: str
    source_url_en: str
    muscles_source: str
    muscles_confidence: str
    muscles_trace: dict[str, Any]
    svg_hash_front: str | None = None
    svg_hash_back: str | None = None

    def to_json_dict(self) -> dict[str, Any]:
        return {
            "key": self.key,
            "name": {"es": self.name_es, "en": self.name_en},
            "short_description": {
                "es": self.short_description_es,
                "en": self.short_description_en,
            },
            "muscles_involved": self.muscles_involved,
            "muscles_source": self.muscles_source,
            "muscles_confidence": self.muscles_confidence,
            "muscles_trace": self.muscles_trace,
            "general_categories": self.general_categories,
            "source_urls": {"es": self.source_url_es, "en": self.source_url_en},
        }


def slug_to_name(slug: str) -> str:
    return slug.replace("-", " ").strip().title()


def normalize_space(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


def is_probably_noise(value: str) -> bool:
    text = normalize_space(value)
    if not text:
        return True
    lowered = text.lower()
    if lowered in {"musclewiki.com", "musclewiki"}:
        return True
    if re.fullmatch(r"[a-f0-9]{8,}", lowered):
        return True
    if "{" in text and "}" in text:
        return True
    if "workout__cls" in lowered or "calc__cls" in lowered:
        return True
    return False


def strip_accents(value: str) -> str:
    return "".join(
        char for char in unicodedata.normalize("NFD", value) if unicodedata.category(char) != "Mn"
    )


def normalize_text_for_match(value: str) -> str:
    return re.sub(r"\s+", " ", strip_accents(value).lower()).strip()


def detect_muscles_in_text(text: str) -> list[str]:
    normalized = normalize_text_for_match(text)
    found: set[str] = set()
    for phrase, muscle_id in MUSCLE_TEXT_TO_ID.items():
        phrase_norm = normalize_text_for_match(phrase)
        if not phrase_norm:
            continue
        pattern = rf"(?<![a-z0-9-]){re.escape(phrase_norm)}(?![a-z0-9-])"
        if re.search(pattern, normalized):
            found.add(muscle_id)
    return sorted(found)


def extract_text_roles_from_html(html: str) -> dict[str, list[str]]:
    plain = re.sub(r"<[^>]+>", "\n", html)
    compact = normalize_space(plain)
    roles = {"primary": [], "secondary": [], "tertiary": []}
    # Segment around role headings in EN/ES.
    segments = [
        ("primary", r"(Primary|Primario)(.*?)(Secondary|Secundario|Tertiary|Terciario|Difficulty|Dificultad|$)"),
        ("secondary", r"(Secondary|Secundario)(.*?)(Tertiary|Terciario|Difficulty|Dificultad|$)"),
        ("tertiary", r"(Tertiary|Terciario)(.*?)(Difficulty|Dificultad|$)"),
    ]
    for role_key, pattern in segments:
        match = re.search(pattern, compact, flags=re.IGNORECASE | re.DOTALL)
        if not match:
            continue
        detected = detect_muscles_in_text(match.group(2))
        if detected:
            roles[role_key] = detected
    return roles


def merge_text_roles(first: dict[str, list[str]], second: dict[str, list[str]]) -> dict[str, list[str]]:
    merged: dict[str, list[str]] = {}
    for role in ("primary", "secondary", "tertiary"):
        merged[role] = sorted(set(first.get(role, [])) | set(second.get(role, [])))
    return merged


def resolve_muscles(
    svg_ids: list[str],
    text_roles: dict[str, list[str]],
    url_slug_inferred: str | None,
) -> tuple[list[str], str, str, dict[str, Any]]:
    text_union = sorted(
        set(text_roles.get("primary", []))
        | set(text_roles.get("secondary", []))
        | set(text_roles.get("tertiary", []))
    )
    if svg_ids:
        source = "svg"
        confidence = "high"
        muscles = sorted(set(svg_ids))
    elif text_union:
        source = "text_roles"
        confidence = "medium"
        muscles = text_union
    elif url_slug_inferred and url_slug_inferred in KNOWN_MUSCLE_IDS:
        source = "url_slug"
        confidence = "low"
        muscles = [url_slug_inferred]
    else:
        source = "none"
        confidence = "low"
        muscles = []

    trace = {
        "svg_detected_ids": sorted(set(svg_ids)),
        "text_roles_detected": {
            "primary": sorted(set(text_roles.get("primary", []))),
            "secondary": sorted(set(text_roles.get("secondary", []))),
            "tertiary": sorted(set(text_roles.get("tertiary", []))),
        },
        "url_slug_inferred": url_slug_inferred,
    }
    return muscles, source, confidence, trace


def numbered_lines(lines: list[str]) -> str:
    cleaned = [normalize_space(line) for line in lines if normalize_space(line)]
    return " ".join(f"{index}. {text}" for index, text in enumerate(cleaned, start=1))


def extract_slug_from_url(url: str) -> str | None:
    match = re.search(r"/exercise/([^/?#]+)", url)
    return match.group(1) if match else None


def extract_exercises_group_from_url(url: str) -> str | None:
    match = re.search(r"/exercises/([^/?#]+)", url)
    return match.group(1) if match else None


def normalize_exercise_url(url: str) -> str:
    cleaned = url.strip()
    if not cleaned:
        return ""
    cleaned = cleaned.split("#")[0].split("?")[0]
    return cleaned


def to_en_exercise_url(url: str, key: str) -> str:
    cleaned = normalize_exercise_url(url)
    if "/es-es/" in cleaned:
        return cleaned.replace("/es-es/", "/en-us/")
    if "/en-us/" in cleaned:
        return cleaned
    if "/exercise/" in cleaned:
        return f"https://musclewiki.com/en-us/exercise/{key}"
    return BASE_EN_EXERCISE.format(key=key)


def load_exercise_urls(urls_file: Path) -> list[str]:
    if not urls_file.exists():
        raise FileNotFoundError(f"URLs file not found: {urls_file}")
    urls: list[str] = []
    for raw_line in urls_file.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        normalized = normalize_exercise_url(line)
        if normalized and "/exercise/" in normalized:
            urls.append(normalized)
    return sorted(set(urls))


def normalize_svg_for_hash(svg_content: str) -> str:
    normalized = re.sub(r"\s+", " ", svg_content).strip()
    normalized = normalized.replace("text-mw-red", "text-mw-color")
    normalized = normalized.replace("text-mw-gray", "text-mw-color")
    return normalized


def sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def find_svg_blocks(html: str) -> list[str]:
    return re.findall(r"(<svg\b.*?</svg>)", html, flags=re.DOTALL | re.IGNORECASE)


def extract_muscles_from_html(html: str) -> list[str]:
    muscles: set[str] = set()
    pattern_red_then_id = re.compile(
        r"<g\b[^>]*\bclass=\"[^\"]*text-mw-red[^\"]*\"[^>]*\bid=\"([^\"]+)\"[^>]*>",
        flags=re.IGNORECASE,
    )
    pattern_id_then_red = re.compile(
        r"<g\b[^>]*\bid=\"([^\"]+)\"[^>]*\bclass=\"[^\"]*text-mw-red[^\"]*\"[^>]*>",
        flags=re.IGNORECASE,
    )
    for match in pattern_red_then_id.findall(html):
        if match in KNOWN_MUSCLE_IDS:
            muscles.add(match)
    for match in pattern_id_then_red.findall(html):
        if match in KNOWN_MUSCLE_IDS:
            muscles.add(match)
    return sorted(muscles)


def extract_name_from_html(html: str, fallback_key: str) -> str:
    og_match = re.search(
        r"<meta[^>]+property=[\"']og:title[\"'][^>]+content=[\"']([^\"']+)[\"']",
        html,
        flags=re.IGNORECASE,
    )
    if og_match:
        og_title = normalize_space(og_match.group(1))
        if og_title:
            es_match = re.search(r"Guía de Ejercicio\s+(.+?)\s+-", og_title, flags=re.IGNORECASE)
            if es_match:
                candidate = normalize_space(es_match.group(1))
                if not is_probably_noise(candidate):
                    return candidate
            en_match = re.search(r"(.+?)\s+Exercise Guide", og_title, flags=re.IGNORECASE)
            if en_match:
                candidate = normalize_space(en_match.group(1))
                if not is_probably_noise(candidate):
                    return candidate

    title_match = re.search(r"<title[^>]*>(.*?)</title>", html, flags=re.DOTALL | re.IGNORECASE)
    if title_match:
        title_text = normalize_space(re.sub(r"<[^>]+>", " ", title_match.group(1)))
        # ES pattern: "Guía de Ejercicio Barbell Curl - Entrenamiento de Biceps | MuscleWiki"
        es_match = re.search(r"Guía de Ejercicio\s+(.+?)\s+-", title_text, flags=re.IGNORECASE)
        if es_match:
            candidate = normalize_space(es_match.group(1))
            if not is_probably_noise(candidate):
                return candidate
        # EN pattern: "Barbell Curl Exercise Guide - Biceps Workout | MuscleWiki"
        en_match = re.search(r"(.+?)\s+Exercise Guide", title_text, flags=re.IGNORECASE)
        if en_match:
            candidate = normalize_space(en_match.group(1))
            if not is_probably_noise(candidate):
                return candidate

    for tag in ("h1", "h2", "h3"):
        for match in re.findall(rf"<{tag}\b[^>]*>(.*?)</{tag}>", html, flags=re.DOTALL | re.IGNORECASE):
            text = normalize_space(re.sub(r"<[^>]+>", " ", match))
            if not text:
                continue
            lowered = text.lower()
            if "musclewiki mobile" in lowered:
                continue
            if len(text) < 3:
                continue
            # Usually title case exercise name, this is a practical heuristic.
            if any(char.isalpha() for char in text) and not is_probably_noise(text):
                return text
    return slug_to_name(fallback_key)


def extract_li_steps_from_html(html: str) -> str:
    # MuscleWiki often renders instructions in <dl>/<dd> instead of <li>.
    # Prioritize this structure to avoid navbar/footer noise.
    dd_section_matches = re.findall(r"<dl\b[^>]*>(.*?)</dl>", html, flags=re.DOTALL | re.IGNORECASE)
    for section_html in dd_section_matches:
        dd_items: list[str] = []
        for dd_content in re.findall(r"<dd\b[^>]*>(.*?)</dd>", section_html, flags=re.DOTALL | re.IGNORECASE):
            text = normalize_space(re.sub(r"<[^>]+>", " ", dd_content))
            if text and len(text) > 20 and not is_probably_noise(text):
                dd_items.append(text)
        if dd_items:
            return numbered_lines(dd_items)

    # Fallback: any <dd> in page if <dl> block was not captured.
    dd_items_global: list[str] = []
    for dd_content in re.findall(r"<dd\b[^>]*>(.*?)</dd>", html, flags=re.DOTALL | re.IGNORECASE):
        text = normalize_space(re.sub(r"<[^>]+>", " ", dd_content))
        if text and len(text) > 20 and not is_probably_noise(text):
            dd_items_global.append(text)
    if dd_items_global:
        return numbered_lines(dd_items_global[:12])

    section_match = re.search(
        r"(Detailed How To:.*?)(?:Ty'?s Tips|$)",
        html,
        flags=re.DOTALL | re.IGNORECASE,
    )
    if section_match:
        section_html = section_match.group(1)
        section_items = []
        for li_content in re.findall(r"<li\b[^>]*>(.*?)</li>", section_html, flags=re.DOTALL | re.IGNORECASE):
            text = normalize_space(re.sub(r"<[^>]+>", " ", li_content))
            if text and len(text) > 20 and not is_probably_noise(text):
                section_items.append(text)
        if section_items:
            return numbered_lines(section_items)

    items = []
    for li_content in re.findall(r"<li\b[^>]*>(.*?)</li>", html, flags=re.DOTALL | re.IGNORECASE):
        text = normalize_space(re.sub(r"<[^>]+>", " ", li_content))
        if text and len(text) > 20:
            items.append(text)

    if items:
        banned_fragments = {
            "iniciar sesión",
            "registrarse",
            "app store",
            "google play",
            "musclewiki",
            "términos",
            "política de privacidad",
            "boletín",
            "youtube",
            "instagram",
            "twitter",
            "facebook",
            "entrenamientos",
            "rutinas",
            "herramientas",
            "artículos",
            "directorio",
        }
        filtered: list[str] = []
        for item in items:
            lowered = item.lower()
            if any(fragment in lowered for fragment in banned_fragments):
                continue
            if is_probably_noise(item):
                continue
            filtered.append(item)
        if filtered:
            return numbered_lines(filtered[:10])

    # If no real <li>, fallback to top "1... 2... 3..." lines often rendered as text.
    if not items:
        numeric_lines = re.findall(
            r"(?:^|\n)\s*([1-9][0-9]?)\s*([^\n<][^\n]+)",
            re.sub(r"<[^>]+>", "\n", html),
            flags=re.IGNORECASE,
        )
        if numeric_lines:
            ordered = [normalize_space(line) for _, line in numeric_lines[:12]]
            sanitized = [line for line in ordered if len(line) > 15 and not is_probably_noise(line)]
            return numbered_lines(sanitized)
    return numbered_lines(items)


def apply_standalone_svg_styles(
    svg_content: str,
    selected_class: str = "text-mw-blue",
    neutral_class: str = "text-mw-gray",
    selected_color: str = DEFAULT_HIGHLIGHT_COLOR,
    neutral_color: str = DEFAULT_NEUTRAL_COLOR,
) -> str:
    style_tag = (
        "<style>"
        f".{selected_class}{{color:{selected_color};}}"
        f".{neutral_class}{{color:{neutral_color};}}"
        "</style>"
    )
    if "<defs>" in svg_content:
        return svg_content.replace("<defs>", f"<defs>{style_tag}", 1)
    return re.sub(r"(<svg\b[^>]*>)", rf"\1{style_tag}", svg_content, count=1, flags=re.IGNORECASE)


def render_template_svg_with_muscles(
    svg_content: str,
    selected_muscles: set[str],
    selected_class: str = "text-mw-blue",
    neutral_class: str = "text-mw-gray",
    selected_color: str = DEFAULT_HIGHLIGHT_COLOR,
    neutral_color: str = DEFAULT_NEUTRAL_COLOR,
) -> str:
    def replace_group(match: re.Match[str]) -> str:
        opening = match.group(0)
        group_id = match.group("gid")
        class_value = match.group("class_value")
        classes = class_value.split()
        if group_id in KNOWN_MUSCLE_IDS:
            classes = [
                token
                for token in classes
                if token not in {"text-mw-red", "text-mw-gray", "text-mw-blue"}
                and not token.startswith("active:text-mw-")
                and "hover:text-mw-" not in token
            ]
            classes.append(selected_class if group_id in selected_muscles else neutral_class)
        new_class_value = " ".join(classes).strip()
        updated = opening.replace(f'class="{class_value}"', f'class="{new_class_value}"')
        return updated

    group_pattern = re.compile(
        r"<g\b(?=[^>]*\bid=\"(?P<gid>[^\"]+)\")(?=[^>]*\bclass=\"(?P<class_value>[^\"]+)\")[^>]*>",
        flags=re.IGNORECASE,
    )
    rendered = group_pattern.sub(replace_group, svg_content)
    return apply_standalone_svg_styles(
        rendered,
        selected_class=selected_class,
        neutral_class=neutral_class,
        selected_color=selected_color,
        neutral_color=neutral_color,
    )


def generate_preview_html(
    manual_artifacts: list[dict[str, Any]],
    preview_path: Path,
) -> None:
    cards: list[str] = []
    for artifact in manual_artifacts:
        key = artifact.get("key", "unknown")
        muscles = ", ".join(artifact.get("muscles_involved", [])) or "(none)"
        source = artifact.get("muscles_source", "none")
        front_rel = artifact.get("front_svg_rel")
        back_rel = artifact.get("back_svg_rel")
        front_img = (
            f'<img class="svgimg" src="{front_rel}" alt="{key} front" />'
            if front_rel
            else '<div class="missing">No front.svg</div>'
        )
        back_img = (
            f'<img class="svgimg" src="{back_rel}" alt="{key} back" />'
            if back_rel
            else '<div class="missing">No back.svg</div>'
        )
        cards.append(
            (
                '<section class="card">'
                f"<h2>{key}</h2>"
                f"<p><strong>Source:</strong> {source}</p>"
                f"<p><strong>Muscles:</strong> {muscles}</p>"
                '<div class="row">'
                f'<div><h3>Front</h3>{front_img}</div>'
                f'<div><h3>Back</h3>{back_img}</div>'
                "</div>"
                "</section>"
            )
        )

    html = (
        "<!doctype html><html><head><meta charset='utf-8'>"
        "<meta name='viewport' content='width=device-width,initial-scale=1'>"
        "<title>SVG Preview</title>"
        "<style>"
        "body{font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;background:#111827;color:#e5e7eb;margin:0;padding:24px;}"
        "h1{margin:0 0 16px 0;} .card{background:#1f2937;border:1px solid #374151;border-radius:12px;padding:16px;margin-bottom:16px;}"
        ".row{display:grid;grid-template-columns:1fr 1fr;gap:16px;} .svgimg{width:100%;max-width:420px;background:#0b1020;border-radius:8px;}"
        "h2,h3{margin:0 0 8px 0;} p{margin:6px 0;} .missing{color:#9ca3af;font-size:14px;}"
        "@media (max-width:900px){.row{grid-template-columns:1fr;}}"
        "</style></head><body>"
        "<h1>SVG Manual Validation Preview</h1>"
        "<p>Highlight color: #448AFF</p>"
        + "".join(cards)
        + "</body></html>"
    )
    preview_path.parent.mkdir(parents=True, exist_ok=True)
    preview_path.write_text(html, encoding="utf-8")


def build_preview_artifact_from_record(
    record: ExerciseRecord,
    template_svgs: list[str],
    reports_dir: Path,
) -> dict[str, Any]:
    if not template_svgs:
        return {
            "key": record.key,
            "muscles_involved": record.muscles_involved,
            "muscles_source": record.muscles_source,
            "front_svg_rel": None,
            "back_svg_rel": None,
        }
    selected = set(record.muscles_involved)
    front_svg = render_template_svg_with_muscles(template_svgs[0], selected)
    front_path = reports_dir / "preview_sample-front.svg"
    front_path.write_text(front_svg, encoding="utf-8")

    back_rel: str | None = None
    if len(template_svgs) > 1:
        back_svg = render_template_svg_with_muscles(template_svgs[1], selected)
        back_path = reports_dir / "preview_sample-back.svg"
        back_path.write_text(back_svg, encoding="utf-8")
        back_rel = str(back_path.relative_to(reports_dir))

    return {
        "key": record.key,
        "muscles_involved": record.muscles_involved,
        "muscles_source": record.muscles_source,
        "front_svg_rel": str(front_path.relative_to(reports_dir)),
        "back_svg_rel": back_rel,
    }


def find_exercise_links(page) -> set[str]:
    hrefs = page.eval_on_selector_all(
        "a[href*='/exercise/']",
        "elements => elements.map(el => el.getAttribute('href') || '')",
    )
    absolute_links = set()
    for href in hrefs:
        if not href:
            continue
        if href.startswith("http"):
            absolute_links.add(href.split("#")[0])
        elif href.startswith("/"):
            absolute_links.add(f"https://musclewiki.com{href}".split("#")[0])
    return absolute_links


def go_next_page_if_possible(page) -> bool:
    next_variants = [
        "button:has-text('Siguiente')",
        "a:has-text('Siguiente')",
        "button:has-text('Next')",
        "a:has-text('Next')",
    ]
    for selector in next_variants:
        elements = page.query_selector_all(selector)
        if not elements:
            continue
        for element in elements:
            aria_disabled = element.get_attribute("aria-disabled")
            classes = element.get_attribute("class") or ""
            if aria_disabled == "true" or "disabled" in classes.lower():
                continue
            try:
                element.click(timeout=2000)
                page.wait_for_timeout(1000)
                return True
            except PlaywrightTimeoutError:
                continue
            except Exception:
                continue
    return False


def click_filter_variant(page, variants: list[str]) -> bool:
    for text in variants:
        selector_options = [
            f"button:has-text('{text}')",
            f"a:has-text('{text}')",
            f"label:has-text('{text}')",
            f"[role='button']:has-text('{text}')",
            f"[data-value='{text}']",
        ]
        for selector in selector_options:
            try:
                locator = page.locator(selector).first
                if locator.count() == 0:
                    continue
                locator.click(timeout=3000)
                page.wait_for_timeout(1500)
                return True
            except Exception:
                continue
    return False


def collect_links_for_category(page, category: str) -> set[str]:
    page.goto(BASE_ES_DIRECTORY, wait_until="domcontentloaded", timeout=60000)
    page.wait_for_timeout(2000)
    clicked = click_filter_variant(page, CATEGORY_TEXT_VARIANTS[category])
    if not clicked:
        print(f"[WARN] Could not click filter for category '{category}'. Collecting visible links anyway.")

    links: set[str] = set()
    visited_guard = 0
    while True:
        links |= find_exercise_links(page)
        visited_guard += 1
        if visited_guard > 120:
            break
        if not go_next_page_if_possible(page):
            break
    return links


def scrape_detail_page(
    page, url: str, fallback_key: str
) -> tuple[str, str, list[str], dict[str, list[str]], list[str], str | None, str | None]:
    page.goto(url, wait_until="domcontentloaded", timeout=60000)
    page.wait_for_timeout(1200)
    html = page.content()
    name = extract_name_from_html(html, fallback_key)
    short_description = extract_li_steps_from_html(html)
    if not short_description:
        try:
            dom_items = page.eval_on_selector_all(
                "main li, article li, section li, main dd, article dd, section dd",
                """elements => elements
                    .map(el => (el.textContent || '').replace(/\\s+/g, ' ').trim())
                    .filter(Boolean)""",
            )
            dom_items = [item for item in dom_items if len(item) > 20 and not is_probably_noise(item)]
            if dom_items:
                short_description = numbered_lines(dom_items[:10])
        except Exception:
            pass
    muscles = extract_muscles_from_html(html)
    text_roles = extract_text_roles_from_html(html)

    svgs = find_svg_blocks(html)
    hash_front = None
    hash_back = None
    if svgs:
        hash_front = sha256_hex(normalize_svg_for_hash(svgs[0]))
    if len(svgs) > 1:
        hash_back = sha256_hex(normalize_svg_for_hash(svgs[1]))

    return name, short_description, muscles, text_roles, svgs, hash_front, hash_back


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def load_json_list(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return []
    if not isinstance(payload, list):
        return []
    normalized: list[dict[str, Any]] = []
    for item in payload:
        if isinstance(item, dict) and isinstance(item.get("key"), str):
            normalized.append(item)
    return normalized


def main() -> int:
    parser = argparse.ArgumentParser(description="Scrape MuscleWiki exercises and export by muscle.")
    parser.add_argument(
        "--urls-file",
        default="scripts/exersise-urls.txt",
        help="File with one exercise URL per line. If present, it is used as the primary source.",
    )
    parser.add_argument(
        "--categories",
        nargs="+",
        default=["barbell", "machine", "smith-machine", "dumbbell", "cable", "kettlebell"],
        help="Categories to scrape from directory filters.",
    )
    parser.add_argument(
        "--output-dir",
        default="assets/data/musclewiki/by_muscle",
        help="Directory for per-muscle bilingual JSON files.",
    )
    parser.add_argument(
        "--reports-dir",
        default="assets/data/musclewiki/reports",
        help="Directory for reports and proof artifacts.",
    )
    parser.add_argument(
        "--template-html",
        default="front_svg.html",
        help="Local template HTML file used for generating validation SVGs.",
    )
    parser.add_argument(
        "--template-output-dir",
        default="assets/data/musclewiki/svg_templates",
        help="Directory where front.svg and back.svg templates will be written.",
    )
    parser.add_argument(
        "--preview-html",
        default="assets/data/musclewiki/reports/svg-preview.html",
        help="Output HTML path for visual SVG validation preview.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Optional max number of exercise keys to process (0 = no limit).",
    )
    parser.add_argument(
        "--urls-only",
        action="store_true",
        help="Use only URLs input: skip manual validation/proof and create single-sample preview.",
    )
    args = parser.parse_args()

    categories = [cat.strip() for cat in args.categories if cat.strip()]
    invalid = [cat for cat in categories if cat not in CATEGORY_TEXT_VARIANTS]
    if invalid:
        print(f"[ERROR] Invalid categories: {invalid}")
        return 2

    started = time.time()
    output_dir = Path(args.output_dir)
    reports_dir = Path(args.reports_dir)
    template_path = Path(args.template_html)
    template_output_dir = Path(args.template_output_dir)
    preview_html_path = Path(args.preview_html)
    if not template_path.exists():
        print(f"[ERROR] Template HTML not found: {template_path}")
        return 2
    template_html = template_path.read_text(encoding="utf-8")
    template_svgs = find_svg_blocks(template_html)
    if len(template_svgs) < 2:
        print("[WARN] Template HTML does not contain two SVG blocks; validation SVG generation may be incomplete.")
    else:
        template_output_dir.mkdir(parents=True, exist_ok=True)
        front_template_path = template_output_dir / "front.svg"
        back_template_path = template_output_dir / "back.svg"
        front_template_path.write_text(
            apply_standalone_svg_styles(template_svgs[0]),
            encoding="utf-8",
        )
        back_template_path.write_text(
            apply_standalone_svg_styles(template_svgs[1]),
            encoding="utf-8",
        )

    urls_file_path = Path(args.urls_file)
    category_to_links: dict[str, set[str]] = {}
    key_to_categories: dict[str, set[str]] = {}
    key_to_primary_es_url: dict[str, str] = {}

    records: list[ExerciseRecord] = []
    errors: list[dict[str, Any]] = []
    svg_hash_observations: list[dict[str, Any]] = []
    manual_validation_artifacts: list[dict[str, Any]] = []

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()

        using_urls_file = False
        if urls_file_path.exists():
            try:
                seed_urls = load_exercise_urls(urls_file_path)
                using_urls_file = len(seed_urls) > 0
                for seed_url in seed_urls:
                    key = extract_slug_from_url(seed_url)
                    if not key:
                        continue
                    key_to_categories.setdefault(key, set())
                    key_to_primary_es_url[key] = seed_url
                print(f"[INFO] URLs loaded from file: {len(seed_urls)}")
            except Exception as exc:  # noqa: BLE001
                errors.append({"stage": "load_urls_file", "file": str(urls_file_path), "error": str(exc)})
                print(f"[ERROR] Could not load URLs file: {exc}")

        if not using_urls_file:
            for category in categories:
                try:
                    links = collect_links_for_category(page, category)
                    category_to_links[category] = links
                    for link in links:
                        key = extract_slug_from_url(link)
                        if not key:
                            continue
                        key_to_categories.setdefault(key, set()).add(category)
                        key_to_primary_es_url.setdefault(key, f"https://musclewiki.com/es-es/exercise/{key}")
                    print(f"[INFO] Category {category}: {len(links)} raw links")
                except Exception as exc:  # noqa: BLE001
                    errors.append({"stage": "collect_links", "category": category, "error": str(exc)})
                    print(f"[ERROR] Category {category}: {exc}")

        keys = sorted(key_to_categories.keys())
        if args.limit > 0:
            keys = keys[: args.limit]
        print(f"[INFO] Total unique exercise keys: {len(keys)}")

        for index, key in enumerate(keys, start=1):
            es_url = key_to_primary_es_url.get(key, BASE_ES_EXERCISE.format(key=key))
            en_url = to_en_exercise_url(es_url, key)
            print(f"[INFO] [{index}/{len(keys)}] Processing {key}")
            try:
                name_es, desc_es, muscles_es, roles_es, _, hash_front_es, hash_back_es = scrape_detail_page(
                    page, es_url, key
                )
            except Exception as exc:  # noqa: BLE001
                errors.append({"stage": "scrape_es", "key": key, "url": es_url, "error": str(exc)})
                continue

            try:
                name_en, desc_en, muscles_en, roles_en, _, hash_front_en, hash_back_en = scrape_detail_page(
                    page, en_url, key
                )
            except Exception as exc:  # noqa: BLE001
                errors.append({"stage": "scrape_en", "key": key, "url": en_url, "error": str(exc)})
                # keep ES data if EN failed
                name_en = slug_to_name(key)
                desc_en = ""
                muscles_en = []
                roles_en = {"primary": [], "secondary": [], "tertiary": []}
                hash_front_en = None
                hash_back_en = None

            svg_combined = sorted(set(muscles_es) | set(muscles_en))
            roles_combined = merge_text_roles(roles_es, roles_en)
            url_slug_group = extract_exercises_group_from_url(es_url)
            muscles_combined, muscles_source, muscles_confidence, muscles_trace = resolve_muscles(
                svg_combined, roles_combined, url_slug_group
            )
            record = ExerciseRecord(
                key=key,
                name_es=name_es,
                name_en=name_en,
                short_description_es=desc_es or desc_en,
                short_description_en=desc_en or desc_es,
                muscles_involved=muscles_combined,
                muscles_source=muscles_source,
                muscles_confidence=muscles_confidence,
                muscles_trace=muscles_trace,
                general_categories=[],
                source_url_es=es_url,
                source_url_en=en_url,
                svg_hash_front=hash_front_es or hash_front_en,
                svg_hash_back=hash_back_es or hash_back_en,
            )
            records.append(record)

            svg_hash_observations.append(
                {
                    "key": key,
                    "front_hash": record.svg_hash_front,
                    "back_hash": record.svg_hash_back,
                }
            )

        if not args.urls_only:
            # Manual validation pages and generated SVGs from muscles.
            validation_dir = reports_dir / "manual_validation"
            validation_dir.mkdir(parents=True, exist_ok=True)
            for validation_url in MANUAL_VALIDATION_URLS:
                validation_key = extract_slug_from_url(validation_url) or validation_url.rstrip("/").split("/")[-1]
                try:
                    page.goto(validation_url, wait_until="domcontentloaded", timeout=60000)
                    page.wait_for_timeout(1200)
                    html = page.content()
                    muscles_svg = extract_muscles_from_html(html)
                    roles = extract_text_roles_from_html(html)
                    inferred_group = extract_exercises_group_from_url(validation_url)
                    muscles, muscles_source, muscles_confidence, muscles_trace = resolve_muscles(
                        muscles_svg, roles, inferred_group
                    )
                    validation_json = {
                        "key": validation_key,
                        "url": validation_url,
                        "muscles_involved": muscles,
                        "muscles_source": muscles_source,
                        "muscles_confidence": muscles_confidence,
                        "muscles_trace": muscles_trace,
                    }
                    json_path = validation_dir / f"{validation_key}.json"
                    write_json(json_path, validation_json)

                    if template_svgs:
                        selected = set(muscles)
                        front_svg = render_template_svg_with_muscles(template_svgs[0], selected)
                        front_path = validation_dir / f"{validation_key}-front.svg"
                        front_path.write_text(front_svg, encoding="utf-8")
                        front_rel = front_path.relative_to(reports_dir)
                        if len(template_svgs) > 1:
                            back_svg = render_template_svg_with_muscles(template_svgs[1], selected)
                            back_path = validation_dir / f"{validation_key}-back.svg"
                            back_path.write_text(back_svg, encoding="utf-8")
                            back_rel = back_path.relative_to(reports_dir)
                        else:
                            back_rel = None
                    else:
                        front_rel = None
                        back_rel = None

                    manual_validation_artifacts.append(
                        {
                            "key": validation_key,
                            "url": validation_url,
                            "json": str(json_path),
                            "muscles_involved": muscles,
                            "muscles_source": muscles_source,
                            "front_svg_rel": str(front_rel) if front_rel else None,
                            "back_svg_rel": str(back_rel) if back_rel else None,
                        }
                    )
                except Exception as exc:  # noqa: BLE001
                    errors.append({"stage": "manual_validation", "url": validation_url, "error": str(exc)})

            # Required proof for barbell-curl, independent from input source.
            try:
                proof_key = "barbell-curl"
                existing = next((record for record in records if record.key == proof_key), None)
                if not existing:
                    proof_es_url = BASE_ES_EXERCISE.format(key=proof_key)
                    proof_en_url = BASE_EN_EXERCISE.format(key=proof_key)
                    name_es, desc_es, muscles_es, roles_es, _, hash_front_es, hash_back_es = scrape_detail_page(
                        page, proof_es_url, proof_key
                    )
                    try:
                        name_en, desc_en, muscles_en, roles_en, _, hash_front_en, hash_back_en = scrape_detail_page(
                            page, proof_en_url, proof_key
                        )
                    except Exception:  # noqa: BLE001
                        name_en = slug_to_name(proof_key)
                        desc_en = ""
                        muscles_en = []
                        roles_en = {"primary": [], "secondary": [], "tertiary": []}
                        hash_front_en = None
                        hash_back_en = None
                    proof_muscles, proof_source, proof_confidence, proof_trace = resolve_muscles(
                        sorted(set(muscles_es) | set(muscles_en)),
                        merge_text_roles(roles_es, roles_en),
                        extract_exercises_group_from_url(proof_es_url),
                    )
                    proof_record = ExerciseRecord(
                        key=proof_key,
                        name_es=name_es,
                        name_en=name_en,
                        short_description_es=desc_es or desc_en,
                        short_description_en=desc_en or desc_es,
                        muscles_involved=proof_muscles,
                        muscles_source=proof_source,
                        muscles_confidence=proof_confidence,
                        muscles_trace=proof_trace,
                        general_categories=[],
                        source_url_es=proof_es_url,
                        source_url_en=proof_en_url,
                        svg_hash_front=hash_front_es or hash_front_en,
                        svg_hash_back=hash_back_es or hash_back_en,
                    )
                    records.append(proof_record)
                    svg_hash_observations.append(
                        {
                            "key": proof_record.key,
                            "front_hash": proof_record.svg_hash_front,
                            "back_hash": proof_record.svg_hash_back,
                        }
                    )
            except Exception as exc:  # noqa: BLE001
                errors.append({"stage": "barbell_curl_proof", "error": str(exc)})

        browser.close()

    # Export per muscle bilingual JSON files.
    grouped: dict[str, list[dict[str, Any]]] = {muscle: [] for muscle in KNOWN_MUSCLE_IDS}
    for record in records:
        payload = record.to_json_dict()
        for muscle in record.muscles_involved:
            if muscle in grouped:
                grouped[muscle].append(payload)

    persisted_counts: dict[str, int] = {}
    for muscle in sorted(KNOWN_MUSCLE_IDS):
        file_path = output_dir / f"{muscle}.json"
        existing_items = load_json_list(file_path)
        merged_by_key: dict[str, dict[str, Any]] = {item["key"]: item for item in existing_items}
        for item in grouped.get(muscle, []):
            merged_by_key[item["key"]] = item
        if not merged_by_key:
            continue
        merged_items = sorted(merged_by_key.values(), key=lambda entry: entry["key"])
        write_json(file_path, merged_items)
        persisted_counts[muscle] = len(merged_items)

    # Proof JSON for barbell-curl.
    if not args.urls_only:
        proof = next((record.to_json_dict() for record in records if record.key == "barbell-curl"), None)
        write_json(reports_dir / "barbell-curl-proof.json", proof or {"error": "barbell-curl not found"})

    # SVG consistency report.
    front_hashes = sorted({item["front_hash"] for item in svg_hash_observations if item.get("front_hash")})
    back_hashes = sorted({item["back_hash"] for item in svg_hash_observations if item.get("back_hash")})
    consistency_report = {
        "total_records": len(records),
        "unique_front_hashes": front_hashes,
        "unique_back_hashes": back_hashes,
        "front_is_consistent": len(front_hashes) <= 1,
        "back_is_consistent": len(back_hashes) <= 1,
        "observations": svg_hash_observations,
    }
    write_json(reports_dir / "svg_consistency_report.json", consistency_report)
    if args.urls_only:
        sample = next((record for record in sorted(records, key=lambda item: item.key) if record.muscles_involved), None)
        if sample:
            sample_artifact = build_preview_artifact_from_record(sample, template_svgs, reports_dir)
            generate_preview_html([sample_artifact], preview_html_path)
    else:
        generate_preview_html(manual_validation_artifacts, preview_html_path)

    # Main report.
    elapsed = round(time.time() - started, 2)
    by_category_counts = {category: len(links) for category, links in category_to_links.items()}
    by_muscle_counts = persisted_counts
    report = {
        "generated_at_epoch": int(time.time()),
        "elapsed_seconds": elapsed,
        "input_mode": "urls_file" if urls_file_path.exists() else "category_discovery",
        "urls_file": str(urls_file_path) if urls_file_path.exists() else None,
        "categories": categories,
        "by_category_raw_link_counts": by_category_counts,
        "total_unique_records": len(records),
        "by_muscle_counts": by_muscle_counts,
        "output_dir": str(output_dir),
        "reports_dir": str(reports_dir),
        "svg_templates_dir": str(template_output_dir),
        "preview_html": str(preview_html_path),
        "manual_validation_artifacts": manual_validation_artifacts,
        "errors": errors,
    }
    write_json(reports_dir / "run_report.json", report)

    print(f"[DONE] Records: {len(records)} | Errors: {len(errors)} | Elapsed: {elapsed}s")
    print(f"[DONE] Output: {output_dir}")
    print(f"[DONE] Reports: {reports_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
