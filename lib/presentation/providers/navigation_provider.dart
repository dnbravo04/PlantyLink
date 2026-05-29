import 'package:flutter_riverpod/flutter_riverpod.dart';

class _TabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

/// Controls which tab is active in the main shell bottom navigation.
final selectedTabIndexProvider =
    NotifierProvider<_TabIndexNotifier, int>(_TabIndexNotifier.new);
