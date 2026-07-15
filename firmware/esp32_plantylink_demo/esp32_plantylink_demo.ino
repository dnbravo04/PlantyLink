/**
 * PlantyLink — Firmware DEMO (PlantyCore) · 2026-07-15
 * =====================================================================
 * Build de demo en vivo con SOLO un ESP32, sin sensores externos.
 *
 * Por qué: el Pt100 pelado (2 pines, sin MAX31865 ni divisor) no se puede
 * leer. En su lugar publicamos la TEMPERATURA INTERNA del ESP32
 * (temperatureRead()) como `temperatura`: dato real del propio chip, en vivo,
 * que sube si tapas/tocas el módulo. Honesto y sin hardware extra.
 *
 * Demuestra:
 *   - PlantyLink ↔ PlantyCore conectados: temperatura en vivo en la app.
 *   - Control bidireccional: la app enciende "bomba_agua" → el firmware lo
 *     recibe, mueve GPIO2 (LED onboard si existe) y hace eco en sensors/, así
 *     el botón de la app se CONFIRMA (round-trip real por hardware).
 *
 * Contrato RTDB (igual que espera la app):
 *   ESCRIBE devices/{DEVICE_ID}/sensors/  cada 5 s: temperatura, bomba_agua,
 *           conectado, timestamp (hora del servidor).
 *   ESCRIBE devices/{DEVICE_ID}/info/     al arrancar: capacidades → la app
 *           muestra SOLO temperatura (oculta suelo/pH/EC por el modelo P1).
 *   LEE     devices/{DEVICE_ID}/controls/bomba_agua
 *
 * Placa:      ESP32 DevKit (ESP32-D0WD-V3), core esp32 3.x
 * Librerías:  "Firebase Arduino Client Library for ESP8266 and ESP32" (mobizt)
 */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ─── EDITAR ANTES DE FLASHEAR ────────────────────────────────────────────────
#define WIFI_SSID       "TU_SSID"          // red 2.4 GHz (no 5 GHz)
#define WIFI_PASSWORD   "TU_PASSWORD"

// Firebase console → Config del proyecto → General → "Clave de API web"
#define API_KEY         "TU_WEB_API_KEY"
#define DATABASE_URL    "https://hydrotrack-13047.firebaseio.com"

// Authentication → Users → Add user (proveedor email/contraseña habilitado)
#define DEVICE_EMAIL    "esp32-01@plantylink.device"
#define DEVICE_PASSWORD "CAMBIAR_ESTA_CLAVE"

// ID con el que vincularás en la app (QR / manual). Formato válido en la app:
// ^[a-zA-Z0-9][a-zA-Z0-9:\-_]{2,63}$
#define DEVICE_ID       "pl-esp32-01"

// ─── Pines ───────────────────────────────────────────────────────────────────
#define PIN_LED_BOMBA  2   // LED onboard (si la placa lo tiene). Sirve de "bomba".

// ─── Temporización ───────────────────────────────────────────────────────────
#define PUBLISH_INTERVAL_MS 5000UL  // < 10 s (umbral de "stale" de la app)

// ─── Estado ──────────────────────────────────────────────────────────────────
FirebaseData   fbdo;
FirebaseData   fbStream;
FirebaseAuth   fbAuth;
FirebaseConfig fbConfig;

const String kBasePath     = String("devices/") + DEVICE_ID;
const String kSensorsPath  = kBasePath + "/sensors";
const String kControlsPath = kBasePath + "/controls";

bool manualPumpCmd = false;
bool relayState    = false;
unsigned long lastPublishMs = 0;

// ─── Bomba (LED) ─────────────────────────────────────────────────────────────
void applyPump(bool on) {
  digitalWrite(PIN_LED_BOMBA, on ? HIGH : LOW);
  relayState = on;
  Serial.printf("[BOMBA] %s\n", on ? "ON" : "OFF");
  if (Firebase.ready()) {
    // Eco del estado real → la app confirma el botón (firmware dueño de sensors/)
    Firebase.RTDB.setBoolAsync(&fbdo, kSensorsPath + "/bomba_agua", relayState);
  }
}

// ─── Publicación ─────────────────────────────────────────────────────────────
void publishSensors() {
  float t = temperatureRead(); // °C — sensor interno del chip (core esp32 3.x)

  FirebaseJson json;
  json.set("temperatura", t);
  json.set("bomba_agua", relayState);
  json.set("conectado", true);

  if (!Firebase.RTDB.updateNodeSilent(&fbdo, kSensorsPath, &json)) {
    Serial.printf("[RTDB] updateNode falló: %s\n", fbdo.errorReason().c_str());
    return;
  }
  Firebase.RTDB.setTimestamp(&fbdo, kSensorsPath + "/timestamp");
  Serial.printf("[RTDB] pub ok  T=%.1f°C  bomba=%d\n", t, relayState);
}

// ─── Stream de controls/ ─────────────────────────────────────────────────────
void handleControlKey(const String &key, bool value) {
  if (key == "bomba_agua") {
    manualPumpCmd = value;
    Serial.printf("[CTRL] bomba_agua = %d\n", value);
  } else if (key == "riego_automatico") {
    Serial.printf("[CTRL] riego_automatico = %d (no usado en demo)\n", value);
  }
}

void streamCallback(FirebaseStream data) {
  const String path = data.dataPath();
  if (path == "/" && data.dataTypeEnum() == firebase_rtdb_data_type_json) {
    FirebaseJson *json = data.jsonObjectPtr();
    FirebaseJsonData item;
    if (json->get(item, "bomba_agua")) handleControlKey("bomba_agua", item.to<bool>());
  } else if (data.dataTypeEnum() == firebase_rtdb_data_type_boolean) {
    handleControlKey(path.substring(1), data.to<bool>());
  }
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) Serial.println("[RTDB] stream timeout, reconectando…");
}

// ─── Auto-registro + capacidades ─────────────────────────────────────────────
void selfRegister() {
  const String uid = fbAuth.token.uid.c_str();
  Firebase.RTDB.setString(&fbdo, "usuarios/" + uid + "/esp32_id", DEVICE_ID);
  Firebase.RTDB.setBool(&fbdo, "usuarios/" + uid + "/esp32_vinculado", true);
  Serial.printf("[AUTH] registrado uid=%s → esp32_id=%s\n", uid.c_str(), DEVICE_ID);
}

void declareCapabilities() {
  FirebaseJson info;
  info.set("modelo_hardware", "esp32-demo-internaltemp");
  info.set("version_firmware", "0.1.0-demo");
  info.set("tipo_cultivo", "suelo");        // no-hidro → app oculta pH/EC/tanques
  info.set("sensores/temperatura", true);   // ÚNICO sensor declarado
  info.set("actuadores/bomba_agua", true);
  Firebase.RTDB.updateNode(&fbdo, kBasePath + "/info", &info);
  Serial.println("[INFO] capacidades declaradas (solo temperatura)");
}

// ─── Setup / Loop ────────────────────────────────────────────────────────────
void setup() {
  pinMode(PIN_LED_BOMBA, OUTPUT);
  digitalWrite(PIN_LED_BOMBA, LOW);

  Serial.begin(115200);
  delay(200);
  Serial.println("\n[BOOT] PlantyCore demo (temp interna)");

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("[WiFi] conectando");
  while (WiFi.status() != WL_CONNECTED) { Serial.print("."); delay(300); }
  Serial.printf("\n[WiFi] OK  ip=%s\n", WiFi.localIP().toString().c_str());

  fbConfig.api_key = API_KEY;
  fbConfig.database_url = DATABASE_URL;
  fbConfig.token_status_callback = tokenStatusCallback;
  fbAuth.user.email = DEVICE_EMAIL;
  fbAuth.user.password = DEVICE_PASSWORD;

  Firebase.begin(&fbConfig, &fbAuth);
  Firebase.reconnectWiFi(true);

  Serial.print("[AUTH] esperando token");
  while (!Firebase.ready()) { Serial.print("."); delay(300); }
  Serial.println(" OK");

  selfRegister();
  declareCapabilities();

  if (!Firebase.RTDB.beginStream(&fbStream, kControlsPath)) {
    Serial.printf("[RTDB] beginStream falló: %s\n", fbStream.errorReason().c_str());
  }
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback, streamTimeoutCallback);
  Serial.println("[READY] publicando cada 5 s");
}

void loop() {
  if (!Firebase.ready()) return;

  if (manualPumpCmd != relayState) applyPump(manualPumpCmd);

  const unsigned long now = millis();
  if (now - lastPublishMs >= PUBLISH_INTERVAL_MS) {
    lastPublishMs = now;
    publishSensors();
  }
}
