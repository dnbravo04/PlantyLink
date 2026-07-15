import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';

/// Freshness of the latest sensor reading, derived from the age of its
/// `timestamp` — NOT from the firmware-written `conectado` boolean, which can
/// never flip back to false if the device dies (see ROADMAP_PRODUCTO.md,
/// Fase 1 "verdad de conexión").
enum DataFreshness {
  /// Last reading is < 5 min old — device is alive.
  live,

  /// Last reading is 5–15 min old — values shown are getting old.
  stale,

  /// Last reading is > 15 min old (or never arrived) — treat as disconnected.
  offline,
}

/// Snapshot of how fresh the current sensor data is.
class DataStaleness {
  final DataFreshness freshness;

  /// Age of the newest reading. [Duration.zero] when no reading exists yet.
  final Duration age;

  /// False when the device never wrote a reading (no timestamp at all) —
  /// distinct from "wrote once and went silent".
  final bool hasData;

  const DataStaleness({
    required this.freshness,
    required this.age,
    required this.hasData,
  });

  bool get isLive => freshness == DataFreshness.live;
  bool get isStale => freshness == DataFreshness.stale;
  bool get isOffline => freshness == DataFreshness.offline;

  int get ageMinutes => age.inMinutes;

  static const none = DataStaleness(
    freshness: DataFreshness.offline,
    age: Duration.zero,
    hasData: false,
  );
}

const _liveThreshold = Duration(minutes: 5);
const _staleThreshold = Duration(minutes: 15);

/// Emits the freshness of the latest sensor reading and re-evaluates every
/// 30 s, so the UI degrades from Live → Stale → Offline even when the device
/// stops emitting (a plain `Provider` would freeze on the last value).
final dataStalenessProvider = StreamProvider<DataStaleness>((ref) {
  // Rebuild (and restart the timer) whenever a new reading lands.
  final timestamp =
      ref.watch(sensorProvider.select((async) => async.value?.timestamp));

  DataStaleness compute() {
    if (timestamp == null) return DataStaleness.none;
    final age = DateTime.now().difference(timestamp);
    final freshness = age < _liveThreshold
        ? DataFreshness.live
        : age < _staleThreshold
            ? DataFreshness.stale
            : DataFreshness.offline;
    return DataStaleness(freshness: freshness, age: age, hasData: true);
  }

  return Stream<DataStaleness>.multi((controller) {
    controller.add(compute());
    final timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => controller.add(compute()),
    );
    controller.onCancel = timer.cancel;
  });
});
