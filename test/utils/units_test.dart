import 'package:flutter_test/flutter_test.dart';
import 'package:hydrotracker/core/utils/units.dart';

void main() {
  group('UnitsPrefs', () {
    test('defaults are metric (°C, mS/cm)', () {
      const units = UnitsPrefs();
      expect(units.tempValue(25), 25);
      expect(units.tempUnit, '°C');
      expect(units.ecValue(1.8), 1.8);
      expect(units.ecUnit, 'mS/cm');
      expect(units.formatEc(1.8), '1.80');
    });

    test('converts °C to °F', () {
      const units = UnitsPrefs(fahrenheit: true);
      expect(units.tempValue(0), 32);
      expect(units.tempValue(25), 77);
      expect(units.tempUnit, '°F');
      expect(units.formatTemp(25), '77.0');
    });

    test('converts mS/cm to µS/cm without decimals', () {
      const units = UnitsPrefs(microSiemens: true);
      expect(units.ecValue(1.8), 1800);
      expect(units.ecUnit, 'µS/cm');
      expect(units.formatEc(1.85), '1850');
    });
  });
}
