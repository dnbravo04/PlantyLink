# PlantyLink — Roadmap de producto y auditoría actualizada

**Fecha:** 2026-07-04 · **Demo en vivo:** 2026-07-15.
Documento complementario a `docs/AUDITORIA_FIRMWARE_HARDWARE.md` (auditoría técnica + firmware de demo). Todo ítem está etiquetado **[DEMO-15JUL]** o **[ROADMAP-PRODUCTO]**. Nada etiquetado [ROADMAP-PRODUCTO] es necesario para el 15 de julio.

---

## Cambios desde la última auditoría

Verificado contra el working tree el 2026-07-04 (HEAD = `d2596b0`):

| Qué | Estado | Cambio |
|---|---|---|
| `firmware/esp32_plantylink/esp32_plantylink.ino` | **Existe** (13.4 KB) | NUEVO desde la auditoría — generado en la sesión anterior. **Sin modificaciones posteriores y SIN COMMITEAR** (untracked) |
| `docs/AUDITORIA_FIRMWARE_HARDWARE.md` | Existe | NUEVO — también sin commitear |
| `lib/` (modelos, servicios, pantallas) | Sin cambios vs HEAD | `SensorData` sigue **sin** campos `humedad_suelo`/`humedad_aire`; `kDemoMode` sigue con default `true` |
| `functions/index.js` | Sin cambios | El bug de ruta `sensores` vs `sensors` (línea 77) **sigue vigente** |
| `database.rules.json` | Sin cambios | Sin `.indexOn` para `history`/`alerts`; hueco de "device hijack" vigente |
| Commits nuevos | Ninguno | El último commit (`d2596b0`) es anterior a la auditoría (solo assets) |

Hallazgos **nuevos** de esta pasada (no estaban en la auditoría anterior):

1. **La detección de desconexión está rota de punta a punta.** El chip "Conectado / Sin conexión" del dashboard (`dashboard_screen.dart:238`) lee `sensor.conectado`, un booleano que el firmware escribe `true` y que **nunca puede volver a `false`** si el dispositivo muere (el cliente REST del ESP32 no soporta `onDisconnect`). El mecanismo correcto — `staleDataStream` por antigüedad de `timestamp` en `sensor_stream_service.dart:34` — **es código muerto: nadie lo consume**. Hoy, si el ESP32 se apaga, la app muestra "Conectado" con valores congelados indefinidamente.
2. **La lógica multi-dispositivo SÍ está completa** (pregunta abierta de la sesión anterior): cambiar activo (`device_screen.dart` → `cambiarDispositivoActivo`), renombrar, desvincular con fallback al primer dispositivo restante, y dispositivos legacy sintetizados en la lista. Todo device-scoped se reconstruye reactivo vía `deviceContextProvider` (un solo puntero `usuarios/{uid}/esp32_id`). Brecha restante: la lista de dispositivos no muestra estado online por dispositivo.
3. **`DeviceService.registrarNFC` es código muerto** — definido, jamás llamado. El nodo `nfc_logs/` no lo escribe ni lo lee nadie.
4. **La lógica de alertas vive en 3 lugares** sin fuente única de verdad: `trend_alert_provider.dart` (tendencias en-app), `notification_service.dart` (notifs locales) y `functions/index.js` (push por umbral — hoy muerto por el bug de ruta).
5. **`cached/` es escribible por cualquier usuario autenticado** (reglas): cualquier cuenta puede envenenar la caché compartida de la API de plantas.
6. El dashboard sí tiene empty-state "Sin dispositivo vinculado" (bien); el caso "dispositivo vinculado pero que nunca escribió" cae en defaults engañosos de `SensorData.fromMap` (pH 7.0 "perfecto", temperatura 0.0).

**[DEMO-15JUL] Estado del subconjunto de demo:** el firmware existe y cubre suelo+DHT22+bomba+sync; falta ejecutar el checklist de `AUDITORIA_FIRMWARE_HARDWARE.md` (crear cuenta de dispositivo, flashear, calibrar, compilar app con `--dart-define=DEMO_MODE=false`, vincular). Único trabajo de código opcional pre-demo: fix de una línea en `functions/index.js` si se quieren push, y (recomendado) commitear `firmware/` y `docs/` para no perderlos.

---

## Alcance agua+suelo (decisiones registradas 2026-07-04)

**[ROADMAP-PRODUCTO]** — nada de esta sección condiciona el 15 de julio.

### Qué ya está insinuado en el código (verificado)

- **La vía hidropónica está modelada de punta a punta en Flutter, sin nada detrás:** `SensorData` (pH, EC, tanques, 4 bombas, modos auto/override), `PlantProfile` (umbrales `ph_min/max`, `ec_min/max`, `nivel_agua_min`, `nivel_fertilizante_min`, con catálogo de hortalizas hidropónicas y fuentes bibliográficas), `CalibrationService` (pH a 2 puntos, factor EC, "para que el ESP32 los aplique"), `ScheduleService`, pantalla de calibración y controles de 4 bombas en el dashboard. **Cero firmware/hardware detrás de todo esto.**
- **La vía de suelo existe solo en el firmware de demo** (claves nuevas `humedad_suelo`/`humedad_aire` que la app ignora) y en pistas sueltas: `plant_selector_screen.dart` tiene categoría `'soil'`/"Suelo" para las guías de cuidado del catálogo externo. `PlantProfile` **no tiene** umbrales de humedad de suelo.
- **No existe ningún discriminador de tipo de cultivo** en el esquema (`devices/{id}/profile` no tiene `tipo_cultivo` ni nada equivalente), ni concepto de "capacidades del dispositivo".

### Qué habría que diseñar desde cero

Un mecanismo para que app, firmware y esquema acuerden **qué sensores/actuadores tiene realmente cada dispositivo** — hoy la app asume el set hidropónico completo y pinta defaults para lo que falte. Y umbrales de suelo en `PlantProfile` (`humedad_suelo_min/max`) con su catálogo.

### Decisiones registradas (2026-07-04 — respuestas del dueño del producto; P3/P4 delegadas al equipo técnico)

**P1 — Alcance suelo/hidro: el producto arranca SUELO-FIRST.** La demo del 15 de julio y la primera unidad real usan una planta en tierra, no hidropónica. Queda descartada la opción "dispositivo full con todo simultáneo"; la arquitectura adoptada es el **modelo de capacidades** (el firmware declara qué sensores tiene, la app pinta solo eso), que sirve por igual si el empaque comercial termina siendo dos SKUs cerrados o un dispositivo modular. Esa decisión de empaque sigue abierta a nivel de producto, pero **ya no bloquea nada técnico**. Consecuencia inmediata: la vía hidropónica del código Flutter (pH/EC/dosificadoras) pasa a ser una capacidad futura, no el caso base.

**P2 — Un dispositivo = un cultivo: SÍ (confirmado).** El esquema mantiene `devices/{id}/profile` singular; no se diseña anidación multi-bandeja. Si algún día cambia, será esquema v3 y se acepta ese costo.

**P3 — Lazo de control (delegado; decisión técnica): EN EL FIRMWARE.** El dispositivo sincroniza los umbrales de `devices/{id}/profile` a su almacenamiento local (NVS) y decide el riego por sí mismo; la nube (app + Cloud Functions) solo observa y alerta. Razón: el riego no puede depender de un round-trip a Firebase — perder WiFi no debe matar la planta. `controls/` queda exactamente como la app ya lo modela: órdenes manuales y conmutación del modo automático.

**P4 — Fallback sin conectividad (delegado; decisión técnica): POLÍTICA POR ACTUADOR.**
- **Bomba de agua (riego): sigue funcionando offline** con los últimos umbrales conocidos, bajo límites duros grabados en firmware: duración máxima de ciclo, tiempo mínimo entre ciclos, y paro si la lectura del sensor de suelo es inválida o físicamente imposible. Peor caso acotado: riego subóptimo, no inundación.
- **Dosificadoras (ácido/base/fertilizante, cuando existan): se detienen offline.** Dosificar química sin lectura fresca de pH/EC y sin supervisión remota es el único escenario de daño real al cultivo. Reanudan solo con conectividad y lecturas recientes.
- En ambos casos el dispositivo entra al estado `OFFLINE_SAFE` de la máquina de estados (Fase 2) y registra localmente lo actuado para volcarlo al reconectar.

---

## Roadmap de producto por fases con dependencias

**[ROADMAP-PRODUCTO]** — íntegramente fuera del plazo del 15 de julio. Criterio de orden: dependencias técnicas reales + costo de validación + reversibilidad. No hay fechas.

### Fase 0 — Decisiones y esquema de datos
*Bloquea: todas las demás fases. Costo: bajo (días). Reversibilidad: BAJA — es el compromiso arquitectónico del producto.*

1. ~~Responder P1–P4~~ **HECHO 2026-07-04** (ver sección anterior): suelo-first con modelo de capacidades, 1 dispositivo = 1 cultivo, lazo de control en firmware, fallback por actuador. Única pendiente de producto: empaque comercial (SKUs vs modular) — no bloquea el esquema.
2. **Esquema v2 de `devices/{id}`:**
   - Campos propios `humedad_suelo` / `humedad_aire` en `sensors/` + parseo en `SensorData` → **elimina el shim `MAP_SOIL_TO_TANK`** del firmware (poner el `#define` a 0 el mismo día que la app muestre el campo real).
   - Nodo `devices/{id}/info/` (capacidades, versión de firmware, modelo de hardware) — adoptado por la decisión P1.
   - `PlantProfile` con umbrales de suelo (`humedad_suelo_min/max`) + discriminador `tipo_cultivo` + **catálogo de plantas de tierra** (el `PlantCatalog` actual es de hortalizas hidropónicas con umbrales EC/pH — el caso base del producto ya no es ese).
   - Revisión de escalabilidad: el nodo `sensors/` plano con ~20 campos opcionales ya muestra el anti-patrón "un nodo gigante con campos para todo". Con capacidades declaradas en `info/`, `sensors/` plano es tolerable; sin ellas, no.
3. **Arreglos baratos e independientes (pueden ir primero, no dependen de P1–P4):** fix `sensores`→`sensors` en `functions/index.js`; `.indexOn: ["timestamp"]` para `history` y `alerts`; endurecer `cached/` (solo lectura para clientes, escritura vía CF); actualizar README.

### Fase 1 — Verdad de conexión y propiedad de nodos
*Depende de: nada de Fase 0 salvo decisiones (puede solaparse). Bloquea: OTA (Fase 4), UX de estados (Fase 5). Costo: bajo-medio. Reversibilidad: alta.*

1. **Presencia real:** derivar "conectado" de la antigüedad de `timestamp` (consumir el `staleDataStream` que ya existe o recalcular en el widget) y/o heartbeat + CF programada que marque `conectado=false`. Retirar la semántica actual del booleano escrito por el firmware.
2. **Propiedad por nodo, documentada y respetada:** `sensors/` lo escribe SOLO el firmware; `controls/` SOLO la app. Hoy `ControlService.setPump` escribe en ambos (eco optimista en `sensors/`) y el firmware también hace eco → dos escritores sobre `sensors/bomba_agua`. Sustituir por: la app escribe solo `controls/`, la UI del botón muestra estado "pendiente" hasta que el firmware confirme vía `sensors/`. Elimina la clase entera de conflictos de escritura.
3. **Reconexión/offline en firmware:** buffer circular de lecturas en RAM/NVS durante cortes y volcado al reconectar (rellena huecos de `history`); política P4 ya decidida (riego continúa con límites duros, dosificación se detiene) implementada como estado `OFFLINE_SAFE`.

### Fase 2 — Firmware mantenible + modelo de capacidades
*Depende de: Fase 0 (esquema, P1, P3) y Fase 1 (propiedad de nodos). Bloquea: Fase 3 y Fase 4. Costo: medio. Reversibilidad: media.*

1. Migrar de `.ino` monolítico a **PlatformIO** con módulos: `net/` (WiFi+auth+RTDB), `sensors/` (un driver por sensor detrás de una interfaz común), `actuators/` (bombas con interlock y límites), `sync/` (publicación/stream), `control/` (lazo de riego local).
2. **Máquina de estados explícita:** `BOOT → WIFI → AUTH → SYNC → RUN ⇄ OFFLINE_SAFE`, con watchdog. Es prerrequisito real de OTA (rollback seguro) y del fallback P4.
3. Configuración en NVS (WiFi, DEVICE_ID, calibraciones) en vez de `#define` — prerrequisito de aprovisionamiento (Fase 4).
4. El firmware **declara capacidades** en `devices/{id}/info/` al arrancar (si P1 = a/b).
5. Ejecutar en firmware lo que la app ya escribe y hoy nadie lee: `schedules/` (horarios) y `calibration/` (cuando existan pH/EC).

### Fase 3 — Multi-sensor hidropónico
*Depende de: Fase 2 (interfaz de drivers) y Fase 0 (esquema). No bloquea a nadie — es incremental por sensor. Costo: medio-alto (hardware). Reversibilidad: alta (sensor a sensor).*
*Nota por decisión P1 (suelo-first): esta fase queda **condicionada a validar primero el producto de suelo**. El modelo de capacidades hace que agregarla después no requiera rediseño — es puramente aditiva.*

1. Orden de validación más barato primero: **nivel de tanque** (flotador digital o ultrasónico — barato, valida `nivel_agua`/`nivel_agua_tanque` reales) → **EC** (sonda + divisor, GPIO 35) → **pH** (sonda + amplificador tipo PH-4502C, GPIO 36/39) → **bombas restantes** (3 relés más: GPIO 25, 27, 33 como salidas digitales).
2. ADC1 disponible confirmado: GPIO 32, 33, 35, 36, 39 (34 ya ocupado por suelo). Alcanza para pH + EC + 1-2 analógicos más sin hardware extra; si se agotan, ADS1115 por I2C (GPIO 21/22 libres).
3. Conectar la calibración existente (UI + `calibration/` + factor EC / 2 puntos pH) al driver correspondiente — el lado app ya está hecho.

### Fase 4 — Aprovisionamiento, auth a escala y OTA
*Depende de: Fase 1 (presencia) y Fase 2 (NVS, máquina de estados). Costo: alto. Reversibilidad: baja (compromete el modelo de flota). No iniciar hasta que exista >1 unidad real en campo.*

1. **Auth de dispositivo a escala:** la cuenta email/contraseña hardcodeada del firmware de demo no escala (una cuenta manual por unidad + password en flash). Camino razonable: al emparejar, una **Cloud Function acuña un custom token** (o registra credenciales generadas) para ese `DEVICE_ID` y lo entrega al dispositivo durante el aprovisionamiento; las reglas pasan a validar un claim `device_id` en el token en vez del hueco actual "cualquier usuario que se auto-asigne el ID escribe en el device" (cierra también el device-hijack).
2. **Aprovisionamiento WiFi:** SoftAP o BLE para meter credenciales sin recompilar (usa la config NVS de Fase 2).
3. **OTA:** binarios firmados en Firebase Storage/Hosting, nodo `devices/{id}/info/fw_version` + comando de update, partición dual + rollback (la máquina de estados de Fase 2 es el prerrequisito). Antes de una unidad en campo, OTA es costo sin retorno.

### Fase 5 — UX adaptativa y datos server-side
*Depende de: Fase 0 (capacidades) y Fase 1 (presencia). Puede solaparse con Fase 3. Costo: medio. Reversibilidad: alta.*

1. **Dashboard por capacidades:** mostrar solo las tarjetas de sensores que el dispositivo declara (cierra la brecha actual: gauges hidropónicos en 0/defaults con hardware de suelo). Tarjetas nuevas para `humedad_suelo`/`humedad_aire`. Con la decisión P1 (suelo-first), esto sube de prioridad dentro de la fase: hoy el dashboard le muestra pH/EC/fertilizante a un usuario de maceta de tierra — exactamente lo que no debe pasar en el producto base.
2. **Estados de error visibles que hoy no existen:** "datos viejos desde hace X min" (stale), "dispositivo nunca ha reportado", "comando de bomba pendiente/sin confirmar", online/offline por dispositivo en la lista de `device_screen`.
3. **Historial server-side:** mover la grabación de `history/` de la app (hoy: solo graba con la app abierta, `sensor_repository_impl.dart:101`) al firmware o a una CF programada; retirar el recorder del repositorio y la poda cliente (que descarga el nodo entero).
4. **Unificar alertas en un solo lugar** (CF como fuente de verdad; la app solo presenta), eliminando la triplicación actual.

**Grafo de dependencias resumido:**
`F0 → {F1, F2, F5}` · `F1 → {F2.5(fallback), F4, F5.2}` · `F2 → {F3, F4}` · `F3 y F5` incrementales, no bloquean nada.

---

## Deuda técnica identificada

**[ROADMAP-PRODUCTO]** salvo indicación contraria.

| # | Deuda | Dónde | Gravedad |
|---|---|---|---|
| 1 | Detección de desconexión rota: `conectado` no puede volver a `false`; `staleDataStream` es código muerto | `sensor_stream_service.dart:34`, `dashboard_screen.dart:238`, firmware | Alta (el usuario ve "Conectado" con el equipo muerto) |
| 2 | Bug de ruta `sensores` vs `sensors` → push FCM nunca dispara | `functions/index.js:77` | Alta, fix de 1 línea. *(También es el único fix opcional [DEMO-15JUL])* |
| 3 | Doble escritor sobre `sensors/bomba_agua` (eco optimista de la app + eco del firmware) | `control_service.dart:26`, firmware | Media (carreras visibles al usuario) |
| 4 | `history/` escrito por la app: huecos cuando nadie abre la app, poda que descarga el nodo completo, sin `.indexOn` | `sensor_repository_impl.dart`, `history_service.dart`, `database.rules.json` | Media-alta |
| 5 | Reglas: device-hijack (cualquier cuenta puede reclamar cualquier `esp32_id`) y `cached/` escribible por cualquier autenticado | `database.rules.json` | Alta a escala; tolerable con 1 unidad |
| 6 | `kDemoMode` default `true`: un build sin flag ignora el hardware silenciosamente | `app_config.dart:12` | Media (riesgo operacional, no de código) |
| 7 | Defaults engañosos de `SensorData.fromMap` (pH 7.0, 0.0) — indistinguible "sin sensor" de "lectura 0" | `sensor_data.dart:62` | Media; lo resuelve el modelo de capacidades |
| 8 | Heurística EC frágil (`>10` ⇒ µS/cm) repetida en app y CF | `sensor_data.dart:34`, `functions/index.js:52` | Baja; fijar unidad canónica en esquema v2 |
| 9 | Código muerto: `registrarNFC`/`nfc_logs` (nunca llamado), `staleDataStream` (nunca consumido) | `device_service.dart:123` | Baja |
| 10 | Lógica de alertas triplicada (trend provider, notifs locales, CF) | `trend_alert_provider.dart`, `notification_service.dart`, `functions/index.js` | Media |
| 11 | README documenta reglas/esquema que no existen (`sensores/` raíz) | `README.md` | Baja |
| 12 | Firmware: credenciales en `#define` dentro del sketch (riesgo de commit de secretos); archivo aún sin commitear | `firmware/esp32_plantylink/esp32_plantylink.ino` | Media *(mitigación mínima [DEMO-15JUL]: `secrets.h` gitignored antes del primer commit del firmware)* |
| 13 | Shim `MAP_SOIL_TO_TANK` (humedad de suelo disfrazada de nivel de tanque) — préstamo de campo deliberado y señalizado, a retirar con esquema v2 | firmware + `sensor_data.dart` | Media (honestidad del dato) |

---

## Qué de esto NO debe tocarse antes del 15 de julio

Regla general: **entre hoy y la demo, el único trabajo debería ser ejecutar el checklist de la demo.** Cada refactor de esta lista arriesga romper el camino feliz que la demo necesita.

- **`firmware/esp32_plantylink/esp32_plantylink.ino`** — NO modularizar, NO migrar a PlatformIO, NO meter NVS/OTA/máquina de estados. Cambios permitidos: solo credenciales, `DEVICE_ID` y las dos constantes de calibración del suelo. (Commitearlo tal cual sí es seguro y recomendado.)
- **`lib/models/sensor_data.dart` y el esquema de `sensors/`** — NO añadir aún `humedad_suelo`/`humedad_aire` ni retirar el shim `MAP_SOIL_TO_TANK` si eso desestabiliza el dashboard a días de la demo; el shim existe precisamente para que la demo funcione sin tocar la app. (Si sobra un día completo con margen para probar en dispositivo real, es el único ítem de app promovible; si no, va a Fase 0.)
- **`lib/core/services/control_service.dart` (eco optimista)** — NO cambiar la doble escritura ahora: el botón de bomba de la demo depende de ese eco para responder al instante.
- **`database.rules.json`** — NO endurecer reglas (device-hijack, `cached/`) antes de la demo: el auto-registro del firmware y el emparejamiento del teléfono dependen del comportamiento actual.
- **`deviceContextProvider` y providers device-scoped** — NO refactorizar; toda la cadena reactiva de la demo pasa por ahí.
- **Detección de staleness / chip "Conectado"** — aunque está rota (deuda #1), NO rehacerla esta semana: con el firmware publicando cada 5 s el chip funciona de facto durante la demo. En su lugar, mitigación operacional: verificar el monitor Serial antes de presentar y tener hotspot 2.4 GHz de respaldo.
- **Único cambio de código seguro y recomendado pre-demo:** `sensores` → `sensors` en `functions/index.js:77` + redeploy de functions (no toca la app ni el firmware; solo activa las push). Opcional.
