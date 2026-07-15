import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
import '../../core/services/weather_service.dart';
import '../../core/utils/units.dart';
import '../../core/services/calibration_service.dart';
import '../../core/services/schedule_service.dart';
import '../../core/services/device_info_service.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../../domain/repositories/plant_repository.dart';
import '../../data/repositories/sensor_repository_impl.dart';
import '../../data/repositories/plant_repository_impl.dart';
import '../../models/linked_device.dart';
import '../../models/device_info.dart';
import '../../models/sensor_data.dart';
import '../../models/plant_profile.dart';
import '../../models/pump_schedule.dart';
import '../../models/trend_alert.dart';

export 'agronomic_providers.dart';
export 'data_staleness_provider.dart';

// ── Core services ─────────────────────────────────────────────────────────────

/// Returns the [DemoDataService] singleton when [kDemoMode] is true,
/// otherwise null. Repositories check for null to choose their data source.
final demoDataServiceProvider = Provider<DemoDataService?>((ref) {
  return kDemoMode ? DemoDataService() : null;
});

/// Tracks which demo device is currently active. Providers that depend on
/// device identity watch this to rebuild when the user switches devices.
final demoActiveDeviceProvider = StreamProvider<String>((ref) {
  final demo = ref.watch(demoDataServiceProvider);
  if (demo == null) return Stream.value('');
  return demo.activeDeviceStream;
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

/// Reads the active device's declared capabilities (`devices/{id}/info/`).
/// Null in demo mode or before a device is linked.
final deviceInfoServiceProvider = Provider<DeviceInfoService?>((ref) {
  if (kDemoMode) return null;
  final ctx = ref.watch(deviceContextProvider).value;
  if (ctx == null) return null;
  return DeviceInfoService(esp32Id: ctx.esp32Id);
});

/// Live capability model for the active device. In demo mode, returns the
/// capabilities of the currently selected demo device. In production, reads
/// from `devices/{id}/info/`.
final deviceInfoProvider = StreamProvider<DeviceInfo>((ref) {
  if (kDemoMode) {
    final demo = ref.watch(demoDataServiceProvider);
    if (demo == null) return Stream.value(const DeviceInfo());
    // Re-evaluate whenever the active demo device changes.
    ref.watch(demoActiveDeviceProvider);
    return Stream.value(demo.activeDeviceInfo);
  }
  final service = ref.watch(deviceInfoServiceProvider);
  if (service == null) return Stream.value(const DeviceInfo());
  return service.infoStream;
});

/// True when the active device should be treated as hydroponic and the UI may
/// show pH/EC/tanques/dosificadoras (modelo de capacidades, decisión P1
/// soil-first de ROADMAP_PRODUCTO.md).
///
/// - Device with declared capabilities: hydro iff it says so (tipo_cultivo or
///   pH/EC sensors present).
/// - Legacy/demo device without `info/`: inferred from data — if it reports
///   soil moisture it's a soil unit; otherwise assume the old full-hydro set
///   so real data is never hidden.
final isHydroDeviceProvider = Provider<bool>((ref) {
  final info = ref.watch(deviceInfoProvider).value;
  if (info != null && !info.isEmpty) {
    return info.tipoCultivo == 'hidroponico' ||
        info.hasSensor('ph') ||
        info.hasSensor('conductividad');
  }
  final sensor = ref.watch(sensorProvider).value;
  return sensor?.humedadSuelo == null;
});

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

/// Stream of the user's registered ESP32 devices (multi-device support).
/// The active one is whichever matches [deviceContextProvider]'s esp32Id.
final linkedDevicesProvider = StreamProvider<List<LinkedDevice>>((ref) {
  if (kDemoMode) {
    final demo = ref.watch(demoDataServiceProvider);
    if (demo != null) {
      return Stream.value([
        for (final d in demo.demoDevices)
          LinkedDevice(id: d.id, nombre: d.nombre),
      ]);
    }
    return Stream.value(const []);
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
    // Rebuild when the active demo device changes so streams re-subscribe.
    ref.watch(demoActiveDeviceProvider);
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
    ref.watch(demoActiveDeviceProvider);
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
    // Without an explicit choice, beginners default to the simple view.
    final stored = ref.watch(userProfileProvider).value?['modo_visualizacion']
        as String?;
    if (stored != null) return stored;
    return ref.watch(experienceProvider) == 'novato' ? 'sencilla' : 'tecnica';
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

class ExperienceNotifier extends Notifier<String> {
  @override
  String build() {
    return ref.watch(userProfileProvider).value?['experiencia'] as String? ??
        'novato';
  }

  void set(String level) {
    state = level;
    ref.read(userServiceProvider)?.updateUserSettings({'experiencia': level});
  }
}

/// Grower experience level (`novato` | `avanzado`). Drives the default
/// visualization mode and how much technical detail screens show.
final experienceProvider =
    NotifierProvider<ExperienceNotifier, String>(ExperienceNotifier.new);

class UnitsNotifier extends Notifier<UnitsPrefs> {
  @override
  UnitsPrefs build() {
    final user = ref.watch(userProfileProvider).value;
    return UnitsPrefs(
      fahrenheit: user?['unidad_temp'] == 'F',
      microSiemens: user?['unidad_ec'] == 'uS',
    );
  }

  void setFahrenheit(bool value) {
    state = UnitsPrefs(fahrenheit: value, microSiemens: state.microSiemens);
    ref.read(userServiceProvider)?.updateUserSettings(
        {'unidad_temp': value ? 'F' : 'C'});
  }

  void setMicroSiemens(bool value) {
    state = UnitsPrefs(fahrenheit: state.fahrenheit, microSiemens: value);
    ref.read(userServiceProvider)?.updateUserSettings(
        {'unidad_ec': value ? 'uS' : 'mS'});
  }
}

/// Display units for temperature (°C/°F) and EC (mS/µS). Data is stored in
/// °C and mS/cm; conversion happens at presentation time only.
final unitsProvider =
    NotifierProvider<UnitsNotifier, UnitsPrefs>(UnitsNotifier.new);

/// Current weather for the user's `ciudad`. Null hides the dashboard chip
/// (no city set, geocoding miss, or network failure). Demo mode shows fixed
/// conditions so the UI is visible. Refreshed via the dashboard's
/// pull-to-refresh (ref.invalidate) with a 30-minute service-side cache.
final weatherProvider = FutureProvider<WeatherInfo?>((ref) async {
  if (kDemoMode) {
    return const WeatherInfo(
        ciudad: 'Ciudad Demo', tempC: 23, humidity: 55, weatherCode: 1);
  }
  final ciudad =
      ref.watch(userProfileProvider).value?['ciudad'] as String?;
  if (ciudad == null || ciudad.trim().isEmpty) return null;
  return WeatherService().fetchForCity(ciudad);
});

/// App version straight from the platform ("2.0.0"), so UI footers never
/// drift from pubspec.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

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

/// Stream of the device's calibration data. Empty map in demo mode or when
/// no device is linked.
final calibrationDataProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(calibrationServiceProvider);
  if (service == null) return Stream.value(const {});
  return service.calibrationStream;
});

/// Stream of pump/actuator schedules from Firebase, sorted by start time.
/// Returns an empty stream when no device is linked.
final schedulesProvider = StreamProvider<List<PumpSchedule>>((ref) {
  if (kDemoMode) return Stream.value([]);
  final service = ref.watch(scheduleServiceProvider);
  if (service == null) return Stream.value([]);
  return service.schedulesStream;
});

// ── Pump commands (node-ownership: app → controls/, firmware → sensors/) ──────

/// How long a pump command stays "pending" without a firmware echo before the
/// UI gives up and reverts to the last confirmed state. Overridable in tests.
final pumpConfirmTimeoutProvider =
    Provider<Duration>((ref) => const Duration(seconds: 8));

/// Reads a pump's confirmed state (from `sensors/`) for the given command key.
bool? _sensorPumpValue(SensorData s, String pumpId) {
  switch (pumpId) {
    case 'bomba_agua':
      return s.bombaAgua;
    case 'bomba_fertilizante':
      return s.bombaFertilizante;
    case 'bomba_dosificadora_acido':
      return s.bombaDosificadoraAcido;
    case 'bomba_dosificadora_basico':
      return s.bombaDosificadoraBasico;
    default:
      return null;
  }
}

/// Tracks pump commands that have been sent to `controls/` but not yet
/// confirmed by the firmware via `sensors/`.
///
/// The app no longer echoes actuator state into `sensors/` (that node belongs
/// to the firmware). To keep the button responsive, [send] records the desired
/// value as *pending* and the notifier clears it when a fresh sensor snapshot
/// reports the commanded value — or after [pumpConfirmTimeoutProvider] elapses,
/// so a lost command can't leave the button stuck forever.
///
/// State maps `pumpId → desiredValue` and only contains currently-pending pumps.
class PumpCommandsNotifier extends Notifier<Map<String, bool>> {
  final Map<String, Timer> _timers = {};

  @override
  Map<String, bool> build() {
    // Clear pending flags as the firmware confirms each command.
    ref.listen(sensorProvider, (_, next) => _reconcile(next.value));
    ref.onDispose(() {
      for (final t in _timers.values) {
        t.cancel();
      }
      _timers.clear();
    });
    return const {};
  }

  /// Whether [pumpId] is waiting on a firmware confirmation.
  bool isPending(String pumpId) => state.containsKey(pumpId);

  /// Send a pump command: write to `controls/` and mark it pending until the
  /// firmware echoes it back on `sensors/` (or the confirm timeout fires).
  Future<void> send(String pumpId, bool active) async {
    _timers.remove(pumpId)?.cancel();
    state = {...state, pumpId: active};
    final timeout = ref.read(pumpConfirmTimeoutProvider);
    _timers[pumpId] = Timer(timeout, () => _clear(pumpId));
    try {
      await ref.read(sensorRepositoryProvider)?.togglePump(pumpId, active);
    } catch (_) {
      // Failed to enqueue — drop the pending flag so the button reflects the
      // real (unchanged) state and the user can retry.
      _clear(pumpId);
      rethrow;
    }
  }

  void _reconcile(SensorData? sensor) {
    if (sensor == null || state.isEmpty) return;
    for (final entry in state.entries.toList()) {
      if (_sensorPumpValue(sensor, entry.key) == entry.value) {
        _clear(entry.key);
      }
    }
  }

  void _clear(String pumpId) {
    _timers.remove(pumpId)?.cancel();
    if (!state.containsKey(pumpId)) return;
    state = {...state}..remove(pumpId);
  }
}

/// Pump commands awaiting firmware confirmation (`pumpId → desiredValue`).
/// The dashboard watches this to show a pending state on actuator buttons.
final pumpCommandsProvider =
    NotifierProvider<PumpCommandsNotifier, Map<String, bool>>(
        PumpCommandsNotifier.new);
