import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/linked_device.dart';
import '../firebase_constants.dart';
import '../retry_policy.dart';

/// Manages ESP32 device pairing and NFC registration in Firebase RTDB.
///
/// Single responsibility: hardware-device lifecycle operations only.
///
/// Multi-device layout under `usuarios/{uid}`:
///   esp32_id                       → active device (services resolve this)
///   esp32_vinculado                → whether any device is linked
///   dispositivos/{esp32Id}         → registry: {nombre, vinculado_en}
class DeviceService {
  late final FirebaseDatabase _db;

  DeviceService() {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Link [esp32Id] to the currently signed-in user: registers it in the
  /// device list and makes it the active device. Re-pairing an already
  /// registered device keeps its custom name.
  Future<void> vincularESP32(String esp32Id) async {
    final uid = _uid;
    if (uid == null) return;
    final existingName = (await _db
            .ref('usuarios/$uid/dispositivos/$esp32Id/nombre')
            .get())
        .value as String?;
    await RetryPolicy.execute(
      () => _db.ref('usuarios/$uid').update({
        'esp32_vinculado': true,
        'esp32_id': esp32Id,
        'dispositivos/$esp32Id': {
          'nombre': existingName ?? esp32Id,
          'vinculado_en': ServerValue.timestamp,
        },
      }),
    );
  }

  /// Make an already-linked device the active one. All device-scoped
  /// providers rebuild reactively via `deviceContextProvider`.
  Future<void> cambiarDispositivoActivo(String esp32Id) {
    final uid = _uid;
    if (uid == null) return Future.value();
    return RetryPolicy.execute(
      () => _db.ref('usuarios/$uid/esp32_id').set(esp32Id),
    );
  }

  /// Rename a device in the user's registry.
  Future<void> renombrarDispositivo(String esp32Id, String nombre) {
    final uid = _uid;
    if (uid == null) return Future.value();
    return RetryPolicy.execute(
      () => _db.ref('usuarios/$uid/dispositivos/$esp32Id/nombre').set(nombre),
    );
  }

  /// Remove a device from the registry. If it was the active device, the
  /// first remaining device becomes active (or none, clearing the context).
  Future<void> desvincularESP32(String esp32Id) async {
    final uid = _uid;
    if (uid == null) return;
    final userRef = _db.ref('usuarios/$uid');
    await RetryPolicy.execute(
      () => userRef.child('dispositivos/$esp32Id').remove(),
    );

    final active = (await userRef.child('esp32_id').get()).value as String?;
    if (active != esp32Id) return;

    final remaining =
        (await userRef.child('dispositivos').get()).value as Map?;
    final next = (remaining == null || remaining.isEmpty)
        ? null
        : remaining.keys.first as String;
    await RetryPolicy.execute(
      () => userRef.update({
        'esp32_id': next,
        'esp32_vinculado': next != null,
      }),
    );
  }

  /// Stream of the user's registered devices, sorted by name.
  ///
  /// Accounts linked before the registry existed only have `esp32_id`; that
  /// device is synthesized into the list so nothing appears unlinked.
  Stream<List<LinkedDevice>> get linkedDevicesStream {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return _db.ref('usuarios/$uid').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final raw = data['dispositivos'] as Map<dynamic, dynamic>? ?? {};
      final devices = raw.entries
          .map((e) => LinkedDevice.fromMap(
              e.key as String, e.value as Map<dynamic, dynamic>? ?? {}))
          .toList()
        ..sort((a, b) =>
            a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

      final active = data['esp32_id'] as String?;
      if (active != null &&
          active.isNotEmpty &&
          !devices.any((d) => d.id == active)) {
        devices.insert(0, LinkedDevice(id: active, nombre: active));
      }
      return devices;
    });
  }

  /// Log an NFC scan event to `devices/{esp32Id}/nfc_logs/`.
  Future<void> registrarNFC(String esp32Id, String usuario, int nivel) {
    return RetryPolicy.execute(
      () => _db.ref('devices/$esp32Id/nfc_logs').push().set({
        'usuario': usuario,
        'nivel': nivel,
        'timestamp': ServerValue.timestamp,
      }),
    );
  }
}
