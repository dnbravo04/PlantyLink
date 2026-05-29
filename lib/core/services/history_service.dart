import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/sensor_data.dart';
import '../../models/trend_alert.dart';
import '../firebase_constants.dart';
import '../retry_policy.dart';

/// Reads and writes historical sensor data from/to `history/` in Firebase RTDB.
///
/// Single responsibility: history storage only.
/// Trend alerts are also stored here (with `event: 'alerta_tendencia'`) but
/// are filtered out of the sensor-history stream.
class HistoryService {
  late final FirebaseDatabase _db;

  HistoryService() {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
  }

  /// Stream of the last 60 sensor readings from `history/`, sorted oldest→newest.
  ///
  /// Trend-alert entries (those with `event: 'alerta_tendencia'`) are excluded.
  Stream<List<SensorData>> get historyStream {
    return _db
        .ref('history')
        .orderByChild('timestamp')
        .limitToLast(60)
        .onValue
        .map((event) {
      final raw = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final list = <SensorData>[];
      raw.forEach((_, value) {
        if (value is! Map<dynamic, dynamic>) return;
        if (value['event'] == 'alerta_tendencia') return;
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

  /// Append a snapshot of [data] to `history/`.
  ///
  /// Retries on transient failures. Called periodically by
  /// [SensorRepositoryImpl] in production mode.
  Future<void> appendSensorReading(SensorData data) {
    return RetryPolicy.execute(
      () => _db.ref('history').push().set(data.toMap()),
    );
  }

  /// Persist a [TrendAlert] to `history/` for later retrieval.
  ///
  /// Failures are swallowed — alert persistence must never interrupt the
  /// main data flow.
  Future<void> saveAlert(TrendAlert alert) async {
    try {
      await _db.ref('history').push().set(alert.toMap());
    } catch (_) {
      // Intentionally silent.
    }
  }
}
