import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_constants.dart';

/// Manages two Firebase RTDB paths for the plant catalog:
///
/// - `cached/plants/{perenualId}/` — API response cache with a 30-day TTL.
///   Avoids redundant Perenual API calls across app restarts.
///
/// - `usuarios/{uid}/plants/` — The current user's saved plant catalog.
///   Each entry is a [PlantProfile.toMap()] payload, optionally extended
///   with a `perenual_id` key.
class CatalogService {
  static const int _cacheTTLDays = 30;

  late final FirebaseDatabase _db;

  CatalogService() {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
  }

  // ── API cache ──────────────────────────────────────────────────────────────

  /// Returns the cached [PerenualSpeciesDetail] JSON for [perenualId], or
  /// `null` if no cache entry exists or it has expired.
  Future<Map<String, dynamic>?> getCachedSpecies(int perenualId) async {
    final snap = await _db.ref('cached/plants/$perenualId').get();
    if (!snap.exists) return null;
    final entry = snap.value as Map<dynamic, dynamic>?;
    if (entry == null) return null;

    final cachedAtMs = entry['cached_at'] as int?;
    if (cachedAtMs == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - cachedAtMs;
    if (age > const Duration(days: _cacheTTLDays).inMilliseconds) return null;

    final data = entry['data'];
    if (data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }

  /// Stores [data] (a [PerenualSpeciesDetail.toJson()] map) under
  /// `cached/plants/{perenualId}/` with the current timestamp.
  Future<void> cacheSpecies(int perenualId, Map<String, dynamic> data) async {
    await _db.ref('cached/plants/$perenualId').set({
      'cached_at': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    });
  }

  // ── User catalog ───────────────────────────────────────────────────────────

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Live stream of the authenticated user's saved plant catalog entries.
  /// Each element is a raw map suitable for passing to [PlantProfile.fromMap].
  Stream<List<Map<String, dynamic>>> get userCatalogStream {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _db.ref('usuarios/$uid/plants').onValue.map((event) {
      final raw = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return raw.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    });
  }

  /// Appends [plantData] (a [PlantProfile.toMap()] + optional `perenual_id`)
  /// to the user's plant catalog. Silently no-ops when not authenticated.
  Future<void> savePlantToCatalog(Map<String, dynamic> plantData) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.ref('usuarios/$uid/plants').push().set(plantData);
  }

  /// Removes the first catalog entry whose `planta` field equals [nombre].
  Future<void> removePlantFromCatalog(String nombre) async {
    final uid = _uid;
    if (uid == null) return;
    final snap = await _db.ref('usuarios/$uid/plants').get();
    if (!snap.exists) return;
    final raw = snap.value as Map<dynamic, dynamic>? ?? {};
    for (final entry in raw.entries) {
      final val = entry.value;
      if (val is Map && val['planta'] == nombre) {
        await _db.ref('usuarios/$uid/plants/${entry.key}').remove();
        return;
      }
    }
  }
}
