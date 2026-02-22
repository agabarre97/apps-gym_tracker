# Auditoría UI/UX y Guía de Estilo: "Gym: all in one"

## 1. Auditoría Heurística de Nielsen

Esta auditoría evalúa la interfaz actual contra los principios heurísticos de Jakob Nielsen, con el objetivo de reducir la fricción y permitir al usuario completar sus rutinas lo más rápido posible.

### 1.1 Visibilidad del estado del sistema
* **Positivo**: El calendario en `LandingScreen` muestra claramente qué días tienen entrenamiento. El onboarding (`GetProfileFlow`) tiene un indicador de progreso lineal.
* **Área de mejora**: Durante un `WorkoutSession`, el usuario necesita retroalimentación visual inmediata al completar una serie (ej. cambio de color de la celda, animación de completado). El temporizador de descanso debe ser muy visible y fácil de saltar/ajustar.

### 1.2 Prevención de errores
* **Positivo**: Se usan diálogos de confirmación destructivos (ej. `DeleteRoutineDialog`).
* **Área de mejora**: Al ingresar pesos o repeticiones, el teclado debe ser estrictamente numérico. Considerar autocompletar con el peso/repeticiones de la última sesión para evitar escritura repetitiva.

### 1.3 Control y libertad del usuario
* **Positivo**: Flujos cancelables y navegación hacia atrás permitida en la mayoría de pantallas.
* **Área de mejora**: En el registro del entrenamiento, permitir deshacer rápidamente si el usuario marca una serie como completada por error.

### 1.4 Consistencia y estándares
* **Positivo**: Uso constante de `SelectableOptionGridCard` y un sistema centralizado de espaciados (`AppSpacing`).
* **Área de mejora**: Mantener la coherencia semántica de colores (ej. Verde solo para completar/positivo, Rojo solo para borrar/peligro).

### 1.5 Flexibilidad y eficiencia de uso (Crucial para Gym)
* **Positivo**: Acceso directo al botón "Train" desde el Landing.
* **Área de mejora**: La selección de la rutina para hoy debería estar preseleccionada basada en el calendario. "Iniciar entrenamiento de hoy" debería requerir 1 solo toque.

---

## 2. Mapa de Calor Teórico (Zonas de Atención Visual)

Para que el usuario inicie y complete sus rutinas sin fricción, la interfaz debe priorizar la acción principal.

### 2.1 Landing Screen (Dashboard)
* **Zona Caliente (Rojo - Alta Atención):**
  * Botón primario de "Entrenar Hoy" (Flotante o centrado abajo, tamaño grande).
  * Día actual en el calendario.
* **Zona Templada (Amarillo - Media Atención):**
  * Rutina sugerida para hoy o próxima rutina.
* **Zona Fría (Azul - Baja Atención):**
  * Acceso al perfil, ajustes, selector de idioma.

### 2.2 Workout Session (Registro Activo)
* **Zona Caliente:**
  * Celda de la serie actual (Input de Peso y Repeticiones).
  * Botón de "Completar Serie" (Check) adyacente al input.
  * Temporizador de descanso (cuando está activo).
* **Zona Templada:**
  * Nombre del ejercicio actual y navegación rápida a siguientes ejercicios.
  * Historial rápido (peso de la sesión anterior).
* **Zona Fría:**
  * Botones globales (Finalizar entrenamiento, Cancelar).

---

## 3. Checklist de Accesibilidad

- [ ] **Contraste WCAG 2.1 (AA)**: El texto regular tiene un ratio mínimo de 4.5:1 y el texto grande 3:1 respecto a su fondo en ambos temas.
- [ ] **Áreas táctiles (Touch Targets)**: Todos los botones, iconos interactivos y switches tienen un área mínima de 44x44 dp (siguiendo `buttonHeightSmall: 44` definido en AppSizes).
- [ ] **Teclados apropiados**: Todos los inputs de peso/medidas abren teclados numéricos (`TextInputType.numberWithOptions(decimal: true)`).
- [ ] **Feedback visual**: Los botones cambian su estado visual en hover/pressed.
- [ ] **Legibilidad**: Fuentes legibles, evitando pesos excesivamente finos (`w300` o menos) para lectura larga.

---

## 4. Guía de Estilo Actualizada ("Gym: all in one")

### 4.1 Identidad
* **Nombre Oficial**: Gym: all in one
* **Concepto Visual**: Limpio, enfocado en datos, profesional. Sin distracciones.

### 4.2 Sistema Dual Theme (Paleta de Colores)

#### Modo Oscuro (Existente / Refinado)
* **Scaffold Background**: `#1C1C1E` (Gris muy oscuro, relaja la vista)
* **Surface/Cards**: `#2C2C2E` (Para elevación nivel 1)
* **Primary**: `#FFFFFF` (Blanco puro para acciones principales)
* **Text Primary**: `#FFFFFF` (100% opacidad)
* **Text Secondary**: `#FFFFFF` (70% opacidad, equivale a `Colors.white70`)
* **Text Subtle**: `#FFFFFF` (38% opacidad, equivale a `Colors.white38`)

#### Modo Claro (Nuevo)
* **Scaffold Background**: `#F2F2F7` (Gris niebla claro, estilo iOS, no fatiga)
* **Surface/Cards**: `#FFFFFF` (Blanco puro, crea contraste limpio con el fondo)
* **Primary**: `#000000` o `#1C1C1E` (Negro profundo para acciones principales, brutalista y moderno)
* **Text Primary**: `#000000` (100% opacidad)
* **Text Secondary**: `#3C3C43` (Gris oscuro legible, 60% opacidad)
* **Text Subtle**: `#3C3C43` (Gris medio, 30% opacidad)
* **Border/Divider**: `#E5E5EA` (Gris muy sutil para separar contenido)

#### Colores Semánticos (Ambos modos)
* **Success/Complete**: `#34C759` (Verde vibrante, para completar series)
* **Destructive/Delete**: `#FF3B30` (Rojo intenso)
* **Rest/Timer**: `#007AFF` (Azul para temporizadores o estados neutrales-activos)

### 4.3 Tipografía (Basada en sistema Material)
* Mantener tipografía sin serifa legible (ej. Inter o Roboto).
* **Headings**: Pesos Bold (`w700`) o SemiBold (`w600`).
* **Body**: Peso Regular (`w400`).
* **Números (Métricas/Relojes)**: Tabular figures para evitar que los números "salten" al cambiar.

### 4.4 Componentes y Estados
* **Botón Primario**:
  * Default: Fondo Primary, Texto invertido.
  * Pressed: 80% Opacidad.
  * Disabled: Fondo Surface opaco, texto sutil.
* **Tarjetas (`Card`)**:
  * Borde redondeado: `16dp` o `12dp` (según `AppSizes`).
  * Sombra: Sin sombra en modo oscuro. Sombra muy suave en modo claro (`blurRadius: 8, color: Colors.black.withOpacity(0.05)`).
