# CONTEXT.md — Gym Tracker

Documento de contexto para agentes y desarrolladores: resume el propósito del proyecto, la arquitectura, los puntos calientes del código y decisiones recientes inferidas del trabajo en Cursor (transcripts y cambios típicos). **No sustituye** al [README.md](README.md) para instalación, Makefile ni scraping MuscleWiki.

---

## Qué es esta aplicación

- **Nombre**: `gym_tracker` (Flutter, SDK Dart `>=3.0.0`).
- **Propósito**: compañero de entrenamiento multi-modal: **musculación** (rutinas multi-día, series/peso/repes), **movilidad** (rutinas tipo Bend con temporizador), **HIIT** (temporizador por fases), **calendario / historial**, **perfil / onboarding**, **i18n ES/EN**.
- **Auth opcional**: Firebase Auth (email + Google); con usuario activo los datos pueden sincronizarse vía Firestore; **sin auth funciona offline** con almacenamiento local.

---

## Arquitectura (hexagonal)

- **Dominio** (`lib/domain/`): entidades y puertos sin dependencias de Flutter.
- **Datos** (`lib/data/datasources/`): implementaciones de puertos (SharedPreferences, assets JSON, Firebase opcional).
- **Presentación** (`lib/presentation/`): pantallas, tema, componentes reutilizables.

Flujo típico: pantalla → puerto → datasource → `StoragePort` (local o sincronizado).

### Arranque y DI manual

- [`lib/main.dart`](lib/main.dart): inicializa `SharedPreferences`, intenta Firebase si la plataforma lo soporta; si hay usuario, `SyncedStorageDatasource` usa su `uid`; construye los puertos (`ProfilePort`, `RoutinePort`, `WorkoutSessionPort`, etc.) y arranca `GymTrackerApp`.
- **Deuda conocida** (README): muchos puertos se pasan por constructores hasta pantallas como `LandingScreen` / `LoadingScreen`; no hay un service locator central.

---

## Datos y persistencia

- **Contrato genérico**: `StoragePort` (get/set/remove por clave string).
- **Local**: `LocalStorageDatasource` → SharedPreferences.
- **Sync**: `SyncedStorageDatasource` refleja el mismo modelo en Firestore bajo el usuario (detalle en código del datasource).
- **Sesiones de fuerza**: JSON bajo claves definidas en [`lib/data/datasources/workout_session_datasource.dart`](lib/data/datasources/workout_session_datasource.dart) (lista serializada de `WorkoutSession`).
- **Catálogo / rutinas movilidad / HIIT**: JSON en `assets/data/` cargados vía `AssetDataLoader` / rutas equivalentes.

---

## Dominio relevante (musculación)

### Entidades clave

- [`lib/domain/entities/workout_session.dart`](lib/domain/entities/workout_session.dart): `WorkoutSession`, `WorkoutExercise`, `ExerciseSet`. Las series pueden ser **drop sets** (`isDropSet`, `dropParentSetNumber` 1-based).
- [`lib/domain/entities/routine.dart`](lib/domain/entities/routine.dart): `Routine`, `RoutineDay`, `RoutineExerciseConfig`, `RoutineSetConfig` (`dropSetCount`, `dropSetReps`, etc.).
- [`lib/domain/entities/exercise.dart`](lib/domain/entities/exercise.dart): ejercicios del catálogo; los entrenamientos referencian **`exerciseKey`**, no solo el nombre visible.

### Construcción de sesión nueva y referencias históricas

- Servicio: [`lib/domain/services/workout_session_builder.dart`](lib/domain/services/workout_session_builder.dart) (`WorkoutSessionBuilder.build`).
- **Sesiones candidatas**: misma `routineId`, mismo `routineDayIndex`, tiempo efectivo (`startTime ?? date`) **no posterior** al tiempo objetivo de la nueva sesión; orden **más reciente primero**.
- **Referencias por ejercicio (no por sesión única)**: para cada `exerciseKey`, se busca la **primera sesión candidata** (en ese orden temporal) que contenga ese ejercicio con `sets.isNotEmpty`. Así un ejercicio omitido en la última sesión sigue pudiendo tomar datos de una sesión anterior válida.
- **Drop sets al construir la siguiente sesión**: ya **no** se hace solo matching posicional plano de `previousSets[i]` frente a la rejilla expandida. Se parte las series previas en **principales** y **drops agrupados por `dropParentSetNumber`**. Para cada serie principal de la rutina, el número de filas drop generadas es `max(dropSetCount de la rutina, drops previos para ese padre)`, de modo que los drops **manuales** (rutina con `dropSetCount == 0`) pueden persistir entre sesiones sin desplazar pesos de las series principales.

### Otros servicios de dominio

- [`lib/domain/services/exercise_progress_calculator.dart`](lib/domain/services/exercise_progress_calculator.dart), [`lib/domain/services/rest_time_calculator.dart`](lib/domain/services/rest_time_calculator.dart), [`lib/domain/services/routine_pdf_export_service.dart`](lib/domain/services/routine_pdf_export_service.dart): lógica extraída para tests y reutilización.

---

## Presentación — mapa rápido

| Área | Rutas típicas |
|------|----------------|
| Entrada / splash / locale | [`lib/main.dart`](lib/main.dart), [`loading_screen.dart`](lib/presentation/screens/loading_screen.dart) |
| Home / calendario / flujo entrenar | [`landing_screen.dart`](lib/presentation/screens/landing_screen.dart), [`home_screen.dart`](lib/presentation/screens/home_screen.dart) |
| Rutinas (crear, editar, musculación, movilidad, HIIT) | [`lib/presentation/screens/routine/`](lib/presentation/screens/routine/) |
| Sesión musculación | [`workout_session_screen.dart`](lib/presentation/screens/workout/workout_session_screen.dart), [`focused_exercise_screen.dart`](lib/presentation/screens/workout/focused_exercise_screen.dart), pickers en la misma carpeta |
| Movilidad / HIIT | [`mobility/`](lib/presentation/screens/mobility/), [`hiit/`](lib/presentation/screens/hiit/) |
| Perfil / auth | [`profile/`](lib/presentation/screens/profile/), [`auth_screen.dart`](lib/presentation/screens/auth/auth_screen.dart) |

### Comportamiento documentado en conversaciones de agentes

- **Entrenamiento a medias**: en `LandingScreen`, tras cargar datos, se puede invocar (p. ej. vía `addPostFrameCallback`) una comprobación de sesión del día con `startTime != null` y `endTime == null`, mostrando diálogo para **retomar** o continuar con flujo **nuevo**; el mismo helper puede reutilizarse desde el botón “Entrenar”. Tests de widget dedicados evitan `pumpAndSettle` indefinido por timers en `WorkoutSessionScreen`.

---

## Tests

- **Unit**: `test/unit/` — incluye [`test/unit/domain/workout_session_builder_test.dart`](test/unit/domain/workout_session_builder_test.dart) (referencias temporales, rutina/día, drops semánticos).
- **Widget**: `test/widget/` — pantallas aisladas; cuidado con **timers periódicos** (p. ej. sesión activa): usar pumps acotados en lugar de `pumpAndSettle` donde cuelgue.
- **E2E / integración**: `test/e2e/` — flujos largos (onboarding, idioma, HIIT, referencias de timeline).
- Comandos: ver tabla en README (`make test`, `make test-unit`, etc.).

---

## Convenciones del repo (Cursor / equipo)

- **Commits**: Conventional Commits (`feat(scope):`, `fix(scope):`, …) — regla en `.cursor/rules/git-conventional-commits.mdc`.
- **Estilo / calidad**: `.cursor/rules/code-guidelines.mdc` y reglas Flutter/architecture en `.cursor/rules/`.
- **Skills útiles** en `.cursor/skills/` (p. ej. añadir rutinas de movilidad desde Bend).

---

## Activos y scripts

- Imágenes, fuentes, datos JSON: `assets/` (ver `pubspec.yaml`).
- Scraper MuscleWiki: `scripts/musclewiki_scraper.py`, URLs en `scripts/exersise-urls.txt`; salidas bajo `assets/data/musclewiki/`.
- **Scaffolds archivados**: `archive/` (React Native / Compose), solo referencia.

---

## Limitaciones y deuda (resumen README)

- **Pliometría**: tipo de rutina definido, flujo no implementado del todo.
- **Movilidad custom**: principalmente rutinas predefinidas.
- **Duplicados**: si una sesión tiene el mismo `exerciseKey` dos veces, la lógica de “primera coincidencia” en builder/historial sigue el comportamiento histórico del código.

---

## Cómo usar este fichero como agente nuevo

1. Leer esta sección y el **README** (features + árbol de carpetas oficial).
2. Para bugs de **referencias o drops**, ir directo a [`workout_session_builder.dart`](lib/domain/services/workout_session_builder.dart) y tests asociados.
3. Para **UI musculación en vivo**, [`focused_exercise_screen.dart`](lib/presentation/screens/workout/focused_exercise_screen.dart) + [`workout_session_screen.dart`](lib/presentation/screens/workout/workout_session_screen.dart) (`_buildExerciseWithHistory` al añadir ejercicios en sesión tiene reglas distintas al builder — conviene comparar si el bug es “nueva sesión desde rutina” vs “añadir ejercicio en mitad de entreno”).
4. Ejecutar `make analyze` / `make test` antes de cerrar cambios importantes.

---

## Historial temático (agentes / chats)

Resumen **no exhaustivo** de hilos útiles en transcripts del proyecto (Cursor): alerta de sesión incompleta al abrir la landing y tests asociados; planes de `WorkoutSessionBuilder` para referencias por ejercicio y persistencia semántica de drop sets. Para detalle línea a línea, revisar los UUID en la carpeta de transcripts del proyecto Cursor si hace falta auditoría.

---

*Última actualización orientativa: mantener alineado con README y con cambios recientes en `WorkoutSessionBuilder` y pantallas citadas.*
