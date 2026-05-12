class SensorData {
  final double? temperatura;
  final double? nivelAguaTanque; // Nivel de agua en tanque (%)
  final double? nivelFertilizanteTanque; // Nivel de fertilizante en tanque (%)
  final double? ph; // pH del agua
  final double? conductividad; // Conductividad eléctrica (mS/cm)
  final bool? nivelAgua; // Nivel de agua (true/false)
  final bool? conectado; // Estado de conexión

  // Estados de actuadores
  final bool? bombaAgua; // Control bomba de agua
  final bool? bombaFertilizante; // Control bomba de fertilizante
  final bool? bombaDosificadoraAcido; // Bomba dosificadora ácido
  final bool? bombaDosificadoraBasico; // Bomba dosificadora básico

  // Modos automáticos
  final bool? bombaAguaAuto; // Modo automático bomba agua
  final bool? bombaFertilizanteAuto; // Modo automático bomba fertilizante
  final bool? dosificadoraAcidoAuto; // Modo automático dosificadora ácido
  final bool? dosificadoraBaseAuto; // Modo automático dosificadora base

  // Sobrescritura manual
  final bool? bombaAguaManualOverride; // Sobrescritura manual bomba agua
  final bool?
  bombaFertilizanteManualOverride; // Sobrescritura manual bomba fertilizante
  final bool?
  dosificadoraAcidoManualOverride; // Sobrescritura manual dosificadora ácido
  final bool?
  dosificadoraBaseManualOverride; // Sobrescritura manual dosificadora base

  final DateTime timestamp;

  SensorData({
    this.temperatura,
    this.nivelAguaTanque,
    this.nivelFertilizanteTanque,
    this.ph,
    this.conductividad,
    this.nivelAgua,
    this.conectado,
    this.bombaAgua,
    this.bombaFertilizante,
    this.bombaDosificadoraAcido,
    this.bombaDosificadoraBasico,
    this.bombaAguaAuto,
    this.bombaFertilizanteAuto,
    this.dosificadoraAcidoAuto,
    this.dosificadoraBaseAuto,
    this.bombaAguaManualOverride,
    this.bombaFertilizanteManualOverride,
    this.dosificadoraAcidoManualOverride,
    this.dosificadoraBaseManualOverride,
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
      conectado: map['conectado'] as bool? ?? false,

      // Estados de actuadores
      bombaAgua: map['bomba_agua'] as bool? ?? false,
      bombaFertilizante: map['bomba_fertilizante'] as bool? ?? false,
      bombaDosificadoraAcido: map['bomba_dosificadora_acido'] as bool? ?? false,
      bombaDosificadoraBasico:
          map['bomba_dosificadora_basico'] as bool? ?? false,

      // Modos automáticos
      bombaAguaAuto: map['bomba_agua_auto'] as bool? ?? false,
      bombaFertilizanteAuto: map['bomba_fertilizante_auto'] as bool? ?? false,
      dosificadoraAcidoAuto: map['dosificadora_acido_auto'] as bool? ?? false,
      dosificadoraBaseAuto: map['dosificadora_base_auto'] as bool? ?? false,

      // Sobrescritura manual
      bombaAguaManualOverride:
          map['bomba_agua_manual_override'] as bool? ?? false,
      bombaFertilizanteManualOverride:
          map['bomba_fertilizante_manual_override'] as bool? ?? false,
      dosificadoraAcidoManualOverride:
          map['dosificadora_acido_manual_override'] as bool? ?? false,
      dosificadoraBaseManualOverride:
          map['dosificadora_base_manual_override'] as bool? ?? false,

      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['timestamp'] as num).toInt(),
            )
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
      'conectado': conectado,

      // Estados de actuadores
      'bomba_agua': bombaAgua,
      'bomba_fertilizante': bombaFertilizante,
      'bomba_dosificadora_acido': bombaDosificadoraAcido,
      'bomba_dosificadora_basico': bombaDosificadoraBasico,

      // Modos automáticos
      'bomba_agua_auto': bombaAguaAuto,
      'bomba_fertilizante_auto': bombaFertilizanteAuto,
      'dosificadora_acido_auto': dosificadoraAcidoAuto,
      'dosificadora_base_auto': dosificadoraBaseAuto,

      // Sobrescritura manual
      'bomba_agua_manual_override': bombaAguaManualOverride,
      'bomba_fertilizante_manual_override': bombaFertilizanteManualOverride,
      'dosificadora_acido_manual_override': dosificadoraAcidoManualOverride,
      'dosificadora_base_manual_override': dosificadoraBaseManualOverride,

      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
