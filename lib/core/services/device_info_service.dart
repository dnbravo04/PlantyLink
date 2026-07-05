import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/device_info.dart';
import '../firebase_constants.dart';

/// Reads the device's declared capabilities from `devices/{esp32Id}/info/`.
///
/// The firmware writes this node on boot. The app uses it to show only the
/// sensors/actuators a device actually has instead of assuming the full
/// hydroponic set (capability model — ROADMAP_PRODUCTO.md, decisión P1).
///
/// Read-only: capabilities are owned by the device, never written by the app.
class DeviceInfoService {
  late final FirebaseDatabase _db;
  final String esp32Id;

  DeviceInfoService({required this.esp32Id}) {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
  }

  /// Live stream of the device's capabilities. Emits an empty [DeviceInfo]
  /// when the node is absent (device predates the capability model or hasn't
  /// booted yet); consumers should then fall back to showing everything.
  Stream<DeviceInfo> get infoStream {
    return _db.ref('devices/$esp32Id/info').onValue.map((event) {
      final raw = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return DeviceInfo.fromMap(raw);
    });
  }
}
