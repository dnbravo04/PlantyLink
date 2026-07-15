import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/sensor_data.dart';
import '../firebase_constants.dart';

/// Owns the real-time Firebase RTDB listener on `devices/{esp32Id}/sensors/`.
///
/// Single responsibility: produce a [SensorData] stream. Stale-data detection
/// is handled by `dataStalenessProvider` (Riverpod), not here.
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
  ///
  /// Uses [distinct] to skip duplicate emissions when sensor values haven't
  /// changed between ticks, reducing unnecessary widget rebuilds.
  Stream<SensorData> get sensorStream {
    return _db.ref('devices/$esp32Id/sensors').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return SensorData.fromMap(data);
    }).distinct();
  }

}
