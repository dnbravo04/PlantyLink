SRS — HydroTrack v1.1
Software Requirements Specification
Proyecto: Ingeniería Agrícola – Agricultura Digital
Equipo: Michelle Vanegas, Luis Medina, Diego Bravo
Fecha: Mayo 2026

1. Introducción
1.1 Propósito
Especifica los requisitos funcionales y no funcionales de HydroTrack, app Android para monitoreo y control remoto de sistemas hidropónicos y cultivos ornamentales de interior, orientada a usuarios sin formación técnica.

1.2 Alcance
Monitoreo en tiempo real de parámetros ambientales, control manual/automático de actuadores, alertas agronómicas, perfiles de cultivo validados y configuración personalizada. Escalabilidad futura a múltiples niveles y usuarios. Sincronización vía NFC.

1.3 Definiciones
ESP32: microcontrolador WiFi que lee sensores y controla actuadores.
Firebase RTDB: base de datos en tiempo real, broker entre ESP32 y la app.
NFC: comunicación de corto alcance usada para vincular usuario al sistema.
EC: conductividad eléctrica (mS/cm).
Perfil de cultivo: parámetros óptimos (temp, pH, EC) asociados a una especie.
Actuador: bomba de agua, fertilizante, dosificadora ácido/base.

1.4 Referencias
University of Florida IFAS Extension. HS1433 – Producción de lechuga en sistemas hidropónicos.

HANNA Instruments Colombia. Hidroponía: pH y CE.

FAO. Good Agricultural Practices for greenhouse vegetable crops.

Mulla et al. (2025). Cloud-Enabled IoT System using Firebase. arXiv:2601.17414.

2. Descripción General del Sistema
2.1 Perspectiva del producto
HydroTrack es una app Android que se comunica con un ESP32 a través de Firebase RTDB. El ESP32 lee sensores y controla actuadores. La app lee y escribe en Firebase en tiempo real. El ESP32 ejecuta lógica de control local solo como respaldo ante pérdida de conexión o emergencia (seguridad). La autoridad principal es la app.

text
Sensores físicos → ESP32 [WiFi] → Firebase RTDB ↔ App Flutter (Android)
                                       ↑
Actuadores ← ESP32 (lee controls/)   Usuario
2.2 Usuarios del sistema
Un único rol: Usuario sincronizado. Todo aquel que vincule su dispositivo vía NFC tiene acceso completo. Sin distinción de administrador.

2.3 Suposiciones y dependencias
ESP32 con WiFi estable al mismo proyecto Firebase.

Android 8.0+.

Conexión a internet requerida para operación completa; modo offline muestra últimos datos conocidos (solo lectura).

Sensores compatibles I2C/SPI/UART que escriben en el schema fijo.

3. Requisitos Funcionales
RF-01 – Autenticación y registro
ID	Requisito
RF-01.1	Registro con correo electrónico o número de teléfono (SMS OTP).
RF-01.2	Primer ingreso: nombre de usuario único y ciudad.
RF-01.3	Nombre de usuario duplicado solicita uno diferente.
RF-01.4	Después del registro, se guía al usuario a vincular el ESP32 vía NFC.
RF-01.5	Cierre de sesión con confirmación previa.
RF-01.6	Al cerrar sesión, redirigir a pantalla de vinculación inicial.
RF-02 – Vinculación NFC
ID	Requisito
RF-02.1	El ESP32 está equipado con un lector NFC. Al acercar el teléfono, la app transmite el UID del usuario mediante HCE (Host Card Emulation) al lector.
RF-02.2	El ESP32 escribe automáticamente un registro en nfc/registros/ con el UID, nivel (fijo = 1) y timestamp.
RF-02.3	La app escucha la colección nfc/registros/; al aparecer su UID, muestra check verde y considera exitosa la vinculación.
RF-02.4	Si no se detecta registro después de 30 s, muestra error y permite reintentar.
RF-03 – Dashboard principal
ID	Requisito
RF-03.1	Muestra en tiempo real: temperatura (°C), pH, EC (mS/cm), nivel de agua (%), nivel de fertilizante (%).
RF-03.2	Indicador visual por métrica: verde (dentro de rango), rojo (fuera de rango). Los umbrales provienen del perfil de cultivo activo.
RF-03.3	Modo de visualización seleccionable por el usuario en Configuración: "Vista Técnica" (valores numéricos y gauges) y "Vista Sencilla" (resumen con iconos y texto claro: "pH Alto", "Todo bien").
RF-03.4	Muestra estado de conexión ESP32 mediante chip (conectado/desconectado).
RF-03.5	Muestra el cultivo activo con botón para cambiar rápidamente al selector de plantas.
RF-03.6	El dashboard completo debe caber sin scroll en 360×800 dp.
RF-03.7	Conversión automática: si rawValue EC > 10 (µS/cm), displayValue = rawValue/1000 (mS/cm).
RF-04 – Control de actuadores
ID	Requisito
RF-04.1	Control manual de cuatro actuadores: bomba de agua, bomba fertilizante, dosificadora ácido, dosificadora base.
RF-04.2	Control visual tipo "IlluminatedButton" que se ilumina cuando está activo.
RF-04.3	Feedback háptico al presionar.
RF-04.4	Modo automático configurable por actuador. En modo automático, el ESP32 activa el actuador según umbrales del perfil activo (ej. nivel de agua < mínimo → bomba). El usuario puede sobrescribir manualmente en cualquier momento.
RF-04.5	La sobrescritura manual (on/off) desactiva temporalmente el modo automático para ese actuador. Se reanuda automáticamente cuando: el usuario presiona "Volver a Auto", o tras un tiempo configurable (default 30 min).
RF-04.6	Cada activación de actuador (manual o automática) se registra en history/ con timestamp y evento.
RF-05 – Perfiles de cultivo
ID	Requisito
RF-05.1	Catálogo predefinido de perfiles con valores validados académicamente.
RF-05.2	Cultivos iniciales: lechuga romana, tomate cherry, pimiento, albahaca, plantas ornamentales de interior.
RF-05.3	Cada perfil define: temp min/max, pH min/max, EC min/max, nivel agua min (default 20%), nivel fertilizante min (default 20%).
RF-05.4	Usuario puede personalizar los umbrales desde Configuración.
RF-05.5	Botón "Restablecer valores del cultivo" para volver a los predeterminados.
RF-05.6	Los perfiles personalizados se guardan en profile/ y se sincronizan.
RF-05.7	La arquitectura permite agregar nuevos perfiles sin cambios estructurales.
Tabla de perfiles validados:

Cultivo	Temp min	Temp max	pH min	pH max	EC min	EC max	Fuente
Tomate Cherry	18	28	5.5	6.5	2.0	3.5	IFAS, FAO
Lechuga Romana	15	22	5.5	6.5	1.0	1.8	IFAS, HANNA
Pimiento	20	30	5.5	6.5	1.8	2.8	IFAS
Albahaca	18	25	5.5	6.5	1.0	1.6	FAO, HANNA
Ornamentales interior	18	26	5.5	6.5	1.0	1.5	Estimado seguro
La humedad no se incluye en el dashboard actual; se omite del perfil.

RF-06 – Alertas agronómicas
ID	Requisito
RF-06.1	Alerta inmediata cuando un parámetro sale del rango del perfil activo.
RF-06.2	Alerta por tendencia: la app calcula la pendiente con las últimas 5 lecturas; si el valor proyectado en 5 min estará fuera de rango, genera una prealerta.
RF-06.3	Las alertas se muestran en el dashboard como texto plano, sin decoración.
RF-06.4	Notificaciones push locales (background/cerrada).
RF-06.5	Usuario puede activar/desactivar push desde Configuración.
RF-06.6	Cada alerta se registra en history/ con timestamp, parámetro y valor.
RF-07 – Historial y gráficas
ID	Requisito
RF-07.1	Firebase almacena historial de lecturas.
RF-07.2	Pantalla de historial con gráficas de línea para temperatura, pH, EC.
RF-07.3	Cada gráfica muestra líneas punteadas de los límites del perfil activo.
RF-07.4	Filtros temporales: última hora, 24 h, semana.
RF-07.5	Demo local limitado a 60 registros; en producción, sin límite.
RF-08 – Compatibilidad de sensores
ID	Requisito
RF-08.1	Schema fijo en sensors/; cualquier sensor que escriba allí es compatible.
RF-08.2	El ESP32 puede leer sensores I2C/SPI/UART. La app no conoce el hardware.
RF-08.3	En Configuración, el usuario marca qué sensores están físicamente conectados; se guarda en usuarios/{uid}/sensores_activos. Solo los activos se muestran en el dashboard.
RF-08.4	Si un sensor activo no envía datos en 60 s, se muestra "Sin señal".
RF-09 – Configuración (Settings)
ID	Requisito
RF-09.1	Editar nombre y ciudad inline.
RF-09.2	Cambiar cultivo activo.
RF-09.3	Ajustar umbrales con sliders y guardar.
RF-09.4	Toggle notificaciones push.
RF-09.5	Estado ESP32 y botón reconectar (navega a onboarding/esp32).
RF-09.6	Mostrar versión de la app (hardcodeada).
RF-09.7	Cerrar sesión con confirmación.
RF-09.8	Checklist de sensores activos (temperatura, pH, conductividad, nivel agua, nivel fertilizante).
RF-09.9	Selector de modo de visualización: "Vista Técnica" / "Vista Sencilla".
RF-10 – Modo sin conexión
ID	Requisito
RF-10.1	Sin internet se muestran los últimos datos conocidos con indicador "sin conexión".
RF-10.2	Controles de actuadores deshabilitados con texto explicativo.
RF-10.3	Reconexión automática sin intervención del usuario.
4. Requisitos No Funcionales
Igual que en la versión anterior, con ajuste en visualización:
RNF-02.1: Un usuario no técnico debe entender el estado del cultivo en ≤10 s en cualquiera de los dos modos de vista.

5. Requisitos del Sistema Físico (ESP32)
ID	Requisito
RHW-01	Escribe en sensors/ cada 5 s (configurable).
RHW-02	Lee controls/ y actúa sobre actuadores en <1.5 s.
RHW-03	Heartbeat en esp32/heartbeat cada 30 s.
RHW-04	Extensible para nuevos sensores.
RHW-05	Lógica de control local de respaldo: si está activado el modo automático para un actuador y la comunicación con Firebase se pierde por más de 60 s, el ESP32 activa el actuador si el sensor correspondiente supera el umbral crítico (por seguridad). Esto no reemplaza el control de la app en condiciones normales. El control primario siempre es desde la app.
RHW-06	El ESP32 lleva un lector NFC. Cuando un teléfono con HCE transmite un UID Firebase, el ESP32 lo escribe en nfc/registros/.
6. Schema de Firebase RTDB (unificado)
text
sensors/
  temperatura: double
  ph: double
  conductividad: double          // app convierte a mS/cm si >10
  nivel_agua_tanque: double
  nivel_fertilizante_tanque: double
  timestamp: int

profile/                          // umbrales activos (personalizables)
  planta: string
  temp_min: double
  temp_max: double
  ph_min: double
  ph_max: double
  ec_min: double
  ec_max: double
  nivel_agua_min: double
  nivel_fertilizante_min: double

controls/
  bomba_agua: bool
  bomba_agua_auto: bool          // true = modo automático habilitado
  bomba_agua_manual_override: bool // true = comando manual vigente
  bomba_fertilizante: bool
  bomba_fertilizante_auto: bool
  bomba_fertilizante_manual_override: bool
  dosificadora_acido: bool
  dosificadora_acido_auto: bool
  dosificadora_acido_manual_override: bool
  dosificadora_base: bool
  dosificadora_base_auto: bool
  dosificadora_base_manual_override: bool

history/{pushKey}/
  timestamp: int
  temperatura: double
  ph: double
  conductividad: double
  nivel_agua_tanque: double
  nivel_fertilizante_tanque: double
  evento: string                // "alerta", "bomba_activada", etc.

plant_profiles/{id}/
  nombre: string
  emoji: string
  temp_min: double
  temp_max: double
  ph_min: double
  ph_max: double
  ec_min: double
  ec_max: double
  nivel_agua_min: double
  nivel_fertilizante_min: double
  fuente: string

usuarios/{uid}/
  nombre: string
  ciudad: string
  creado: int
  esp32_vinculado: bool
  sensores_activos: [string]   // ej. ["temperatura","ph","conductividad","nivel_agua_tanque","nivel_fertilizante_tanque"]
  modo_visualizacion: string   // "tecnica" | "sencilla"
  alertas_push: bool

system/
  alerts_enabled: bool
  version: string

esp32/
  heartbeat: int

nfc/registros/{pushKey}/
  usuario: string
  nivel: int                    // fijo 1 por ahora
  timestamp: int
7. Pantallas del sistema
Pantalla	Ruta	Descripción
Vinculación	/ (sin sesión)	Registro email/teléfono
SMS OTP	/onboarding/otp	Verificación código
Perfil inicial	/onboarding/perfil	Nombre, ciudad
Vinculación NFC	/onboarding/esp32	Espera lectura NFC por ESP32
Dashboard	/ (con sesión)	Principal (Vista Técnica/Sencilla)
Historial	/history	Gráficas y filtros
Selector plantas	/plantas	Catálogo perfiles
Configuración	/settings	Ajustes y cuenta
8. Fuera de alcance (v1.0)
Oxígeno disuelto.

Multi-instalación / múltiples niveles simultáneos.

Web dashboard.

Asistentes de voz.

ML predictivo.

Publicación en Play Store.

HydroTracker Architecture Guide v3 — Para la IA
INSTRUCCIÓN OBLIGATORIA PARA LA IA:
Lee este documento COMPLETAMENTE antes de escribir una sola línea de código. Es tu prompt de sistema. Cualquier violación romperá la aplicación.

1. Estructura del Proyecto
text
lib/
├── app.dart                       # MaterialApp, tabla de rutas (AppRoutes)
├── main.dart                      # Inicialización Firebase, datos demo, runApp
├── firebase_options.dart          # FlutterFire autogenerado
├── core/
│   ├── theme/
│   │   ├── app_colors.dart        # ÚNICA fuente de verdad de colores
│   │   └── app_theme.dart         # ThemeData, sin gradientes
│   ├── demo_data_service.dart
│   ├── firebase_service.dart
│   ├── firebase_constants.dart
│   └── phone_utils.dart
├── models/
│   ├── sensor_data.dart
│   └── plant_profile.dart
├── domain/repositories/
│   ├── sensor_repository.dart
│   └── plant_repository.dart
├── data/repositories/
│   ├── sensor_repository_impl.dart
│   └── plant_repository_impl.dart
└── presentation/
    ├── providers/
    │   └── app_providers.dart     # TODOS los providers, sin excepción
    ├── screens/
    │   ├── dashboard_screen.dart
    │   ├── history_screen.dart
    │   ├── plant_selector_screen.dart
    │   ├── settings_screen.dart
    │   └── onboarding/
    │       ├── vinculation_screen.dart
    │       ├── sms_verification_screen.dart
    │       ├── perfil_screen.dart
    │       └── esp32_vinculacion_screen.dart
    └── widgets/
        ├── common/
        │   ├── app_scaffold.dart
        │   └── app_card.dart
        └── dashboard/
            ├── circular_metric.dart
            ├── illuminated_button.dart  # Reemplaza cualquier Switch/Toggle
            └── status_chip.dart
2. Principios de Diseño (OBLIGATORIOS)
Usuario objetivo
El usuario final es un agricultor urbano o entusiasta de plantas, NO técnico.
Cada decisión de UI debe aprobarse con: “¿lo entendería alguien de 60 años sin experiencia en apps de monitoreo?”.

Modos de visualización: Técnico y Sencillo
El dashboard y las métricas pueden verse en dos modos, seleccionables en Configuración:

Vista Técnica: valores numéricos grandes, gauges circulares con color (verde/rojo), unidades.

Vista Sencilla: iconos grandes (✅/⚠️) y texto descriptivo (“Temperatura normal”, “pH Alto”). Sin números pequeños ni gráficos.

El modo actual se obtiene de usuarios/{uid}/modo_visualizacion ("tecnica" o "sencilla"). La app lo aplica en dashboard e historial.

Paleta de colores
Token	Valor	Uso
background	#0D1117	Fondo Scaffold
cardBackground	#161B22	Cards, chips
cardBorder	#30363D	Bordes, divisores
textPrimary	#FFFFFF	Títulos, valores
textSecondary	#8B949E	Labels, hints
textMuted	#484F58	Deshabilitado
success	#2EA043	En rango, OK
warning	#D29922	Alertas
error	#F85149	Fuera de rango
info	#58A6FF	Agua
accent	#238636	Fertilizante
NUNCA hardcodear colores. NUNCA usar gradientes.

IlluminatedButton — control de actuadores
Utilizado para los 4 controles. Reemplaza completamente Switch y Toggle.

Forma: rectangular redondeado (borderRadius: 12)

Tamaño mínimo: 80×80 dp

Estado APAGADO:

Fondo cardBackground, borde cardBorder 1.5px, ícono textMuted, label textSecondary, sin sombra.

Estado ENCENDIDO: (actuador activo)

Fondo: color del actuador con opacidad 0.15

Borde: color del actuador, 2px

Ícono: color del actuador, tamaño aumentado

Label: color del actuador

BoxShadow: color del actuador con opacidad 0.3, blurRadius 8

Animación: AnimatedContainer duration 200ms

Al presionar: feedback háptico HapticFeedback.mediumImpact.

Colores por actuador:

Bomba de agua: info (#58A6FF)

Bomba fertilizante: accent (#238636)

Dosificadora ácido: warning (#D29922)

Dosificadora base: success (#2EA043)

Comportamiento manual/automático
Cada actuador tiene dos modos: Automático y Manual.

En modo Automático (controls/<actuador>_auto == true): el ESP32 controla el estado según los umbrales. El botón en la app muestra el estado actual (iluminado o apagado) e incluye un pequeño indicador "AUTO". Al presionarlo, se activa una sobrescritura manual temporal.

Sobrescritura manual: al presionar el botón en modo auto, se envía el estado opuesto y se pone controls/<actuador>_manual_override = true. El ESP32 obedece esa orden y congela el automatismo.
El botón ahora muestra icono de "manual" (un dedo) y se mantiene en ese estado.

Si el usuario vuelve a presionar, se alterna (on/off) manteniendo la sobrescritura.

Una presión larga (>500 ms) o un botón dedicado "Volver a Auto" restablece manual_override = false y reanuda el modo automático.

Si el usuario no lo restaura, tras 30 minutos (configurable en system/override_timeout_min) la app automáticamente envía manual_override = false.

En modo Manual (_auto == false): el botón actúa como un toggle directo. Cada pulsación envía el estado opuesto y mantiene manual_override = true. No hay timeout automático. El usuario debe activar el modo Auto desde Configuración si lo desea.

La pantalla de Configuración permite habilitar/deshabilitar el modo automático por actuador (toggle adicional).

3. Reglas de Capas
Capa	Responsabilidad	Dependencias permitidas
Presentation	Widgets, navegación, estado	domain/, core/theme
Domain	Interfaces abstractas	models/ únicamente
Data	Implementaciones Firebase	domain/, core/*_service
Core	Firebase, demo, utils, tema	models/ (excepciones)
Models	Datos puros, serialización	Nada
REGLA DE ORO: Las pantallas NUNCA importan FirebaseService ni DemoDataService directamente. Siempre a través de providers.

4. Pantalla de Configuración (/settings)
Secciones en orden:

Perfil de usuario: avatar con inicial, nombre y ciudad editables inline. Guarda en usuarios/{uid}/.

Cultivo activo: card con la planta actual + botón “Cambiar cultivo” → /plantas.

Umbrales personalizados: sliders para temp_min, temp_max, ph_min, ph_max, ec_min, ec_max. Muestra valores actuales. Botones “Guardar” y “Restablecer a valores del cultivo”.

Sensores activos: checklist de sensores (temperatura, pH, conductividad, nivel_agua, nivel_fertilizante). Solo los marcados se muestran en el dashboard. Guarda en usuarios/{uid}/sensores_activos.

Modo de visualización: radio buttons “Vista Técnica” / “Vista Sencilla”. Guarda en usuarios/{uid}/modo_visualizacion.

Notificaciones: toggle alertas push.

Control automático por actuador: toggles para activar/desactivar modo automático de cada actuador (bomba_agua_auto, etc.).

Sistema: chip estado ESP32, versión app, botón “Reconectar ESP32” → /onboarding/esp32.

Cuenta: botón “Cerrar sesión” (color error, confirmación con AlertDialog, signOut, redirige a vinculación).

5. Manejo de EC
La unidad de display es mS/cm.
Si el valor crudo de sensors/conductividad > 10, se divide entre 1000.
Conversión aplicada en la capa de presentación (dashboard, historial, settings).
Repetir en TODAS las pantallas que muestren EC.

6. Vinculación NFC – Pantalla esp32_vinculacion_screen
Muestra una animación de espera (por ejemplo, un spinner NFC) y el texto “Acerca tu teléfono al lector del sistema”.

Utiliza el paquete flutter_nfc_kit o similar para activar HCE y transmitir el UID del usuario (FirebaseAuth.instance.currentUser!.uid) vía NFC.

Escucha en tiempo real el nodo nfc/registros/ hasta que aparezca un registro con el UID del usuario. Cuando aparezca, muestra check verde y navega automáticamente al dashboard.

Si pasan 30 segundos sin éxito, muestra mensaje de error y botón “Reintentar”.

7. Alertas de tendencia
La lógica de tendencia se aloja en un provider TrendNotifier o dentro del DashboardNotifier.

Se mantienen las últimas 5 lecturas de cada parámetro con sus timestamps.

Se calcula una regresión lineal simple (pendiente). Si el valor predicho para dentro de 5 minutos supera el umbral, se genera una alerta de tendencia (texto: “pH subiendo rápido...”).

La alerta se muestra en el dashboard y se guarda en history/ con evento = "alerta_tendencia".

8. Datos semilla de perfiles de cultivo
Ubicación: core/demo_data_service.dart o un JSON asset.
Al primer inicio, si el nodo plant_profiles/ está vacío, se insertan los siguientes perfiles (validados):

dart
final Map<String, Map<String, dynamic>> defaultProfiles = {
  'tomate_cherry': {
    'nombre': 'Tomate Cherry',
    'emoji': '🍅',
    'temp_min': 18.0, 'temp_max': 28.0,
    'ph_min': 5.5, 'ph_max': 6.5,
    'ec_min': 2.0, 'ec_max': 3.5,
    'nivel_agua_min': 20.0, 'nivel_fertilizante_min': 20.0,
    'fuente': 'IFAS, FAO'
  },
  'lechuga_romana': {
    'nombre': 'Lechuga Romana',
    'emoji': '🥬',
    'temp_min': 15.0, 'temp_max': 22.0,
    'ph_min': 5.5, 'ph_max': 6.5,
    'ec_min': 1.0, 'ec_max': 1.8,
    'nivel_agua_min': 20.0, 'nivel_fertilizante_min': 20.0,
    'fuente': 'IFAS, HANNA'
  },
  'pimiento': {
    'nombre': 'Pimiento',
    'emoji': '🫑',
    'temp_min': 20.0, 'temp_max': 30.0,
    'ph_min': 5.5, 'ph_max': 6.5,
    'ec_min': 1.8, 'ec_max': 2.8,
    'nivel_agua_min': 20.0, 'nivel_fertilizante_min': 20.0,
    'fuente': 'IFAS'
  },
  'albahaca': {
    'nombre': 'Albahaca',
    'emoji': '🌿',
    'temp_min': 18.0, 'temp_max': 25.0,
    'ph_min': 5.5, 'ph_max': 6.5,
    'ec_min': 1.0, 'ec_max': 1.6,
    'nivel_agua_min': 20.0, 'nivel_fertilizante_min': 20.0,
    'fuente': 'FAO, HANNA'
  },
  'ornamentales': {
    'nombre': 'Ornamentales Interior',
    'emoji': '🪴',
    'temp_min': 18.0, 'temp_max': 26.0,
    'ph_min': 5.5, 'ph_max': 6.5,
    'ec_min': 1.0, 'ec_max': 1.5,
    'nivel_agua_min': 20.0, 'nivel_fertilizante_min': 20.0,
    'fuente': 'Estimación segura'
  }
};
Los valores de nivel_agua_min y nivel_fertilizante_min son defaults; el usuario puede modificarlos.

9. Dashboard — Reglas estrictas
Sin scroll en 360×800 dp.

Métricas: máximo 5 CircularMetric en Wrap, dimensiones 90×90 dp cada una. En Vista Sencilla, se reemplazan por un Column con iconos grandes y texto plano.

Gauges solo verde o rojo, sin arcoíris.

Controles: grilla 2×2 de IlluminatedButton.

Alertas: texto plano, ícono pequeño de advertencia, sin card wrapper.

Header: nombre app + cultivo activo + chip estado ESP32.

Aplica filtro de sensores activos (solo los marcados en usuarios/{uid}/sensores_activos).

10. Consistencia — Checklist antes de entregar código
¿Todas las pantallas usan AppScaffold?

¿Ninguna pantalla importa FirebaseService directamente?

¿Todos los providers están en app_providers.dart?

¿Ningún color está hardcodeado?

¿Los controles de actuadores usan IlluminatedButton, no Switch/Toggle?

¿El dashboard no hace scroll?

¿Los valores de EC se convierten si rawValue > 10?

¿El cierre de sesión pide confirmación?

¿Las rutas nuevas están registradas en app.dart?

¿Se respetan los modos de vista Técnico/Sencillo?

¿Los archivos compilan sin errores en Flutter 3.x + Riverpod 2.x?

11. Errores comunes — NO hacer esto
NO usar Switch o Toggle nativo.

NO usar Scaffold directamente → siempre AppScaffold.

NO importar firebase_service.dart desde pantallas.

NO crear providers fuera de app_providers.dart.

NO usar gradientes ni glass.

NO hacer el dashboard scrollable.

NO hardcodear strings de rutas → usar AppRoutes.xxx.

NO mostrar EC sin aplicar conversión.

NO cerrar sesión sin AlertDialog.

NO poner lógica de negocio en widgets.

NO ignorar el modo de visualización → siempre preguntar modoVisualizacion antes de construir métricas.

NO implementar la vinculación NFC simulando la escritura en Firebase desde la app → el ESP32 escribe el registro; la app solo escucha.