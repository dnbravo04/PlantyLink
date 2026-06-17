import 'package:flutter_test/flutter_test.dart';
import 'package:hydrotracker/models/trend_alert.dart';

void main() {
  final baseTime = DateTime(2024, 1, 1, 12, 0);

  List<SensorReading> makeReadings(List<double> values, {Duration interval = const Duration(seconds: 30)}) {
    return List.generate(values.length, (i) => SensorReading(
      value: values[i],
      timestamp: baseTime.add(interval * i),
    ));
  }

  group('TrendCalculator._calculateSlope (via checkTrendAlert)', () {
    test('returns null when fewer than 5 readings', () {
      final readings = makeReadings([20.0, 21.0, 22.0, 23.0]);
      final alert = TrendCalculator.checkTrendAlert(readings, 'temperatura', 15.0, 30.0);
      expect(alert, isNull);
    });

    test('returns null when values are stable within thresholds', () {
      final readings = makeReadings([22.0, 22.1, 22.0, 22.1, 22.0]);
      final alert = TrendCalculator.checkTrendAlert(readings, 'temperatura', 15.0, 30.0);
      expect(alert, isNull);
    });

    test('detects rising trend toward max threshold', () {
      // Rapidly rising: 25, 26, 27, 28, 29 — predicted to exceed max=30
      final readings = makeReadings([25.0, 26.0, 27.0, 28.0, 29.0]);
      final alert = TrendCalculator.checkTrendAlert(readings, 'temperatura', 15.0, 30.0);
      expect(alert, isNotNull);
      expect(alert!.thresholdType, 'max');
      expect(alert.sensorKey, 'temperatura');
      expect(alert.predictedValue, greaterThan(30.0));
    });

    test('detects falling trend toward min threshold', () {
      // Rapidly falling: 20, 18, 16, 14, 12 — predicted to go below min=10
      final readings = makeReadings([20.0, 18.0, 16.0, 14.0, 12.0]);
      final alert = TrendCalculator.checkTrendAlert(readings, 'ph', 10.0, null);
      expect(alert, isNotNull);
      expect(alert!.thresholdType, 'min');
      expect(alert.sensorKey, 'ph');
      expect(alert.predictedValue, lessThan(10.0));
    });

    test('returns null when both min and max are null', () {
      final readings = makeReadings([100.0, 200.0, 300.0, 400.0, 500.0]);
      final alert = TrendCalculator.checkTrendAlert(readings, 'test', null, null);
      expect(alert, isNull);
    });
  });

  group('TrendCalculator message', () {
    test('includes sensor name and direction for rising alert', () {
      final readings = makeReadings([25.0, 26.0, 27.0, 28.0, 29.0]);
      final alert = TrendCalculator.checkTrendAlert(readings, 'temperatura', 15.0, 30.0);
      expect(alert!.message, contains('Temperatura'));
      expect(alert.message, contains('subiendo'));
    });

    test('includes sensor name and direction for falling alert', () {
      final readings = makeReadings([6.0, 5.5, 5.0, 4.5, 4.0]);
      final alert = TrendCalculator.checkTrendAlert(readings, 'ph', 3.0, 8.0);
      expect(alert!.message, contains('pH'));
      expect(alert.message, contains('bajando'));
    });
  });

  group('TrendAlert serialization', () {
    test('round-trips through toMap/fromMap', () {
      final alert = TrendAlert(
        sensorKey: 'ph',
        message: 'pH bajando rápido...',
        currentValue: 5.5,
        predictedValue: 4.8,
        slope: -0.001,
        timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        thresholdType: 'min',
      );

      final map = alert.toMap();
      final restored = TrendAlert.fromMap(map);

      expect(restored.sensorKey, 'ph');
      expect(restored.message, alert.message);
      expect(restored.currentValue, 5.5);
      expect(restored.predictedValue, 4.8);
      expect(restored.thresholdType, 'min');
      expect(restored.timestamp, alert.timestamp);
    });

    test('toMap includes event field', () {
      final alert = TrendAlert(
        sensorKey: 'temperatura',
        message: 'test',
        currentValue: 0,
        predictedValue: 0,
        slope: 0,
        timestamp: DateTime.now(),
        thresholdType: 'max',
      );

      expect(alert.toMap()['event'], 'alerta_tendencia');
    });
  });
}
