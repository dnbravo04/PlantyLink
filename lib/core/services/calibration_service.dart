import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_constants.dart';

/// Reads and writes sensor calibration offsets to Firebase RTDB.
///
/// Path: `devices/{esp32Id}/calibration/` — scoped per device so the ESP32
/// can apply them.
///
/// pH uses 2-point linear calibration: the app stores raw readings at two
/// known buffer solutions (pH 4.0 and 7.0) so the ESP32 (or the app) can
/// compute a slope and offset.
///
/// EC uses a single correction factor: measured = raw × factor.
class CalibrationService {
  late final FirebaseDatabase _db;
  final String esp32Id;

  CalibrationService({required this.esp32Id}) {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
  }

  // ── pH ─────────────────────────────────────────────────────────────────────

  /// Saves a pH calibration point. [buffer] is the known reference value
  /// (4.0 or 7.0), [rawReading] is what the sensor reported at that moment.
  Future<void> savePhCalibrationPoint({
    required double buffer,
    required double rawReading,
  }) {
    final key = buffer <= 4.5 ? 'ph_low' : 'ph_high';
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'device';
    return _db.ref('devices/$esp32Id/calibration').update({
      '${key}_buffer': buffer,
      '${key}_raw': rawReading,
      'calibrated_by': uid,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Clears both pH calibration points (resets to factory defaults).
  Future<void> clearPhCalibration() {
    return _db.ref('devices/$esp32Id/calibration').update({
      'ph_low_buffer': null,
      'ph_low_raw': null,
      'ph_high_buffer': null,
      'ph_high_raw': null,
    });
  }

  // ── EC ─────────────────────────────────────────────────────────────────────

  /// Saves the EC calibration factor. [knownEc] is the reference solution
  /// conductivity in mS/cm, [rawReading] is what the sensor reported.
  Future<void> saveEcCalibration({
    required double knownEc,
    required double rawReading,
  }) {
    final factor = rawReading == 0 ? 1.0 : knownEc / rawReading;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'device';
    return _db.ref('devices/$esp32Id/calibration').update({
      'ec_known': knownEc,
      'ec_raw': rawReading,
      'ec_factor': factor,
      'calibrated_by': uid,
      'timestamp': ServerValue.timestamp,
    });
  }

  Future<void> clearEcCalibration() {
    return _db.ref('devices/$esp32Id/calibration').update({
      'ec_known': null,
      'ec_raw': null,
      'ec_factor': null,
    });
  }

  // ── Read current calibration ───────────────────────────────────────────────

  Stream<Map<String, dynamic>> get calibrationStream {
    return _db.ref('devices/$esp32Id/calibration').onValue.map((event) {
      final raw = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return Map<String, dynamic>.from(raw);
    });
  }
}
