.PHONY: help run format test tests analyze clean gen-l10n build-apk build-ios pub-get lint check-format fix fix-snap test-coverage-check scrape-musclewiki scrape-musclewiki-full

## ─── Default ────────────────────────────────────────────────────────────────

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

## ─── Development ────────────────────────────────────────────────────────────

fix-snap: ## Patch Flutter snap with missing native tools (requires sudo, idempotent)
	@./scripts/fix-flutter-snap.sh

run: fix-snap ## Run the app in debug mode (auto-detects device)
	flutter run

run-linux: fix-snap ## Run the app on Linux desktop
	flutter run -d linux

run-chrome: ## Run the app on Chrome (web)
	flutter run -d chrome

pub-get: ## Install / update dependencies
	flutter pub get

gen-l10n: ## Regenerate localisation files from ARB sources
	flutter gen-l10n

## ─── Quality ────────────────────────────────────────────────────────────────

format: ## Format all Dart files
	dart format lib/ test/

lint: ## Run dart format check without applying changes
	dart format --set-exit-if-changed lib/ test/

check-format: lint ## Alias for format check used by hooks

analyze: ## Run Flutter static analysis
	flutter analyze

fix: ## Apply automated dart fixes
	dart fix --apply

## ─── Testing ────────────────────────────────────────────────────────────────

test: ## Run all tests
	flutter test --concurrency=4

tests: test ## Alias for test target used by hooks

test-unit: ## Run only unit tests
	flutter test test/unit/ --concurrency=4

test-widget: ## Run only widget tests
	flutter test test/widget/ --concurrency=4

test-e2e: ## Run only end-to-end tests
	flutter test test/e2e/ --concurrency=2

test-coverage: ## Run tests with coverage report
	flutter test --coverage
	@echo "Coverage report generated at coverage/lcov.info"

test-coverage-check: test-coverage ## Fail if line coverage below threshold
	@python3 scripts/check_coverage.py --lcov coverage/lcov.info --min-lines 70

## ─── Build ──────────────────────────────────────────────────────────────────

build-apk: ## Build Android APK (release)
	flutter build apk

build-ios: ## Build iOS (release, macOS only)
	flutter build ios

## ─── Maintenance ────────────────────────────────────────────────────────────

clean: ## Clean build artifacts and caches
	flutter clean
	flutter pub get

ci: format analyze test-coverage-check ## Run CI pipeline (format + analyze + coverage gate)

## ─── Data: MuscleWiki ────────────────────────────────────────────────────────

scrape-musclewiki: ## Scrape from scripts/exersise-urls.txt (urls-only mode)
	python3 scripts/musclewiki_scraper.py --urls-file "scripts/exersise-urls.txt" --urls-only

scrape-musclewiki-full: ## Scrape with manual validation/proof enabled
	python3 scripts/musclewiki_scraper.py --urls-file "scripts/exersise-urls.txt"
