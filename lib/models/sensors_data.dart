class SensorData {
  final double temperatura;
  final double humedad;
  final bool nivelAgua;
  final DateTime timestamp;

  SensorData({
    required this.temperatura,
    required this.humedad,
    required this.nivelAgua,
    required this.timestamp,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      temperatura: (map['temperatura'] ?? 0).toDouble(),
      humedad: (map['humedad'] ?? 0).toDouble(),
      nivelAgua: map['nivel_agua'] ?? false,
      timestamp: DateTime.now(),
    );
  }
}