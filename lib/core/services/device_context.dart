import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase_constants.dart';

/// Holds the current user's UID and their linked ESP32 device ID.
///
/// Services that read/write device-scoped Firebase paths depend on this
/// to construct paths like `devices/{esp32Id}/sensors/`.
class DeviceContext {
  final String esp32Id;
  final String uid;

  const DeviceContext({required this.esp32Id, required this.uid});
}

/// Reactive provider that resolves the current user's linked ESP32 device.
///
/// Emits:
/// - `null` when no user is signed in or no device is linked
/// - `DeviceContext(esp32Id, uid)` when a device is linked
///
/// All device-scoped service providers watch this to get the esp32Id.
final deviceContextProvider = StreamProvider<DeviceContext?>((ref) {
  final db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: kFirebaseDatabaseUrl,
  );

  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) return Stream.value(null);

    return db.ref('usuarios/${user.uid}/esp32_id').onValue.map((event) {
      final esp32Id = event.snapshot.value as String?;
      if (esp32Id == null || esp32Id.isEmpty) return null;
      return DeviceContext(esp32Id: esp32Id, uid: user.uid);
    });
  });
});
