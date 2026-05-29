import 'dart:math' as math;
import '../../data/api/perenual_models.dart';
import '../../models/agronomic/enriched_plant_profile.dart';
import '../../models/agronomic/growth_stage.dart';
import '../../models/agronomic/nutrient_recommendation.dart';
import '../../models/agronomic/ph_correction.dart';
import '../../models/agronomic/sensor_health.dart';
import '../../models/plant_profile.dart';
import '../../models/trend_alert.dart';

/// Pure business-logic service for agronomic calculations.
///
/// No Firebase, no Riverpod — all methods are deterministic given their inputs.
/// This makes the service trivially testable and re-usable across providers.
class AgronomicService {
  // ── Plant enrichment ────────────────────────────────────────────────────────

  /// Merge a [PlantProfile] with optional Perenual [detail] into an
  /// [EnrichedPlantProfile].  When [detail] is null the result still carries
  /// the full [base] profile so callers can always work with one type.
  EnrichedPlantProfile enrichPlant(
    PlantProfile base,
    PerenualSpeciesDetail? detail,
  ) {
    if (detail == null) {
      return EnrichedPlantProfile(base: base);
    }

    final imageUrl = detail.defaultImage?.mediumUrl.isNotEmpty == true
        ? detail.defaultImage!.mediumUrl
        : detail.defaultImage?.regularUrl;

    final scientificName = detail.scientificName.isNotEmpty
        ? detail.scientificName.first
        : null;

    return EnrichedPlantProfile(
      base: base,
      perenualId: detail.id,
      description: detail.description.isNotEmpty ? detail.description : null,
      scientificName: scientificName,
      imageUrl: imageUrl,
      cycle: detail.cycle.isNotEmpty ? detail.cycle : null,
      growthRate: detail.growthRate.isNotEmpty ? detail.growthRate : null,
      careLevel: detail.careLevel.isNotEmpty ? detail.careLevel : null,
      careTips: _buildCareTips(detail),
    );
  }

  List<String> _buildCareTips(PerenualSpeciesDetail detail) {
    final tips = <String>[];
    if (detail.watering.isNotEmpty) {
      tips.add('Riego: ${detail.watering}');
    }
    if (detail.sunlight.isNotEmpty) {
      tips.add('Luz: ${detail.sunlight.join(', ')}');
    }
    if (detail.pruningMonth.isNotEmpty) {
      tips.add('Poda: ${detail.pruningMonth.join(', ')}');
    }
    if (detail.droughtTolerant) {
      tips.add('Tolerante a sequía');
    }
    if (detail.indoor) {
      tips.add('Apta para cultivo interior');
    }
    if (detail.edibleFruit) {
      tips.add('Fruto comestible');
    }
    return tips;
  }

  // ── Growth stage ────────────────────────────────────────────────────────────

  /// Estimate [GrowthStage] from the number of days since transplant.
  GrowthStage calculateGrowthStage(int daysSincePlanting) =>
      GrowthStage.fromDaysSincePlanting(daysSincePlanting);

  // ── Nutrient dosing ─────────────────────────────────────────────────────────

  /// Return a [NutrientRecommendation] for [profile] at the given [stage].
  ///
  /// EC target ranges are derived from the profile's thresholds and scaled
  /// by stage-specific multipliers:
  /// - Germination / seedling: 50 % of full EC to avoid root burn.
  /// - Vegetative: 100 % (nominal).
  /// - Flowering: 110 % to support fruit set.
  /// - Harvest: 70 % flush phase.
  NutrientRecommendation recommendDosing(
    PlantProfile profile,
    GrowthStage stage,
  ) {
    final (ecScale, npk, dose, notes) = switch (stage) {
      GrowthStage.germination => (
          0.5,
          '1-1-1',
          0.5,
          'Solución muy diluida para proteger raíces emergentes.',
        ),
      GrowthStage.seedling => (
          0.5,
          '2-1-1',
          1.0,
          'Énfasis en nitrógeno para crecimiento foliar inicial.',
        ),
      GrowthStage.vegetative => (
          1.0,
          '3-1-2',
          2.0,
          'Nutrición completa. Mantener EC dentro del rango óptimo.',
        ),
      GrowthStage.flowering => (
          1.1,
          '1-3-2',
          2.5,
          'Mayor fósforo y potasio para soporte de flores y frutos.',
        ),
      GrowthStage.harvest => (
          0.7,
          '1-1-3',
          1.5,
          'Fase de lavado. Reducir EC para mejorar sabor y calidad.',
        ),
    };

    return NutrientRecommendation(
      stage: stage,
      ecTargetMin: profile.ecMin * ecScale,
      ecTargetMax: profile.ecMax * ecScale,
      phTargetMin: profile.phMin,
      phTargetMax: profile.phMax,
      npkRatio: npk,
      doseMlPerLiter: dose,
      notes: notes,
    );
  }

  // ── pH correction ───────────────────────────────────────────────────────────

  /// Calculate how much pH adjuster to add for [volumeLiters] of solution.
  ///
  /// Uses a conservative empirical constant:
  ///   ~1 mL of adjuster per 10 L shifts pH by ~0.1 unit.
  /// This is a starting estimate — always add slowly and re-measure.
  PhCorrection calculatePHCorrection({
    required double currentPH,
    required double targetPH,
    required double volumeLiters,
  }) {
    final delta = targetPH - currentPH;
    final type = delta < 0 ? 'acid' : 'base';
    // 1 mL / 10 L per 0.1 pH unit → mL = |delta| * 10 * volumeLiters / 10
    final estimatedML = delta.abs() * volumeLiters;

    final product = type == 'acid' ? 'pH Down (ácido fosfórico / cítrico)' : 'pH Up (hidróxido de potasio)';
    final notes =
        'Añadir $product de a poco. Agregar ${estimatedML.toStringAsFixed(1)} mL '
        'para ${volumeLiters.toStringAsFixed(0)} L. Esperar 5 min y remedir.';

    return PhCorrection(
      currentPH: currentPH,
      targetPH: targetPH,
      volumeLiters: volumeLiters,
      correctionType: type,
      estimatedMLNeeded: estimatedML,
      notes: notes,
    );
  }

  // ── Sensor drift detection ──────────────────────────────────────────────────

  /// Detect erratic / drifting behaviour in a sensor's recent readings.
  ///
  /// Computes the coefficient of variation (CV = σ / |μ|) of [readings].
  /// - CV < 5 %  → [SensorHealthStatus.ok]
  /// - CV < 15 % → [SensorHealthStatus.warning]
  /// - CV ≥ 15 % → [SensorHealthStatus.critical]
  SensorHealth detectDrift(
    String sensorKey,
    List<SensorReading> readings,
  ) {
    if (readings.length < 3) {
      return SensorHealth(
        sensorKey: sensorKey,
        driftMagnitude: 0,
        status: SensorHealthStatus.ok,
        recommendation: 'Datos insuficientes para análisis de deriva.',
      );
    }

    final values = readings.map((r) => r.value).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;

    if (mean.abs() < 1e-9) {
      return SensorHealth(
        sensorKey: sensorKey,
        driftMagnitude: 0,
        status: SensorHealthStatus.ok,
        recommendation: 'Sensor en cero — verificar conexión.',
      );
    }

    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            values.length;
    final stdDev = math.sqrt(variance);
    final cv = stdDev / mean.abs();

    final status = cv < 0.05
        ? SensorHealthStatus.ok
        : cv < 0.15
            ? SensorHealthStatus.warning
            : SensorHealthStatus.critical;

    final recommendation = switch (status) {
      SensorHealthStatus.ok => 'Sensor operando con normalidad.',
      SensorHealthStatus.warning =>
        'Lecturas inestables. Calibrar próximamente.',
      SensorHealthStatus.critical =>
        'Alta variabilidad detectada. Calibrar o reemplazar sensor.',
    };

    return SensorHealth(
      sensorKey: sensorKey,
      driftMagnitude: cv,
      status: status,
      recommendation: recommendation,
    );
  }
}
