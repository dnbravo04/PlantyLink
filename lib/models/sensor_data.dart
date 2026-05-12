class SensorData {
  final double? temperatura;
  final double? nivelAguaTanque; // Nivel de agua en tanque (%)
  final double? nivelFertilizanteTanque; // Nivel de fertilizante en tanque (%)
  final double? ph; // pH del agua
  final double? conductividad; // Conductividad eléctrica (mS/cm)
  final bool? nivelAgua; // Nivel de agua (true/false)
  final bool? conectado; // Estado de conexión
  final bool? bombaAgua; // Control bomba de agua
  final bool? bombaFertilizante; // Control bomba de fertilizante
  final bool? bombaDosificadoraAcido; // Bomba dosificadora ácido
  final bool? bombaDosificadoraBasico; // Bomba dosificadora básico
  final DateTime timestamp;

  SensorData({
    this.temperatura,
    this.nivelAguaTanque,
    this.nivelFertilizanteTanque,
    this.ph,
    this.conductividad,
    this.nivelAgua,
    this.bombaAgua,
    this.bombaFertilizante,
    this.bombaDosificadoraAcido,
    this.bombaDosificadoraBasico,
    this.conectado,
    required this.timestamp,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      temperatura: (map['temperatura'] as num?)?.toDouble() ?? 0.0,
      nivelAguaTanque: (map['nivel_agua_tanque'] as num?)?.toDouble() ?? 0.0,
      nivelFertilizanteTanque:
          (map['nivel_fertilizante_tanque'] as num?)?.toDouble() ?? 0.0,
      ph: (map['ph'] as num?)?.toDouble() ?? 7.0,
      conductividad: (map['conductividad'] as num?)?.toDouble() ?? 0.0,
      nivelAgua: map['nivel_agua'] as bool? ?? false,
      bombaAgua: map['bomba_agua'] as bool? ?? false,
      bombaFertilizante: map['bomba_fertilizante'] as bool? ?? false,
      bombaDosificadoraAcido: map['bomba_dosificadora_acido'] as bool? ?? false,
      bombaDosificadoraBasico:
          map['bomba_dosificadora_basico'] as bool? ?? false,
      conectado: map['conectado'] as bool? ?? false,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['timestamp'] as num).toInt())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperatura': temperatura,
      'nivel_agua_tanque': nivelAguaTanque,
      'nivel_fertilizante_tanque': nivelFertilizanteTanque,
      'ph': ph,
      'conductividad': conductividad,
      'nivel_agua': nivelAgua,
      'bomba_agua': bombaAgua,
      'bomba_fertilizante': bombaFertilizante,
      'bomba_dosificadora_acido': bombaDosificadoraAcido,
      'bomba_dosificadora_basico': bombaDosificadoraBasico,
      'conectado': conectado,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
