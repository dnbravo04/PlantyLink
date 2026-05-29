/// Growth stage of a hydroponic plant, used to adjust nutrient dosing.
enum GrowthStage {
  germination,
  seedling,
  vegetative,
  flowering,
  harvest;

  String get label => switch (this) {
        GrowthStage.germination => 'Germinación',
        GrowthStage.seedling => 'Plántula',
        GrowthStage.vegetative => 'Vegetativo',
        GrowthStage.flowering => 'Floración',
        GrowthStage.harvest => 'Cosecha',
      };

  String get description => switch (this) {
        GrowthStage.germination => 'Semilla en proceso de germinación (0–7 días)',
        GrowthStage.seedling => 'Plántula en desarrollo inicial (8–21 días)',
        GrowthStage.vegetative => 'Crecimiento vegetativo activo (22–45 días)',
        GrowthStage.flowering => 'Floración y desarrollo de frutos (46–70 días)',
        GrowthStage.harvest => 'Lista para cosechar (71+ días)',
      };

  /// Estimate stage from days since transplant.
  static GrowthStage fromDaysSincePlanting(int days) {
    if (days <= 7) return GrowthStage.germination;
    if (days <= 21) return GrowthStage.seedling;
    if (days <= 45) return GrowthStage.vegetative;
    if (days <= 70) return GrowthStage.flowering;
    return GrowthStage.harvest;
  }
}
