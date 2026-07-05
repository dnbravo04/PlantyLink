# PlantyLink — Auditoría de firmware y hardware (estado real del repo)

**Fecha de auditoría:** 2026-07-04 · **Objetivo:** demo en vivo el 2026-07-15.
**Repo auditado:** app Flutter + Firebase (proyecto `hydrotrack-13047`, RTDB `https://hydrotrack-13047.firebaseio.com`) + Cloud Functions. Todo lo afirmado aquí proviene de archivos del repositorio; lo que no existe se marca como **no implementado / no encontrado**.

Este documento es autocontenido: sirve para pedir recomendaciones de compra de hardware sin acceso al repo.

---

## Estado encontrado

### 1. Firmware: NO EXISTE

Búsqueda exhaustiva: `**/*.ino`, `**/platformio.ini`, carpeta `/firmware`, `*.py` de MicroPython, `*.c/*.cpp/*.h` fuera de boilerplate.

- **0 archivos de firmware.** Los únicos `.cpp/.h` del repo son runners generados por Flutter para Windows/Linux/iOS (ej. `windows/runner/main.cpp`) y artefactos de build de Android. Nada de ESP32.
- **No hay** código de WiFi, ni de conexión Firebase embebida, ni definición de pines, ni drivers de sensores en ninguna parte del repo.
- La única mención al firmware es un comentario en `database.rules.json`: *"the future ESP32 firmware will need its own auth strategy to write sensor data"* — es decir, el propio repo reconoce que el firmware no existe.

### 2. Lado Flutter: completo y funcional (contrato definido)

Archivos relevantes encontrados en `/lib`:

| Archivo | Rol |
|---|---|
| `lib/models/sensor_data.dart` | Modelo de lecturas: define TODAS las claves que el ESP32 debe escribir |
| `lib/models/linked_device.dart` | Dispositivo registrado bajo `usuarios/{uid}/dispositivos/{esp32Id}` |
| `lib/models/pump_schedule.dart` | Horarios de riego (`actuador`, `hora_inicio 'HH:mm'`, `duracion_minutos`, `dias_semana 0=Lun…6=Dom`, `activo`) |
| `lib/models/plant_profile.dart` | Perfil de planta con umbrales (`temp_min/max`, `ph_min/max`, `ec_min/max`, `nivel_agua_min`, `nivel_fertilizante_min`) |
| `lib/core/services/sensor_stream_service.dart` | Lee `devices/{id}/sensors` en vivo; marca datos **stale si `timestamp` > 10 s** de antigüedad |
| `lib/core/services/control_service.dart` | Escribe `devices/{id}/controls/{bomba}` (y espeja en `sensors/` para UI inmediata) |
| `lib/core/services/calibration_service.dart` | Escribe `devices/{id}/calibration` (pH 2 puntos, factor EC) "para que el ESP32 los aplique" |
| `lib/core/services/schedule_service.dart` | Escribe `devices/{id}/schedules`; el comentario dice "el ESP32 sondea este nodo" |
| `lib/core/services/history_service.dart` + `lib/data/repositories/sensor_repository_impl.dart` | **El historial lo escribe la APP** (snapshot cada 30 s mientras está abierta), no el ESP32 |
| `lib/core/services/device_service.dart` | Vinculación multi-dispositivo bajo `usuarios/{uid}` + log NFC |
| `lib/presentation/screens/onboarding/esp32_vinculacion_screen.dart` | Pantalla de emparejamiento: NFC + QR + entrada manual |
| `lib/core/app_config.dart` | `kDemoMode` — **default `true`**; producción requiere compilar con `--dart-define=DEMO_MODE=false` |
| `functions/index.js` | Cloud Function `sensorAlerts`: push FCM cuando un valor sale del rango del perfil |

### 3. Esquema RTDB que el código espera (extraído de las rutas leídas/escritas)

```
devices/{esp32Id}/
├── sensors/                  ← LEE la app (stream en vivo). DEBE escribirlo el ESP32.
│   ├── temperatura            num  °C
│   ├── ph                     num  (default UI: 7.0 si falta)
│   ├── conductividad          num  mS/cm; si >10 la app asume µS/cm y divide /1000
│   ├── nivel_agua_tanque      num  %
│   ├── nivel_fertilizante_tanque  num  %
│   ├── nivel_agua             bool (switch de nivel)
│   ├── conectado              bool
│   ├── bomba_agua / bomba_fertilizante /
│   │   bomba_dosificadora_acido / bomba_dosificadora_basico   bool (estado)
│   ├── *_auto, *_manual_override                              bool (modos)
│   └── timestamp              num  epoch **milisegundos** (staleness: >10 s = desconectado)
├── controls/                 ← ESCRIBE la app. DEBE leerlo el ESP32 (stream/poll).
│   ├── bomba_agua … bomba_dosificadora_basico   bool (comandos)
│   └── riego_automatico                          bool
├── calibration/              ← escribe la app; el ESP32 debería aplicarla (pH/EC)
├── schedules/{pushKey}/      ← escribe la app; el ESP32 debería ejecutarlos
├── history/                  ← escribe la APP cada 30 s (no es tarea del ESP32)
├── alerts/                   ← escribe la app (alertas de tendencia)
├── profile/                  ← escribe la app (planta activa + umbrales)
├── alert_state/              ← escribe la Cloud Function (cooldown de push)
└── nfc_logs/                 ← escribe la app al escanear

usuarios/{uid}/
├── esp32_id                  string  → dispositivo ACTIVO del usuario
├── esp32_vinculado           bool
├── dispositivos/{esp32Id}/   {nombre, vinculado_en}
├── fcm_token, alerts_enabled, plants/, foto_url, …
```

**Seguridad (`database.rules.json`):** `devices/{esp32Id}` solo es legible/escribible por un usuario autenticado cuyo `usuarios/{uid}/esp32_id` sea ese ID (o lo tenga en `dispositivos/`). Consecuencia directa para el firmware: **el ESP32 debe autenticarse contra Firebase Auth** (no hay escritura anónima). Una cuenta email/contraseña "de dispositivo" que se auto-registre en su propio nodo `usuarios/{uid}/esp32_id` cumple las reglas sin tocar la consola más que para crear el usuario.

### 4. Qué asume la app que el ESP32 hace (y qué es mock)

- **Sensores esperados (por semántica del modelo, la app NO define tipos ni pines en ninguna parte):** temperatura (°C), pH, conductividad EC, nivel de agua de tanque (%), nivel de fertilizante (%), switch booleano de nivel. **No se encontró en el repo ningún tipo de sensor concreto, protocolo ni pin** — el hardware nunca fue especificado.
- **Actuadores esperados:** 4 bombas booleanas (`bomba_agua`, `bomba_fertilizante`, `bomba_dosificadora_acido`, `bomba_dosificadora_basico`) + modo `riego_automatico`. La app escribe el comando en `controls/` y espeja en `sensors/` para que el botón responda al instante; espera que el dispositivo aplique el comando. Lógica eléctrica (HIGH/LOW, PWM): **no definida en el repo**.
- **Comunicación:** existe SOLO del lado Flutter (SDK Firebase en el teléfono). **No hay ni una línea de código de red para ESP32.**
- **NFC:** implementado **completamente del lado app** (`nfc_manager ^4.2.1`). La pantalla de vinculación lee el **UID de un tag pasivo** (ISO 14443/15693), lo formatea como hex `aa:bb:cc:dd` y lo registra bajo `usuarios/{uid}`. También hay QR y entrada manual (regex de ID válido: `^[a-zA-Z0-9][a-zA-Z0-9:\-_]{2,63}$`). **El ESP32 no necesita chip NFC:** basta un sticker NFC pasivo (o un QR impreso) en la caja cuyo contenido/UID sea el `DEVICE_ID` del firmware. No hay ni hace falta código NFC en firmware.
- **Mock/demo:** `DemoDataService` simula todo en memoria (temperatura ~24 °C, pH ~6.8, EC ~1500 µS/cm, tanques 75 %/60 %) cuando `kDemoMode == true`, que es el **default de compilación**. En modo producción la app lee Firebase de verdad y además graba el historial ella misma cada 30 s.

### 5. Discrepancias y hallazgos importantes

1. **Bug de ruta en Cloud Functions:** `functions/index.js` escucha `/devices/{esp32Id}/sensores` (español) pero la app lee/escribe `devices/{esp32Id}/sensors` (inglés). **La función de push FCM nunca se dispara hoy.** Arreglo de una línea (cambiar `sensores` → `sensors` y redesplegar) si se quieren notificaciones push en la demo.
2. **README desactualizado:** documenta unas reglas con nodo raíz `sensores/` que no coinciden con `database.rules.json` real.
3. **La app no tiene UI de humedad de suelo ni humedad ambiente.** El dashboard muestra: temperatura, pH, EC, tanque de agua, fertilizante. `SensorData` no tiene campo `humedad_suelo`. El pedido de priorizar humedad de suelo + DHT22 para la demo **no encaja 1:1 con la UI actual** — ver decisión tomada en "Firmware generado".
4. **Umbral de staleness = 10 s:** el firmware debe publicar a intervalos menores o el dashboard mostrará "desconectado".
5. **`timestamp` en milisegundos epoch:** un timestamp mal formado deja la app en "stale" permanente. El firmware generado usa el timestamp del servidor RTDB para evitar depender de NTP.
6. **Para la demo la app debe compilarse con `--dart-define=DEMO_MODE=false`**, si no, ignora Firebase por completo.

### Suposiciones hechas (por ausencia de información en el repo)

- Tipo de placa (**ESP32 DevKit WROOM-32**), sensores concretos (**DHT22**, **capacitivo v1.2**), relé (**módulo 1 canal optoacoplado activo-LOW**) y todos los pines: elegidos por mí; el repo no especifica nada de hardware.
- Estrategia de autenticación del dispositivo (cuenta email/contraseña + auto-registro): derivada de las reglas, pero no está prescrita en el repo.
- Calibración del sensor de suelo (`SOIL_RAW_AIR=3200`, `SOIL_RAW_WATER=1300`): valores típicos a 3.3 V/12 bits, **deben medirse con el sensor real**.
- Parámetros de riego automático (umbral 35 %, ciclo 8 s, cooldown 60 s): inventados como valores razonables de demo; la app solo define el booleano `riego_automatico`.

---

## Firmware generado

Archivo creado en el repo: **`firmware/esp32_plantylink/esp32_plantylink.ino`** (Arduino IDE / arduino-cli, placa "ESP32 Dev Module").

### Decisiones de diseño

- **Stack:** Arduino-ESP32 + librería **Firebase-ESP-Client (mobizt) v4.4.x** (maneja login email/contraseña, refresh de token y streams RTDB) + **DHT sensor library (Adafruit)**. Es la vía con más documentación para llegar al 15 de julio.
- **Publica cada 5 s** a `devices/{DEVICE_ID}/sensors` (la app marca stale a los 10 s).
- **Mapeo de sensores → claves del contrato:**
  - DHT22 temperatura → `temperatura` (la app la muestra tal cual ✔)
  - DHT22 humedad → `humedad_aire` (clave nueva; **la app la ignora hoy** — pendiente UI)
  - Suelo capacitivo → `humedad_suelo` (clave nueva; **la app la ignora hoy** — pendiente UI)
  - Con `MAP_SOIL_TO_TANK 1` (default, **shim de demo señalizado**): `humedad_suelo` se publica también como `nivel_agua_tanque`, para que el gauge "Tanque de agua" del dashboard reaccione en vivo al regar. Poner a 0 cuando haya UI propia o sensor de nivel real.
- **`timestamp`:** se escribe con `setTimestamp` (hora del servidor RTDB, epoch ms) — sin dependencia de NTP.
- **Control de bomba:** stream sobre `devices/{DEVICE_ID}/controls`; aplica `bomba_agua` al relé (GPIO 26, activo-LOW) y refleja el estado real en `sensors/bomba_agua`. `riego_automatico` implementa un ciclo simple: suelo < 35 % → bomba 8 s → cooldown 60 s.
- **Auth:** login con cuenta de dispositivo (email/contraseña) y **auto-registro** al arrancar (`usuarios/{uid}/esp32_id = DEVICE_ID`), lo que satisface `database.rules.json` sin cambios en las reglas.
- **Anti-arranque de bomba en boot:** el pin del relé se fija en reposo *antes* de `pinMode` (los módulos activo-LOW se disparan con el pin flotante durante el boot).

### NO implementado (pendiente explícito, no simulado)

- **NFC en firmware** — innecesario: el emparejamiento lo resuelve el teléfono leyendo un tag pasivo pegado a la caja (o QR/manual).
- `bomba_fertilizante`, dosificadoras ácido/base — los comandos se reciben y se registran por Serial, sin hardware asignado.
- `schedules/` (horarios) y `calibration/` (no hay sensores pH/EC en este prototipo).
- Sensores de pH, EC, niveles de tanque reales → la UI mostrará sus defaults (pH 7.0, EC 0, fertilizante 0 %).

### Puesta en marcha (checklist para el 15 de julio)

1. Firebase console → Authentication → habilitar Email/Password → crear usuario p. ej. `esp32-01@plantylink.device`.
2. Copiar la **Web API Key** (Configuración del proyecto → General) en `API_KEY`.
3. Editar en el `.ino`: WiFi, credenciales del dispositivo y `DEVICE_ID` (p. ej. `pl-esp32-01`).
4. Flashear; verificar por Serial `[AUTH] … OK` y `[RTDB] pub ok`.
5. Compilar la app con `flutter run --dart-define=DEMO_MODE=false` e ir a "Conectar dispositivo" → **Ingresar ID** (o QR con el texto `pl-esp32-01`, o grabar/pegar un tag NFC cuyo UID se use como `DEVICE_ID`).
6. Calibrar el sensor de suelo: leer el crudo al aire y en agua (Serial) y ajustar `SOIL_RAW_AIR` / `SOIL_RAW_WATER`.
7. Opcional (push FCM): corregir `sensores` → `sensors` en `functions/index.js` y `firebase deploy --only functions`.

### Código completo (`firmware/esp32_plantylink/esp32_plantylink.ino`)

```cpp
/**
 * PlantyLink — Firmware ESP32 · Prototipo mínimo para demo (2026-07-15)
 * =====================================================================
 *
 * Implementa exactamente el contrato que la app Flutter ya espera en
 * Firebase Realtime Database (ver lib/core/services/*.dart):
 *
 *   LEE   devices/{DEVICE_ID}/controls/bomba_agua         (bool, escrito por la app)
 *   LEE   devices/{DEVICE_ID}/controls/riego_automatico   (bool, escrito por la app)
 *   ESCRIBE devices/{DEVICE_ID}/sensors/                  (cada PUBLISH_INTERVAL_MS)
 *       temperatura        °C            ← DHT22
 *       humedad_aire       %HR           ← DHT22   (clave NUEVA: la app aún no la muestra)
 *       humedad_suelo      %             ← sensor capacitivo (clave NUEVA: la app aún no la muestra)
 *       nivel_agua_tanque  %             ← humedad_suelo, SOLO si MAP_SOIL_TO_TANK=1 (shim de demo)
 *       bomba_agua         bool          ← estado real del relé
 *       conectado          true
 *       timestamp          epoch ms      ← ServerValue.timestamp (hora del servidor RTDB)
 *
 * La app marca los datos como "stale" si timestamp tiene más de 10 s
 * (SensorStreamService.staleDataStream) → publicamos cada 5 s.
 *
 * Autenticación: las reglas (database.rules.json) exigen auth != null y que
 * usuarios/{auth.uid}/esp32_id == DEVICE_ID. Este firmware inicia sesión con
 * una "cuenta de dispositivo" (email/contraseña creada en Firebase Auth) y se
 * auto-registra escribiendo usuarios/{su_uid}/esp32_id = DEVICE_ID al arrancar
 * (permitido por las reglas: cada cuenta escribe su propio nodo usuarios/).
 *
 * NO implementado (pendiente explícito, no crítico para la demo):
 *   - NFC en firmware: no hace falta. El emparejamiento NFC lo hace el
 *     teléfono leyendo el UID de un tag pasivo (sticker NTAG) pegado a la caja.
 *   - bomba_fertilizante / dosificadoras ácido-base (se registran por Serial).
 *   - schedules/ (horarios de riego) y calibration/ (pH/EC: no hay sensores).
 *   - Sensores de pH, EC y niveles de tanque reales.
 *
 * Placa:      ESP32 DevKit (WROOM-32)
 * Librerías (Arduino IDE → Library Manager):
 *   - "Firebase Arduino Client Library for ESP8266 and ESP32" (mobizt) v4.4.x
 *   - "DHT sensor library" (Adafruit) + "Adafruit Unified Sensor"
 */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <DHT.h>
#include "addons/TokenHelper.h" // tokenStatusCallback
#include "addons/RTDBHelper.h"  // ayudas de impresión RTDB

// ─── Configuración: EDITAR ANTES DE FLASHEAR ─────────────────────────────────
#define WIFI_SSID       "TU_SSID"
#define WIFI_PASSWORD   "TU_PASSWORD"

// Firebase console → Configuración del proyecto → General → "Clave de API web"
#define API_KEY         "TU_WEB_API_KEY"
#define DATABASE_URL    "https://hydrotrack-13047.firebaseio.com" // = lib/core/firebase_constants.dart

// Cuenta de dispositivo: crearla UNA vez en Firebase console → Authentication
// → Users → Add user (proveedor email/contraseña habilitado).
#define DEVICE_EMAIL    "esp32-01@plantylink.device"
#define DEVICE_PASSWORD "CAMBIAR_ESTA_CLAVE"

// Debe coincidir EXACTAMENTE con el ID que se vincula en la app (QR, manual o
// UID del tag NFC). Formato válido según la app: ^[a-zA-Z0-9][a-zA-Z0-9:\-_]{2,63}$
#define DEVICE_ID       "pl-esp32-01"

// Shim de demo: publica humedad_suelo también como nivel_agua_tanque para que
// el gauge "Tanque de agua" del dashboard reaccione en vivo. Poner 0 cuando
// exista sensor de nivel real o UI propia de humedad de suelo.
#define MAP_SOIL_TO_TANK 1

// ─── Pines ───────────────────────────────────────────────────────────────────
// GPIO 4 : DHT22 (digital). Sin conflicto con WiFi.
// GPIO 34: sensor de humedad de suelo (ADC1_CH6). OBLIGATORIO usar ADC1
//          (GPIO 32-39): los pines ADC2 no funcionan con WiFi activo.
//          GPIO 34 es solo-entrada, ideal para un sensor analógico.
// GPIO 26: relé de la bomba. No es pin de strapping (evitamos 0/2/12/15) y no
//          genera pulsos en el arranque.
#define PIN_DHT        4
#define PIN_SOIL       34
#define PIN_RELAY_PUMP 26
#define PIN_LED_STATUS 2   // LED azul onboard: encendido = Firebase listo

// La mayoría de módulos de relé de 1 canal con optoacoplador son activos en LOW.
#define RELAY_ACTIVE_LOW 1

// ─── Calibración del sensor de suelo (capacitivo v1.2 @ 3.3 V, ADC 12 bits) ──
// Medir y ajustar: valor crudo con el sensor al aire (seco) y sumergido (agua).
#define SOIL_RAW_AIR   3200
#define SOIL_RAW_WATER 1300

// ─── Temporización ───────────────────────────────────────────────────────────
#define PUBLISH_INTERVAL_MS 5000UL   // < 10 s (umbral stale de la app)

// Riego automático (controls/riego_automatico == true):
#define AUTO_ON_BELOW_PCT   35.0f    // arranca ciclo si humedad_suelo < 35 %
#define AUTO_RUN_MS         8000UL   // bomba encendida 8 s por ciclo
#define AUTO_COOLDOWN_MS    60000UL  // mínimo 60 s entre ciclos

// ─── Estado global ───────────────────────────────────────────────────────────
DHT dht(PIN_DHT, DHT22);

FirebaseData   fbdo;      // operaciones puntuales (set/update)
FirebaseData   fbStream;  // stream de controls/
FirebaseAuth   fbAuth;
FirebaseConfig fbConfig;

const String kBasePath    = String("devices/") + DEVICE_ID;
const String kSensorsPath = kBasePath + "/sensors";
const String kControlsPath = kBasePath + "/controls";

bool manualPumpCmd   = false; // controls/bomba_agua (orden de la app)
bool autoMode        = false; // controls/riego_automatico
bool autoCycleActive = false;
bool relayState      = false; // estado real aplicado al relé

unsigned long autoCycleStartMs = 0;
unsigned long lastAutoCycleEnd = 0;
unsigned long lastPublishMs    = 0;

float lastSoilPct = -1; // -1 = sin lectura válida aún

// ─── Relé ────────────────────────────────────────────────────────────────────
void applyRelay(bool on) {
#if RELAY_ACTIVE_LOW
  digitalWrite(PIN_RELAY_PUMP, on ? LOW : HIGH);
#else
  digitalWrite(PIN_RELAY_PUMP, on ? HIGH : LOW);
#endif
  relayState = on;
  Serial.printf("[BOMBA] %s\n", on ? "ON" : "OFF");
}

// Refleja el estado real de la bomba en sensors/bomba_agua para que el botón
// de la app quede sincronizado (la app lee sensors/, no controls/).
void echoPumpState() {
  if (!Firebase.ready()) return;
  Firebase.RTDB.setBoolAsync(&fbdo, kSensorsPath + "/bomba_agua", relayState);
}

// ─── Sensores ────────────────────────────────────────────────────────────────
float readSoilPct() {
  uint32_t acc = 0;
  for (int i = 0; i < 8; i++) {
    acc += analogRead(PIN_SOIL);
    delay(3);
  }
  int raw = acc / 8;
  float pct = 100.0f * (SOIL_RAW_AIR - raw) / float(SOIL_RAW_AIR - SOIL_RAW_WATER);
  return constrain(pct, 0.0f, 100.0f);
}

// ─── Publicación a RTDB ──────────────────────────────────────────────────────
void publishSensors() {
  float t = dht.readTemperature(); // °C
  float h = dht.readHumidity();    // %HR
  float soil = readSoilPct();
  lastSoilPct = soil;

  FirebaseJson json;
  if (!isnan(t)) json.set("temperatura", t);
  if (!isnan(h)) json.set("humedad_aire", h);
  json.set("humedad_suelo", soil);
#if MAP_SOIL_TO_TANK
  json.set("nivel_agua_tanque", soil);
#endif
  json.set("bomba_agua", relayState);
  json.set("conectado", true);

  if (!Firebase.RTDB.updateNodeSilent(&fbdo, kSensorsPath, &json)) {
    Serial.printf("[RTDB] updateNode falló: %s\n", fbdo.errorReason().c_str());
    return;
  }
  // Hora del servidor (epoch ms) — evita depender de NTP local y satisface el
  // chequeo de staleness de la app (timestamp en milisegundos).
  Firebase.RTDB.setTimestamp(&fbdo, kSensorsPath + "/timestamp");

  Serial.printf("[RTDB] pub ok  T=%.1f°C  HR=%.0f%%  suelo=%.0f%%  bomba=%d\n",
                t, h, soil, relayState);
}

// ─── Stream de controls/ ─────────────────────────────────────────────────────
void handleControlKey(const String &key, bool value) {
  if (key == "bomba_agua") {
    manualPumpCmd = value;
    Serial.printf("[CTRL] bomba_agua = %d\n", value);
  } else if (key == "riego_automatico") {
    autoMode = value;
    Serial.printf("[CTRL] riego_automatico = %d\n", value);
  } else if (key == "bomba_fertilizante" || key == "bomba_dosificadora_acido" ||
             key == "bomba_dosificadora_basico") {
    // Pendiente: sin hardware asignado en este prototipo.
    Serial.printf("[CTRL] %s = %d (NO IMPLEMENTADO en este prototipo)\n",
                  key.c_str(), value);
  }
}

void streamCallback(FirebaseStream data) {
  const String path = data.dataPath(); // "/" (snapshot inicial) o "/<clave>"
  if (path == "/" && data.dataTypeEnum() == firebase_rtdb_data_type_json) {
    FirebaseJson *json = data.jsonObjectPtr();
    FirebaseJsonData item;
    if (json->get(item, "bomba_agua"))       handleControlKey("bomba_agua", item.to<bool>());
    if (json->get(item, "riego_automatico")) handleControlKey("riego_automatico", item.to<bool>());
  } else if (data.dataTypeEnum() == firebase_rtdb_data_type_boolean) {
    handleControlKey(path.substring(1), data.to<bool>());
  }
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) Serial.println("[RTDB] stream timeout, reconectando…");
}

// ─── Auto-registro (satisface database.rules.json) ───────────────────────────
void selfRegister() {
  const String uid = fbAuth.token.uid.c_str();
  Firebase.RTDB.setString(&fbdo, "usuarios/" + uid + "/esp32_id", DEVICE_ID);
  Firebase.RTDB.setBool(&fbdo, "usuarios/" + uid + "/esp32_vinculado", true);
  Serial.printf("[AUTH] registrado uid=%s → esp32_id=%s\n", uid.c_str(), DEVICE_ID);
}

// ─── Setup / Loop ────────────────────────────────────────────────────────────
void setup() {
  // Relé en reposo ANTES de configurar el pin: evita que la bomba arranque
  // durante el boot (con módulos activos-LOW el pin flotante enciende el relé).
#if RELAY_ACTIVE_LOW
  digitalWrite(PIN_RELAY_PUMP, HIGH);
#else
  digitalWrite(PIN_RELAY_PUMP, LOW);
#endif
  pinMode(PIN_RELAY_PUMP, OUTPUT);
  applyRelay(false);

  pinMode(PIN_LED_STATUS, OUTPUT);
  digitalWrite(PIN_LED_STATUS, LOW);

  Serial.begin(115200);
  dht.begin();
  analogReadResolution(12);
  analogSetPinAttenuation(PIN_SOIL, ADC_11db); // rango completo ~0-3.3 V

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("[WiFi] conectando");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.printf("\n[WiFi] OK  ip=%s\n", WiFi.localIP().toString().c_str());

  fbConfig.api_key = API_KEY;
  fbConfig.database_url = DATABASE_URL;
  fbConfig.token_status_callback = tokenStatusCallback;
  fbAuth.user.email = DEVICE_EMAIL;
  fbAuth.user.password = DEVICE_PASSWORD;

  Firebase.begin(&fbConfig, &fbAuth);
  Firebase.reconnectWiFi(true);

  Serial.print("[AUTH] esperando token");
  while (!Firebase.ready()) {
    Serial.print(".");
    delay(300);
  }
  Serial.println(" OK");
  digitalWrite(PIN_LED_STATUS, HIGH);

  selfRegister();

  if (!Firebase.RTDB.beginStream(&fbStream, kControlsPath)) {
    Serial.printf("[RTDB] beginStream falló: %s\n", fbStream.errorReason().c_str());
  }
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback, streamTimeoutCallback);
}

void loop() {
  if (!Firebase.ready()) {
    digitalWrite(PIN_LED_STATUS, LOW);
    return;
  }
  digitalWrite(PIN_LED_STATUS, HIGH);

  const unsigned long now = millis();

  // ── Riego automático ──
  if (autoCycleActive && now - autoCycleStartMs >= AUTO_RUN_MS) {
    autoCycleActive = false;
    lastAutoCycleEnd = now;
  }
  if (autoMode && !autoCycleActive && !manualPumpCmd &&
      lastSoilPct >= 0 && lastSoilPct < AUTO_ON_BELOW_PCT &&
      now - lastAutoCycleEnd >= AUTO_COOLDOWN_MS) {
    autoCycleActive = true;
    autoCycleStartMs = now;
    Serial.printf("[AUTO] suelo %.0f%% < %.0f%% → ciclo de riego %lus\n",
                  lastSoilPct, AUTO_ON_BELOW_PCT, AUTO_RUN_MS / 1000);
  }

  // ── Aplicar estado de bomba (manual O ciclo automático) ──
  const bool desired = manualPumpCmd || autoCycleActive;
  if (desired != relayState) {
    applyRelay(desired);
    echoPumpState();
  }

  // ── Publicación periódica ──
  if (now - lastPublishMs >= PUBLISH_INTERVAL_MS) {
    lastPublishMs = now;
    publishSensors();
  }
}
```

---

## Especificación de hardware

Derivada estrictamente del firmware anterior (no del "diseño ideal" de la app).

### Lista de compra

| # | Componente | Protocolo / interfaz | Pin ESP32 | Voltaje | Corriente aprox. | Cantidad |
|---|---|---|---|---|---|---|
| 1 | ESP32 DevKit V1 (WROOM-32, 30 o 38 pines) | WiFi 2.4 GHz (b/g/n) — **no 5 GHz** | — | 5 V por USB/VIN (lógica 3.3 V) | picos ~400 mA en TX WiFi | 1 |
| 2 | DHT22 / AM2302 (temperatura + humedad ambiente) | Digital 1-wire propietario | GPIO 4 (+ pull-up 10 kΩ a 3.3 V si es el sensor suelto; los módulos de 3 pines ya la traen) | 3.3 V | ~1.5 mA | 1 |
| 3 | Sensor capacitivo de humedad de suelo v1.2 | Analógico (0–3.0 V a VCC 3.3 V) | GPIO 34 (ADC1_CH6, solo-entrada) | **3.3 V** (no 5 V: la salida saturaría el ADC) | ~5 mA | 1 |
| 4 | Módulo relé 1 canal con optoacoplador, disparo LOW | Digital (activo-LOW) | GPIO 26 | VCC 5 V (bobina); señal IN acepta 3.3 V | ~70 mA al activar bobina | 1 |
| 5 | Mini bomba de agua sumergible DC 3–5 V (o 12 V + fuente propia) | Conmutada por contactos del relé | — (a través del relé) | 3–5 V DC | 100–300 mA (verificar la ficha) | 1 |
| 6 | Fuente USB 5 V ≥ 2 A + cable micro-USB de datos | — | — | 5 V | — | 1 |
| 7 | Tag NFC pasivo NTAG213/215 (sticker) **o** QR impreso con el `DEVICE_ID` | ISO 14443 (lo lee el teléfono, no el ESP32) | — | pasivo | — | 1 |
| 8 | Protoboard + cables dupont M-M/M-H | — | — | — | — | 1 juego |
| 9 | (Opcional, recomendado) Fuente 5 V dedicada para la bomba o portapilas 3×AA | — | — | 5 V | según bomba | 1 |

### Mapa de pines y justificación

| GPIO | Uso | Por qué este pin |
|---|---|---|
| 34 | Suelo (analógico) | Es **ADC1**: los canales ADC2 (GPIO 0, 2, 4, 12–15, 25–27) **quedan inutilizables para `analogRead` mientras el WiFi está activo** — limitación de silicio del ESP32 descubierta/confirmada al escribir el firmware. GPIO 34 además es solo-entrada, sin funciones de boot. |
| 4 | DHT22 (digital) | GPIO 4 es ADC2, pero aquí se usa como **digital**, así que no hay conflicto con WiFi. No es pin de strapping. |
| 26 | Relé bomba | Pin de propósito general sin rol en el boot; se evitan los strapping pins (0, 2, 5, 12, 15) que pueden pulsar el relé al arrancar, y los pines de flash (6–11), que no deben tocarse. |
| 2 | LED de estado | LED azul onboard del DevKit; es strapping pin pero como salida de LED no afecta. |

### Limitaciones y advertencias descubiertas al escribir el firmware

1. **ADC2 vs WiFi:** cualquier sensor analógico adicional (pH, EC, nivel por presión…) debe ir a ADC1 (GPIO 32–39). Quedan libres 32, 33, 35, 36, 39 → hay margen para los sensores futuros de la app (pH y EC analógicos cabrían sin problema).
2. **Relé a 3.3 V:** los módulos de relé de 5 V con optoacoplador disparan bien con 3.3 V en modo activo-LOW; si se consigue un módulo que no conmute, usar uno con jumper VCC/JD-VCC (alimentar bobina a 5 V del VIN y señal a 3.3 V) o un módulo específico de 3.3 V.
3. **Alimentación de la bomba:** **nunca** desde el pin 3V3 del ESP32 (el regulador no da para el pico del motor + WiFi → brownout y reinicio). Usar el pin VIN/5 V solo si la fuente USB es ≥ 2 A y la bomba pequeña; lo robusto es fuente separada para la bomba con **GND común** con el ESP32.
4. **Pulso del relé en el boot:** con módulos activo-LOW, el pin flota durante el arranque y la bomba puede dar un golpe de ~1 s. El firmware lo mitiga fijando el pin en reposo como primera instrucción de `setup()`; elegir GPIO 26 (y no 0/2/15) también evita los pulsos de strapping.
5. **DHT22 mínimo 2 s entre lecturas:** el ciclo de publicación de 5 s lo respeta de sobra.
6. **WiFi solo 2.4 GHz:** para la demo, asegurar que el hotspot/red del venue tenga banda 2.4 GHz visible (los hotspots de iPhone modernos requieren activar "Maximizar compatibilidad").
7. **Sin sensor de nivel real:** `nivel_agua` (bool) no se publica; la app lo trata como `false` por defecto. El gauge de fertilizante mostrará 0 %. Es el comportamiento honesto con el hardware disponible; el shim `MAP_SOIL_TO_TANK` es la única concesión de demo y está señalizada en el código.

### Pendientes explícitos post-demo

- UI en Flutter para `humedad_suelo` y `humedad_aire` (hoy el modelo `SensorData` ni las lee).
- Fix de una línea en `functions/index.js` (`sensores` → `sensors`) para que funcionen las push FCM.
- Ejecución de `schedules/` y aplicación de `calibration/` en firmware.
- Sensores de pH, EC y nivel de tanque + las 3 bombas restantes, si el producto sigue la línea hidropónica que la app ya modela.
