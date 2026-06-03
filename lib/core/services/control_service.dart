import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_constants.dart';
import '../retry_policy.dart';

/// Writes actuator commands to `controls/` in Firebase RTDB.
///
/// Single responsibility: translate pump/automation toggle requests into
/// Firebase writes, with automatic retry on transient failures.
class ControlService {
  late final FirebaseDatabase _db;

  ControlService() {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
  }

  /// Set [pumpKey] (e.g. `bomba_agua`) to [active].
  ///
  /// Writes to both `controls/` (ESP32 reads this) and `sensors/` (app UI
  /// reads this), so the button state flips immediately without waiting for
  /// the ESP32 to echo the value back.
  Future<void> setPump(String pumpKey, bool active) {
    return RetryPolicy.execute(
      () => _db.ref().update({
        'controls/$pumpKey': active,
        'sensors/$pumpKey': active,
      }),
    );
  }

  /// Enable or disable automatic watering under `controls/riego_automatico`.
  Future<void> setAutoWatering(bool active) {
    return RetryPolicy.execute(
      () => _db.ref('controls/riego_automatico').set(active),
    );
  }
}
