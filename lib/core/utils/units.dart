/// Display-unit preferences. Sensor data is always stored in °C and mS/cm;
/// conversion happens only at presentation time.
class UnitsPrefs {
  final bool fahrenheit;
  final bool microSiemens;

  const UnitsPrefs({this.fahrenheit = false, this.microSiemens = false});

  // ── Temperature ────────────────────────────────────────────────────────
  double tempValue(double celsius) =>
      fahrenheit ? celsius * 9 / 5 + 32 : celsius;
  String get tempUnit => fahrenheit ? '°F' : '°C';
  String formatTemp(double celsius) => tempValue(celsius).toStringAsFixed(1);

  // ── Electrical conductivity ────────────────────────────────────────────
  double ecValue(double mSCm) => microSiemens ? mSCm * 1000 : mSCm;
  String get ecUnit => microSiemens ? 'µS/cm' : 'mS/cm';
  String formatEc(double mSCm) =>
      ecValue(mSCm).toStringAsFixed(microSiemens ? 0 : 2);
}
