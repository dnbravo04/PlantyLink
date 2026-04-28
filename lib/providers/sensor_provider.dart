import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/firebase_service.dart';
import '../models/sensor_data.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

final sensorProvider = StreamProvider<SensorData>((ref) {
  return ref.watch(firebaseServiceProvider).sensorStream;
});

final plantaActivaProvider = StreamProvider<String>((ref) {
  return ref.watch(firebaseServiceProvider).plantaActivaStream;
});

final historialProvider = StateProvider<List<SensorData>>((ref) => []);