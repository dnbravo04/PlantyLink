import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_constants.dart';
import '../retry_policy.dart';

/// Writes actuator commands to `devices/{esp32Id}/controls/` in Firebase RTDB.
///
/// Single responsibility: translate pump/automation toggle requests into
/// Firebase writes, with automatic retry on transient failures.
class ControlService {
  late final FirebaseDatabase _db;
  final String esp32Id;

  ControlService({required this.esp32Id}) {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
  }

  /// Set [pumpKey] (e.g. `bomba_agua`) to [active].
  ///
  /// Writes **only** to `controls/` — the app's exclusive node. The firmware
  /// owns `sensors/` and echoes the applied value back there once it acts, so
  /// the UI reflects confirmed hardware state rather than an optimistic guess.
  /// Until that echo lands, the button shows a pending state
  /// (see `PumpCommandsNotifier`). This node-ownership split (app→`controls/`,
  /// firmware→`sensors/`) removes the double-writer race on `sensors/`.
  Future<void> setPump(String pumpKey, bool active) {
    return RetryPolicy.execute(
      () => _db.ref('devices/$esp32Id/controls/$pumpKey').set(active),
    );
  }

  /// Enable or disable automatic watering under `controls/riego_automatico`.
  Future<void> setAutoWatering(bool active) {
    return RetryPolicy.execute(
      () => _db.ref('devices/$esp32Id/controls/riego_automatico').set(active),
    );
  }
}
