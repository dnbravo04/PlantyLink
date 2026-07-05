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
 *       humedad_aire       %HR           ← DHT22            (la app la muestra, F0.2)
 *       humedad_suelo      %             ← sensor capacitivo (la app la muestra, F0.2)
 *       nivel_agua_tanque  %             ← humedad_suelo, SOLO si MAP_SOIL_TO_TANK=1 (shim, ahora 0)
 *       bomba_agua         bool          ← estado real del relé
 *       conectado          true
 *       timestamp          epoch ms      ← ServerValue.timestamp (hora del servidor RTDB)
 *   ESCRIBE devices/{DEVICE_ID}/info/                     (una vez, al arrancar)
 *       modelo_hardware, version_firmware, tipo_cultivo, sensores{}, actuadores{}
 *       → modelo de capacidades (P1): la app muestra solo lo que este equipo tiene
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

// Shim de demo (F0.2: RESUELTO). La app ya tiene tarjeta propia de humedad de
// suelo, así que dejamos de prestar el campo nivel_agua_tanque. Poner a 1 solo
// para demos con una versión antigua de la app que no muestra humedad_suelo.
#define MAP_SOIL_TO_TANK 0

// Identidad/capacidades publicadas en devices/{id}/info al arrancar.
#define FW_VERSION      "0.1.0-demo"
#define HW_MODEL        "esp32-soil-v1"

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

// ─── Capacidades (modelo P1) → devices/{id}/info ─────────────────────────────
// La app lee esto para mostrar SOLO los sensores/actuadores que este equipo
// tiene, en vez de asumir el set hidropónico completo. Los sets se guardan como
// mapas {clave: true} (RTDB desaconseja arrays).
void declareCapabilities() {
  FirebaseJson info;
  info.set("modelo_hardware", HW_MODEL);
  info.set("version_firmware", FW_VERSION);
  info.set("tipo_cultivo", "suelo");
  info.set("sensores/temperatura", true);
  info.set("sensores/humedad_aire", true);
  info.set("sensores/humedad_suelo", true);
  info.set("actuadores/bomba_agua", true);
  Firebase.RTDB.updateNode(&fbdo, kBasePath + "/info", &info);
  Serial.println("[INFO] capacidades declaradas en devices/" DEVICE_ID "/info");
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
  declareCapabilities();

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
