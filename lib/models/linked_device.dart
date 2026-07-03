/// A device registered under `usuarios/{uid}/dispositivos/{esp32Id}`.
///
/// The *active* device is not stored here — `usuarios/{uid}/esp32_id` remains
/// the single pointer every device-scoped service resolves through
/// `deviceContextProvider`. Switching devices just rewrites that pointer.
class LinkedDevice {
  final String id;
  final String nombre;
  final DateTime? vinculadoEn;

  const LinkedDevice({
    required this.id,
    required this.nombre,
    this.vinculadoEn,
  });

  factory LinkedDevice.fromMap(String id, Map<dynamic, dynamic> map) {
    final ts = map['vinculado_en'];
    return LinkedDevice(
      id: id,
      nombre: map['nombre'] as String? ?? id,
      vinculadoEn: ts is num
          ? DateTime.fromMillisecondsSinceEpoch(ts.toInt())
          : null,
    );
  }
}
