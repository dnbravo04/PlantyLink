import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../../models/sensor_data.dart';
import '../../models/trend_alert.dart';
import '../firebase_constants.dart';
import '../retry_policy.dart';

/// Reads and writes historical sensor data from/to `devices/{esp32Id}/history/`
/// and trend alerts to `devices/{esp32Id}/alerts/` in Firebase RTDB.
///
/// Single responsibility: history and alert storage only.
class HistoryService {
  late final FirebaseDatabase _db;
  final String esp32Id;

  HistoryService({required this.esp32Id}) {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
  }

  /// Stream of the last 60 sensor readings from `devices/{esp32Id}/history/`,
  /// sorted oldest→newest.
  Stream<List<SensorData>> get historyStream {
    return _db
        .ref('devices/$esp32Id/history')
        .orderByChild('timestamp')
        .limitToLast(60)
        .onValue
        .map((event) {
      final raw = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final list = <SensorData>[];
      raw.forEach((_, value) {
        if (value is! Map<dynamic, dynamic>) return;
        try {
          list.add(SensorData.fromMap(value));
        } catch (_) {
          // Skip malformed entries silently.
        }
      });
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    });
  }

  /// Maximum number of history entries to keep per device.
  /// Older entries are pruned after each write.
  static const int _maxHistoryEntries = 2880; // ~24h at 30s intervals

  /// Append a snapshot of [data] to `devices/{esp32Id}/history/`.
  ///
  /// Retries on transient failures. Called periodically by
  /// [SensorRepositoryImpl] in production mode.
  /// After writing, prunes entries beyond [_maxHistoryEntries].
  Future<void> appendSensorReading(SensorData data) async {
    await RetryPolicy.execute(
      () => _db.ref('devices/$esp32Id/history').push().set(data.toMap()),
    );
    // Fire-and-forget pruning — failures must not block the main flow.
    _pruneOldEntries();
  }

  Future<void> _pruneOldEntries() async {
    try {
      final ref = _db.ref('devices/$esp32Id/history');
      final snapshot = await ref.orderByChild('timestamp').limitToFirst(1).get();
      if (!snapshot.exists) return;

      // Only prune if we have more than the limit.
      final countSnap = await ref.get();
      if (!countSnap.exists) return;
      final count = (countSnap.value as Map?)?.length ?? 0;
      if (count <= _maxHistoryEntries) return;

      final excess = count - _maxHistoryEntries;
      final oldestSnap = await ref.orderByChild('timestamp').limitToFirst(excess).get();
      if (!oldestSnap.exists) return;

      final updates = <String, dynamic>{};
      (oldestSnap.value as Map).forEach((key, _) {
        updates[key.toString()] = null; // null deletes the key
      });
      await ref.update(updates);
    } catch (e) {
      debugPrint('[HistoryService] pruneOldEntries failed: $e');
    }
  }

  /// Stream of the last 20 trend alerts from `devices/{esp32Id}/alerts/`,
  /// sorted newest first.
  Stream<List<TrendAlert>> get alertHistoryStream {
    return _db
        .ref('devices/$esp32Id/alerts')
        .orderByChild('timestamp')
        .limitToLast(20)
        .onValue
        .map((event) {
      final raw = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final list = <TrendAlert>[];
      raw.forEach((_, value) {
        if (value is! Map<dynamic, dynamic>) return;
        try {
          list.add(TrendAlert.fromMap(value));
        } catch (_) {}
      });
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  /// Persist a [TrendAlert] to `devices/{esp32Id}/alerts/` for later retrieval.
  ///
  /// Failures are swallowed — alert persistence must never interrupt the
  /// main data flow.
  Future<void> saveAlert(TrendAlert alert) async {
    try {
      await _db.ref('devices/$esp32Id/alerts').push().set(alert.toMap());
    } catch (e) {
      debugPrint('[HistoryService] saveAlert failed: $e');
    }
  }
}
