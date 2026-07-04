import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/app_config.dart';
import '../../core/demo_data_service.dart';
import '../../core/services/device_context.dart';
import '../../core/services/sensor_stream_service.dart';
import '../../core/services/control_service.dart';
import '../../core/services/history_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/device_service.dart';
import '../../core/services/user_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/calibration_service.dart';
import '../../core/services/schedule_service.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../../domain/repositories/plant_repository.dart';
import '../../data/repositories/sensor_repository_impl.dart';
import '../../data/repositories/plant_repository_impl.dart';
import '../../models/linked_device.dart';
import '../../models/sensor_data.dart';
import '../../models/plant_profile.dart';
import '../../models/pump_schedule.dart';
import '../../models/trend_alert.dart';

export 'agronomic_providers.dart';

// ── Core services ─────────────────────────────────────────────────────────────

/// Returns the [DemoDataService] singleton when [kDemoMode] is true,
/// otherwise null. Repositories check for null to choose their data source.
final demoDataServiceProvider = Provider<DemoDataService?>((ref) {
  return kDemoMode ? DemoDataService() : null;
});

/// Reactive device context — resolves the current user's linked ESP32 ID.
/// All device-scoped services depend on this. Emits null when no device linked.
/// Re-exported from device_context.dart where it's defined.
// ignore: unnecessary_import
// deviceContextProvider is defined in device_context.dart and auto-imported.

final sensorStreamServiceProvider = Provider<SensorStreamService?>((ref) {
  if (kDemoMode) return null;
  final ctx = ref.watch(deviceContextProvider).value;
  if (ctx == null) return null;
  return SensorStreamService(esp32Id: ctx.esp32Id);
});

final controlServiceProvider = Provider<ControlService?>((ref) {
  if (kDemoMode) return null;
  final ctx = ref.watch(deviceContextProvider).value;
  if (ctx == null) return null;
  return ControlService(esp32Id: ctx.esp32Id);
});

final historyServiceProvider = Provider<HistoryService?>((ref) {
  if (kDemoMode) return null;
  final ctx = ref.watch(deviceContextProvider).value;
  if (ctx == null) return null;
  return HistoryService(esp32Id: ctx.esp32Id);
});

final profileServiceProvider = Provider<ProfileService?>((ref) {
  if (kDemoMode) return null;
  final ctx = ref.watch(deviceContextProvider).value;
  if (ctx == null) return null;
  return ProfileService(esp32Id: ctx.esp32Id);
});

final calibrationServiceProvider = Provider<CalibrationService?>((ref) {
  if (kDemoMode) return null;
  final ctx = ref.watch(deviceContextProvider).value;
  if (ctx == null) return null;
  return CalibrationService(esp32Id: ctx.esp32Id);
});

final scheduleServiceProvider = Provider<ScheduleService?>((ref) {
  if (kDemoMode) return null;
  final ctx = ref.watch(deviceContextProvider).value;
  if (ctx == null) return null;
  return ScheduleService(esp32Id: ctx.esp32Id);
});

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

/// Stream of the user's registered ESP32 devices (multi-device support).
/// The active one is whichever matches [deviceContextProvider]'s esp32Id.
final linkedDevicesProvider = StreamProvider<List<LinkedDevice>>((ref) {
  if (kDemoMode) {
    return Stream.value(const [
      LinkedDevice(id: 'ESP32-DEMO', nombre: 'PlantyLink Demo'),
    ]);
  }
  // Re-subscribe on sign-in/sign-out so the stream follows the current user.
  ref.watch(deviceContextProvider);
  return ref.watch(deviceServiceProvider).linkedDevicesStream;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// User-account operations at `usuarios/{uid}`. Unlike the device-scoped
/// services this is always available — profile edits and preferences must
/// work before any ESP32 is linked. Null only in demo mode (no writes).
final userServiceProvider = Provider<UserService?>((ref) {
  if (kDemoMode) return null;
  return UserService();
});

// ── Repositories ─────────────────────────────────────────────────────────────

final sensorRepositoryProvider = Provider<SensorRepository?>((ref) {
  final demo = ref.watch(demoDataServiceProvider);
  if (kDemoMode && demo != null) {
    // Demo mode: no device context needed, use in-memory simulation.
    return SensorRepositoryImpl(
      sensorStreamService: null,
      controlService: null,
      historyService: null,
      demoService: demo,
    );
  }

  final sensorService = ref.watch(sensorStreamServiceProvider);
  final controlService = ref.watch(controlServiceProvider);
  final historyService = ref.watch(historyServiceProvider);
  if (sensorService == null || controlService == null || historyService == null) {
    return null; // No device linked yet.
  }
  final repo = SensorRepositoryImpl(
    sensorStreamService: sensorService,
    controlService: controlService,
    historyService: historyService,
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final plantRepositoryProvider = Provider<PlantRepository?>((ref) {
  final demo = ref.watch(demoDataServiceProvider);
  if (kDemoMode && demo != null) {
    return PlantRepositoryImpl(
      profileService: null,
      demoService: demo,
    );
  }

  final profileService = ref.watch(profileServiceProvider);
  if (profileService == null) return null;
  return PlantRepositoryImpl(
    profileService: profileService,
    demoService: null,
  );
});

// ── UI-facing stream providers ────────────────────────────────────────────────

final sensorProvider = StreamProvider<SensorData>((ref) {
  final repo = ref.watch(sensorRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.sensorStream;
});

final plantaActivaProvider = StreamProvider<String>((ref) {
  final repo = ref.watch(plantRepositoryProvider);
  if (repo == null) return Stream.value('Sin configurar');
  return repo.activePlantNameStream;
});

final historyStreamProvider = StreamProvider<List<SensorData>>((ref) {
  final repo = ref.watch(sensorRepositoryProvider);
  if (repo == null) return Stream.value([]);
  return repo.historyStream;
});

final activePlantProfileProvider = StreamProvider<PlantProfile?>((ref) {
  final repo = ref.watch(plantRepositoryProvider);
  if (repo == null) return Stream.value(null);
  return repo.activePlantProfileStream;
});

/// Stream of the active crop's planting date. Emits null when unset or when
/// no device is linked. Used to derive the current [GrowthStage].
final plantingDateProvider = StreamProvider<DateTime?>((ref) {
  final repo = ref.watch(plantRepositoryProvider);
  if (repo == null) return Stream.value(null);
  return repo.plantingDateStream;
});

/// Stream of the current user's profile at `usuarios/{uid}`.
/// Returns an empty stream in demo mode (no auth required).
final userProfileProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(userServiceProvider);
  if (service == null) return Stream.value({});
  return service.userProfileStream;
});

/// Stream of whether system alerts are enabled.
final alertsEnabledProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(userServiceProvider);
  if (service == null) return Stream.value(true);
  return service.alertsEnabledStream;
});

class VisualizationModeNotifier extends Notifier<String> {
  @override
  String build() {
    // Follows the stored preference. set() takes effect immediately; outside
    // demo mode the stored value catches up once the RTDB write lands.
    return ref.watch(userProfileProvider).value?['modo_visualizacion']
            as String? ??
        'tecnica';
  }

  void set(String mode) {
    state = mode;
    ref.read(userServiceProvider)?.updateUserSettings(
        {'modo_visualizacion': mode});
  }
}

/// The user's preferred visualization mode. Local-first so the dashboard
/// toggle also works in demo mode, where nothing is persisted.
final visualizationModeProvider =
    NotifierProvider<VisualizationModeNotifier, String>(
        VisualizationModeNotifier.new);

/// True when the device has any active network connection.
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    return results.any((r) => r != ConnectivityResult.none);
  });
});

/// Stream of the last 20 saved trend alerts from Firebase, newest first.
/// Returns an empty stream in demo mode or when no device is linked.
final alertHistoryProvider = StreamProvider<List<TrendAlert>>((ref) {
  if (kDemoMode) return Stream.value([]);
  final service = ref.watch(historyServiceProvider);
  if (service == null) return Stream.value([]);
  return service.alertHistoryStream;
});

/// Stream of pump/actuator schedules from Firebase, sorted by start time.
/// Returns an empty stream when no device is linked.
final schedulesProvider = StreamProvider<List<PumpSchedule>>((ref) {
  if (kDemoMode) return Stream.value([]);
  final service = ref.watch(scheduleServiceProvider);
  if (service == null) return Stream.value([]);
  return service.schedulesStream;
});
