# PlantyLink Cloud Functions

`sensorAlerts` envía notificaciones push (FCM) cuando un sensor sale del rango
definido por el perfil de planta activo, incluso con la app cerrada. La app
solo muestra notificaciones locales mientras está abierta; esta función cubre
el resto.

## Cómo funciona

1. El ESP32 escribe en `devices/{esp32Id}/sensores`.
2. La función compara cada valor con `devices/{esp32Id}/profile`
   (`temp_min/max`, `ph_min/max`, `ec_min/max`, `nivel_agua_min`,
   `nivel_fertilizante_min`).
3. Busca usuarios con `usuarios/{uid}/esp32_id == esp32Id`,
   `alerts_enabled != false` y un `fcm_token` (la app lo guarda al iniciar
   sesión en builds sin demo mode).
4. Envía un push por el canal `plantylink_alerts` con cooldown de 30 minutos
   por sensor (estado en `devices/{esp32Id}/alert_state`).

## Despliegue

```bash
cd functions
npm install
firebase login
firebase deploy --only functions
```

Requiere el plan Blaze en el proyecto `hydrotrack-13047` (las funciones con
triggers de RTDB no están en el plan gratuito). Probar en local:

```bash
npm run serve
```
