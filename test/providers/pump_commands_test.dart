import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrotracker/domain/repositories/sensor_repository.dart';
import 'package:hydrotracker/models/sensor_data.dart';
import 'package:hydrotracker/presentation/providers/app_providers.dart';

/// Records the pump commands the notifier forwards, and can simulate a
/// transient write failure.
class _FakeRepo implements SensorRepository {
  final List<(String, bool)> toggles = [];
  bool throwOnToggle = false;

  @override
  Future<void> togglePump(String pumpId, bool active) async {
    if (throwOnToggle) throw Exception('write failed');
    toggles.add((pumpId, active));
  }

  @override
  Future<void> setAutoWatering(bool active) async {}

  @override
  Stream<SensorData> get sensorStream => const Stream.empty();

  @override
  Stream<List<SensorData>> get historyStream => const Stream.empty();
}

SensorData _sensor({bool? bombaAgua}) =>
    SensorData(timestamp: DateTime.now(), bombaAgua: bombaAgua);

void main() {
  late StreamController<SensorData> sensors;
  late _FakeRepo repo;
  late ProviderContainer container;

  ProviderContainer build({Duration timeout = const Duration(seconds: 8)}) {
    return ProviderContainer(overrides: [
      sensorProvider.overrideWith((ref) => sensors.stream),
      sensorRepositoryProvider.overrideWith((ref) => repo),
      pumpConfirmTimeoutProvider.overrideWithValue(timeout),
    ]);
  }

  setUp(() {
    sensors = StreamController<SensorData>.broadcast();
    repo = _FakeRepo();
  });

  tearDown(() async {
    container.dispose();
    await sensors.close();
  });

  test('send marks the pump pending and writes the command exactly once',
      () async {
    container = build();
    container.listen(pumpCommandsProvider, (_, _) {}); // keep alive
    await container.read(pumpCommandsProvider.notifier).send('bomba_agua', true);

    expect(container.read(pumpCommandsProvider), {'bomba_agua': true});
    expect(repo.toggles, [('bomba_agua', true)]);
  });

  test('firmware echo on sensors/ clears the pending flag', () async {
    container = build();
    container.listen(pumpCommandsProvider, (_, _) {});
    await container.read(pumpCommandsProvider.notifier).send('bomba_agua', true);

    sensors.add(_sensor(bombaAgua: true)); // firmware confirms
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(container.read(pumpCommandsProvider), isEmpty);
  });

  test('a snapshot that does not match the command keeps it pending', () async {
    container = build();
    container.listen(pumpCommandsProvider, (_, _) {});
    await container.read(pumpCommandsProvider.notifier).send('bomba_agua', true);

    sensors.add(_sensor(bombaAgua: false)); // still off — not confirmed
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(container.read(pumpCommandsProvider), {'bomba_agua': true});
  });

  test('pending auto-clears after the confirm timeout with no echo', () async {
    container = build(timeout: const Duration(milliseconds: 30));
    container.listen(pumpCommandsProvider, (_, _) {});
    await container.read(pumpCommandsProvider.notifier).send('bomba_agua', true);
    expect(container.read(pumpCommandsProvider), isNotEmpty);

    await Future<void>.delayed(const Duration(milliseconds: 70));

    expect(container.read(pumpCommandsProvider), isEmpty);
  });

  test('a failed write drops the pending flag and rethrows', () async {
    repo.throwOnToggle = true;
    container = build();
    container.listen(pumpCommandsProvider, (_, _) {});

    await expectLater(
      container.read(pumpCommandsProvider.notifier).send('bomba_agua', true),
      throwsException,
    );
    expect(container.read(pumpCommandsProvider), isEmpty);
  });
}
