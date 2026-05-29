import '../plant_profile.dart';
import 'growth_stage.dart';

/// A [PlantProfile] augmented with data fetched from the Perenual API.
///
/// Created by [AgronomicService.enrichPlant]. Carries nullable API fields
/// so enrichment degrades gracefully when no network data is available.
class EnrichedPlantProfile {
  final PlantProfile base;
  final int? perenualId;
  final String? description;
  final String? scientificName;
  final String? imageUrl;
  final String? cycle;
  final String? growthRate;
  final String? careLevel;
  final List<String> careTips;
  final GrowthStage currentStage;

  const EnrichedPlantProfile({
    required this.base,
    this.perenualId,
    this.description,
    this.scientificName,
    this.imageUrl,
    this.cycle,
    this.growthRate,
    this.careLevel,
    this.careTips = const [],
    this.currentStage = GrowthStage.vegetative,
  });

  EnrichedPlantProfile copyWith({
    PlantProfile? base,
    int? perenualId,
    String? description,
    String? scientificName,
    String? imageUrl,
    String? cycle,
    String? growthRate,
    String? careLevel,
    List<String>? careTips,
    GrowthStage? currentStage,
  }) {
    return EnrichedPlantProfile(
      base: base ?? this.base,
      perenualId: perenualId ?? this.perenualId,
      description: description ?? this.description,
      scientificName: scientificName ?? this.scientificName,
      imageUrl: imageUrl ?? this.imageUrl,
      cycle: cycle ?? this.cycle,
      growthRate: growthRate ?? this.growthRate,
      careLevel: careLevel ?? this.careLevel,
      careTips: careTips ?? this.careTips,
      currentStage: currentStage ?? this.currentStage,
    );
  }
}
