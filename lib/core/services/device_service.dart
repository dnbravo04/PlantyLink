import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_constants.dart';
import '../retry_policy.dart';

/// Manages ESP32 device pairing and NFC registration in Firebase RTDB.
///
/// Single responsibility: hardware-device lifecycle operations only.
class DeviceService {
  late final FirebaseDatabase _db;

  DeviceService() {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
  }

  /// Link [esp32Id] to the currently signed-in user under `usuarios/{uid}`.
  Future<void> vincularESP32(String esp32Id) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Future.value();
    return RetryPolicy.execute(
      () => _db.ref('usuarios/$uid').update({
        'esp32_vinculado': true,
        'esp32_id': esp32Id,
      }),
    );
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
