/**
 * PlantyLink Cloud Functions.
 *
 * `sensorAlerts` watches each device's live sensor node and sends an FCM push
 * to the owning user(s) whenever a value leaves the range defined by the
 * active plant profile. This complements the in-app local notifications,
 * which only fire while the app is open.
 *
 * RTDB layout (see lib/core/services/*.dart):
 *   devices/{esp32Id}/sensores      → live sensor values (written by ESP32)
 *   devices/{esp32Id}/profile       → active plant profile with thresholds
 *   devices/{esp32Id}/alert_state   → last-notified timestamps (this function)
 *   usuarios/{uid}/esp32_id         → device linked to the user
 *   usuarios/{uid}/alerts_enabled   → user opt-out flag (default true)
 *   usuarios/{uid}/fcm_token        → push target (written by the app)
 */
const {onValueWritten} = require("firebase-functions/v2/database");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/** Minimum time between pushes for the same sensor on the same device. */
const COOLDOWN_MS = 30 * 60 * 1000;

/**
 * Checks run against the profile. `value` receives the raw `sensores` map,
 * already EC-normalized where relevant.
 */
const CHECKS = [
  {
    key: "temperatura",
    label: "Temperatura",
    unit: "°C",
    value: (s) => s.temperatura,
    min: (p) => p.temp_min,
    max: (p) => p.temp_max,
  },
  {
    key: "ph",
    label: "pH",
    unit: "",
    value: (s) => s.ph,
    min: (p) => p.ph_min,
    max: (p) => p.ph_max,
  },
  {
    key: "conductividad",
    label: "Conductividad EC",
    unit: " mS/cm",
    // ESP32 may report µS/cm; the app treats values > 10 as µS/cm.
    value: (s) =>
      s.conductividad > 10 ? s.conductividad / 1000 : s.conductividad,
    min: (p) => p.ec_min,
    max: (p) => p.ec_max,
  },
  {
    key: "nivel_agua_tanque",
    label: "Nivel de agua",
    unit: "%",
    value: (s) => s.nivel_agua_tanque,
    min: (p) => p.nivel_agua_min,
    max: () => null,
  },
  {
    key: "nivel_fertilizante_tanque",
    label: "Nivel de fertilizante",
    unit: "%",
    value: (s) => s.nivel_fertilizante_tanque,
    min: (p) => p.nivel_fertilizante_min,
    max: () => null,
  },
];

exports.sensorAlerts = onValueWritten(
    {
      ref: "/devices/{esp32Id}/sensores",
      instance: "hydrotrack-13047",
    },
    async (event) => {
      const esp32Id = event.params.esp32Id;
      const sensores = event.data.after.val();
      if (!sensores) return;

      const db = admin.database();
      const profileSnap =
          await db.ref(`devices/${esp32Id}/profile`).get();
      const profile = profileSnap.val();
      if (!profile) return; // no plant configured, nothing to compare against

      // ── Detect out-of-range sensors ─────────────────────────────────────
      const violations = [];
      for (const check of CHECKS) {
        const value = check.value(sensores);
        if (typeof value !== "number") continue;
        const min = check.min(profile);
        const max = check.max(profile);
        if (typeof min === "number" && value < min) {
          violations.push({
            ...check,
            current: value,
            message: `${check.label} baja: ${value.toFixed(1)}${check.unit} ` +
                `(mínimo ${min}${check.unit})`,
          });
        } else if (typeof max === "number" && value > max) {
          violations.push({
            ...check,
            current: value,
            message: `${check.label} alta: ${value.toFixed(1)}${check.unit} ` +
                `(máximo ${max}${check.unit})`,
          });
        }
      }
      if (violations.length === 0) return;

      // ── Cooldown: skip sensors alerted recently ─────────────────────────
      const now = Date.now();
      const stateRef = db.ref(`devices/${esp32Id}/alert_state`);
      const state = (await stateRef.get()).val() || {};
      const due = violations.filter(
          (v) => now - (state[v.key] || 0) > COOLDOWN_MS,
      );
      if (due.length === 0) return;

      // ── Resolve users linked to this device ─────────────────────────────
      const usersSnap = await db.ref("usuarios")
          .orderByChild("esp32_id").equalTo(esp32Id).get();
      const users = usersSnap.val() || {};
      const targets = Object.entries(users).filter(([, u]) =>
        u.fcm_token && u.alerts_enabled !== false);
      if (targets.length === 0) {
        logger.info(`No push targets for device ${esp32Id}`);
        return;
      }

      // ── Send one notification summarizing the due violations ────────────
      const planta = profile.planta || "tu cultivo";
      const body = due.map((v) => v.message).join("\n");
      const sends = targets.map(async ([uid, user]) => {
        try {
          await admin.messaging().send({
            token: user.fcm_token,
            notification: {
              title: `⚠️ Alerta de ${planta}`,
              body,
            },
            android: {
              priority: "high",
              notification: {channelId: "plantylink_alerts"},
            },
            apns: {payload: {aps: {sound: "default"}}},
          });
          logger.info(`Alert sent to ${uid} for ${esp32Id}`, {
            sensors: due.map((v) => v.key),
          });
        } catch (err) {
          // Stale token → remove it so we stop retrying.
          if (err.code === "messaging/registration-token-not-registered" ||
              err.code === "messaging/invalid-registration-token") {
            await db.ref(`usuarios/${uid}/fcm_token`).remove();
            logger.info(`Removed stale FCM token for ${uid}`);
          } else {
            logger.error(`FCM send failed for ${uid}`, err);
          }
        }
      });
      await Promise.all(sends);

      // ── Record notified timestamps ──────────────────────────────────────
      const updates = {};
      for (const v of due) updates[v.key] = now;
      await stateRef.update(updates);
    },
);
