import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/firebase_service.dart';
import '../../core/demo_data_service.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../../domain/repositories/plant_repository.dart';
import '../../data/repositories/sensor_repository_impl.dart';
import '../../data/repositories/plant_repository_impl.dart';
import '../../models/sensor_data.dart';
import '../../models/plant_profile.dart';

/// ---------------------------------------------------------------------------
/// Core services (low-level)
/// ---------------------------------------------------------------------------

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final demoDataServiceProvider = Provider<DemoDataService>((ref) {
  return DemoDataService();
});

/// ---------------------------------------------------------------------------
/// Repositories (abstraction layer)
/// ---------------------------------------------------------------------------
///
/// UI code should depend on these providers rather than raw services.
/// This makes testing and swapping data sources trivial.

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  return SensorRepositoryImpl(
    firebaseService: ref.watch(firebaseServiceProvider),
    demoService: ref.watch(demoDataServiceProvider),
  );
});

final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  return PlantRepositoryImpl(
    firebaseService: ref.watch(firebaseServiceProvider),
    demoService: ref.watch(demoDataServiceProvider),
  );
});

/// ---------------------------------------------------------------------------
/// UI-facing streams
/// ---------------------------------------------------------------------------

final sensorProvider = StreamProvider<SensorData>((ref) {
  return ref.watch(sensorRepositoryProvider).sensorStream;
});

final plantaActivaProvider = StreamProvider<String>((ref) {
  return ref.watch(plantRepositoryProvider).activePlantNameStream;
});

final historyStreamProvider = StreamProvider<List<SensorData>>((ref) {
  return ref.watch(sensorRepositoryProvider).historyStream;
});

/// Stream of the currently active plant's full profile (thresholds).
final activePlantProfileProvider = StreamProvider<PlantProfile?>((ref) {
  return ref.watch(plantRepositoryProvider).activePlantProfileStream;
});

/// Stream of the current user's profile data from Firebase.
final userProfileProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(firebaseServiceProvider).userProfileStream;
});

/// Stream of whether alerts are enabled in the system.
final alertsEnabledProvider = StreamProvider<bool>((ref) {
  return ref.watch(firebaseServiceProvider).alertsEnabledStream;
});

/// Stream of user's visualization mode ("tecnica" or "sencilla")
final visualizationModeProvider = StreamProvider<String>((ref) {
  return ref.watch(firebaseServiceProvider).userProfileStream.map((profile) {
    return profile['modo_visualizacion'] as String? ?? 'tecnica';
  });
});
