import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../providers/navigation_provider.dart';
import '../providers/trend_alert_provider.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// Main app shell with bottom navigation bar.
/// 3 tabs: Monitor, Historial, Sistema.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = [
    DashboardScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabIndexProvider);
    final hasActiveAlerts = ref.watch(trendAlertProvider).alerts.isNotEmpty;
    final isOnline = ref.watch(connectivityProvider).value ?? true;

    return Scaffold(
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isOnline
                ? const SizedBox.shrink()
                : _OfflineBanner(key: const ValueKey('offline')),
          ),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(selectedTabIndexProvider.notifier).select(index);
        },
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: hasActiveAlerts,
              child: const Icon(Icons.dashboard_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: hasActiveAlerts,
              child: const Icon(Icons.dashboard_rounded),
            ),
            label: 'Monitor',
          ),
          const NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart_rounded),
            label: 'Historial',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Sistema',
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.shade800,
      child: const SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sin conexión — mostrando datos en caché',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
