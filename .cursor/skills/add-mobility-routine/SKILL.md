---
name: add-mobility-routine
description: Add a new predefined mobility routine from Bend to the gym tracker app. Use when the user asks to add a mobility routine, mentions a Bend routine URL, or wants to add exercises from bend.com.
---

# Add Mobility Routine

Adds a predefined mobility routine (sourced from [bend.com](https://bend.com)) to the app. Requires modifying exactly 5 files plus running one command.

## Input Required

From the Bend routine page, extract:

1. **Routine name** (EN + ES)
2. **Total duration** (from the page title, e.g. "13-Minute Flexibility Routine" = 13)
3. **Exercise list** with: name, duration per exercise, and whether it is bilateral
   - `bilateral: true` = centered/symmetric (e.g. butterfly, cat-cow, squat)
   - `bilateral: false` = one side then the other (e.g. pigeon, lunges, figure four)
   - `duration_seconds` = per-side duration; the timer will double it for non-bilateral
   - Bend page shows **total** time — if bilateral:false, divide by 2 for `duration_seconds`
4. **Routine key**: `snake_case` identifier (e.g. `hips`, `pelvic_tilt`, `feet_ankles_2`)
5. **Subtype**: which mobility category it belongs to (`tobillos`, `cadera`, or a new one)

## Checklist

Work through each step in order. Mark done as you go.

### Step 1: Create JSON asset

**File**: `assets/data/mobility_routines/{routine_key}.json`

```json
{
  "key": "{routine_key}",
  "name_key": "mobility_{routine_key}",
  "total_duration_minutes": {N},
  "exercises": [
    {"key": "{exercise_snake_key}", "duration_seconds": {N}, "bilateral": {true|false}}
  ]
}
```

The `assets/data/mobility_routines/` directory is already registered in `pubspec.yaml` — no change needed there.

### Step 2: Add localization keys

**Files**: `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb`

Add **routine name** keys after the existing `mobilityFeetAnkles2` / `mobilityPelvicTilt` / `mobilityHips` block:

```
"mobility{CamelCaseRoutineKey}": "Routine Display Name",
```

Add **exercise name** keys after the last exercise block (before `"mobilityRoutineNotFound"`). Use a section comment for grouping:

```
"@@_MOBILITY_EXERCISES_{UPPER_KEY}": "Description",
"mobility{CamelCaseExerciseName}": "Exercise Display Name",
```

**Convention**: ARB keys use `mobility` prefix + camelCase of the snake_case key. Examples:
- `lying_figure_four` -> `mobilityLyingFigureFour`
- `cat_cow` -> `mobilityCatCow`
- `pelvic_tilt` (as exercise) -> `mobilityPelvicTiltExercise` (suffix to distinguish from routine name)

**Important**: If an exercise already exists in another routine (check `_mobilityExerciseNameGetters` in the tile file), do NOT add duplicate ARB keys.

### Step 3: Add exercise name getters

**File**: `lib/presentation/components/mobility_exercise_tile.dart`

Add entries to `_mobilityExerciseNameGetters` map. Group by routine with a comment:

```dart
// {Routine Name} routine
'{exercise_snake_key}': (l) => l.mobility{CamelCaseName},
```

Skip exercises that already have an entry in the map (shared across routines).

### Step 4: Register routine in creation flow

**File**: `lib/presentation/screens/routine/create_routine_flow.dart`

Two maps to update:

1. `_routineNameGetters` — add:
   ```dart
   '{routine_key}': (l) => l.mobility{CamelCaseRoutineKey},
   ```

2. `_routinesBySubType` — append the routine key to the existing subtype list:
   ```dart
   '{subtype}': ['existing_key', '{routine_key}'],
   ```

If the subtype is **new** (not yet in the map), also:
- Add the subtype to `_routinesBySubType`
- Add a `SelectableOption` entry in `lib/presentation/screens/routine/mobility_subtype_screen.dart`
- Add the subtype name l10n key to both ARB files

### Step 5: Regenerate localizations

```bash
flutter gen-l10n
```

### Step 6: Verify

Run `flutter analyze` to check for compilation errors. Key things to verify:
- JSON is valid (no trailing commas)
- All ARB keys referenced in the exercise name getters and routine name getters exist
- No duplicate ARB keys

## Example: Existing Routines

| Key | Subtype | Duration | Exercises |
|-----|---------|----------|-----------|
| `feet_ankles_2` | `tobillos` | 11 min | 14 exercises |
| `pelvic_tilt` | `cadera` | 7 min | 9 exercises |
| `hips` | `cadera` | 13 min | 9 exercises |

## Reference Files

| Purpose | Path |
|---------|------|
| JSON assets | `assets/data/mobility_routines/` |
| English l10n | `lib/l10n/app_en.arb` |
| Spanish l10n | `lib/l10n/app_es.arb` |
| Exercise name map | `lib/presentation/components/mobility_exercise_tile.dart` |
| Routine registry | `lib/presentation/screens/routine/create_routine_flow.dart` |
| Subtype screen | `lib/presentation/screens/routine/mobility_subtype_screen.dart` |
| Entity model | `lib/domain/entities/mobility_routine.dart` |
