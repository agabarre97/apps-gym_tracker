#!/usr/bin/env python3
"""Simple LCOV line coverage gate."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


def parse_lcov_lines(path: Path) -> tuple[int, int]:
    hits = 0
    found = 0
    with path.open("r", encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            if line.startswith("DA:"):
                _, payload = line.split(":", 1)
                _line_no, hit_count = payload.split(",", 1)
                found += 1
                if int(hit_count) > 0:
                    hits += 1
    return hits, found


def main() -> int:
    parser = argparse.ArgumentParser(description="Check LCOV line coverage.")
    parser.add_argument("--lcov", required=True, help="Path to lcov.info")
    parser.add_argument(
        "--min-lines",
        required=True,
        type=float,
        help="Minimum allowed line coverage percentage.",
    )
    args = parser.parse_args()

    lcov_path = Path(args.lcov)
    if not lcov_path.exists():
        print(f"ERROR: LCOV file not found: {lcov_path}")
        return 2

    hits, found = parse_lcov_lines(lcov_path)
    if found == 0:
        print("ERROR: No DA records found in LCOV file.")
        return 2

    coverage = (hits / found) * 100.0
    print(f"Line coverage: {coverage:.2f}% ({hits}/{found})")

    if coverage < args.min_lines:
        print(
            f"ERROR: Coverage {coverage:.2f}% is below threshold {args.min_lines:.2f}%"
        )
        return 1
    print("Coverage threshold satisfied.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
