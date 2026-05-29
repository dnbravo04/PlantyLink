import 'growth_stage.dart';

/// Nutrient dosing recommendation for a specific [GrowthStage].
///
/// EC and pH target ranges are derived from the active [PlantProfile] thresholds,
/// scaled by growth-stage multipliers in [AgronomicService.recommendDosing].
class NutrientRecommendation {
  final GrowthStage stage;
  final double ecTargetMin;
  final double ecTargetMax;
  final double phTargetMin;
  final double phTargetMax;

  /// N-P-K ratio string, e.g. "3-1-2" for vegetative growth.
  final String npkRatio;

  /// Recommended solution dose in mL per liter of reservoir water.
  final double doseMlPerLiter;

  /// Human-readable notes about this stage's nutritional needs.
  final String notes;

  const NutrientRecommendation({
    required this.stage,
    required this.ecTargetMin,
    required this.ecTargetMax,
    required this.phTargetMin,
    required this.phTargetMax,
    required this.npkRatio,
    required this.doseMlPerLiter,
    required this.notes,
  });
}
