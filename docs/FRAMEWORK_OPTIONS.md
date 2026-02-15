# Framework Options and Agent Assignments

## Phase 1: Three App Framework Options

The three best options for building an app with Android focus and optional iOS support:

| Option | Framework | Platform Coverage | Language | awesome-cursorrules Match |
|--------|-----------|-------------------|----------|---------------------------|
| **A** | **Flutter** | Android, iOS, Web | Dart | `flutter-app-expert-cursorrules-prompt-file` |
| **B** | **React Native + Expo** | Android, iOS, Web | TypeScript | `react-native-expo` + `typescript-expo-jest-detox` |
| **C** | **Android Jetpack Compose** | Android only (native) | Kotlin | `android-jetpack-compose-cursorrules-prompt-file` |

### Summary

- **Flutter**: Best DX (hot reload), rich UI, single codebase. Use if you prioritize animations and shared UI.
- **React Native + Expo**: Largest JS/TS ecosystem, fast iteration. Use if your team knows React/TypeScript.
- **Jetpack Compose**: Native Android, best performance, Material 3. Use if you only need Android or want maximum control.

---

## Phase 2: Agent Assignment

| Agent | Model | Assigned Framework |
|-------|-------|--------------------|
| Agent 1 | Composer 1.5 | **Flutter** |
| Agent 2 | Claude 4.6 Opus High | **React Native + Expo** |
| Agent 3 | GPT 5.3 Codex | **Android Jetpack Compose** |

Each agent creates its framework's scaffold in a separate folder:
- **Flutter**: `gym_tracker_flutter/`
- **React Native**: `gym_tracker_expo/`
- **Jetpack Compose**: `gym_tracker_compose/`
