class PumpSchedule {
  final String? id;
  final String actuador;
  final String horaInicio; // 'HH:mm'
  final int duracionMinutos;
  final List<int> diasSemana; // 0=Mon…6=Sun, empty = every day
  final bool activo;

  const PumpSchedule({
    this.id,
    required this.actuador,
    required this.horaInicio,
    required this.duracionMinutos,
    required this.diasSemana,
    this.activo = true,
  });

  Map<String, dynamic> toMap() => {
        'actuador': actuador,
        'hora_inicio': horaInicio,
        'duracion_minutos': duracionMinutos,
        'dias_semana': diasSemana,
        'activo': activo,
      };

  factory PumpSchedule.fromMap(String id, Map<dynamic, dynamic> map) {
    return PumpSchedule(
      id: id,
      actuador: map['actuador'] as String? ?? 'bomba_agua',
      horaInicio: map['hora_inicio'] as String? ?? '00:00',
      duracionMinutos: (map['duracion_minutos'] as num?)?.toInt() ?? 5,
      diasSemana: (map['dias_semana'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      activo: map['activo'] as bool? ?? true,
    );
  }

  PumpSchedule copyWith({bool? activo}) => PumpSchedule(
        id: id,
        actuador: actuador,
        horaInicio: horaInicio,
        duracionMinutos: duracionMinutos,
        diasSemana: diasSemana,
        activo: activo ?? this.activo,
      );
}
