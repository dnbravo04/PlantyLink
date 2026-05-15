# HydroTrack - Software Requirements Specification
**Versión 1.2 | Mayo 2026**

**Proyecto:** Ingeniería Agrícola – Agricultura Digital  
**Equipo:** Michelle Vanegas · Luis Medina · Diego Bravo  
**Grupo 3**

---

## INSTRUCCIONES DE USO PARA DESARROLLADORES

Este documento contiene la especificación completa de requisitos funcionales y no funcionales de HydroTrack. Antes de comenzar cualquier desarrollo:

1. **Lee completamente este documento** - Cada requisito es crítico para el éxito del proyecto
2. **Referencia académica** - Los valores de los perfiles de cultivo están validados con fuentes científicas. No modificar sin justificación académica.
3. **Arquitectura** - Sigue estrictamente los principios de diseño y estructura de capas definidos en la sección de arquitectura (secciones 2-6)
4. **Validación** - Antes de entregar código, verifica que todos los requisitos funcionales estén implementados según la especificación

---

## 1. Introducción

### 1.1 Propósito
Especifica los requisitos funcionales y no funcionales de HydroTrack, aplicación Android para monitoreo y control remoto de sistemas hidropónicos y cultivos ornamentales de interior, orientada a usuarios sin formación técnica.

### 1.2 Alcance
Monitoreo en tiempo real de parámetros ambientales para sistemas hidropónicos y plantas ornamentales de interior, control manual y automático de actuadores, alertas agronómicas, perfiles de cultivo validados con respaldo académico y configuración personalizada. Escalabilidad futura a múltiples niveles y usuarios. Sincronización vía NFC.

### 1.3 Definiciones
- **ESP32:** microcontrolador WiFi que lee sensores y controla actuadores.
- **Firebase RTDB:** base de datos en tiempo real, broker entre ESP32 y la app.
- **NFC:** comunicación de corto alcance usada para vincular usuario al sistema.
- **EC:** conductividad eléctrica (mS/cm).
- **Perfil de cultivo:** parámetros óptimos (temp, pH, EC) asociados a una especie.
- **Actuador:** bomba de agua, bomba de fertilizante, dosificadora ácido/base.

### 1.4 Referencias
- Setiawan, F., & Santoso, B. (2025). IoT implementation for adjustment automatic pH and TDS/EC parameters on the system hydroponics lettuce. Applied Science and Technology Research Journal, 4(1), 43–53.
- Prasna Mahardika, I. P., et al. (2025). Rancang bangun sistem monitoring pertanian hidroponik berbasis IoT dan aplikasi mobile (Hydrotech). Jurnal SPEKTRUM, 12(3), 127–136.
- Dantas, J., et al. (2024). Dispositivo para cultivo indoor de plantas. Revista Foco, 17(5), e5049. DOI: 10.54751/revistafoco.v17n5-118
- Rofiansyah, R., et al. (2025). IoT-based control and monitoring system for hydroponic plant growth using image processing and mobile applications. PeerJ Computer Science, 11, e2763. DOI: 10.7717/peerj-cs.2763
- Al-Gaadi, K. A., et al. (2024). Quantitative and qualitative responses of hydroponic tomato production to different levels of salinity. Phyton, 93(6), 1311–1323. DOI: 10.32604/phyton.2024.049535
- Rahman, M. M., et al. (2023). Effect of different nutrient solutions on growth, yield, and quality of hydroponic Capsicum varieties. European Journal of Applied Sciences, 11(3), 503–521.
- Rusu, T., et al. (2021). Overview of multiple applications of basil species and cultivars and the effects of production environmental parameters on yields and secondary metabolites in hydroponic systems. Sustainability, 13(20), 11332. DOI: 10.3390/su132011332
- Abu Sneineh, A., & Shabaneh, A. A. A. (2023). Design of a smart hydroponics monitoring system using an ESP32 microcontroller and the Internet of Things. MethodsX, 10, 102401. DOI: 10.1016/j.mex.2023.102401
- Patel, R., & Kumar, A. (2025). Cloud-enabled IoT system for real-time environmental monitoring and remote device control using Firebase. arXiv preprint arXiv:2601.17414.
- Universidad El Bosque. (2024). Hacia una caracterización de los compradores entre 20 y 35 años de plantas ornamentales vivas en Bogotá. Repositorio institucional.
- FAO. (s.f.). Ciudades más verdes en América Latina y el Caribe. https://www.fao.org/americas/prioridades/agricultura-urbana/es/
- Colviveros. (2025). Información de interés sobre el viverismo en Colombia y el mundo. https://colviveros.org
- Mercado-Sierra, B., et al. (2022). Hydroponic solutions for ornamental plants. Agronomy, 12(5), 1014. [parámetros Spathiphyllum/EC indoor]

---

## 2. Descripción General del Sistema

### 2.1 Perspectiva del producto
HydroTrack es una aplicación Android que se comunica con un ESP32 a través de Firebase RTDB. El ESP32 lee sensores y controla actuadores. La app lee y escribe en Firebase en tiempo real. El ESP32 ejecuta lógica de control local solo como respaldo ante pérdida de conexión o emergencia (seguridad). La autoridad principal es la app.

```
Sensores físicos → ESP32 [WiFi] → Firebase RTDB ↔ App Flutter (Android)
                                       ↑
Actuadores ← ESP32 (lee controls/)   Usuario
```

### 2.2 Usuarios del sistema
Un único rol: Usuario sincronizado. Todo aquel que vincule su dispositivo vía NFC tiene acceso completo. Sin distinción de administrador.

### 2.3 Suposiciones y dependencias
- ESP32 con WiFi estable conectado al mismo proyecto Firebase.
- Android 8.0+ en el dispositivo del usuario.
- Conexión a internet requerida para operación completa; modo offline muestra últimos datos conocidos (solo lectura).
- Sensores compatibles I2C/SPI/UART que escriben en el schema fijo.

---

## 3. Requisitos Funcionales

### RF-01 – Autenticación y registro
- **RF-01.1:** Registro con correo electrónico o número de teléfono (SMS OTP).
- **RF-01.2:** Primer ingreso: nombre de usuario único y ciudad.
- **RF-01.3:** Nombre de usuario duplicado solicita uno diferente.
- **RF-01.4:** Después del registro, se guía al usuario a vincular el ESP32 vía NFC.
- **RF-01.5:** Cierre de sesión con confirmación previa.
- **RF-01.6:** Al cerrar sesión, redirigir a pantalla de vinculación inicial.

### RF-02 – Vinculación NFC
- **RF-02.1:** El ESP32 está equipado con un lector NFC. Al acercar el teléfono, la app transmite el UID del usuario mediante HCE (Host Card Emulation) al lector.
- **RF-02.2:** El ESP32 escribe automáticamente un registro en nfc/registros/ con el UID, nivel (fijo = 1) y timestamp.
- **RF-02.3:** La app escucha la colección nfc/registros/; al aparecer su UID, muestra check verde y considera exitosa la vinculación.
- **RF-02.4:** Si no se detecta registro después de 30 s, muestra error y permite reintentar.

### RF-03 – Dashboard principal
- **RF-03.1:** Muestra en tiempo real: temperatura (°C), pH, EC (mS/cm), nivel de agua (%), nivel de fertilizante (%).
- **RF-03.2:** Indicador visual por métrica: verde (dentro de rango), rojo (fuera de rango). Los umbrales provienen del perfil de cultivo activo.
- **RF-03.3:** Modo de visualización seleccionable por el usuario en Configuración: "Vista Técnica" (valores numéricos y gauges) y "Vista Sencilla" (resumen con iconos y texto claro: "pH Alto", "Todo bien").
- **RF-03.4:** Muestra estado de conexión ESP32 mediante chip (conectado/desconectado).
- **RF-03.5:** Muestra el cultivo activo con botón para cambiar rápidamente al selector de plantas.
- **RF-03.6:** El dashboard completo debe caber sin scroll en 360×800 dp.
- **RF-03.7:** Conversión automática: si rawValue EC > 10 (µS/cm), displayValue = rawValue / 1000 (mS/cm).

### RF-04 – Control de actuadores
- **RF-04.1:** Control manual de cuatro actuadores: bomba de agua, bomba fertilizante, dosificadora ácido, dosificadora base.
- **RF-04.2:** Control visual tipo "IlluminatedButton" que se ilumina cuando está activo.
- **RF-04.3:** Feedback háptico al presionar.
- **RF-04.4:** Modo automático configurable por actuador. En modo automático, el ESP32 activa el actuador según umbrales del perfil activo.
- **RF-04.5:** La sobrescritura manual (on/off) desactiva temporalmente el modo automático para ese actuador. Se reanuda automáticamente cuando el usuario presiona 'Volver a Auto' o tras un tiempo configurable (default 30 min).
- **RF-04.6:** Cada activación de actuador (manual o automática) se registra en history/ con timestamp y evento.

### RF-05 – Perfiles de cultivo
- **RF-05.1:** Catálogo predefinido de perfiles con valores validados académicamente.
- **RF-05.2:** Cultivos iniciales: lechuga romana, tomate cherry, pimiento, albahaca, plantas ornamentales de interior (pothos, sansevieria, espatifilo).
- **RF-05.3:** Cada perfil define: temp min/max, pH min/max, EC min/max, nivel agua min (default 20%), nivel fertilizante min (default 20%).
- **RF-05.4:** Usuario puede personalizar los umbrales desde Configuración.
- **RF-05.5:** Botón "Restablecer valores del cultivo" para volver a los predeterminados.
- **RF-05.6:** Los perfiles personalizados se guardan en profile/ y se sincronizan.
- **RF-05.7:** La arquitectura permite agregar nuevos perfiles sin cambios estructurales.

#### Tabla de perfiles validados:

| Cultivo | T° min | T° max | pH min | pH max | EC min | EC max | Fuente académica |
|---------|--------|--------|--------|--------|--------|--------|------------------|
| Tomate Cherry | 18 | 28 | 5.5 | 6.5 | 2.0 | 3.5 | Al-Gaadi et al. (2024), Phyton, 93(6) |
| Lechuga Romana | 15 | 22 | 5.5 | 6.5 | 1.0 | 1.8 | Rofiansyah et al. (2025), PeerJ CS |
| Pimiento | 20 | 30 | 5.8 | 6.5 | 1.8 | 2.8 | Rahman et al. (2023), Eur. J. Appl. Sci. |
| Albahaca | 15 | 24 | 5.5 | 6.5 | 1.0 | 1.6 | Rusu et al. (2021), Sustainability |
| Pothos (interior) | 18 | 30 | 5.5 | 6.5 | 0.8 | 1.5 | Dantas et al. (2024); estimado |
| Sansevieria (interior) | 15 | 28 | 5.5 | 6.5 | 0.5 | 1.2 | Dantas et al. (2024); estimado |
| Espatifilo (interior) | 18 | 26 | 5.5 | 6.5 | 0.8 | 1.5 | Dantas et al. (2024); Mercado-Sierra et al. (2022) |

### RF-06 – Alertas agronómicas
- **RF-06.1:** Alerta inmediata cuando un parámetro sale del rango del perfil activo.
- **RF-06.2:** Alerta por tendencia: la app calcula la pendiente con las últimas 5 lecturas; si el valor proyectado en 5 min estará fuera de rango, genera una prealerta.
- **RF-06.3:** Las alertas se muestran en el dashboard como texto plano, sin decoración.
- **RF-06.4:** Notificaciones push locales (background/cerrada).
- **RF-06.5:** Usuario puede activar/desactivar push desde Configuración.
- **RF-06.6:** Cada alerta se registra en history/ con timestamp, parámetro y valor.

### RF-07 – Historial y gráficas
- **RF-07.1:** Firebase almacena historial de lecturas.
- **RF-07.2:** Pantalla de historial con gráficas de línea para temperatura, pH, EC.
- **RF-07.3:** Cada gráfica muestra líneas punteadas de los límites del perfil activo.
- **RF-07.4:** Filtros temporales: última hora, 24 h, semana.
- **RF-07.5:** Demo local limitado a 60 registros; en producción, sin límite.

### RF-08 – Compatibilidad de sensores
- **RF-08.1:** Schema fijo en sensors/; cualquier sensor que escriba allí es compatible.
- **RF-08.2:** El ESP32 puede leer sensores I2C/SPI/UART. La app no conoce el hardware.
- **RF-08.3:** En Configuración, el usuario marca qué sensores están físicamente conectados; se guarda en usuarios/{uid}/sensores_activos. Solo los activos se muestran en el dashboard.
- **RF-08.4:** Si un sensor activo no envía datos en 60 s, se muestra 'Sin señal'.

### RF-09 – Configuración (Settings)
- **RF-09.1:** Editar nombre y ciudad inline.
- **RF-09.2:** Cambiar cultivo activo.
- **RF-09.3:** Ajustar umbrales con sliders y guardar.
- **RF-09.4:** Toggle notificaciones push.
- **RF-09.5:** Estado ESP32 y botón reconectar (navega a onboarding/esp32).
- **RF-09.6:** Mostrar versión de la app (hardcodeada).
- **RF-09.7:** Cerrar sesión con confirmación.
- **RF-09.8:** Checklist de sensores activos (temperatura, pH, conductividad, nivel agua, nivel fertilizante).
- **RF-09.9:** Selector de modo de visualización: "Vista Técnica" / "Vista Sencilla".

### RF-10 – Modo sin conexión
- **RF-10.1:** Sin internet se muestran los últimos datos conocidos con indicador sin conexión.
- **RF-10.2:** Controles de actuadores deshabilitados con texto explicativo.
- **RF-10.3:** Reconexión automática sin intervención del usuario.

---

## 4. Requisitos No Funcionales
- **RNF-01:** El dashboard debe reflejar datos del sensor en ≤3 s desde su escritura en Firebase RTDB.
- **RNF-02:** La app debe iniciar y mostrar el dashboard en ≤4 s en dispositivos con Android 8.0+.
- **RNF-02.1:** Un usuario no técnico debe entender el estado del cultivo en ≤10 s en cualquiera de los dos modos de vista.
- **RNF-03:** El modo sin conexión debe activarse automáticamente en ≤5 s tras pérdida de conectividad a internet.
- **RNF-04:** El dashboard debe funcionar correctamente en pantallas de 360×800 dp sin scroll.
- **RNF-05:** Solo usuarios autenticados y vinculados vía NFC pueden escribir en Firebase (reglas de seguridad RTDB).
- **RNF-06:** La app debe ser compatible con Android 8.0 (API 26) o superior.

---

## 5. Requisitos del Sistema Físico (ESP32)
- **RHW-01:** Escribe en sensors/ cada 5 s (configurable).
- **RHW-02:** Lee controls/ y actúa sobre actuadores en <1.5 s.
- **RHW-03:** Heartbeat en esp32/heartbeat cada 30 s.
- **RHW-04:** Extensible para nuevos sensores.
- **RHW-05:** Lógica de control local de respaldo: si está activado el modo automático para un actuador y la comunicación con Firebase se pierde por más de 60 s, el ESP32 activa el actuador si el sensor correspondiente supera el umbral crítico (por seguridad). Esto no reemplaza el control de la app en condiciones normales. El control primario siempre es desde la app.
- **RHW-06:** El ESP32 lleva un lector NFC. Cuando un teléfono con HCE transmite un UID Firebase, el ESP32 lo escribe en nfc/registros/.

---

## 6. Schema de Firebase RTDB

```
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
```

---

## 7. Pantallas del sistema

| Pantalla | Ruta | Descripción |
|----------|------|-------------|
| Vinculación | / (sin sesión) | Registro email/teléfono |
| SMS OTP | /onboarding/otp | Verificación código |
| Perfil inicial | /onboarding/perfil | Nombre, ciudad |
| Vinculación NFC | /onboarding/esp32 | Espera lectura NFC por ESP32 |
| Dashboard | / (con sesión) | Principal (Vista Técnica/Sencilla) |
| Historial | /history | Gráficas y filtros |
| Selector plantas | /plantas | Catálogo de perfiles |
| Configuración | /settings | Ajustes y cuenta |

---

**HydroTrack SRS v1.2 | Ingeniería Agrícola – Agricultura Digital | UNAL Bogotá | Mayo 2026**