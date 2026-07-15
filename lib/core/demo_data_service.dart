import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/device_info.dart';
import '../models/plant_profile.dart';
import '../models/sensor_data.dart';

/// Per-device simulation state held in memory.
class _DeviceSimState {
  final String id;
  final String nombre;
  final DeviceInfo info;

  // Current sensor values — only the ones this device "has".
  double temperatura;
  double? ph;
  double? conductividad;
  double? nivelAguaTanque;
  double? nivelFertilizanteTanque;
  double? humedadSuelo;
  double? humedadAire;
  bool nivelAguaBool = true;
  bool bombaAgua = false;
  bool bombaFertilizante = false;
  bool bombaAcido = false;
  bool bombaBasico = false;

  final List<Map<String, dynamic>> history = [];

  _DeviceSimState({
    required this.id,
    required this.nombre,
    required this.info,
    required this.temperatura,
    this.ph,
    this.conductividad,
    this.nivelAguaTanque,
    this.nivelFertilizanteTanque,
    this.humedadSuelo,
    this.humedadAire,
  });
}

/// Simulates sensor data for TWO demo devices entirely in memory.
///
/// - **pl-demo-full** ("PlantyLink Pro"): full hydroponic — all sensors and
///   actuators (pH, EC, tanks, 4 pumps, soil humidity, air humidity, temp).
/// - **pl-demo-suelo** ("PlantyLink Suelo"): realistic soil scenario — only
///   temperature, soil humidity, air humidity, and one water pump.
///
/// The active device can be switched via [switchDevice]; streams re-emit the
/// new device's data immediately.
class DemoDataService {
  static final DemoDataService _instance = DemoDataService._internal();
  factory DemoDataService() => _instance;

  // ── Stream controllers ───────────────────────────────────────────────────
  final _sensorController = StreamController<SensorData>.broadcast();
  final _historyController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _plantController = StreamController<PlantProfile>.broadcast();
  final _plantingDateController = StreamController<DateTime>.broadcast();
  /// Emits whenever the active demo device changes.
  final _activeDeviceController = StreamController<String>.broadcast();

  // ── Timers ───────────────────────────────────────────────────────────────
  Timer? _simulationTimer;
  Timer? _historyTimer;
  bool _isRunning = false;

  // ── Two demo devices ─────────────────────────────────────────────────────
  static const kFullDeviceId = 'pl-demo-full';
  static const kSoilDeviceId = 'pl-demo-suelo';

  late final Map<String, _DeviceSimState> _devices;
  String _activeDeviceId = kFullDeviceId;

  static const int _maxHistory = 60;

  // ── Plant catalogue ──────────────────────────────────────────────────────
  List<PlantProfile> get availablePlants => PlantCatalog.plantas;
  List<PlantProfile> get plants => PlantCatalog.plantas;
  int _activePlantIndex = 0;
  PlantProfile get activePlant => availablePlants[_activePlantIndex];
  DateTime _plantingDate = DateTime.now().subtract(const Duration(days: 30));

  DemoDataService._internal() {
    _devices = {
      kFullDeviceId: _DeviceSimState(
        id: kFullDeviceId,
        nombre: 'PlantyLink Pro',
        info: const DeviceInfo(
          modeloHardware: 'esp32-hydro-v1',
          versionFirmware: '1.0.0',
          tipoCultivo: 'hidroponico',
          sensores: {
            'temperatura',
            'humedad_suelo',
            'humedad_aire',
            'ph',
            'conductividad',
            'nivel_agua_tanque',
            'nivel_fertilizante_tanque',
          },
          actuadores: {
            'bomba_agua',
            'bomba_fertilizante',
            'bomba_dosificadora_acido',
            'bomba_dosificadora_basico',
          },
        ),
        temperatura: 24.0,
        ph: 6.8,
        conductividad: 1500.0,
        nivelAguaTanque: 75.0,
        nivelFertilizanteTanque: 60.0,
        humedadSuelo: 55.0,
        humedadAire: 60.0,
      ),
      kSoilDeviceId: _DeviceSimState(
        id: kSoilDeviceId,
        nombre: 'PlantyLink Suelo',
        info: const DeviceInfo(
          modeloHardware: 'esp32-soil-v1',
          versionFirmware: '0.1.0-demo',
          tipoCultivo: 'suelo',
          sensores: {'temperatura', 'humedad_suelo', 'humedad_aire'},
          actuadores: {'bomba_agua'},
        ),
        temperatura: 22.5,
        humedadSuelo: 45.0,
        humedadAire: 55.0,
      ),
    };
  }

  // ── Active device ────────────────────────────────────────────────────────

  String get activeDeviceId => _activeDeviceId;
  _DeviceSimState get _active => _devices[_activeDeviceId]!;

  /// Info for the currently active demo device.
  DeviceInfo get activeDeviceInfo => _active.info;

  /// Info for a specific demo device by ID.
  DeviceInfo deviceInfoFor(String id) =>
      _devices[id]?.info ?? const DeviceInfo();

  /// All demo devices as a list of (id, name) pairs.
  List<({String id, String nombre})> get demoDevices =>
      _devices.values.map((d) => (id: d.id, nombre: d.nombre)).toList();

  /// Switches the active device. Re-emits sensor data immediately.
  void switchDevice(String deviceId) {
    if (!_devices.containsKey(deviceId) || deviceId == _activeDeviceId) return;
    _activeDeviceId = deviceId;
    debugPrint('🔄 DemoDataService: dispositivo activo → $deviceId');
    _activeDeviceController.add(deviceId);
    _emitSensorSnapshot();
    _emitHistory();
  }

  /// Stream that emits the active device ID whenever it changes.
  Stream<String> get activeDeviceStream {
    final current = _activeDeviceId;
    return Stream.multi((controller) {
      controller.add(current);
      final sub = _activeDeviceController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  // ── Public streams ───────────────────────────────────────────────────────

  Stream<SensorData> get sensorStream => _sensorController.stream;

  Stream<List<Map<String, dynamic>>> get historyStream =>
      _historyController.stream;

  Stream<PlantProfile> get activePlantStream {
    final current = activePlant;
    return Stream.multi((controller) {
      controller.add(current);
      final sub = _plantController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  Stream<DateTime> get plantingDateStream {
    final current = _plantingDate;
    return Stream.multi((controller) {
      controller.add(current);
      final sub = _plantingDateController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  void startSimulation() {
    if (_isRunning) return;
    _isRunning = true;

    _emitSensorSnapshot();

    // Sensor tick every 3 s — simulates BOTH devices in parallel.
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _simulateAllDevices();
    });

    // History entry every 10 s for the active device.
    _historyTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _appendHistory();
    });

    debugPrint('🔄 DemoDataService: simulación iniciada (2 dispositivos)');
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    _historyTimer?.cancel();
    _simulationTimer = null;
    _historyTimer = null;
    _isRunning = false;
    debugPrint('⏹️ DemoDataService: simulación detenida');
  }

  void dispose() {
    stopSimulation();
    _sensorController.close();
    _historyController.close();
    _plantController.close();
    _plantingDateController.close();
    _activeDeviceController.close();
  }

  // ── Plant management ─────────────────────────────────────────────────────

  void changePlant(int index) {
    if (index < 0 || index >= availablePlants.length) return;
    _activePlantIndex = index;
    debugPrint('🌱 DemoDataService: planta activa → ${activePlant.nombre}');
    if (!_plantController.isClosed) {
      _plantController.add(activePlant);
    }
    _emitSensorSnapshot();
  }

  void setPlantingDate(DateTime date) {
    _plantingDate = date;
    debugPrint('🌱 DemoDataService: fecha de siembra → $date');
    if (!_plantingDateController.isClosed) {
      _plantingDateController.add(date);
    }
  }

  // ── Pump toggle ──────────────────────────────────────────────────────────

  void togglePump(String pumpId, bool active) {
    final dev = _active;
    // Only toggle pumps this device actually has.
    if (!dev.info.hasActuator(pumpId)) {
      debugPrint('⚠️ DemoDataService: ${dev.id} no tiene $pumpId');
      return;
    }
    switch (pumpId) {
      case 'bomba_agua':
        dev.bombaAgua = active;
      case 'bomba_fertilizante':
        dev.bombaFertilizante = active;
      case 'bomba_dosificadora_acido':
        dev.bombaAcido = active;
      case 'bomba_dosificadora_basico':
        dev.bombaBasico = active;
      default:
        debugPrint('⚠️ DemoDataService: pumpId desconocido: $pumpId');
        return;
    }
    _emitSensorSnapshot();
  }

  // ── Simulation logic ─────────────────────────────────────────────────────

  void _simulateAllDevices() {
    final rng = math.Random();
    for (final dev in _devices.values) {
      _simulateDevice(dev, rng);
    }
    // Only emit the active device's data to the stream.
    _emitSensorSnapshot();
  }

  void _simulateDevice(_DeviceSimState dev, math.Random rng) {
    dev.temperatura += (rng.nextDouble() - 0.5);
    dev.temperatura = dev.temperatura.clamp(18.0, 30.0);

    if (dev.humedadSuelo != null) {
      dev.humedadSuelo = (dev.humedadSuelo! + (rng.nextDouble() - 0.5) * 3)
          .clamp(20.0, 90.0);
    }
    if (dev.humedadAire != null) {
      dev.humedadAire = (dev.humedadAire! + (rng.nextDouble() - 0.5) * 2)
          .clamp(35.0, 85.0);
    }
    if (dev.ph != null) {
      dev.ph = (dev.ph! + (rng.nextDouble() - 0.5) * 0.2).clamp(5.5, 7.5);
    }
    if (dev.conductividad != null) {
      dev.conductividad =
          (dev.conductividad! + (rng.nextDouble() - 0.5) * 100)
              .clamp(800.0, 2200.0);
    }
    if (dev.nivelAguaTanque != null) {
      dev.nivelAguaTanque =
          (dev.nivelAguaTanque! + (rng.nextDouble() - 0.5) * 4)
              .clamp(10.0, 100.0);
    }
    if (dev.nivelFertilizanteTanque != null) {
      dev.nivelFertilizanteTanque =
          (dev.nivelFertilizanteTanque! + (rng.nextDouble() - 0.5) * 4)
              .clamp(10.0, 100.0);
    }

    // Occasionally simulate a low-water alert on full device.
    if (dev.nivelAguaTanque != null) {
      if (rng.nextDouble() < 0.05) {
        dev.nivelAguaBool = false;
      } else if (dev.nivelAguaTanque! > 30) {
        dev.nivelAguaBool = true;
      }
    }
  }

  void _emitSensorSnapshot() {
    if (_sensorController.isClosed) return;
    final dev = _active;
    final map = <String, dynamic>{
      'temperatura': dev.temperatura,
      'conectado': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'bomba_agua': dev.bombaAgua,
    };

    // Only include keys that this device's sensors/actuators support.
    if (dev.humedadSuelo != null) map['humedad_suelo'] = dev.humedadSuelo;
    if (dev.humedadAire != null) map['humedad_aire'] = dev.humedadAire;
    if (dev.ph != null) map['ph'] = dev.ph;
    if (dev.conductividad != null) map['conductividad'] = dev.conductividad;
    if (dev.nivelAguaTanque != null) {
      map['nivel_agua_tanque'] = dev.nivelAguaTanque;
      map['nivel_agua'] = dev.nivelAguaBool;
    }
    if (dev.nivelFertilizanteTanque != null) {
      map['nivel_fertilizante_tanque'] = dev.nivelFertilizanteTanque;
    }
    if (dev.info.hasActuator('bomba_fertilizante')) {
      map['bomba_fertilizante'] = dev.bombaFertilizante;
    }
    if (dev.info.hasActuator('bomba_dosificadora_acido')) {
      map['bomba_dosificadora_acido'] = dev.bombaAcido;
    }
    if (dev.info.hasActuator('bomba_dosificadora_basico')) {
      map['bomba_dosificadora_basico'] = dev.bombaBasico;
    }

    _sensorController.add(SensorData.fromMap(map));
  }

  void _emitHistory() {
    if (_historyController.isClosed) return;
    _historyController.add(List.unmodifiable(_active.history));
  }

  void _appendHistory() {
    if (_historyController.isClosed) return;
    final dev = _active;

    final entry = <String, dynamic>{
      'temperatura': dev.temperatura,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    if (dev.humedadSuelo != null) entry['humedad_suelo'] = dev.humedadSuelo;
    if (dev.humedadAire != null) entry['humedad_aire'] = dev.humedadAire;
    if (dev.ph != null) entry['ph'] = dev.ph;
    if (dev.conductividad != null) entry['conductividad'] = dev.conductividad;
    if (dev.nivelAguaTanque != null) {
      entry['nivel_agua_tanque'] = dev.nivelAguaTanque;
    }
    if (dev.nivelFertilizanteTanque != null) {
      entry['nivel_fertilizante_tanque'] = dev.nivelFertilizanteTanque;
    }

    dev.history.add(entry);
    if (dev.history.length > _maxHistory) {
      dev.history.removeAt(0);
    }

    _historyController.add(List.unmodifiable(dev.history));
  }
}
