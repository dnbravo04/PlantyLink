/**
 * PlantyLink — Firmware
*/

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ─── Configuración: EDITAR ANTES DE FLASHEAR ─────────────────────────────────
#define WIFI_SSID       "REDACTED_WIFI_SSID"
#define WIFI_PASSWORD   "REDACTED_WIFI_PASSWORD"

#define API_KEY         "AIzaSyADO17mJSijQWZmYXcju-9tx1ftHD-HYRU"
#define DATABASE_URL    "https://hydrotrack-13047.firebaseio.com"

#define DEVICE_EMAIL    "esp32-01@plantylink.device"
#define DEVICE_PASSWORD "REDACTED_DEVICE_PASSWORD"

#define DEVICE_ID       "pl-esp32-01"

#define FW_VERSION      "0.2.0-demo-ingenia"
#define HW_MODEL        "esp32-demo-v1"

// ─── Pines ───────────────────────────────────────────────────────────────────
#define PIN_PROBE       34   // ADC1_CH6 · solo-entrada · ADC1 obligatorio con WiFi
#define PIN_PUMP_LED    2    // LED azul onboard = estado de la bomba
#define PIN_PUMP_EXT    26   // LED externo opcional (mismo estado)

// ─── Sonda ───────────────────────────────────────────────────────────────────
#define R_FIXED         10000.0f   // resistencia del divisor (la de 10 kΩ)
#define ADC_MAX         4095.0f

// Parámetros del NTC 10k (valores típicos; ajustables si hay tiempo de calibrar)
#define NTC_R0          10000.0f   // resistencia nominal a 25 °C
#define NTC_T0_K        298.15f    // 25 °C en kelvin
#define NTC_BETA        3950.0f    // constante Beta típica de estas sondas

// Rangos de decisión de la auto-detección
#define PROBE_NTC_MIN   4000.0f
#define PROBE_NTC_MAX   40000.0f
#define PROBE_OPEN_MIN  100000.0f

enum ProbeType { PROBE_NTC, PROBE_PT100, PROBE_NONE };
ProbeType probeType = PROBE_NONE;

// ─── Temporización ───────────────────────────────────────────────────────────
#define PUBLISH_INTERVAL_MS 2000UL   // muy por debajo del umbral stale (10 s) de la app
#define SIM_TICK_MS         250UL    // paso de integración de la simulación

// ─── Riego automático ────────────────────────────────────────────────────────
#define AUTO_ON_BELOW_PCT   35.0f
#define AUTO_RUN_MS         8000UL
#define AUTO_COOLDOWN_MS    30000UL  // reducido a 30 s: en la expo el jurado no espera 1 min

// ─── Modelo de simulación del suelo ──────────────────────────────────────────
// El suelo se seca solo, y se humedece cuando la bomba está encendida.
// Así el ciclo completo (baja → riega → sube → corta) se ve EN VIVO en la app.
#define SOIL_START_PCT    55.0f
#define SOIL_DRY_RATE     0.45f   // % por segundo que baja sin riego  (~45 s para llegar a 35 %)
#define SOIL_WET_RATE     3.50f   // % por segundo que sube con la bomba encendida
#define SOIL_MIN_PCT      8.0f
#define SOIL_MAX_PCT      92.0f

// ─── Estado global ───────────────────────────────────────────────────────────
FirebaseData   fbdo;
FirebaseData   fbStream;
FirebaseAuth   fbAuth;
FirebaseConfig fbConfig;

const String kBasePath     = String("devices/") + DEVICE_ID;
const String kSensorsPath  = kBasePath + "/sensors";
const String kControlsPath = kBasePath + "/controls";

bool manualPumpCmd   = false;
bool autoMode        = false;
bool autoCycleActive = false;
bool pumpState       = false;

unsigned long autoCycleStartMs = 0;
unsigned long lastAutoCycleEnd = 0;
unsigned long lastPublishMs    = 0;
unsigned long lastSimTickMs    = 0;

float soilPct = SOIL_START_PCT;

// ─── Actuador (LED en lugar del relé) ────────────────────────────────────────
void applyPump(bool on) {
  digitalWrite(PIN_PUMP_LED, on ? HIGH : LOW);
  digitalWrite(PIN_PUMP_EXT, on ? HIGH : LOW);
  pumpState = on;
  Serial.printf("[BOMBA] %s\n", on ? "ON" : "OFF");
}

void echoPumpState() {
  if (!Firebase.ready()) return;
  Firebase.RTDB.setBoolAsync(&fbdo, kSensorsPath + "/bomba_agua", pumpState);
}

// ─── Lectura cruda de la sonda ───────────────────────────────────────────────
float readProbeOhms() {
  uint32_t acc = 0;
  for (int i = 0; i < 32; i++) {
    acc += analogRead(PIN_PROBE);
    delay(2);
  }
  float raw = acc / 32.0f;
  if (raw >= ADC_MAX - 1.0f) return 1.0e9f;   // circuito abierto
  if (raw <= 1.0f)           return 0.0f;     // cortocircuito a GND
  return R_FIXED * raw / (ADC_MAX - raw);
}

void detectProbe() {
  float r = readProbeOhms();
  Serial.printf("[SONDA] R medida ≈ %.0f ohm\n", r);

  if (r >= PROBE_NTC_MIN && r <= PROBE_NTC_MAX) {
    probeType = PROBE_NTC;
    Serial.println("[SONDA] Detectada: NTC 10k → TEMPERATURA REAL habilitada");
  } else if (r > 0.0f && r < 1000.0f) {
    probeType = PROBE_PT100;
    Serial.println("[SONDA] Detectada: PT100 (2 hilos) → resolución insuficiente sin");
    Serial.println("        amplificador MAX31865 → TEMPERATURA SIMULADA");
  } else {
    probeType = PROBE_NONE;
    Serial.println("[SONDA] No conectada o fuera de rango → TEMPERATURA SIMULADA");
  }
}

// ─── Temperatura ─────────────────────────────────────────────────────────────
float readTemperatureC() {
  if (probeType == PROBE_NTC) {
    float r = readProbeOhms();
    if (r > 0.0f && r < 1.0e8f) {
      // Ecuación Beta: 1/T = 1/T0 + (1/B) · ln(R/R0)
      float invT = 1.0f / NTC_T0_K + (1.0f / NTC_BETA) * log(r / NTC_R0);
      float tC = (1.0f / invT) - 273.15f;
      if (tC > -20.0f && tC < 80.0f) return tC;
    }
  }
  // Simulación: ambiente de invernadero, deriva lenta + ruido.
  float base = 23.0f + 1.5f * sin(millis() / 45000.0f);
  return base + (random(-30, 31) / 100.0f);
}

// ─── Humedad de aire (simulada: no hay DHT22) ────────────────────────────────
// Ligada al suelo de forma plausible: suelo húmedo → aire algo más húmedo.
float simulateAirHumidity() {
  float base = 45.0f + 0.25f * soilPct;
  return constrain(base + (random(-80, 81) / 100.0f), 30.0f, 90.0f);
}

// ─── Simulación de humedad de suelo ──────────────────────────────────────────
void tickSoilSimulation(float dtSeconds) {
  if (pumpState) {
    soilPct += SOIL_WET_RATE * dtSeconds;
  } else {
    soilPct -= SOIL_DRY_RATE * dtSeconds;
  }
  soilPct += (random(-4, 5) / 100.0f);   // ruido de medición
  soilPct = constrain(soilPct, SOIL_MIN_PCT, SOIL_MAX_PCT);
}

// ─── Publicación a RTDB ──────────────────────────────────────────────────────
void publishSensors() {
  float t = readTemperatureC();
  float h = simulateAirHumidity();

  FirebaseJson json;
  json.set("temperatura", t);
  json.set("humedad_aire", h);
  json.set("humedad_suelo", soilPct);
  json.set("bomba_agua", pumpState);
  json.set("conectado", true);

  if (!Firebase.RTDB.updateNodeSilent(&fbdo, kSensorsPath, &json)) {
    Serial.printf("[RTDB] updateNode falló: %s\n", fbdo.errorReason().c_str());
    return;
  }
  Firebase.RTDB.setTimestamp(&fbdo, kSensorsPath + "/timestamp");

  Serial.printf("[RTDB] pub ok  T=%.1f°C%s  HR=%.0f%%(sim)  suelo=%.0f%%(sim)  bomba=%d\n",
                t, (probeType == PROBE_NTC ? "(real)" : "(sim)"), h, soilPct, pumpState);
}

// ─── Stream de controls/ ─────────────────────────────────────────────────────
void handleControlKey(const String &key, bool value) {
  if (key == "bomba_agua") {
    manualPumpCmd = value;
    Serial.printf("[CTRL] bomba_agua = %d\n", value);
  } else if (key == "riego_automatico") {
    autoMode = value;
    Serial.printf("[CTRL] riego_automatico = %d\n", value);
  } else {
    Serial.printf("[CTRL] %s = %d (sin hardware en este prototipo)\n", key.c_str(), value);
  }
}

void streamCallback(FirebaseStream data) {
  const String path = data.dataPath();
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
// Declaramos explícitamente qué es real y qué está simulado. Esto es honesto,
// y además le da a la app la información para marcarlo en la UI si hace falta.
void declareCapabilities() {
  const bool tempReal = (probeType == PROBE_NTC);

  FirebaseJson info;
  info.set("modelo_hardware", HW_MODEL);
  info.set("version_firmware", FW_VERSION);
  info.set("tipo_cultivo", "suelo");
  info.set("modo_demo", true);

  info.set("sensores/temperatura", true);
  info.set("sensores/humedad_aire", true);
  info.set("sensores/humedad_suelo", true);
  info.set("actuadores/bomba_agua", true);

  info.set("sensores_simulados/temperatura", !tempReal);
  info.set("sensores_simulados/humedad_aire", true);
  info.set("sensores_simulados/humedad_suelo", true);
  info.set("actuadores_simulados/bomba_agua", true);   // LED en lugar de relé+bomba

  Firebase.RTDB.updateNode(&fbdo, kBasePath + "/info", &info);
  Serial.println("[INFO] capacidades declaradas (modo_demo = true)");
}

// ─── Setup / Loop ────────────────────────────────────────────────────────────
void setup() {
  pinMode(PIN_PUMP_LED, OUTPUT);
  pinMode(PIN_PUMP_EXT, OUTPUT);
  applyPump(false);

  Serial.begin(115200);
  delay(500);
  Serial.println("\n\n=== PlantyLink · firmware demo Ingenia Futuro ===");

  randomSeed(esp_random());

  analogReadResolution(12);
  analogSetPinAttenuation(PIN_PROBE, ADC_11db);
  detectProbe();

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

  selfRegister();
  declareCapabilities();

  if (!Firebase.RTDB.beginStream(&fbStream, kControlsPath)) {
    Serial.printf("[RTDB] beginStream falló: %s\n", fbStream.errorReason().c_str());
  }
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback, streamTimeoutCallback);

  lastSimTickMs = millis();
  Serial.println("=== listo · abre la app y conéctate a " DEVICE_ID " ===\n");
}

void loop() {
  if (!Firebase.ready()) return;

  const unsigned long now = millis();

  // ── Simulación del suelo ──
  if (now - lastSimTickMs >= SIM_TICK_MS) {
    float dt = (now - lastSimTickMs) / 1000.0f;
    lastSimTickMs = now;
    tickSoilSimulation(dt);
  }

  // ── Riego automático ──
  if (autoCycleActive && now - autoCycleStartMs >= AUTO_RUN_MS) {
    autoCycleActive = false;
    lastAutoCycleEnd = now;
    Serial.println("[AUTO] ciclo de riego terminado");
  }
  if (autoMode && !autoCycleActive && !manualPumpCmd &&
      soilPct < AUTO_ON_BELOW_PCT &&
      now - lastAutoCycleEnd >= AUTO_COOLDOWN_MS) {
    autoCycleActive = true;
    autoCycleStartMs = now;
    Serial.printf("[AUTO] suelo %.0f%% < %.0f%% → ciclo de riego de %lu s\n",
                  soilPct, AUTO_ON_BELOW_PCT, AUTO_RUN_MS / 1000);
  }

  // ── Aplicar estado de bomba (manual O ciclo automático) ──
  const bool desired = manualPumpCmd || autoCycleActive;
  if (desired != pumpState) {
    applyPump(desired);
    echoPumpState();
  }

  // ── Publicación periódica ──
  if (now - lastPublishMs >= PUBLISH_INTERVAL_MS) {
    lastPublishMs = now;
    publishSensors();
  }
}

