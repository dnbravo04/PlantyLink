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

  Map<String, dynamic> toMap() => {
    'planta': nombre,
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
      nombre: 'Lechuga',
      emoji: '🥬',
      tempMin: 15,
      tempMax: 24,
      humMin: 60,
      humMax: 80,
      phMin: 5.5,
      phMax: 6.5,
    ),
    PlantProfile(
      nombre: 'Albahaca',
      emoji: '🌿',
      tempMin: 18,
      tempMax: 30,
      humMin: 50,
      humMax: 75,
      phMin: 5.5,
      phMax: 6.5,
    ),
    PlantProfile(
      nombre: 'Tomate',
      emoji: '🍅',
      tempMin: 20,
      tempMax: 28,
      humMin: 65,
      humMax: 85,
      phMin: 5.8,
      phMax: 6.8,
    ),
  ];
}
