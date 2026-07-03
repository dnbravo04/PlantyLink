import 'package:flutter_test/flutter_test.dart';
import 'package:hydrotracker/models/linked_device.dart';

void main() {
  group('LinkedDevice.fromMap', () {
    test('parses all fields from a complete map', () {
      final device = LinkedDevice.fromMap('ESP32-ABC123', {
        'nombre': 'Invernadero',
        'vinculado_en': 1751500000000,
      });

      expect(device.id, 'ESP32-ABC123');
      expect(device.nombre, 'Invernadero');
      expect(device.vinculadoEn,
          DateTime.fromMillisecondsSinceEpoch(1751500000000));
    });

    test('falls back to the id when nombre is missing', () {
      final device = LinkedDevice.fromMap('ESP32-ABC123', {});

      expect(device.nombre, 'ESP32-ABC123');
      expect(device.vinculadoEn, isNull);
    });

    test('ignores a non-numeric vinculado_en', () {
      final device = LinkedDevice.fromMap('ESP32-ABC123', {
        'nombre': 'Huerto',
        'vinculado_en': 'no-un-timestamp',
      });

      expect(device.vinculadoEn, isNull);
    });
  });
}
