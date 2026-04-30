import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_constants.dart';
import '../models/sensor_data.dart';
import '../models/plant_profile.dart';

class FirebaseService {
  late FirebaseDatabase _db;

  FirebaseService() {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
  }

  // Stream de sensores en tiempo real
  Stream<SensorData> get sensorStream {
    return _db.ref('sensors').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return SensorData.fromMap(data);
    });
  }

  // Stream de planta activa
  Stream<String> get plantaActivaStream {
    return _db.ref('profile/planta').onValue.map((event) {
      return event.snapshot.value as String? ?? 'Sin configurar';
    });
  }

  // Stream de umbrales
  Stream<Map<dynamic, dynamic>> get thresholdsStream {
    return _db.ref('profile').onValue.map((event) {
      return event.snapshot.value as Map<dynamic, dynamic>? ?? {};
    });
  }

  // Control de bomba de agua
  Future<void> controlarBombaAgua(bool estado) async {
    await _db.ref('controls/bomba_agua').set(estado);
  }

  // Control de bomba de fertilizante
  Future<void> controlarBombaFertilizante(bool estado) async {
    await _db.ref('controls/bomba_fertilizante').set(estado);
  }

  // Control de dosificadora de ácido
  Future<void> controlarDosificadoraAcido(bool estado) async {
    await _db.ref('controls/bomba_dosificadora_acido').set(estado);
  }

  // Control de dosificadora básico
  Future<void> controlarDosificadoraBasico(bool estado) async {
    await _db.ref('controls/bomba_dosificadora_basico').set(estado);
  }

  // Control automático de riego
  Future<void> activarRiegoAutomatico(bool estado) async {
    await _db.ref('controls/riego_automatico').set(estado);
  }

  // Activar perfil de planta
  Future<void> activarPerfil(PlantProfile perfil) async {
    await _db.ref('profile').set(perfil.toMap());
  }

  // Registro NFC
  Future<void> registrarNFC(String usuario, int nivel) async {
    await _db.ref('nfc/registros').push().set({
      'usuario': usuario,
      'nivel': nivel,
      'timestamp': ServerValue.timestamp,
    });
  }
}
