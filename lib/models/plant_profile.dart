class PlantProfile {
  final String nombre;
  final String emoji;
  final double tempMin, tempMax;
  final double humMin, humMax;
  final double phMin, phMax;

  const PlantProfile({
    required this.nombre,
    required this.emoji,
    required this.tempMin,
    required this.tempMax,
    required this.humMin,
    required this.humMax,
    required this.phMin,
    required this.phMax,
  });

  factory PlantProfile.fromMap(Map<dynamic, dynamic> map) {
    return PlantProfile(
      nombre: map['planta'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '🌱',
      tempMin: (map['temp_min'] as num?)?.toDouble() ?? 0.0,
      tempMax: (map['temp_max'] as num?)?.toDouble() ?? 0.0,
      humMin: (map['hum_min'] as num?)?.toDouble() ?? 0.0,
      humMax: (map['hum_max'] as num?)?.toDouble() ?? 0.0,
      phMin: (map['ph_min'] as num?)?.toDouble() ?? 0.0,
      phMax: (map['ph_max'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
    'planta': nombre,
    'emoji': emoji,
    'temp_min': tempMin,
    'temp_max': tempMax,
    'hum_min': humMin,
    'hum_max': humMax,
    'ph_min': phMin,
    'ph_max': phMax,
  };
}

class PlantCatalog {
  static const List<PlantProfile> plantas = [
    PlantProfile(
      nombre: 'Tomate Cherry',
      emoji: '🍅',
      tempMin: 18,
      tempMax: 28,
      humMin: 65,
      humMax: 85,
      phMin: 6.0,
      phMax: 7.0,
    ),
    PlantProfile(
      nombre: 'Lechuga Romana',
      emoji: '🥬',
      tempMin: 15,
      tempMax: 22,
      humMin: 60,
      humMax: 80,
      phMin: 5.5,
      phMax: 6.5,
    ),
    PlantProfile(
      nombre: 'Pimiento',
      emoji: '🫑',
      tempMin: 20,
      tempMax: 30,
      humMin: 60,
      humMax: 80,
      phMin: 6.0,
      phMax: 7.0,
    ),
    PlantProfile(
      nombre: 'Albahaca',
      emoji: '🌿',
      tempMin: 18,
      tempMax: 25,
      humMin: 50,
      humMax: 75,
      phMin: 5.5,
      phMax: 6.5,
    ),
  ];
}
