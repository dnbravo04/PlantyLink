import 'package:flutter_test/flutter_test.dart';
import 'package:hydrotracker/domain/services/agronomic_service.dart';
import 'package:hydrotracker/models/agronomic/growth_stage.dart';
import 'package:hydrotracker/models/agronomic/sensor_health.dart';
import 'package:hydrotracker/models/plant_profile.dart';
import 'package:hydrotracker/models/trend_alert.dart';

void main() {
  late AgronomicService service;

  setUp(() {
    service = AgronomicService();
  });

  const tomato = PlantProfile(
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
    fuente: 'test',
  );

  // ── Growth stage ──────────────────────────────────────────────────────────

  group('GrowthStage.fromDaysSincePlanting', () {
    test('0–7 days → germination', () {
      expect(GrowthStage.fromDaysSincePlanting(0), GrowthStage.germination);
      expect(GrowthStage.fromDaysSincePlanting(7), GrowthStage.germination);
    });

    test('8–21 days → seedling', () {
      expect(GrowthStage.fromDaysSincePlanting(8), GrowthStage.seedling);
      expect(GrowthStage.fromDaysSincePlanting(21), GrowthStage.seedling);
    });

    test('22–45 days → vegetative', () {
      expect(GrowthStage.fromDaysSincePlanting(22), GrowthStage.vegetative);
      expect(GrowthStage.fromDaysSincePlanting(45), GrowthStage.vegetative);
    });

    test('46–70 days → flowering', () {
      expect(GrowthStage.fromDaysSincePlanting(46), GrowthStage.flowering);
      expect(GrowthStage.fromDaysSincePlanting(70), GrowthStage.flowering);
    });

    test('71+ days → harvest', () {
      expect(GrowthStage.fromDaysSincePlanting(71), GrowthStage.harvest);
      expect(GrowthStage.fromDaysSincePlanting(200), GrowthStage.harvest);
    });
  });

  // ── Nutrient dosing ───────────────────────────────────────────────────────

  group('recommendDosing', () {
    test('germination scales EC to 50%', () {
      final rec = service.recommendDosing(tomato, GrowthStage.germination);
      expect(rec.ecTargetMin, closeTo(tomato.ecMin * 0.5, 0.01));
      expect(rec.ecTargetMax, closeTo(tomato.ecMax * 0.5, 0.01));
      expect(rec.stage, GrowthStage.germination);
    });

    test('vegetative uses 100% EC', () {
      final rec = service.recommendDosing(tomato, GrowthStage.vegetative);
      expect(rec.ecTargetMin, closeTo(tomato.ecMin, 0.01));
      expect(rec.ecTargetMax, closeTo(tomato.ecMax, 0.01));
    });

    test('flowering scales EC to 110%', () {
      final rec = service.recommendDosing(tomato, GrowthStage.flowering);
      expect(rec.ecTargetMin, closeTo(tomato.ecMin * 1.1, 0.01));
      expect(rec.ecTargetMax, closeTo(tomato.ecMax * 1.1, 0.01));
    });

    test('harvest scales EC to 70%', () {
      final rec = service.recommendDosing(tomato, GrowthStage.harvest);
      expect(rec.ecTargetMin, closeTo(tomato.ecMin * 0.7, 0.01));
      expect(rec.ecTargetMax, closeTo(tomato.ecMax * 0.7, 0.01));
    });

    test('pH range is always the profile range (unscaled)', () {
      for (final stage in GrowthStage.values) {
        final rec = service.recommendDosing(tomato, stage);
        expect(rec.phTargetMin, tomato.phMin);
        expect(rec.phTargetMax, tomato.phMax);
      }
    });

    test('all stages produce non-empty NPK ratio and notes', () {
      for (final stage in GrowthStage.values) {
        final rec = service.recommendDosing(tomato, stage);
        expect(rec.npkRatio, isNotEmpty);
        expect(rec.notes, isNotEmpty);
      }
    });
  });

  // ── pH correction ─────────────────────────────────────────────────────────

  group('calculatePHCorrection', () {
    test('acid correction when current pH > target', () {
      final result = service.calculatePHCorrection(
        currentPH: 7.0,
        targetPH: 6.0,
        volumeLiters: 10.0,
      );
      expect(result.correctionType, 'acid');
      expect(result.needsAcid, true);
      expect(result.estimatedMLNeeded, closeTo(10.0, 0.1));
      expect(result.delta, closeTo(1.0, 0.01));
    });

    test('base correction when current pH < target', () {
      final result = service.calculatePHCorrection(
        currentPH: 5.0,
        targetPH: 6.5,
        volumeLiters: 20.0,
      );
      expect(result.correctionType, 'base');
      expect(result.needsAcid, false);
      expect(result.estimatedMLNeeded, closeTo(30.0, 0.1));
    });

    test('zero correction when pH matches target', () {
      final result = service.calculatePHCorrection(
        currentPH: 6.0,
        targetPH: 6.0,
        volumeLiters: 50.0,
      );
      expect(result.estimatedMLNeeded, 0.0);
      expect(result.delta, 0.0);
    });

    test('notes contain product name', () {
      final acid = service.calculatePHCorrection(
        currentPH: 7.0, targetPH: 6.0, volumeLiters: 10.0,
      );
      expect(acid.notes, contains('pH Down'));

      final base = service.calculatePHCorrection(
        currentPH: 5.0, targetPH: 6.0, volumeLiters: 10.0,
      );
      expect(base.notes, contains('pH Up'));
    });
  });

  // ── Sensor drift detection ────────────────────────────────────────────────

  group('detectDrift', () {
    final now = DateTime.now();

    List<SensorReading> makeReadings(List<double> values) {
      return List.generate(values.length, (i) => SensorReading(
        value: values[i],
        timestamp: now.subtract(Duration(minutes: values.length - i)),
      ));
    }

    test('returns ok with insufficient data (< 3 readings)', () {
      final result = service.detectDrift('ph', makeReadings([6.0, 6.1]));
      expect(result.status, SensorHealthStatus.ok);
      expect(result.driftMagnitude, 0.0);
    });

    test('returns ok for stable readings (CV < 5%)', () {
      // Values close together: mean ~22, stddev ~0.3 → CV ~1.4%
      final result = service.detectDrift(
        'temperatura',
        makeReadings([22.0, 22.1, 21.9, 22.0, 22.2]),
      );
      expect(result.status, SensorHealthStatus.ok);
      expect(result.driftMagnitude, lessThan(0.05));
    });

    test('returns warning for moderately unstable readings (5% ≤ CV < 15%)', () {
      // Mean ~20, stddev ~2 → CV ~10%
      final result = service.detectDrift(
        'ph',
        makeReadings([18.0, 20.0, 22.0, 18.0, 22.0]),
      );
      expect(result.status, SensorHealthStatus.warning);
    });

    test('returns critical for highly erratic readings (CV ≥ 15%)', () {
      // Mean ~10, stddev ~5 → CV ~50%
      final result = service.detectDrift(
        'conductividad',
        makeReadings([5.0, 15.0, 5.0, 15.0, 5.0, 15.0]),
      );
      expect(result.status, SensorHealthStatus.critical);
    });

    test('handles near-zero mean gracefully', () {
      final result = service.detectDrift(
        'test',
        makeReadings([0.0, 0.0, 0.0]),
      );
      expect(result.status, SensorHealthStatus.ok);
      expect(result.recommendation, contains('cero'));
    });

    test('recommendation matches status', () {
      final ok = service.detectDrift('ph', makeReadings([6.0, 6.0, 6.01]));
      expect(ok.recommendation, contains('normalidad'));

      final warning = service.detectDrift('ph', makeReadings([6.0, 7.0, 5.5, 6.5, 7.0]));
      expect(warning.recommendation, contains('Calibrar'));
    });
  });
}
