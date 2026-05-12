# HydroTracker Architecture Guide v2

> **For AI assistants:** Read this file COMPLETELY before writing a single line 
> of code. This is your system prompt. Violating any rule here will break the app.

---

## 1. Project Structure

lib/
├── app.dart                  # MaterialApp, route table, AppRoutes constants
├── main.dart                 # Firebase init, demo data bootstrap, runApp
├── firebase_options.dart     # FlutterFire generated config
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart   # Única fuente de verdad para colores
│   │   └── app_theme.dart    # ThemeData, sin gradientes
│   ├── demo_data_service.dart
│   ├── firebase_service.dart
│   ├── firebase_constants.dart
│   └── phone_utils.dart
│
├── models/
│   ├── sensor_data.dart
│   └── plant_profile.dart
│
├── domain/repositories/
│   ├── sensor_repository.dart
│   └── plant_repository.dart
│
├── data/repositories/
│   ├── sensor_repository_impl.dart
│   └── plant_repository_impl.dart
│
└── presentation/
    ├── providers/
    │   └── app_providers.dart    # TODOS los providers van aquí, sin excepción
    ├── screens/
    │   ├── dashboard_screen.dart
    │   ├── history_screen.dart
    │   ├── plant_selector_screen.dart
    │   ├── settings_screen.dart       # NUEVA
    │   └── onboarding/
    │       ├── vinculation_screen.dart
    │       ├── sms_verification_screen.dart
    │       ├── perfil_screen.dart
    │       └── esp32_vinculacion_screen.dart
    └── widgets/
        ├── common/
        │   ├── app_scaffold.dart      # Renombrado de GradientScaffold
        │   └── app_card.dart          # Renombrado de GlassCard
        └── dashboard/
            ├── circular_metric.dart
            ├── illuminated_button.dart  # NUEVO — reemplaza PumpButton y Switch
            └── status_chip.dart

---

## 2. Principios de Diseño (OBLIGATORIOS)

### Usuario objetivo
El usuario final es un agricultor urbano o entusiasta de plantas.
NO es un desarrollador. NO es técnico. 
CADA decisión de UI debe preguntarse: "¿Lo entendería alguien de 60 años 
que nunca ha usado una app de monitoreo?"

### Panel de control — IlluminatedButton
Los controles de bombas y actuadores NO usan Switch ni Toggle.
Usan IlluminatedButton: un botón que se ILUMINA cuando está activo.

Especificación de IlluminatedButton:
- Forma: rectangular redondeada (borderRadius: 12)
- Tamaño: flexible, mínimo 80x80px
- Estado APAGADO:
  * Fondo: AppColors.cardBackground (#161B22)
  * Borde: AppColors.cardBorder (#30363D), 1.5px
  * Ícono: AppColors.textMuted (#484F58)
  * Label: AppColors.textSecondary
  * Sin brillo
- Estado ENCENDIDO:
  * Fondo: color del actuador con opacidad 0.15
  * Borde: color del actuador, 2px
  * Ícono: color del actuador, tamaño ligeramente mayor
  * Label: color del actuador
  * BoxShadow: color del actuador con opacidad 0.3, blurRadius 8
  * Animación: AnimatedContainer duration 200ms
- Al presionar: feedback háptico (HapticFeedback.mediumImpact)

Colores por actuador:
- Bomba de agua: AppColors.info (#58A6FF)
- Bomba fertilizante: AppColors.accent (#238636)  
- Dosificadora ácido: AppColors.warning (#D29922)
- Dosificadora base: AppColors.success (#2EA043)

### Paleta de colores
| Token          | Valor     | Uso                        |
|----------------|-----------|----------------------------|
| background     | #0D1117   | Fondo app, Scaffold        |
| cardBackground | #161B22   | Cards, chips               |
| cardBorder     | #30363D   | Bordes, divisores          |
| textPrimary    | #FFFFFF   | Títulos, valores           |
| textSecondary  | #8B949E   | Labels, hints              |
| textMuted      | #484F58   | Deshabilitado              |
| success        | #2EA043   | En rango, OK               |
| warning        | #D29922   | Alertas                    |
| error          | #F85149   | Fuera de rango             |
| info           | #58A6FF   | Agua                       |
| accent         | #238636   | Fertilizante               |

NUNCA hardcodear colores. NUNCA usar gradientes.

### Dashboard — Reglas estrictas
- TODO debe ser visible SIN scroll en un teléfono estándar (360x800dp)
- Métricas: 5 CircularMetric en un Wrap, máximo 100x100px cada una
- Gauges: SOLO verde (en rango) o rojo (fuera de rango). Sin arcoíris.
- Controles: IlluminatedButton en una grilla 2x2
- Alertas: texto plano, ícono pequeño, sin card wrapper
- Header: una línea — nombre app + planta activa | chips de estado

### Tipografía
- Valores sensor: fontSize 20, fontWeight w700
- Títulos sección: fontSize 14, fontWeight w600  
- Labels/unidades: fontSize 11-12, color textSecondary
- Alertas: fontSize 12, color warning, máximo 2 líneas

---

## 3. Reglas de Capas

| Capa           | Responsabilidad              | Puede depender de          |
|----------------|------------------------------|----------------------------|
| Presentation   | Widgets, navegación, estado  | domain/, core/theme        |
| Domain         | Interfaces abstractas        | models/ únicamente         |
| Data           | Implementaciones Firebase    | domain/, core/*_service    |
| Core           | Firebase, demo, tema         | models/ (algunos)          |
| Models         | Datos puros, serialización   | Nada                       |

REGLA DE ORO: Las pantallas NUNCA importan FirebaseService ni 
DemoDataService directamente. SIEMPRE a través de providers.

---

## 4. Settings Screen — Especificación completa

Ruta: /settings
Archivo: lib/presentation/screens/settings_screen.dart

Secciones en orden:

### 4.1 Perfil de usuario
- Avatar circular con inicial del nombre
- Nombre de usuario (editable inline con IconButton de lápiz)
- Ciudad (editable inline)
- Al guardar: actualiza Firebase en usuarios/{uid}/

### 4.2 Cultivo activo
- Card que muestra la planta activa actual
- Botón "Cambiar cultivo" → navega a /plantas

### 4.3 Umbrales personalizados
- Sliders para temp_min, temp_max, ph_min, ph_max, ec_min, ec_max
- Valores actuales mostrados junto a cada slider
- Botón "Guardar umbrales" → escribe en Firebase profile/
- Botón "Restablecer a valores del cultivo" → recarga los del PlantProfile

### 4.4 Notificaciones
- Toggle IlluminatedButton: Alertas activadas/desactivadas
- Guarda en Firebase system/alerts_enabled

### 4.5 Sistema
- Chip de estado ESP32 (conectado/desconectado)
- Versión de la app (hardcodeada como "1.0.0")
- Botón "Reconectar ESP32" → navega a /onboarding/esp32

### 4.6 Cuenta
- Botón "Cerrar sesión" — color error, pide confirmación con AlertDialog
  antes de llamar FirebaseAuth.instance.signOut()
  Tras cerrar sesión, navega a la pantalla de vinculación

---

## 5. Manejo de EC — Regla crítica

Los valores de EC desde Firebase pueden venir en µS/cm (valores > 10).
La unidad de display SIEMPRE es mS/cm.

Regla: si rawValue > 10, displayValue = rawValue / 1000
Esta conversión se hace en la capa de presentación, no en el modelo.
Aplicar en: dashboard_screen, history_screen, settings_screen, 
y cualquier nueva pantalla que muestre EC.

---

## 6. Firebase RTDB Schema

sensors/
  temperatura: double (°C)
  ph: double
  conductividad: double (puede venir en µS/cm, ver §5)
  nivel_agua: bool
  nivel_fertilizante: double (0-100%)
  bomba_agua: bool
  bomba_fertilizante: bool
  timestamp: int

profile/
  planta: string
  temp_min: double
  temp_max: double
  ph_min: double
  ph_max: double
  ec_min: double
  ec_max: double
  hum_min: double
  hum_max: double

controls/
  bomba_agua: bool
  bomba_fertilizante: bool
  bomba_dosificadora_acido: bool
  bomba_dosificadora_basico: bool
  riego_automatico: bool

history/
  {pushKey}/
    timestamp: int
    temperatura: double
    ph: double
    conductividad: double
    nivel_agua_tanque: bool
    nivel_fertilizante_tanque: double

system/
  alerts_enabled: bool
  version: string

usuarios/{uid}/
  nombre: string
  ciudad: string
  creado: int
  esp32_vinculado: bool

esp32/
  heartbeat: any

---

## 7. Consistencia — Lista de verificación antes de entregar código

Antes de entregar cualquier archivo, la IA debe verificar:

[ ] ¿Todas las pantallas usan AppScaffold?
[ ] ¿Ninguna pantalla importa FirebaseService directamente?
[ ] ¿Todos los providers están en app_providers.dart?
[ ] ¿Ningún color está hardcodeado?
[ ] ¿Los controles de bombas usan IlluminatedButton, no Switch?
[ ] ¿El dashboard no hace scroll?
[ ] ¿Los valores de EC se convierten si rawValue > 10?
[ ] ¿El cierre de sesión pide confirmación?
[ ] ¿Las rutas nuevas están registradas en app.dart?
[ ] ¿Los archivos entregados compilan sin errores en Flutter 3.x + Riverpod 2.x?

Si alguna respuesta es NO, corregir antes de entregar.

---

## 8. Errores comunes — NO hacer esto

- NO usar Switch o Toggle nativo para controles de bombas
- NO crear Scaffold directamente — usar AppScaffold
- NO importar firebase_service.dart desde pantallas
- NO crear providers fuera de app_providers.dart
- NO usar gradientes ni efectos glass
- NO hacer el dashboard scrollable
- NO hardcodear strings de rutas — usar AppRoutes.xxx
- NO mostrar EC sin aplicar la conversión de unidades
- NO hacer cerrar sesión sin AlertDialog de confirmación
- NO poner lógica de negocio en widgets