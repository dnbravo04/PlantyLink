import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_constants.dart';
import '../models/plant_profile.dart';

class DemoDataService {
  static final DemoDataService _instance = DemoDataService._internal();
  factory DemoDataService() => _instance;

  late FirebaseDatabase _db;
  Timer? _simulationTimer;
  Timer? _historyTimer;
  bool _isRunning = false;
  bool _isUpdating = false;
  final List<StreamSubscription<DatabaseEvent>> _controlSubscriptions = [];

  // Plantas disponibles (referencia al catálogo centralizado)
  List<PlantProfile> get availablePlants => PlantCatalog.plantas;

  // Estado actual simulado
  double _currentTemp = 24.0;
  double _currentPh = 6.8;
  double _currentConductividad = 1500.0;
  double _currentNivelAgua = 75.0;
  double _currentNivelFertilizante = 60.0;
  bool _currentNivelAguaBool = true;
  bool _currentBombaAgua = false;
  bool _currentBombaFertilizante = false;
  bool _currentBombaAcido = false;
  bool _currentBombaBasico = false;
  final bool _currentConectado = true;

  DemoDataService._internal() {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
  }

  // Inicializar Firebase con datos demo
  Future<void> initializeDemoData() async {
    try {
      // Guardar perfiles de plantas
      final profilesRef = _db.ref('plant_profiles');
      for (int i = 0; i < availablePlants.length; i++) {
        await profilesRef.child(i.toString()).set(availablePlants[i].toMap());
      }

      // Establecer planta activa inicial
      await _db.ref('profile/planta').set(availablePlants[0].nombre);
      await _db.ref('profile/ph_min').set(availablePlants[0].phMin);
      await _db.ref('profile/ph_max').set(availablePlants[0].phMax);
      await _db.ref('profile/temp_min').set(availablePlants[0].tempMin);
      await _db.ref('profile/temp_max').set(availablePlants[0].tempMax);
      await _db.ref('profile/ec_min').set(availablePlants[0].ecMin);
      await _db.ref('profile/ec_max').set(availablePlants[0].ecMax);
      await _db
          .ref('profile/nivel_agua_min')
          .set(availablePlants[0].nivelAguaMin);
      await _db
          .ref('profile/nivel_fertilizante_min')
          .set(availablePlants[0].nivelFertilizanteMin);
      await _db.ref('profile/fuente').set(availablePlants[0].fuente);

      // Inicializar sensores
      await _updateSensors();

      // Inicializar controles
      await _db.ref('controls/bomba_agua').set(false);
      await _db.ref('controls/bomba_fertilizante').set(false);
      await _db.ref('controls/bomba_dosificadora_acido').set(false);
      await _db.ref('controls/bomba_dosificadora_basico').set(false);
      await _db.ref('controls/riego_automatico').set(true);

      debugPrint('✅ Datos demo inicializados en Firebase');
    } catch (e) {
      debugPrint('❌ Error inicializando datos demo: $e');
    }
  }

  // Iniciar simulación de datos cambiantes
  void startSimulation() {
    if (_isRunning) return;
    _isRunning = true;

    // Actualizar sensores cada 3 segundos
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _simulateSensorChanges();
    });

    // Guardar historial cada 10 segundos
    _historyTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _saveToHistory();
    });

    debugPrint('🔄 Simulación iniciada');
  }

  // Detener simulación
  void stopSimulation() {
    _simulationTimer?.cancel();
    _historyTimer?.cancel();
    for (final sub in _controlSubscriptions) {
      sub.cancel();
    }
    _controlSubscriptions.clear();
    _isRunning = false;
    debugPrint('⏹️ Simulación detenida');
  }

  // Simular cambios en los sensores
  void _simulateSensorChanges() async {
    if (_isUpdating) return;
    _isUpdating = true;
    try {
      final random = math.Random();

      // Variar temperatura (±0.5°C)
      _currentTemp += (random.nextDouble() - 0.5);
      _currentTemp = _currentTemp.clamp(18.0, 30.0);

      // Variar pH (±0.1)
      _currentPh += (random.nextDouble() - 0.5) * 0.2;
      _currentPh = _currentPh.clamp(5.5, 7.5);

      // Variar conductividad (±50)
      _currentConductividad += (random.nextDouble() - 0.5) * 100;
      _currentConductividad = _currentConductividad.clamp(800.0, 2200.0);

      // Variar nivel de agua (±2%)
      _currentNivelAgua += (random.nextDouble() - 0.5) * 4;
      _currentNivelAgua = _currentNivelAgua.clamp(10.0, 100.0);

      // Variar nivel de fertilizante (±2%)
      _currentNivelFertilizante += (random.nextDouble() - 0.5) * 4;
      _currentNivelFertilizante = _currentNivelFertilizante.clamp(10.0, 100.0);

      // Simular nivel de agua bajo aleatoriamente
      if (random.nextDouble() < 0.05) {
        _currentNivelAguaBool = false;
      } else if (_currentNivelAgua > 30) {
        _currentNivelAguaBool = true;
      }

      await _updateSensors();
    } finally {
      _isUpdating = false;
    }
  }

  // Actualizar datos en Firebase (escritura atómica)
  Future<void> _updateSensors() async {
    try {
      await _db.ref('sensors').update({
        'temperatura': _currentTemp,
        'nivel_agua_tanque': _currentNivelAgua,
        'nivel_fertilizante_tanque': _currentNivelFertilizante,
        'ph': _currentPh,
        'conductividad': _currentConductividad,
        'nivel_agua': _currentNivelAguaBool,
        'bomba_agua': _currentBombaAgua,
        'bomba_fertilizante': _currentBombaFertilizante,
        'bomba_dosificadora_acido': _currentBombaAcido,
        'bomba_dosificadora_basico': _currentBombaBasico,
        'conectado': _currentConectado,
      });
    } catch (e) {
      debugPrint('❌ Error actualizando sensores: $e');
    }
  }

  // Guardar en historial
  Future<void> _saveToHistory() async {
    try {
      final historyRef = _db.ref('history').push();
      await historyRef.set({
        'temperatura': _currentTemp,
        'ph': _currentPh,
        'conductividad': _currentConductividad,
        'nivel_agua_tanque': _currentNivelAgua,
        'nivel_fertilizante_tanque': _currentNivelFertilizante,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('❌ Error guardando historial: $e');
    }
  }

  // Cambiar planta activa
  Future<void> changePlant(int index) async {
    if (index < 0 || index >= availablePlants.length) return;

    final plant = availablePlants[index];
    await _db.ref('profile/planta').set(plant.nombre);
    await _db.ref('profile/ph_min').set(plant.phMin);
    await _db.ref('profile/ph_max').set(plant.phMax);
    await _db.ref('profile/temp_min').set(plant.tempMin);
    await _db.ref('profile/temp_max').set(plant.tempMax);
    await _db.ref('profile/ec_min').set(plant.ecMin);
    await _db.ref('profile/ec_max').set(plant.ecMax);
    await _db.ref('profile/nivel_agua_min').set(plant.nivelAguaMin);
    await _db
        .ref('profile/nivel_fertilizante_min')
        .set(plant.nivelFertilizanteMin);
    await _db.ref('profile/fuente').set(plant.fuente);

    debugPrint('🌱 Planta cambiada a: ${plant.nombre}');
  }

  // Escuchar cambios en controles (para que los botones funcionen)
  void listenToControls() {
    _controlSubscriptions.add(
      _db.ref('controls/bomba_agua').onValue.listen((event) {
        _currentBombaAgua = event.snapshot.value as bool? ?? false;
      }),
    );
    _controlSubscriptions.add(
      _db.ref('controls/bomba_fertilizante').onValue.listen((event) {
        _currentBombaFertilizante = event.snapshot.value as bool? ?? false;
      }),
    );
    _controlSubscriptions.add(
      _db.ref('controls/bomba_dosificadora_acido').onValue.listen((event) {
        _currentBombaAcido = event.snapshot.value as bool? ?? false;
      }),
    );
    _controlSubscriptions.add(
      _db.ref('controls/bomba_dosificadora_basico').onValue.listen((event) {
        _currentBombaBasico = event.snapshot.value as bool? ?? false;
      }),
    );
  }

  // Obtener stream de historial (últimos 60 registros, orden cronológico ascendente)
  Stream<List<Map<String, dynamic>>> get historyStream {
    return _db.ref('history').limitToLast(60).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Map<String, dynamic>>[];
      final Map<dynamic, dynamic> rawMap = data as Map<dynamic, dynamic>;
      final history = rawMap.values.map((item) {
        final Map<dynamic, dynamic> raw = item as Map<dynamic, dynamic>;
        return raw.map((key, value) => MapEntry(key.toString(), value));
      }).toList();
      history.sort(
        (a, b) => (a['timestamp'] as num).compareTo(b['timestamp'] as num),
      );
      return history;
    });
  }

  // Obtener lista de plantas disponibles
  List<PlantProfile> get plants => PlantCatalog.plantas;
}
