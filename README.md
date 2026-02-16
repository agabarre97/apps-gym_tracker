# Gym Tracker

A cross-platform fitness companion built with Flutter. Track strength workouts, mobility routines, and HIIT sessions from a single app.

---

## Install on a Mobile Device

### Android

1. **Build the APK** (requires Flutter SDK installed on your computer):

```bash
make build-apk
```

2. The release APK is generated at:

```
build/app/outputs/flutter-apk/app-release.apk
```

3. **Transfer to your device** — send the `.apk` file via USB, cloud storage, email, or any file-sharing method.

4. **Install on the device**:
   - Open the file on the phone.
   - If prompted, enable _"Install from unknown sources"_ in Settings → Security.
   - Tap _Install_ and wait for completion.

> **Tip**: For development builds with hot reload, connect via USB and run `flutter run`.

### iPhone (iOS)

Building for iOS requires **macOS** with Xcode installed.

1. **Build the iOS bundle**:

```bash
make build-ios
```

2. **Run on a physical device** (development):
   - Open `ios/Runner.xcworkspace` in Xcode.
   - Select your Apple developer team under _Signing & Capabilities_.
   - Connect your iPhone and select it as the run target.
   - Press ▶️ to build and install.

3. **TestFlight distribution** (for sharing with testers):
   - In Xcode, select _Product → Archive_.
   - Upload the archive to App Store Connect.
   - Add testers from the TestFlight tab.

> **Note**: Free Apple developer accounts allow installing on your own device for 7 days. A paid Apple Developer account ($99/year) is needed for TestFlight or App Store distribution.

---

## Getting Started (Development)

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

---

## Features

### Strength Training (Musculación)
- Multi-day routines with muscle group and exercise selection
- Per-exercise set/rep/weight tracking with auto-fill from previous session
- Exercise progress charts (volume, max weight, total reps)
- Import/export routines as JSON

### Mobility
- Predefined routines from Bend (Feet & Ankles, Hips, Pelvic Tilt, Sleep)
- Guided timer with per-exercise countdown and bilateral support
- Exercise detail cards with instructions, tips, modifications, and benefits

### HIIT
- 18 predefined exercises (burpees, battle ropes, box jumps, etc.)
- Configurable sets, work time, rest time, and set rest time via scroll-wheel pickers
- Phase-based timer with visual countdown ring (preview → exercise → rest → set rest → complete)
- Edit exercises from the routine detail screen
- Warning when selecting more than 6 exercises

### Calendar & Training Log
- Calendar with green markers for trained days
- "Train" button for live sessions with time tracking
- "Add training" for logging past/today sessions:
  - Strength: full workout editor (weights, reps)
  - Mobility / HIIT: quick log with confirmation (no weights to edit)
- View past session details

### Profile & Onboarding
- Guided onboarding flow: basic info → body measurements → goals → welcome
- Profile summary with export capabilities
- Language toggle (Spanish / English) with persistent locale

### Authentication (Optional)
- Firebase Auth with email/password and Google Sign-In
- Synced cloud storage when authenticated
- Works fully offline without auth

---

## Makefile Commands

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
│   ├── exercises_es.json         # Strength exercises (Spanish)
│   ├── exercises_en.json         # Strength exercises (English)
│   ├── hiit_exercises_es.json    # HIIT exercises (Spanish)
│   ├── hiit_exercises_en.json    # HIIT exercises (English)
│   ├── mobility_routines/        # Predefined mobility routines
│   │   ├── feet_ankles_2.json
│   │   ├── hips.json
│   │   ├── pelvic_tilt.json
│   │   └── sleep.json
│   └── mobility_exercises_info/  # Exercise instructions/tips
│       ├── es.json
│       └── en.json
└── images/
    └── gym_background.png

lib/
├── main.dart
├── l10n/                         # Localisation (ES/EN)
│   ├── app_es.arb
│   ├── app_en.arb
│   └── app_localizations*.dart
├── domain/
│   ├── entities/
│   │   ├── exercise.dart         # Strength exercise model
│   │   ├── hiit_exercise.dart    # HIIT exercise model
│   │   ├── hiit_config.dart      # HIIT config value object (sets, durations, limits)
│   │   ├── hiit_session.dart     # Completed HIIT session record
│   │   ├── routine.dart          # Routine with days, type, and optional HiitConfig
│   │   ├── mobility_routine.dart # Mobility routine with timed exercises
│   │   ├── mobility_session.dart # Completed mobility session record
│   │   ├── mobility_exercise_info.dart  # Exercise instructions/tips/benefits
│   │   ├── training_day.dart     # Calendar training day marker
│   │   ├── workout_session.dart  # Strength workout session with sets
│   │   ├── muscle_group.dart     # Muscle group categories and filtering
│   │   └── user_profile.dart     # User profile (body info, goals)
│   ├── ports/
│   │   ├── storage_port.dart     # Key-value storage interface
│   │   ├── auth_port.dart        # Authentication interface
│   │   ├── sync_port.dart        # Cloud sync interface
│   │   ├── profile_port.dart
│   │   ├── routine_port.dart
│   │   ├── training_day_port.dart
│   │   ├── workout_session_port.dart
│   │   ├── mobility_session_port.dart
│   │   └── hiit_session_port.dart
│   └── services/
│       └── workout_session_builder.dart  # Session auto-fill from history
├── data/
│   └── datasources/
│       ├── asset_data_loader.dart        # Centralized JSON asset loading
│       ├── local_storage_datasource.dart # SharedPreferences storage
│       ├── firebase_auth_datasource.dart
│       ├── synced_storage_datasource.dart
│       ├── profile_datasource.dart
│       ├── routine_datasource.dart
│       ├── training_day_datasource.dart
│       ├── workout_session_datasource.dart
│       ├── mobility_session_datasource.dart
│       └── hiit_session_datasource.dart
└── presentation/
    ├── components/
    │   ├── circular_timer_painter.dart   # Shared countdown ring painter
    │   ├── time_wheel_picker.dart        # Scroll-wheel time picker
    │   ├── routine_type_helper.dart      # Type → icon/label mapping
    │   ├── language_selector.dart
    │   ├── selectable_option_card.dart
    │   ├── mobility_exercise_tile.dart
    │   ├── mobility_exercise_detail_sheet.dart
    │   ├── export_sheet.dart
    │   └── delete_routine_dialog.dart
    ├── utils/
    │   └── time_formatter.dart           # Shared MM:SS / "X min Ys" formatting
    └── screens/
        ├── loading_screen.dart
        ├── get_profile_flow.dart
        ├── landing_screen.dart           # Calendar, train, routines list
        ├── profile_summary_screen.dart
        ├── auth/
        │   └── auth_screen.dart
        ├── profile/
        │   ├── basic_info_screen.dart
        │   ├── advanced_measures_1_screen.dart
        │   ├── advanced_measures_2_screen.dart
        │   ├── goals_screen.dart
        │   └── welcome_screen.dart
        ├── routine/
        │   ├── create_routine_flow.dart  # Multi-step creation wizard
        │   ├── routine_type_screen.dart
        │   ├── days_selection_screen.dart
        │   ├── muscle_group_selection_screen.dart
        │   ├── exercise_selection_screen.dart
        │   ├── exercise_detail_sheet.dart
        │   ├── routine_summary_screen.dart
        │   ├── routine_detail_screen.dart
        │   ├── mobility_subtype_screen.dart
        │   ├── mobility_option_screen.dart
        │   └── mobility_routine_selection_screen.dart
        ├── workout/
        │   ├── routine_picker_screen.dart
        │   ├── day_picker_screen.dart
        │   ├── workout_session_screen.dart
        │   ├── exercise_progress_screen.dart
        │   └── exercise_progress_calculator.dart
        ├── mobility/
        │   ├── mobility_routine_detail_screen.dart
        │   └── mobility_timer_screen.dart
        └── hiit/
            ├── hiit_exercise_selection_screen.dart
            ├── hiit_config_screen.dart
            ├── hiit_detail_screen.dart
            └── hiit_timer_screen.dart

test/
├── helpers/
│   ├── test_helpers.dart         # Fakes and buildTestableWidget()
│   └── scroll_helpers.dart       # WidgetTester scroll extensions
├── unit/
│   ├── data/                     # Datasource unit tests
│   ├── domain/                   # Entity + service unit tests
│   └── presentation/             # Component unit tests
├── widget/                       # Individual screen widget tests
└── e2e/                          # Full-flow integration tests
    ├── onboarding_flow_test.dart
    ├── language_switch_test.dart
    ├── hiit_creation_flow_test.dart
    └── hiit_timer_flow_test.dart
```

---

## Local Storage

The `StoragePort` interface defines the contract. `LocalStorageDatasource` implements it using SharedPreferences:

```dart
await storage.set('key', 'value');
final value = await storage.get('key');
await storage.remove('key');
```

---

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| **Hexagonal (ports & adapters)** | Domain entities have zero Flutter dependencies; data and presentation depend inward |
| **`AssetDataLoader`** | Centralizes `rootBundle` calls in the data layer, keeping domain pure |
| **`HiitConfig` value object** | Encapsulates HIIT defaults/limits in one place instead of scattered nullable fields |
| **`WorkoutSessionBuilder`** | Extracts session-creation logic from UI coordinators into a testable domain service |
| **`CircularTimerPainter` / `TimeFormatter`** | Shared presentation utilities extracted from duplicated code in timer screens |
| **`ScrollHelpers` test extension** | Standardizes fragile scroll-to-find patterns across widget and e2e tests |

### Remaining Technical Debt

- **Port parameter threading**: `LandingScreen`, `LoadingScreen`, and `_SignedOutRedirect` pass ~10 port parameters through constructors. A future `InheritedWidget`-based service locator would reduce this boilerplate.
- **Plyometrics**: Routine type is defined but not yet implemented.
- **Custom mobility routines**: Only predefined (Bend) routines are available; the custom creation flow is not yet implemented.

---

## Archived Scaffolds

The React Native + Expo and Android Jetpack Compose scaffolds are available in the `archive/` directory for reference.
