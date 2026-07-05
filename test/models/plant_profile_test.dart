import 'package:flutter_test/flutter_test.dart';
import 'package:hydrotracker/models/plant_profile.dart';

void main() {
  group('PlantProfile.fromMap', () {
    test('parses all fields from a complete map', () {
      final map = {
        'planta': 'Tomate Cherry',
        'emoji': '🍅',
        'temp_min': 18.0,
        'temp_max': 28.0,
        'ph_min': 5.5,
        'ph_max': 6.5,
        'ec_min': 2.0,
        'ec_max': 3.5,
        'nivel_agua_min': 25.0,
        'nivel_fertilizante_min': 30.0,
        'fuente': 'Test source',
      };

      final profile = PlantProfile.fromMap(map);

      expect(profile.nombre, 'Tomate Cherry');
      expect(profile.emoji, '🍅');
      expect(profile.tempMin, 18.0);
      expect(profile.tempMax, 28.0);
      expect(profile.phMin, 5.5);
      expect(profile.phMax, 6.5);
      expect(profile.ecMin, 2.0);
      expect(profile.ecMax, 3.5);
      expect(profile.nivelAguaMin, 25.0);
      expect(profile.nivelFertilizanteMin, 30.0);
      expect(profile.fuente, 'Test source');
    });

    test('uses defaults for missing fields', () {
      final profile = PlantProfile.fromMap({});

      expect(profile.nombre, '');
      expect(profile.emoji, '🌱');
      expect(profile.tempMin, 0.0);
      expect(profile.nivelAguaMin, 20.0);
      expect(profile.nivelFertilizanteMin, 20.0);
      expect(profile.fuente, '');
    });

    test('handles int values cast to double', () {
      final profile = PlantProfile.fromMap({
        'temp_min': 18,
        'temp_max': 28,
      });

      expect(profile.tempMin, 18.0);
      expect(profile.tempMax, 28.0);
    });
  });

  group('PlantProfile.toMap', () {
    test('round-trips through fromMap/toMap', () {
      const original = PlantProfile(
        nombre: 'Lechuga',
        emoji: '🥬',
        tempMin: 15,
        tempMax: 22,
        phMin: 5.5,
        phMax: 6.5,
        ecMin: 1.0,
        ecMax: 1.8,
        nivelAguaMin: 20.0,
        nivelFertilizanteMin: 20.0,
        fuente: 'Rofiansyah et al.',
      );

      final map = original.toMap();
      final restored = PlantProfile.fromMap(map);

      expect(restored.nombre, original.nombre);
      expect(restored.emoji, original.emoji);
      expect(restored.tempMin, original.tempMin);
      expect(restored.tempMax, original.tempMax);
      expect(restored.phMin, original.phMin);
      expect(restored.phMax, original.phMax);
      expect(restored.ecMin, original.ecMin);
      expect(restored.ecMax, original.ecMax);
      expect(restored.fuente, original.fuente);
    });

    test('serializes nombre under "planta" key', () {
      const profile = PlantProfile(
        nombre: 'Test',
        emoji: '🌱',
        tempMin: 0, tempMax: 0,
        phMin: 0, phMax: 0,
        ecMin: 0, ecMax: 0,
        nivelAguaMin: 0, nivelFertilizanteMin: 0,
        fuente: '',
      );

      expect(profile.toMap()['planta'], 'Test');
      expect(profile.toMap().containsKey('nombre'), false);
    });
  });

  group('PlantProfile soil fields (soil-first)', () {
    test('defaults tipoCultivo to hidroponico and soil thresholds to null', () {
      final p = PlantProfile.fromMap({});
      expect(p.tipoCultivo, 'hidroponico');
      expect(p.humedadSueloMin, isNull);
      expect(p.humedadSueloMax, isNull);
    });

    test('parses soil thresholds and tipo_cultivo', () {
      final p = PlantProfile.fromMap({
        'tipo_cultivo': 'suelo',
        'humedad_suelo_min': 40.0,
        'humedad_suelo_max': 70.0,
      });
      expect(p.tipoCultivo, 'suelo');
      expect(p.humedadSueloMin, 40.0);
      expect(p.humedadSueloMax, 70.0);
    });

    test('round-trips soil fields through toMap', () {
      const original = PlantProfile(
        nombre: 'Albahaca', emoji: '🌿',
        tempMin: 18, tempMax: 30, phMin: 6, phMax: 7.5,
        ecMin: 0, ecMax: 0, nivelAguaMin: 0, nivelFertilizanteMin: 0,
        humedadSueloMin: 40, humedadSueloMax: 70,
        tipoCultivo: 'suelo', fuente: 'test',
      );
      final restored = PlantProfile.fromMap(original.toMap());
      expect(restored.humedadSueloMin, 40);
      expect(restored.humedadSueloMax, 70);
      expect(restored.tipoCultivo, 'suelo');
    });
  });

  group('PlantCatalog.plantasSuelo', () {
    test('soil plants are tipoCultivo suelo with valid moisture ranges', () {
      expect(PlantCatalog.plantasSuelo, isNotEmpty);
      for (final p in PlantCatalog.plantasSuelo) {
        expect(p.tipoCultivo, 'suelo', reason: p.nombre);
        expect(p.humedadSueloMin, isNotNull, reason: p.nombre);
        expect(p.humedadSueloMax, isNotNull, reason: p.nombre);
        expect(p.humedadSueloMin!, lessThan(p.humedadSueloMax!),
            reason: '${p.nombre}: humedadSueloMin should be < max');
        expect(p.tempMin, lessThan(p.tempMax), reason: p.nombre);
      }
    });

    test('todas combines hydroponic and soil catalogs', () {
      expect(PlantCatalog.todas.length,
          PlantCatalog.plantas.length + PlantCatalog.plantasSuelo.length);
    });
  });

  group('PlantCatalog', () {
    test('contains at least 5 built-in plants', () {
      expect(PlantCatalog.plantas.length, greaterThanOrEqualTo(5));
    });

    test('all plants have valid threshold ranges', () {
      for (final plant in PlantCatalog.plantas) {
        expect(plant.tempMin, lessThan(plant.tempMax),
            reason: '${plant.nombre}: tempMin should be < tempMax');
        expect(plant.phMin, lessThan(plant.phMax),
            reason: '${plant.nombre}: phMin should be < phMax');
        expect(plant.ecMin, lessThan(plant.ecMax),
            reason: '${plant.nombre}: ecMin should be < ecMax');
      }
    });

    test('all plants have non-empty names and emojis', () {
      for (final plant in PlantCatalog.plantas) {
        expect(plant.nombre, isNotEmpty, reason: 'Plant should have a name');
        expect(plant.emoji, isNotEmpty, reason: '${plant.nombre} should have an emoji');
      }
    });
  });
}
