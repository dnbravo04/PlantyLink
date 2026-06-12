import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/sensor_data.dart';
import '../firebase_constants.dart';

/// Owns the real-time Firebase RTDB listener on `devices/{esp32Id}/sensors/`.
///
/// Single responsibility: produce a [SensorData] stream and expose
/// stale-data detection. No writes, no profile concerns.
class SensorStreamService {
  late final FirebaseDatabase _db;
  final String esp32Id;

  SensorStreamService({required this.esp32Id}) {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
  }

  /// Continuous stream of live sensor readings from `devices/{esp32Id}/sensors/`.
  Stream<SensorData> get sensorStream {
    return _db.ref('devices/$esp32Id/sensors').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return SensorData.fromMap(data);
    });
  }

  /// Emits `true` when the most-recent sensor timestamp is older than
  /// [staleThreshold] (default 10 s), indicating the ESP32 stopped sending.
  Stream<bool> staleDataStream({
    Duration staleThreshold = const Duration(seconds: 10),
  }) {
    return sensorStream.map((sensor) {
      return DateTime.now().difference(sensor.timestamp) > staleThreshold;
    });
  }
}
