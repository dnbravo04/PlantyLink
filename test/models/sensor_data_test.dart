import 'package:flutter_test/flutter_test.dart';
import 'package:hydrotracker/models/sensor_data.dart';

void main() {
  group('SensorData.fromMap', () {
    test('parses all sensor fields from a complete map', () {
      final map = {
        'temperatura': 25.5,
        'ph': 6.2,
        'conductividad': 1.8,
        'nivel_agua_tanque': 75.0,
        'nivel_fertilizante_tanque': 50.0,
        'nivel_agua': true,
        'conectado': true,
        'bomba_agua': true,
        'bomba_fertilizante': false,
        'bomba_dosificadora_acido': false,
        'bomba_dosificadora_basico': false,
        'bomba_agua_auto': true,
        'bomba_fertilizante_auto': false,
        'dosificadora_acido_auto': false,
        'dosificadora_base_auto': false,
        'bomba_agua_manual_override': false,
        'bomba_fertilizante_manual_override': false,
        'dosificadora_acido_manual_override': false,
        'dosificadora_base_manual_override': false,
        'timestamp': 1700000000000,
      };

      final sensor = SensorData.fromMap(map);

      expect(sensor.temperatura, 25.5);
      expect(sensor.ph, 6.2);
      expect(sensor.conductividad, 1.8);
      expect(sensor.nivelAguaTanque, 75.0);
      expect(sensor.nivelFertilizanteTanque, 50.0);
      expect(sensor.nivelAgua, true);
      expect(sensor.conectado, true);
      expect(sensor.bombaAgua, true);
      expect(sensor.bombaFertilizante, false);
      expect(sensor.bombaAguaAuto, true);
      expect(sensor.bombaAguaManualOverride, false);
      expect(sensor.timestamp, DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });

    test('uses defaults for missing fields', () {
      final sensor = SensorData.fromMap({});

      expect(sensor.temperatura, 0.0);
      expect(sensor.ph, 7.0);
      expect(sensor.conductividad, 0.0);
      expect(sensor.conectado, false);
      expect(sensor.bombaAgua, false);
      // timestamp should default to approximately now
      expect(
        sensor.timestamp.difference(DateTime.now()).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('handles int values cast to double', () {
      final sensor = SensorData.fromMap({
        'temperatura': 25, // int, not double
        'ph': 7,
        'timestamp': 1700000000000,
      });

      expect(sensor.temperatura, 25.0);
      expect(sensor.ph, 7.0);
    });
  });

  group('SensorData.toMap', () {
    test('round-trips through fromMap/toMap', () {
      final original = SensorData(
        temperatura: 22.5,
        ph: 6.0,
        conductividad: 1500.0,
        nivelAguaTanque: 80.0,
        nivelFertilizanteTanque: 60.0,
        nivelAgua: true,
        conectado: true,
        bombaAgua: false,
        bombaFertilizante: true,
        bombaDosificadoraAcido: false,
        bombaDosificadoraBasico: false,
        bombaAguaAuto: true,
        bombaFertilizanteAuto: false,
        dosificadoraAcidoAuto: false,
        dosificadoraBaseAuto: false,
        bombaAguaManualOverride: false,
        bombaFertilizanteManualOverride: false,
        dosificadoraAcidoManualOverride: false,
        dosificadoraBaseManualOverride: false,
        timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      final map = original.toMap();
      final restored = SensorData.fromMap(map);

      expect(restored.temperatura, original.temperatura);
      expect(restored.ph, original.ph);
      expect(restored.conductividad, original.conductividad);
      expect(restored.bombaAgua, original.bombaAgua);
      expect(restored.bombaFertilizante, original.bombaFertilizante);
      expect(restored.timestamp, original.timestamp);
    });
  });

  group('ecNormalized', () {
    test('returns raw value when <= 10 (already mS/cm)', () {
      final sensor = SensorData(conductividad: 2.5, timestamp: DateTime.now());
      expect(sensor.ecNormalized, 2.5);
    });

    test('converts µS/cm to mS/cm when > 10', () {
      final sensor = SensorData(conductividad: 1500.0, timestamp: DateTime.now());
      expect(sensor.ecNormalized, 1.5);
    });

    test('returns 0 when conductividad is null', () {
      final sensor = SensorData(timestamp: DateTime.now());
      expect(sensor.ecNormalized, 0.0);
    });

    test('treats exactly 10 as mS/cm (no conversion)', () {
      final sensor = SensorData(conductividad: 10.0, timestamp: DateTime.now());
      expect(sensor.ecNormalized, 10.0);
    });

    test('converts value just above 10', () {
      final sensor = SensorData(conductividad: 10.1, timestamp: DateTime.now());
      expect(sensor.ecNormalized, closeTo(0.0101, 0.0001));
    });
  });
}
