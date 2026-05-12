import '../../core/firebase_service.dart';
import '../../core/demo_data_service.dart';
import '../../models/sensor_data.dart';
import '../../domain/repositories/sensor_repository.dart';

/// Implementation of [SensorRepository] that delegates to Firebase.
///
/// The [DemoDataService] is kept as a reference so the app can continue
/// to initialize demo data on startup, but all reads go through the
/// real-time Firebase streams.
class SensorRepositoryImpl implements SensorRepository {
  final FirebaseService _firebase;
  final DemoDataService? _demo;

  SensorRepositoryImpl({
    required FirebaseService firebaseService,
    DemoDataService? demoService,
  })  : _firebase = firebaseService,
        _demo = demoService;

  @override
  Stream<SensorData> get sensorStream => _firebase.sensorStream;

  @override
  Stream<List<SensorData>> get historyStream {
    // Prefer demo service history if available; otherwise fallback to empty.
    final rawStream = _demo?.historyStream ??
        _firebase.sensorStream.map((_) => <Map<String, dynamic>>[]);

    return rawStream.map((list) {
      return list.map((map) => SensorData.fromMap(map)).toList();
    });
  }

  @override
  Future<void> togglePump(String pumpId, bool active) async {
    switch (pumpId) {
      case 'bomba_agua':
        await _firebase.controlarBombaAgua(active);
      case 'bomba_fertilizante':
        await _firebase.controlarBombaFertilizante(active);
      case 'bomba_dosificadora_acido':
        await _firebase.controlarDosificadoraAcido(active);
      case 'bomba_dosificadora_basico':
        await _firebase.controlarDosificadoraBasico(active);
      default:
        throw ArgumentError('Unknown pumpId: $pumpId');
    }
  }

  @override
  Future<void> setAutoWatering(bool active) async {
    await _firebase.activarRiegoAutomatico(active);
  }
}
