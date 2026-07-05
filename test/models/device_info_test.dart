import 'package:flutter_test/flutter_test.dart';
import 'package:hydrotracker/models/device_info.dart';

void main() {
  group('DeviceInfo.fromMap', () {
    test('parses identity and truthy capability keys', () {
      final info = DeviceInfo.fromMap({
        'modelo_hardware': 'esp32-soil-v1',
        'version_firmware': '0.1.0-demo',
        'tipo_cultivo': 'suelo',
        'sensores': {
          'temperatura': true,
          'humedad_suelo': true,
          'humedad_aire': true,
          'ph': false, // explicitly absent hardware
        },
        'actuadores': {'bomba_agua': true},
      });

      expect(info.modeloHardware, 'esp32-soil-v1');
      expect(info.tipoCultivo, 'suelo');
      expect(info.hasSensor('humedad_suelo'), isTrue);
      expect(info.hasSensor('temperatura'), isTrue);
      expect(info.hasSensor('ph'), isFalse); // value was false → excluded
      expect(info.hasActuator('bomba_agua'), isTrue);
      expect(info.isEmpty, isFalse);
    });

    test('empty/absent capabilities → isEmpty (caller should show everything)',
        () {
      expect(DeviceInfo.fromMap({}).isEmpty, isTrue);
      expect(DeviceInfo.fromMap({}).tipoCultivo, 'suelo');
    });

    test('round-trips capabilities through toMap', () {
      const original = DeviceInfo(
        modeloHardware: 'esp32-soil-v1',
        versionFirmware: '0.1.0-demo',
        tipoCultivo: 'suelo',
        sensores: {'temperatura', 'humedad_suelo'},
        actuadores: {'bomba_agua'},
      );

      final restored = DeviceInfo.fromMap(original.toMap());

      expect(restored.sensores, original.sensores);
      expect(restored.actuadores, original.actuadores);
      expect(restored.tipoCultivo, 'suelo');
    });
  });
}
