/// Declared identity and capabilities of a physical device, published by the
/// firmware to `devices/{esp32Id}/info/` on boot.
///
/// The app reads this to know which sensors/actuators a device *actually* has,
/// instead of assuming the full hydroponic set and painting misleading defaults
/// for hardware that isn't there. This is the "capability model" adopted in
/// ROADMAP_PRODUCTO.md (decisión P1, soil-first): it serves both a soil unit
/// (humedad_suelo + DHT22 + 1 pump) and a future hydroponic unit (pH/EC/levels
/// + dosing pumps) without the app committing to either at build time.
///
/// RTDB shape (sets are stored as `{key: true}` maps — RTDB discourages arrays):
///   info/
///     modelo_hardware   "esp32-soil-v1"
///     version_firmware  "0.1.0-demo"
///     tipo_cultivo      "suelo" | "hidroponico"
///     sensores          { "temperatura": true, "humedad_suelo": true, ... }
///     actuadores        { "bomba_agua": true, ... }
class DeviceInfo {
  final String? modeloHardware;
  final String? versionFirmware;

  /// How the device is used. Drives which plant catalog and UI apply.
  final String tipoCultivo; // 'suelo' | 'hidroponico'

  /// Sensor keys the device reports (matching `SensorData` map keys, e.g.
  /// `humedad_suelo`, `temperatura`, `humedad_aire`, `ph`, `conductividad`).
  final Set<String> sensores;

  /// Actuator keys the device controls (e.g. `bomba_agua`).
  final Set<String> actuadores;

  const DeviceInfo({
    this.modeloHardware,
    this.versionFirmware,
    this.tipoCultivo = 'suelo',
    this.sensores = const {},
    this.actuadores = const {},
  });

  bool hasSensor(String key) => sensores.contains(key);
  bool hasActuator(String key) => actuadores.contains(key);

  /// True when the device declared no capabilities at all — either it predates
  /// the capability model or hasn't booted yet. Callers should fall back to
  /// showing everything rather than hiding real data.
  bool get isEmpty => sensores.isEmpty && actuadores.isEmpty;

  factory DeviceInfo.fromMap(Map<dynamic, dynamic> map) {
    return DeviceInfo(
      modeloHardware: map['modelo_hardware'] as String?,
      versionFirmware: map['version_firmware'] as String?,
      tipoCultivo: map['tipo_cultivo'] as String? ?? 'suelo',
      sensores: _truthyKeys(map['sensores']),
      actuadores: _truthyKeys(map['actuadores']),
    );
  }

  Map<String, dynamic> toMap() => {
        'modelo_hardware': modeloHardware,
        'version_firmware': versionFirmware,
        'tipo_cultivo': tipoCultivo,
        'sensores': {for (final k in sensores) k: true},
        'actuadores': {for (final k in actuadores) k: true},
      };

  /// Extracts the keys of a `{key: true}` map, ignoring falsey entries.
  static Set<String> _truthyKeys(dynamic node) {
    if (node is! Map) return const {};
    return node.entries
        .where((e) => e.value == true)
        .map((e) => e.key.toString())
        .toSet();
  }
}
