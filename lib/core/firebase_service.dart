import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/sensor_data.dart';
import '../models/plant_profile.dart';

class FirebaseService {
  late FirebaseDatabase _db;

  FirebaseService() {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://hydrotrack-13047.firebaseio.com',
    );
  }

  // Stream de sensores en tiempo real
  Stream<SensorData> get sensorStream {
    return _db
        .ref('sensors')
        .onValue
        .map((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
          return SensorData.fromMap(data);
        })
        .timeout(
          const Duration(seconds: 10),
          onTimeout: (sink) {
            sink.add(
              SensorData(
                temperatura: 0.0,
                humedad: 0.0,
                nivelAgua: false,
                timestamp: DateTime.now(),
              ),
            );
          },
        );
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

  // Control de bomba
  Future<void> activarBomba() async {
    await _db.ref('pump/manual').set(true);
    await Future.delayed(const Duration(seconds: 11));
    await _db.ref('pump/manual').set(false);
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
