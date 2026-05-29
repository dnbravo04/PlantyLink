/// Sensor drift / health status levels.
enum SensorHealthStatus {
  ok,
  warning,
  critical;

  String get label => switch (this) {
        SensorHealthStatus.ok => 'Normal',
        SensorHealthStatus.warning => 'Advertencia',
        SensorHealthStatus.critical => 'Crítico',
      };
}

/// Drift report for a single sensor, produced by
/// [AgronomicService.detectDrift].
class SensorHealth {
  final String sensorKey;

  /// Coefficient of variation (std dev / mean) of the last N readings.
  /// Higher means more erratic/drifting.
  final double driftMagnitude;

  final SensorHealthStatus status;
  final String recommendation;

  const SensorHealth({
    required this.sensorKey,
    required this.driftMagnitude,
    required this.status,
    required this.recommendation,
  });

  String get sensorLabel => switch (sensorKey) {
        'temperatura' => 'Temperatura',
        'ph' => 'pH',
        'conductividad' => 'Conductividad',
        'nivel_agua_tanque' => 'Nivel de agua',
        'nivel_fertilizante_tanque' => 'Nivel de fertilizante',
        _ => sensorKey,
      };
}
