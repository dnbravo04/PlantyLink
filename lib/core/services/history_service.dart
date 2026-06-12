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

  /// Append a snapshot of [data] to `devices/{esp32Id}/history/`.
  ///
  /// Retries on transient failures. Called periodically by
  /// [SensorRepositoryImpl] in production mode.
  Future<void> appendSensorReading(SensorData data) {
    return RetryPolicy.execute(
      () => _db.ref('devices/$esp32Id/history').push().set(data.toMap()),
    );
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
