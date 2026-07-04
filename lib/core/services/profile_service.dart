import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/plant_profile.dart';
import '../firebase_constants.dart';
import '../retry_policy.dart';

/// Manages the active plant profile in Firebase RTDB.
///
/// Single responsibility: reads and writes to `devices/{esp32Id}/profile/`.
/// User-account data lives in [UserService] — it must work without a device.
class ProfileService {
  late final FirebaseDatabase _db;
  final String esp32Id;

  ProfileService({required this.esp32Id}) {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
  }

  // ── Plant profile ──────────────────────────────────────────────────────────

  /// Stream of the active plant name from `devices/{esp32Id}/profile/planta`.
  Stream<String> get plantaActivaStream {
    return _db.ref('devices/$esp32Id/profile/planta').onValue.map((event) {
      return event.snapshot.value as String? ?? 'Sin configurar';
    });
  }

  /// Stream of the full profile map from `devices/{esp32Id}/profile/`.
  Stream<Map<dynamic, dynamic>> get thresholdsStream {
    return _db.ref('devices/$esp32Id/profile').onValue.map((event) {
      return event.snapshot.value as Map<dynamic, dynamic>? ?? {};
    });
  }

  /// Write a complete [PlantProfile] to `devices/{esp32Id}/profile/`.
  Future<void> activarPerfil(PlantProfile perfil) {
    return RetryPolicy.execute(
      () => _db.ref('devices/$esp32Id/profile').set(perfil.toMap()),
    );
  }

  /// Partially update threshold values on `devices/{esp32Id}/profile/`.
  Future<void> updateProfileThresholds(Map<String, dynamic> values) {
    return RetryPolicy.execute(
      () => _db.ref('devices/$esp32Id/profile').update(values),
    );
  }

  /// Stream of the crop's planting date from
  /// `devices/{esp32Id}/profile/fecha_siembra`. Emits null when unset.
  Stream<DateTime?> get plantingDateStream {
    return _db
        .ref('devices/$esp32Id/profile/fecha_siembra')
        .onValue
        .map((event) {
      final v = event.snapshot.value;
      return v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;
    });
  }

  /// Persist the crop's planting date to
  /// `devices/{esp32Id}/profile/fecha_siembra` (millis since epoch).
  Future<void> setPlantingDate(DateTime date) {
    return RetryPolicy.execute(
      () => _db
          .ref('devices/$esp32Id/profile/fecha_siembra')
          .set(date.millisecondsSinceEpoch),
    );
  }

}
