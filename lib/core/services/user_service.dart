import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase_constants.dart';
import '../retry_policy.dart';

/// Manages the signed-in user's account data at `usuarios/{uid}`.
///
/// Unlike [ProfileService] this is NOT device-scoped: profile edits,
/// preferences and the profile photo must work before any ESP32 is linked.
class UserService {
  late final FirebaseDatabase _db;

  UserService() {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Stream of `usuarios/{uid}`, re-subscribing on sign-in/sign-out.
  Stream<Map<String, dynamic>> get userProfileStream {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(<String, dynamic>{});
      return _db.ref('usuarios/${user.uid}').onValue.map((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
        return Map<String, dynamic>.from(data);
      });
    });
  }

  Future<void> updateUserProfile(String name, String city) async {
    final uid = _uid;
    if (uid == null) return;
    await RetryPolicy.execute(
      () => _db.ref('usuarios/$uid').update({'nombre': name, 'ciudad': city}),
    );
    // Mirror to FirebaseAuth so the name survives outside RTDB (emails,
    // future Firebase-first identity). Best-effort: RTDB stays the source
    // of truth for the app.
    try {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
    } catch (_) {}
  }

  Future<void> updateUserSettings(Map<String, dynamic> settings) {
    final uid = _uid;
    if (uid == null) return Future.value();
    return RetryPolicy.execute(
      () => _db.ref('usuarios/$uid').update(settings),
    );
  }

  // ── Profile photo (Firebase Storage) ──────────────────────────────────────

  /// Uploads the compressed JPEG to `usuarios/{uid}/perfil.jpg`, stores the
  /// tokenized download URL at `usuarios/{uid}/foto_url`, retires the legacy
  /// inline `foto_b64`, and mirrors the URL to FirebaseAuth.
  Future<void> setUserPhoto(Uint8List jpegBytes) async {
    final uid = _uid;
    if (uid == null) return;

    final ref = FirebaseStorage.instance.ref('usuarios/$uid/perfil.jpg');
    await ref.putData(
        jpegBytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();

    await RetryPolicy.execute(
      () => _db.ref('usuarios/$uid').update({
        'foto_url': url,
        'foto_b64': null, // retire the pre-Storage inline photo
      }),
    );
    try {
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);
    } catch (_) {}
  }

  Future<void> removeUserPhoto() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await FirebaseStorage.instance
          .ref('usuarios/$uid/perfil.jpg')
          .delete();
    } catch (_) {
      // Object may not exist (legacy base64-only photo) — keep going.
    }
    await RetryPolicy.execute(
      () => _db.ref('usuarios/$uid').update({
        'foto_url': null,
        'foto_b64': null,
      }),
    );
    try {
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(null);
    } catch (_) {}
  }

  // ── Alert settings ─────────────────────────────────────────────────────────

  Stream<bool> get alertsEnabledStream {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(true);
      return _db
          .ref('usuarios/${user.uid}/alerts_enabled')
          .onValue
          .map((event) => event.snapshot.value as bool? ?? true);
    });
  }

  Future<void> setAlertsEnabled(bool enabled) {
    final uid = _uid;
    if (uid == null) return Future.value();
    return RetryPolicy.execute(
      () => _db.ref('usuarios/$uid/alerts_enabled').set(enabled),
    );
  }

  /// Removes the user's RTDB data before account deletion.
  Future<void> deleteUserData(String uid) async {
    await _db.ref('usuarios/$uid').remove();
  }
}
