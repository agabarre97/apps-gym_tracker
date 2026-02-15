# Gym Tracker

## Framework Selection Rationale

### Multi-Agent Evaluation Process

Three framework alternatives were scaffolded by simulated agents (Composer 1.5, Claude 4.6 Opus High, GPT 5.3 Codex), each following the same requirements:

- Hexagonal (ports & adapters) architecture
- Basic white screen
- Local storage adapter (no network)
- Cursor rules from [awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules/tree/main/rules)

### Analysis of Alternatives

| Framework | Platform | Pros | Cons |
|-----------|----------|------|------|
| **Flutter** | Android, iOS, Web | Single codebase, hot reload, Material 3, strong hexagonal support | Dart learning curve |
| **React Native + Expo** | Android, iOS, Web | Large ecosystem, TypeScript, familiar to web devs | Bridge overhead, larger app size |
| **Android Jetpack Compose** | Android only | Native performance, Material 3, Kotlin coroutines | No iOS support |

### Why Flutter Was Selected

1. **Cross-platform**: Supports Android and iOS from one codebase, matching the "would be great if iOS" requirement.

2. **Hexagonal fit**: Domain (`StoragePort`), data (`LocalStorageDatasource`), and presentation are cleanly separated. Dependency direction is correct (data -> domain).

3. **Maintainability**: Single codebase, consistent structure, and strong typing with Dart null safety.

4. **Gym app fit**: Good for fitness apps with animations and responsive UI. Local storage via SharedPreferences is sufficient for workout data.

5. **Rule coverage**: Flutter rules from awesome-cursorrules are applied and align with the scaffold.

Jetpack Compose was ruled out for lack of iOS support. React Native + Expo is a solid alternative, but Flutter's unified stack and performance profile are a better fit for this project.

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0+)
- Android Studio / Xcode (for device/simulator)

### Setup

1. Clone the repository.
2. Install dependencies:

```bash
make pub-get
```

### Run

```bash
make run
```

Or target a specific platform:

```bash
make run-linux
make run-chrome
```

### Build

```bash
make build-apk   # Android APK
make build-ios    # iOS (macOS only)
```

---

## Makefile Commands

The project includes a `Makefile` to standardise common development workflows. This avoids remembering long CLI commands and ensures every team member uses the same flags and options.

Run `make help` to see all available commands.

| Command | Description |
|---------|-------------|
| `make run` | Run the app in debug mode (auto-detects connected device) |
| `make run-linux` | Run the app on Linux desktop |
| `make run-chrome` | Run the app on Chrome (web) |
| `make pub-get` | Install or update Flutter dependencies |
| `make gen-l10n` | Regenerate localisation Dart files from ARB sources |
| `make format` | Format all Dart files in `lib/` and `test/` |
| `make lint` | Check formatting without applying changes (CI-friendly) |
| `make analyze` | Run Flutter static analysis (`flutter analyze`) |
| `make fix` | Apply automated Dart fixes (`dart fix --apply`) |
| `make test` | Run the full test suite (unit + widget + e2e) |
| `make test-unit` | Run only unit tests |
| `make test-widget` | Run only widget tests |
| `make test-e2e` | Run only end-to-end tests |
| `make test-coverage` | Run tests and generate an LCOV coverage report |
| `make build-apk` | Build a release Android APK |
| `make build-ios` | Build a release iOS bundle (macOS only) |
| `make clean` | Remove build artifacts and re-fetch dependencies |
| `make ci` | Full CI pipeline: format + analyze + test |

---

## Project Structure (Hexagonal Architecture)

```
assets/
├── data/
│   ├── exercises_es.json
│   ├── exercises_en.json
│   └── mobility_routines/
│       └── feet_ankles_2.json
└── images/
    └── gym_background.png

lib/
├── main.dart
├── l10n/
│   ├── app_es.arb
│   ├── app_en.arb
│   └── app_localizations*.dart
├── domain/
│   ├── entities/
│   │   ├── exercise.dart
│   │   ├── routine.dart
│   │   ├── mobility_routine.dart
│   │   ├── mobility_session.dart
│   │   ├── training_day.dart
│   │   ├── workout_session.dart
│   │   ├── muscle_group.dart
│   │   └── user_profile.dart
│   └── ports/
│       ├── storage_port.dart
│       ├── profile_port.dart
│       ├── routine_port.dart
│       ├── training_day_port.dart
│       ├── workout_session_port.dart
│       └── mobility_session_port.dart
├── data/
│   └── datasources/
│       ├── local_storage_datasource.dart
│       ├── profile_datasource.dart
│       ├── routine_datasource.dart
│       ├── training_day_datasource.dart
│       ├── workout_session_datasource.dart
│       └── mobility_session_datasource.dart
└── presentation/
    ├── components/
    │   ├── language_selector.dart
    │   ├── selectable_option_card.dart
    │   ├── routine_type_helper.dart
    │   ├── mobility_exercise_tile.dart
    │   └── delete_routine_dialog.dart
    └── screens/
        ├── loading_screen.dart
        ├── get_profile_flow.dart
        ├── landing_screen.dart
        ├── profile_summary_screen.dart
        ├── profile/
        ├── routine/
        ├── workout/
        └── mobility/

archive/
├── gym_tracker_compose/   # Android Jetpack Compose scaffold
├── gym_tracker_flutter/   # Early Flutter scaffold
└── gym_tracker_expo/      # React Native + Expo scaffold

test/
├── helpers/
│   └── test_helpers.dart
├── unit/
│   ├── data/
│   └── domain/
├── widget/
│   ├── profile flow tests
│   ├── routine creation/detail tests
│   ├── workout flow tests
│   └── landing and mobility tests
└── e2e/
    ├── onboarding_flow_test.dart
    └── language_switch_test.dart
```

---

## Local Storage

The `StoragePort` interface defines the contract. `LocalStorageDatasource` implements it using SharedPreferences. Usage:

```dart
await storage.set('key', 'value');
final value = await storage.get('key');
await storage.remove('key');
```

---

## Archived Scaffolds

The React Native + Expo and Android Jetpack Compose scaffolds are available in the `archive/` directory for reference.
