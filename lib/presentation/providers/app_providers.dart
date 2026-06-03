import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/app_config.dart';
import '../../core/demo_data_service.dart';
import '../../core/services/sensor_stream_service.dart';
import '../../core/services/control_service.dart';
import '../../core/services/history_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/device_service.dart';
import '../../core/services/auth_service.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../../domain/repositories/plant_repository.dart';
import '../../data/repositories/sensor_repository_impl.dart';
import '../../data/repositories/plant_repository_impl.dart';
import '../../models/sensor_data.dart';
import '../../models/plant_profile.dart';
import '../../models/trend_alert.dart';

export 'agronomic_providers.dart';

// ── Core services ─────────────────────────────────────────────────────────────

/// Returns the [DemoDataService] singleton when [kDemoMode] is true,
/// otherwise null. Repositories check for null to choose their data source.
final demoDataServiceProvider = Provider<DemoDataService?>((ref) {
  return kDemoMode ? DemoDataService() : null;
});

final sensorStreamServiceProvider = Provider<SensorStreamService>((ref) {
  return SensorStreamService();
});

final controlServiceProvider = Provider<ControlService>((ref) {
  return ControlService();
});

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService();
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ── Repositories ─────────────────────────────────────────────────────────────

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  final repo = SensorRepositoryImpl(
    sensorStreamService: ref.watch(sensorStreamServiceProvider),
    controlService: ref.watch(controlServiceProvider),
    historyService: ref.watch(historyServiceProvider),
    demoService: ref.watch(demoDataServiceProvider),
  );
  // Cancel the background history-recorder subscription on dispose.
  ref.onDispose(repo.dispose);
  return repo;
});

final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  return PlantRepositoryImpl(
    profileService: ref.watch(profileServiceProvider),
    demoService: ref.watch(demoDataServiceProvider),
  );
});

// ── UI-facing stream providers ────────────────────────────────────────────────

final sensorProvider = StreamProvider<SensorData>((ref) {
  return ref.watch(sensorRepositoryProvider).sensorStream;
});

final plantaActivaProvider = StreamProvider<String>((ref) {
  return ref.watch(plantRepositoryProvider).activePlantNameStream;
});

final historyStreamProvider = StreamProvider<List<SensorData>>((ref) {
  return ref.watch(sensorRepositoryProvider).historyStream;
});

final activePlantProfileProvider = StreamProvider<PlantProfile?>((ref) {
  return ref.watch(plantRepositoryProvider).activePlantProfileStream;
});

/// Stream of the current user's Firestore profile.
/// Returns an empty stream in demo mode (no auth required).
final userProfileProvider = StreamProvider<Map<String, dynamic>>((ref) {
  if (kDemoMode) return Stream.value({});
  return ref.watch(profileServiceProvider).userProfileStream;
});

/// Stream of whether system alerts are enabled.
final alertsEnabledProvider = StreamProvider<bool>((ref) {
  if (kDemoMode) return Stream.value(true);
  return ref.watch(profileServiceProvider).alertsEnabledStream;
});

/// The user's preferred visualization mode — derived from [userProfileProvider]
/// so there is no separate Firebase listener.
final visualizationModeProvider = Provider<String>((ref) {
  return ref.watch(userProfileProvider).value?['modo_visualizacion']
          as String? ??
      'tecnica';
});

/// True when the device has any active network connection.
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    return results.any((r) => r != ConnectivityResult.none);
  });
});

/// Stream of the last 20 saved trend alerts from Firebase, newest first.
/// Returns an empty stream in demo mode.
final alertHistoryProvider = StreamProvider<List<TrendAlert>>((ref) {
  if (kDemoMode) return Stream.value([]);
  return ref.watch(historyServiceProvider).alertHistoryStream;
});
