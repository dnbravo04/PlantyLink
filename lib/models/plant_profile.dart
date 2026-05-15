class PlantProfile {
  final String nombre;
  final String emoji;
  final double tempMin, tempMax;
  final double phMin, phMax;
  final double ecMin, ecMax;
  final double nivelAguaMin;
  final double nivelFertilizanteMin;
  final String fuente;

  const PlantProfile({
    required this.nombre,
    required this.emoji,
    required this.tempMin,
    required this.tempMax,
    required this.phMin,
    required this.phMax,
    required this.ecMin,
    required this.ecMax,
    required this.nivelAguaMin,
    required this.nivelFertilizanteMin,
    required this.fuente,
  });

  factory PlantProfile.fromMap(Map<dynamic, dynamic> map) {
    return PlantProfile(
      nombre: map['planta'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '🌱',
      tempMin: (map['temp_min'] as num?)?.toDouble() ?? 0.0,
      tempMax: (map['temp_max'] as num?)?.toDouble() ?? 0.0,
      phMin: (map['ph_min'] as num?)?.toDouble() ?? 0.0,
      phMax: (map['ph_max'] as num?)?.toDouble() ?? 0.0,
      ecMin: (map['ec_min'] as num?)?.toDouble() ?? 0.0,
      ecMax: (map['ec_max'] as num?)?.toDouble() ?? 0.0,
      nivelAguaMin: (map['nivel_agua_min'] as num?)?.toDouble() ?? 20.0,
      nivelFertilizanteMin:
          (map['nivel_fertilizante_min'] as num?)?.toDouble() ?? 20.0,
      fuente: map['fuente'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'planta': nombre,
    'emoji': emoji,
    'temp_min': tempMin,
    'temp_max': tempMax,
    'ph_min': phMin,
    'ph_max': phMax,
    'ec_min': ecMin,
    'ec_max': ecMax,
    'nivel_agua_min': nivelAguaMin,
    'nivel_fertilizante_min': nivelFertilizanteMin,
    'fuente': fuente,
  };
}

class PlantCatalog {
  static const List<PlantProfile> plantas = [
    PlantProfile(
      nombre: 'Tomate Cherry',
      emoji: '🍅',
      tempMin: 18,
      tempMax: 28,
      phMin: 5.5,
      phMax: 6.5,
      ecMin: 2.0,
      ecMax: 3.5,
      nivelAguaMin: 20.0,
      nivelFertilizanteMin: 20.0,
      fuente: 'Al-Gaadi et al. (2024), Phyton, 93(6)',
    ),
    PlantProfile(
      nombre: 'Lechuga Romana',
      emoji: '🥬',
      tempMin: 15,
      tempMax: 22,
      phMin: 5.5,
      phMax: 6.5,
      ecMin: 1.0,
      ecMax: 1.8,
      nivelAguaMin: 20.0,
      nivelFertilizanteMin: 20.0,
      fuente: 'Rofiansyah et al. (2025), PeerJ CS',
    ),
    PlantProfile(
      nombre: 'Pimiento',
      emoji: '🫑',
      tempMin: 20,
      tempMax: 30,
      phMin: 5.8,
      phMax: 6.5,
      ecMin: 1.8,
      ecMax: 2.8,
      nivelAguaMin: 20.0,
      nivelFertilizanteMin: 20.0,
      fuente: 'Rahman et al. (2023), Eur. J. Appl. Sci.',
    ),
    PlantProfile(
      nombre: 'Albahaca',
      emoji: '🌿',
      tempMin: 15,
      tempMax: 24,
      phMin: 5.5,
      phMax: 6.5,
      ecMin: 1.0,
      ecMax: 1.6,
      nivelAguaMin: 20.0,
      nivelFertilizanteMin: 20.0,
      fuente: 'Rusu et al. (2021), Sustainability',
    ),
    PlantProfile(
      nombre: 'Pothos (interior)',
      emoji: '🌿',
      tempMin: 18,
      tempMax: 30,
      phMin: 5.5,
      phMax: 6.5,
      ecMin: 0.8,
      ecMax: 1.5,
      nivelAguaMin: 20.0,
      nivelFertilizanteMin: 20.0,
      fuente: 'Dantas et al. (2024); estimado',
    ),
    PlantProfile(
      nombre: 'Sansevieria (interior)',
      emoji: '🪴',
      tempMin: 15,
      tempMax: 28,
      phMin: 5.5,
      phMax: 6.5,
      ecMin: 0.5,
      ecMax: 1.2,
      nivelAguaMin: 20.0,
      nivelFertilizanteMin: 20.0,
      fuente: 'Dantas et al. (2024); estimado',
    ),
    PlantProfile(
      nombre: 'Espatifilo (interior)',
      emoji: '🌱',
      tempMin: 18,
      tempMax: 26,
      phMin: 5.5,
      phMax: 6.5,
      ecMin: 0.8,
      ecMax: 1.5,
      nivelAguaMin: 20.0,
      nivelFertilizanteMin: 20.0,
      fuente: 'Dantas et al. (2024); Mercado-Sierra et al. (2022)',
    ),
  ];
}
