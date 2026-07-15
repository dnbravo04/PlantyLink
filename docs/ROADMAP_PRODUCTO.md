# PlantyLink — Roadmap de producto y auditoría actualizada

**Fecha:** 2026-07-04 · **Demo en vivo:** 2026-07-15.
Documento complementario a `docs/AUDITORIA_FIRMWARE_HARDWARE.md` (auditoría técnica + firmware de demo). Todo ítem está etiquetado **[DEMO-15JUL]** o **[ROADMAP-PRODUCTO]**. Nada etiquetado [ROADMAP-PRODUCTO] es necesario para el 15 de julio.

---

## Cambios desde la última auditoría

Verificado contra el working tree el **2026-07-14** (HEAD = `5198d0b`):

| Qué | Estado | Cambio desde última auditoría (2026-07-04) |
|---|---|---|
| `lib/models/sensor_data.dart` | Modificado | `humedadSuelo`/`humedadAire` ahora nullable (null = sin sensor) |
| `lib/core/demo_data_service.dart` | Reescrito | Simula **2 dispositivos** (full-hydro + soil-only) con switch |
| `lib/presentation/providers/app_providers.dart` | Modificado | `demoActiveDeviceProvider`, `deviceInfoProvider` con capabilities en demo, multi-device `linkedDevicesProvider` |
| `lib/presentation/providers/data_staleness_provider.dart` | **NUEVO** | Reemplaza `staleDataStream` — Live/Stale/Offline por antigüedad de timestamp |
| `lib/models/device_info.dart` + `device_info_service.dart` | **NUEVO** | Modelo de capacidades (`sensores`, `actuadores`, `tipo_cultivo`) |
| `lib/presentation/widgets/dashboard/sensor_card.dart` | Modificado | AnimatedValue + tarjetas de humedad suelo/aire |
| `docs/v1.1_design_renovation_plan.md` | **ELIMINADO** | 100% implementado — redundante |
| `firmware/esp32_plantylink/esp32_plantylink.ino` | Modificado | `MAP_SOIL_TO_TANK=0` (shim retirado), declara capabilities en `info/` |
| `functions/index.js` | **Corregido + ampliado** | Ruta `sensores`→`sensors` **corregida y desplegada** (commit `3c508b8`). F0.4 añadió checks de `humedad_suelo`/`humedad_aire` (commit `4bba247`) — **commiteados pero AÚN SIN RE-DESPLEGAR**: producción no los tiene todavía |
| `database.rules.json` | Modificado + **desplegado** | `.indexOn` para `history`/`alerts`; validate de `cached/` (commit `5198d0b`, ya en producción) |
| `lib/core/app_config.dart` | Modificado | `kDemoMode` default → **`false`** (producción por defecto; la demo requiere `--dart-define=DEMO_MODE=true`) |
| `pubspec.yaml` | Modificado | Dependencias actualizadas (google_sign_in 7.x, flutter_local_notifications 22.x, share_plus 13.x, etc.) — **bumps mayores sin verificar en runtime** |

### Hallazgos vigentes (de auditoría 2026-07-04, actualizados):

1. ~~**Detección de desconexión rota**~~ **MITIGADO.** `dataStalenessProvider` consume la antigüedad del timestamp (5min/15min umbrales). El booleano `conectado` del firmware sigue sin poder volver a `false`, pero la UI ya no depende de él para mostrar estado.
2. **La lógica multi-dispositivo está completa** en producción Y en demo. Brecha restante: la lista de dispositivos no muestra estado online por dispositivo.
3. **`DeviceService.registrarNFC` es código muerto** — definido, jamás llamado.
4. **La lógica de alertas vive en 3 lugares** sin fuente única de verdad.
5. **`cached/` es escribible por cualquier usuario autenticado** (reglas) — mitigado con validate en rules.
6. ~~Defaults engañosos de `SensorData.fromMap`~~ **PARCIAL:** `humedadSuelo`/`humedadAire` ahora nullable; pH/EC ocultos en dispositivos suelo vía `isHydroDeviceProvider`.

**[DEMO-15JUL] Estado del subconjunto de demo:** firmware existe; app tiene modo demo con 2 dispositivos (Pro hidro + Suelo). Dos caminos para la demo:
- **Simulación (garantizado):** compilar con `--dart-define=DEMO_MODE=true` — muestra la app completa con datos en vivo simulados, sin hardware.
- **Hardware real (PlantyCore ↔ PlantyLink):** build normal (kDemoMode=false por defecto) + ejecutar el checklist de `AUDITORIA_FIRMWARE_HARDWARE.md` (cuenta de dispositivo, Web API key, flashear, calibrar, vincular). El fix de ruta del CF ya está hecho; **pendiente re-desplegar functions** si se quieren las push de humedad.

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
   - ~~Campos propios `humedad_suelo` / `humedad_aire` en `sensors/` + parseo en `SensorData`~~ **HECHO.** `SensorData` los parsea como nullable; shim `MAP_SOIL_TO_TANK=0` en firmware.
   - ~~Nodo `devices/{id}/info/` (capacidades, versión de firmware, modelo de hardware)~~ **HECHO.** `DeviceInfo` modelo + `DeviceInfoService` + `deviceInfoProvider`.
   - `PlantProfile` con umbrales de suelo (`humedad_suelo_min/max`) + discriminador `tipo_cultivo` + **catálogo de plantas de tierra** (el `PlantCatalog` actual es de hortalizas hidropónicas con umbrales EC/pH — el caso base del producto ya no es ese). **PARCIAL:** `PlantProfile` tiene `tipoCultivo` y `humedadSueloMin/Max`; `PlantCatalog.plantasSuelo` existe con 5 plantas de tierra.
   - Revisión de escalabilidad: el nodo `sensors/` plano con ~20 campos opcionales ya muestra el anti-patrón "un nodo gigante con campos para todo". Con capacidades declaradas en `info/`, `sensors/` plano es tolerable; sin ellas, no.
3. **Arreglos baratos e independientes (pueden ir primero, no dependen de P1–P4):** fix `sensores`→`sensors` en `functions/index.js`; `.indexOn: ["timestamp"]` para `history` y `alerts`; endurecer `cached/` (solo lectura para clientes, escritura vía CF); actualizar README.

### Fase 1 — Verdad de conexión y propiedad de nodos
*Depende de: nada de Fase 0 salvo decisiones (puede solaparse). Bloquea: OTA (Fase 4), UX de estados (Fase 5). Costo: bajo-medio. Reversibilidad: alta.*

1. **Presencia real:** derivar "conectado" de la antigüedad de `timestamp` (consumir el `staleDataStream` que ya existe o recalcular en el widget) y/o heartbeat + CF programada que marque `conectado=false`. Retirar la semántica actual del booleano escrito por el firmware.
2. **Propiedad por nodo, documentada y respetada:** `sensors/` lo escribe SOLO el firmware; `controls/` SOLO la app. **LADO APP HECHO** (`cleanup/safe-refactor`): `ControlService.setPump` ya no hace eco en `sensors/` — escribe solo `controls/$pumpKey`. El botón muestra estado "pendiente" (`PumpCommandsNotifier` + `pumpCommandsProvider`, spinner en `IlluminatedButton`) hasta que el firmware confirme vía `sensors/`, con timeout de 8 s (`pumpConfirmTimeoutProvider`) para no quedar colgado si se pierde el comando. **Pendiente (firmware):** que el firmware sea el único escritor de `sensors/<bomba>` y eche el valor aplicado al actuar; hasta entonces, contra hardware real el botón queda en "pendiente" hasta el timeout. Cubierto por `test/providers/pump_commands_test.dart`.
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

1. ~~**Dashboard por capacidades:**~~ **HECHO.** `isHydroDeviceProvider` oculta pH/EC/tanques/dosificadoras en dispositivos suelo. Tarjetas de `humedad_suelo`/`humedad_aire` implementadas en `SensorCard` y `SimpleMetricsGrid`. Demo mode ahora simula dos dispositivos (full-hydro + soil-only) con switch funcional.
2. ~~**Estados de error visibles:**~~ **PARCIAL.** `dataStalenessProvider` implementa "datos viejos desde hace X min" (Live/Stale/Offline). El chip de estado en `DeviceScreen` lo consume. **Pendiente:** "dispositivo nunca ha reportado", "comando de bomba pendiente/sin confirmar", online/offline por dispositivo en la lista de `device_screen`.
3. **Historial server-side:** mover la grabación de `history/` de la app (hoy: solo graba con la app abierta, `sensor_repository_impl.dart:101`) al firmware o a una CF programada; retirar el recorder del repositorio y la poda cliente (que descarga el nodo entero).
4. **Unificar alertas en un solo lugar** (CF como fuente de verdad; la app solo presenta), eliminando la triplicación actual.

**Grafo de dependencias resumido:**
`F0 → {F1, F2, F5}` · `F1 → {F2.5(fallback), F4, F5.2}` · `F2 → {F3, F4}` · `F3 y F5` incrementales, no bloquean nada.

---

## Deuda técnica identificada

**[ROADMAP-PRODUCTO]** salvo indicación contraria.

| # | Deuda | Dónde | Gravedad |
|---|---|---|---|
| 1 | ~~Detección de desconexión rota~~ **PARCIAL:** `dataStalenessProvider` reemplaza `staleDataStream` — la UI ahora degrada Live→Stale→Offline por antigüedad de `timestamp`. Pendiente: el booleano `conectado` del firmware sigue sin poder volver a `false`; considerar retirarlo a favor exclusivo de staleness | `data_staleness_provider.dart`, firmware | ~~Alta~~ Baja (mitigado en UI) |
| 2 | ~~Bug de ruta `sensores` vs `sensors`~~ **RESUELTO Y DESPLEGADO** (commit `3c508b8`): el trigger escucha `/devices/{id}/sensors`. Nuevo pendiente: los checks de humedad de F0.4 están commiteados pero **sin re-desplegar** (`firebase deploy --only functions`) | `functions/index.js` | ~~Alta~~ Baja (falta redeploy para push de humedad) |
| 3 | ~~Doble escritor sobre `sensors/bomba_agua` (eco optimista de la app + eco del firmware)~~ **LADO APP RESUELTO** (`cleanup/safe-refactor`): la app escribe solo `controls/`; UI "pendiente" hasta confirmación por `sensors/`. Pendiente: firmware como único escritor de `sensors/<bomba>` | `control_service.dart`, `app_providers.dart` (`PumpCommandsNotifier`), firmware | ~~Media~~ Baja (resuelto en app) |
| 4 | `history/` escrito por la app: huecos cuando nadie abre la app, poda que descarga el nodo completo, sin `.indexOn` | `sensor_repository_impl.dart`, `history_service.dart`, `database.rules.json` | Media-alta |
| 5 | Reglas: device-hijack (cualquier cuenta puede reclamar cualquier `esp32_id`) y `cached/` escribible por cualquier autenticado | `database.rules.json` | Alta a escala; tolerable con 1 unidad |
| 6 | ~~`kDemoMode` default `true`~~ **RESUELTO:** default cambiado a `false`. Compilar demo requiere `--dart-define=DEMO_MODE=true` explícito | `app_config.dart` | ~~Media~~ Cerrado |
| 7 | ~~Defaults engañosos~~ **PARCIAL:** `humedadSuelo`/`humedadAire` ahora son nullable (null = sin sensor). pH/EC siguen con default 7.0/0.0 pero `isHydroDeviceProvider` los oculta en dispositivos suelo. Resolver completamente con `DeviceInfo` capabilities | `sensor_data.dart`, `app_providers.dart` | ~~Media~~ Baja |
| 8 | Heurística EC frágil (`>10` ⇒ µS/cm) repetida en app y CF | `sensor_data.dart:34`, `functions/index.js:52` | Baja; fijar unidad canónica en esquema v2 |
| 9 | ~~Código muerto: `registrarNFC`/`nfc_logs`, `staleDataStream`~~ **RESUELTO:** ambos eliminados | — | ~~Baja~~ Cerrado |
| 10 | Lógica de alertas triplicada (trend provider, notifs locales, CF) | `trend_alert_provider.dart`, `notification_service.dart`, `functions/index.js` | Media |
| 11 | ~~README documenta reglas/esquema que no existen~~ **RESUELTO** (commit `e5de59a`): README apunta al esquema device-scoped real | `README.md` | ~~Baja~~ Cerrado |
| 12 | ~~archivo sin commitear~~ **PARCIAL:** firmware commiteado con guard `.gitignore` para `firmware/**/secrets.h` (commit `a97002d`). Credenciales aún como `#define` con placeholders; extracción real a `secrets.h` pendiente (Fase 2) | `firmware/esp32_plantylink/esp32_plantylink.ino` | ~~Media~~ Baja |
| 13 | ~~Shim `MAP_SOIL_TO_TANK`~~ **RESUELTO:** firmware commit `24342e7` puso `MAP_SOIL_TO_TANK=0` y la app ya muestra `humedad_suelo` directamente | — | ~~Media~~ Cerrado |

---

## Qué de esto NO debe tocarse antes del 15 de julio

> **Nota (actualización 2026-07-14):** varios ítems de esta lista ya fueron implementados con éxito (humedad_suelo/aire en UI, staleness, shim retirado). Se mantiene la lista como referencia de decisiones, tachando lo resuelto.

- **`firmware/esp32_plantylink/esp32_plantylink.ino`** — NO modularizar, NO migrar a PlatformIO, NO meter NVS/OTA/máquina de estados. Cambios permitidos: solo credenciales, `DEVICE_ID` y las dos constantes de calibración del suelo.
- ~~**`lib/models/sensor_data.dart` y el esquema de `sensors/`** — NO añadir aún `humedad_suelo`/`humedad_aire`~~ **YA HECHO** — `SensorData` los parsea como nullable, el dashboard los muestra, shim `MAP_SOIL_TO_TANK=0`.
- **`lib/core/services/control_service.dart` (eco optimista)** — NO cambiar la doble escritura ahora: el botón de bomba de la demo depende de ese eco para responder al instante.
- **`database.rules.json`** — NO endurecer reglas (device-hijack, `cached/`) antes de la demo.
- ~~**Detección de staleness / chip "Conectado"**~~ **YA HECHO** — `dataStalenessProvider` reemplaza `staleDataStream`; la UI degrada Live→Stale→Offline.
- **Único cambio de código seguro y recomendado pre-demo:** `sensores` → `sensors` en `functions/index.js:77` + redeploy de functions.
