# Framework Evaluation - Gym Tracker App

## Multi-Agent Evaluation Process

Three framework alternatives were scaffolded by simulated agents, each following the same requirements:

- Hexagonal (ports & adapters) architecture
- Basic white screen
- Local storage adapter (no network)
- Cursor rules from awesome-cursorrules

## Analysis of Alternatives

### Option A: Flutter

| Aspect | Assessment |
|--------|------------|
| **Structure** | `lib/domain/ports/`, `lib/data/datasources/`, `lib/presentation/screens/` – clear hexagonal layers |
| **Local storage** | SharedPreferences via `LocalStorageDatasource` implementing `StoragePort` |
| **White screen** | `HomeScreen` with `Scaffold(backgroundColor: Colors.white)` |
| **Rules** | code-guidelines, code-style-consistency, flutter-best-practices, git-conventional-commits |
| **Cross-platform** | Android, iOS, Web |
| **Language** | Dart |

**Pros**: Single codebase, hot reload, Material 3, strong hexagonal support, native performance.

**Cons**: Dart learning curve if team is JS-focused.

---

### Option B: React Native + Expo

| Aspect | Assessment |
|--------|------------|
| **Structure** | `src/domain/ports/`, `src/data/datasources/`, `src/presentation/screens/` – hexagonal layout |
| **Local storage** | AsyncStorage via `LocalStorageDatasource` implementing `StoragePort` |
| **White screen** | `HomeScreen` with `View style={{ backgroundColor: '#ffffff' }}` |
| **Rules** | code-guidelines, code-style-consistency, react-native-expo, git-conventional-commits |
| **Cross-platform** | Android, iOS, Web |
| **Language** | TypeScript |

**Pros**: Large ecosystem, TypeScript, familiar to web developers, Expo tooling.

**Cons**: Bridge overhead, larger app size, more moving parts than Flutter.

---

### Option C: Android Jetpack Compose

| Aspect | Assessment |
|--------|------------|
| **Structure** | `domain/ports/`, `data/datasource/`, `presentation/screens/` – clean architecture |
| **Local storage** | SharedPreferences via `LocalStorageDatasource` implementing `StoragePort` (suspend API) |
| **White screen** | `HomeScreen` Composable with `Box(Modifier.background(Color.White))` |
| **Rules** | code-guidelines, code-style-consistency, android-jetpack-compose, git-conventional-commits |
| **Cross-platform** | Android only |
| **Language** | Kotlin |

**Pros**: Native Android, best performance, Material 3, Kotlin coroutines.

**Cons**: No iOS support; separate codebase needed for iOS.

---

## Selection Criteria

- Hexagonal separation (domain, ports, adapters)
- Simplicity and maintainability
- Cross-platform support (Android + iOS preferred)
- Quality of applied rules

## Winner: Flutter

**Justification**:

1. **Cross-platform**: Supports Android and iOS from one codebase, matching the “would be great if iOS” requirement.

2. **Hexagonal fit**: Domain (`StoragePort`), data (`LocalStorageDatasource`), and presentation are cleanly separated. Dependency direction is correct (data → domain).

3. **Maintainability**: Single codebase, consistent structure, and strong typing with Dart null safety.

4. **Gym app fit**: Good for fitness apps with animations and responsive UI. Local storage via SharedPreferences is sufficient for workout data.

5. **Rule coverage**: Flutter rules from awesome-cursorrules are applied and align with the scaffold.

Jetpack Compose was ruled out for lack of iOS support. React Native + Expo is a solid alternative, but Flutter’s unified stack and performance profile are a better fit for this project.
