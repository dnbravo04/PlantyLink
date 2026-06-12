import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/pump_schedule.dart';
import '../firebase_constants.dart';

/// Reads and writes pump/actuator schedules to Firebase RTDB.
///
/// Path: `devices/{esp32Id}/schedules/{pushKey}` — the ESP32 polls this node
/// and activates the corresponding actuator at the specified time.
class ScheduleService {
  late final FirebaseDatabase _db;
  final String esp32Id;

  ScheduleService({required this.esp32Id}) {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
  }

  Stream<List<PumpSchedule>> get schedulesStream {
    return _db.ref('devices/$esp32Id/schedules').onValue.map((event) {
      final raw = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final list = raw.entries.map((e) {
        return PumpSchedule.fromMap(
          e.key as String,
          e.value as Map<dynamic, dynamic>,
        );
      }).toList();
      list.sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
      return list;
    });
  }

  Future<void> addSchedule(PumpSchedule schedule) {
    return _db.ref('devices/$esp32Id/schedules').push().set(schedule.toMap());
  }

  Future<void> updateSchedule(PumpSchedule schedule) {
    return _db
        .ref('devices/$esp32Id/schedules/${schedule.id}')
        .update(schedule.toMap());
  }

  Future<void> deleteSchedule(String id) {
    return _db.ref('devices/$esp32Id/schedules/$id').remove();
  }
}
