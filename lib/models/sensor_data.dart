class SensorData {
  final double? temperatura;
  final double? humedad;
  final bool? nivelAgua;
  final DateTime timestamp;

  SensorData({
    this.temperatura,
    this.humedad,
    this.nivelAgua,
    required this.timestamp,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      temperatura: (map['temperatura'] ?? 0).toDouble(),
      humedad: (map['humedad'] ?? 0).toDouble(),
      nivelAgua: map['nivel_agua'] as bool? ?? false,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperatura': temperatura,
      'humedad': humedad,
      'nivelAgua': nivelAgua,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
