import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/firebase_service.dart';
import '../core/demo_data_service.dart';
import '../models/sensor_data.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

final demoDataServiceProvider = Provider((ref) => DemoDataService());

final sensorProvider = StreamProvider<SensorData>((ref) {
  return ref.watch(firebaseServiceProvider).sensorStream;
});

final plantaActivaProvider = StreamProvider<String>((ref) {
  return ref.watch(firebaseServiceProvider).plantaActivaStream;
});

final historyStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(demoDataServiceProvider).historyStream;
});
