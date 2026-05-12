import '../../core/firebase_service.dart';
import '../../core/demo_data_service.dart';
import '../../models/plant_profile.dart';
import '../../domain/repositories/plant_repository.dart';

/// Implementation of [PlantRepository] backed by Firebase.
class PlantRepositoryImpl implements PlantRepository {
  final FirebaseService _firebase;
  final DemoDataService? _demo;

  PlantRepositoryImpl({
    required FirebaseService firebaseService,
    DemoDataService? demoService,
  })  : _firebase = firebaseService,
        _demo = demoService;

  @override
  Stream<String> get activePlantNameStream => _firebase.plantaActivaStream;

  @override
  Stream<PlantProfile?> get activePlantProfileStream {
    return _firebase.thresholdsStream.map((map) {
      if (map.isEmpty) return null;
      try {
        return PlantProfile.fromMap(map);
      } catch (_) {
        return null;
      }
    });
  }

  @override
  List<PlantProfile> get availablePlants {
    return _demo?.availablePlants ?? PlantCatalog.plantas;
  }

  @override
  Future<void> selectPlant(PlantProfile plant) async {
    await _firebase.activarPerfil(plant);
  }

  @override
  Future<void> updateThresholds(Map<String, dynamic> thresholds) async {
    await _firebase.updateProfileThresholds(thresholds);
  }
}
