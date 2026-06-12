import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/plant_profile.dart';
import '../firebase_constants.dart';
import '../retry_policy.dart';

/// Manages plant profiles and user settings in Firebase RTDB.
///
/// Single responsibility: reads and writes to `devices/{esp32Id}/profile/`
/// and `usuarios/{uid}/`. No sensor data, no actuator control.
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

  // ── User settings ──────────────────────────────────────────────────────────

  /// Stream of the current user's profile document from `usuarios/{uid}`.
  ///
  /// Returns an empty-map stream if no user is signed in.
  Stream<Map<String, dynamic>> get userProfileStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value({});
    return _db.ref('usuarios/$uid').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return Map<String, dynamic>.from(data);
    });
  }

  Future<void> updateUserProfile(String name, String city) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Future.value();
    return RetryPolicy.execute(
      () => _db.ref('usuarios/$uid').update({'nombre': name, 'ciudad': city}),
    );
  }

  Future<void> updateUserSettings(Map<String, dynamic> settings) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Future.value();
    return RetryPolicy.execute(
      () => _db.ref('usuarios/$uid').update(settings),
    );
  }

  // ── Alert settings (per-user) ──────────────────────────────────────────────

  Stream<bool> get alertsEnabledStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(true);
    return _db.ref('usuarios/$uid/alerts_enabled').onValue.map((event) {
      return event.snapshot.value as bool? ?? true;
    });
  }

  Future<void> setAlertsEnabled(bool enabled) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Future.value();
    return RetryPolicy.execute(
      () => _db.ref('usuarios/$uid/alerts_enabled').set(enabled),
    );
  }

  /// Removes the user's RTDB data before account deletion.
  Future<void> deleteUserData(String uid) async {
    await _db.ref('usuarios/$uid').remove();
  }
}
