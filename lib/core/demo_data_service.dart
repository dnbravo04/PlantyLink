import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/plant_profile.dart';
import '../models/sensor_data.dart';

/// Simulates hydroponics sensor data entirely in memory.
///
/// No Firebase reads or writes ever happen here. All data is generated
/// locally and emitted through [sensorStream], [historyStream], and
/// [activePlantStream]. Use this service only as a development/demo fallback
/// — never alongside active Firebase writes.
class DemoDataService {
  static final DemoDataService _instance = DemoDataService._internal();
  factory DemoDataService() => _instance;

  // ── Stream controllers ───────────────────────────────────────────────────
  final _sensorController = StreamController<SensorData>.broadcast();
  final _historyController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  // Emits whenever the active plant changes.
  final _plantController = StreamController<PlantProfile>.broadcast();
  // Emits whenever the crop's planting date changes.
  final _plantingDateController = StreamController<DateTime>.broadcast();

  // ── Timers ───────────────────────────────────────────────────────────────
  Timer? _simulationTimer;
  Timer? _historyTimer;
  bool _isRunning = false;

  // ── In-memory sensor state ───────────────────────────────────────────────
  double _currentTemp = 24.0;
  double _currentPh = 6.8;
  double _currentConductividad = 1500.0;
  double _currentNivelAgua = 75.0;
  double _currentNivelFertilizante = 60.0;
  double _currentHumedadSuelo = 55.0; // cultivo en tierra
  double _currentHumedadAire = 60.0; // DHT22
  bool _currentNivelAguaBool = true;
  bool _currentBombaAgua = false;
  bool _currentBombaFertilizante = false;
  bool _currentBombaAcido = false;
  bool _currentBombaBasico = false;

  // ── In-memory history (max 60 entries, mirrors Firebase limitToLast(60)) ─
  final List<Map<String, dynamic>> _history = [];
  static const int _maxHistory = 60;

  // ── Plant catalogue ──────────────────────────────────────────────────────
  List<PlantProfile> get availablePlants => PlantCatalog.plantas;
  List<PlantProfile> get plants => PlantCatalog.plantas;

  // Active plant index — kept in memory only.
  int _activePlantIndex = 0;
  PlantProfile get activePlant => availablePlants[_activePlantIndex];

  // Planting date — kept in memory only. Defaults to ~30 days ago so the demo
  // starts in the vegetative stage with meaningful recommendations.
  DateTime _plantingDate = DateTime.now().subtract(const Duration(days: 30));

  DemoDataService._internal();

  // ── Public streams ───────────────────────────────────────────────────────

  /// Emits a new [SensorData] snapshot every time the simulator ticks.
  Stream<SensorData> get sensorStream => _sensorController.stream;

  /// Emits the full in-memory history list (chronological) on every new entry.
  Stream<List<Map<String, dynamic>>> get historyStream =>
      _historyController.stream;

  /// Emits the active [PlantProfile] whenever it changes.
  ///
  /// Subscribers also receive the current value immediately via [Stream.multi]
  /// so they don't miss the initial plant even if they subscribe after
  /// [startSimulation] was called.
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

  /// Emits the crop's planting date, delivering the current value immediately
  /// to new subscribers (same pattern as [activePlantStream]).
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

  /// Starts the in-memory simulation. Safe to call multiple times.
  void startSimulation() {
    if (_isRunning) return;
    _isRunning = true;

    // Emit an immediate snapshot so the UI has data before the first tick.
    _emitSensorSnapshot();

    // Sensor tick every 3 s
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _simulateSensorChanges();
    });

    // History entry every 10 s
    _historyTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _appendHistory();
    });

    debugPrint('🔄 DemoDataService: simulação iniciada (solo en memoria)');
  }

  /// Stops all timers and closes the stream controllers.
  void stopSimulation() {
    _simulationTimer?.cancel();
    _historyTimer?.cancel();
    _simulationTimer = null;
    _historyTimer = null;
    _isRunning = false;
    debugPrint('⏹️ DemoDataService: simulación detenida');
  }

  /// Releases resources. Call when the service is no longer needed.
  void dispose() {
    stopSimulation();
    _sensorController.close();
    _historyController.close();
    _plantController.close();
    _plantingDateController.close();
  }

  // ── Plant management (in-memory only) ────────────────────────────────────

  /// Switches the active plant profile. Has no effect on Firebase.
  void changePlant(int index) {
    if (index < 0 || index >= availablePlants.length) return;
    _activePlantIndex = index;
    debugPrint('🌱 DemoDataService: planta activa → ${activePlant.nombre}');
    if (!_plantController.isClosed) {
      _plantController.add(activePlant);
    }
    // Emit a fresh snapshot so listeners reflect the new profile immediately.
    _emitSensorSnapshot();
  }

  /// Updates the crop's planting date. Has no effect on Firebase.
  void setPlantingDate(DateTime date) {
    _plantingDate = date;
    debugPrint('🌱 DemoDataService: fecha de siembra → $date');
    if (!_plantingDateController.isClosed) {
      _plantingDateController.add(date);
    }
  }

  // ── Pump toggle (in-memory only) ─────────────────────────────────────────

  /// Simulates toggling a pump. State is kept in memory only.
  void togglePump(String pumpId, bool active) {
    switch (pumpId) {
      case 'bomba_agua':
        _currentBombaAgua = active;
      case 'bomba_fertilizante':
        _currentBombaFertilizante = active;
      case 'bomba_dosificadora_acido':
        _currentBombaAcido = active;
      case 'bomba_dosificadora_basico':
        _currentBombaBasico = active;
      default:
        debugPrint('⚠️ DemoDataService: pumpId desconocido: $pumpId');
        return;
    }
    _emitSensorSnapshot();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _simulateSensorChanges() {
    final rng = math.Random();

    _currentTemp += (rng.nextDouble() - 0.5);
    _currentTemp = _currentTemp.clamp(18.0, 30.0);

    _currentPh += (rng.nextDouble() - 0.5) * 0.2;
    _currentPh = _currentPh.clamp(5.5, 7.5);

    _currentConductividad += (rng.nextDouble() - 0.5) * 100;
    _currentConductividad = _currentConductividad.clamp(800.0, 2200.0);

    _currentNivelAgua += (rng.nextDouble() - 0.5) * 4;
    _currentNivelAgua = _currentNivelAgua.clamp(10.0, 100.0);

    _currentNivelFertilizante += (rng.nextDouble() - 0.5) * 4;
    _currentNivelFertilizante = _currentNivelFertilizante.clamp(10.0, 100.0);

    _currentHumedadSuelo += (rng.nextDouble() - 0.5) * 3;
    _currentHumedadSuelo = _currentHumedadSuelo.clamp(20.0, 90.0);

    _currentHumedadAire += (rng.nextDouble() - 0.5) * 2;
    _currentHumedadAire = _currentHumedadAire.clamp(35.0, 85.0);

    // Occasionally simulate a low-water alert
    if (rng.nextDouble() < 0.05) {
      _currentNivelAguaBool = false;
    } else if (_currentNivelAgua > 30) {
      _currentNivelAguaBool = true;
    }

    _emitSensorSnapshot();
  }

  void _emitSensorSnapshot() {
    if (_sensorController.isClosed) return;
    _sensorController.add(
      SensorData.fromMap({
        'temperatura': _currentTemp,
        'humedad_suelo': _currentHumedadSuelo,
        'humedad_aire': _currentHumedadAire,
        'ph': _currentPh,
        'conductividad': _currentConductividad,
        'nivel_agua_tanque': _currentNivelAgua,
        'nivel_fertilizante_tanque': _currentNivelFertilizante,
        'nivel_agua': _currentNivelAguaBool,
        'bomba_agua': _currentBombaAgua,
        'bomba_fertilizante': _currentBombaFertilizante,
        'bomba_dosificadora_acido': _currentBombaAcido,
        'bomba_dosificadora_basico': _currentBombaBasico,
        'conectado': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }),
    );
  }

  void _appendHistory() {
    if (_historyController.isClosed) return;

    final entry = <String, dynamic>{
      'temperatura': _currentTemp,
      'humedad_suelo': _currentHumedadSuelo,
      'humedad_aire': _currentHumedadAire,
      'ph': _currentPh,
      'conductividad': _currentConductividad,
      'nivel_agua_tanque': _currentNivelAgua,
      'nivel_fertilizante_tanque': _currentNivelFertilizante,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _history.add(entry);
    // Keep list bounded, drop oldest entries
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    }

    _historyController.add(List.unmodifiable(_history));
  }
}
