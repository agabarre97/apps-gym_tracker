.PHONY: help run format test analyze clean gen-l10n build-apk build-ios pub-get lint fix

## ─── Default ────────────────────────────────────────────────────────────────

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

## ─── Development ────────────────────────────────────────────────────────────

run: ## Run the app in debug mode (auto-detects device)
	flutter run

run-linux: ## Run the app on Linux desktop
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

analyze: ## Run Flutter static analysis
	flutter analyze

fix: ## Apply automated dart fixes
	dart fix --apply

## ─── Testing ────────────────────────────────────────────────────────────────

test: ## Run all tests
	flutter test

test-unit: ## Run only unit tests
	flutter test test/unit/

test-widget: ## Run only widget tests
	flutter test test/widget/

test-e2e: ## Run only end-to-end tests
	flutter test test/e2e/

test-coverage: ## Run tests with coverage report
	flutter test --coverage
	@echo "Coverage report generated at coverage/lcov.info"

## ─── Build ──────────────────────────────────────────────────────────────────

build-apk: ## Build Android APK (release)
	flutter build apk

build-ios: ## Build iOS (release, macOS only)
	flutter build ios

## ─── Maintenance ────────────────────────────────────────────────────────────

clean: ## Clean build artifacts and caches
	flutter clean
	flutter pub get

ci: format analyze test ## Run full CI pipeline (format + analyze + test)
