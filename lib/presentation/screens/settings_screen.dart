import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../core/demo_data_service.dart';
import '../../core/services/device_context.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_page_route.dart';
import '../../core/utils/haptics.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/animated_app_card.dart';
import '../widgets/common/user_avatar.dart';
import 'settings/profile_settings_screen.dart';
import 'settings/crop_settings_screen.dart';
import 'settings/preferences_screen.dart';
import 'settings/device_screen.dart';

/// Lightweight settings hub that navigates to focused sub-screens.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final userAsync = ref.watch(userProfileProvider);
    final profileAsync = ref.watch(activePlantProfileProvider);
    final staleness =
        ref.watch(dataStalenessProvider).value ?? DataStaleness.none;

    return AppScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Sistema'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildUserHeader(context, ref, userAsync, c),
          const SizedBox(height: 20),
          AnimatedAppCard(
            delay: 0,
            child: _buildNavTile(
              icon: Icons.person_outline_rounded,
              color: c.info,
              title: 'Perfil y cuenta',
              subtitle: 'Nombre, foto, contraseña',
              onTap: () {
                AppHaptics.light();
                Navigator.push(context,
                    AppPageRoute(builder: (_) => const ProfileSettingsScreen()));
              },
              c: c,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedAppCard(
            delay: 80,
            child: _buildNavTile(
              icon: Icons.eco_rounded,
              color: c.success,
              title: 'Mi cultivo',
              subtitle: profileAsync.when(
                data: (p) => p?.nombre ?? 'Sin configurar',
                loading: () => 'Cargando...',
                error: (_, _) => 'Error',
              ),
              onTap: () {
                AppHaptics.light();
                Navigator.push(context,
                    AppPageRoute(builder: (_) => const CropSettingsScreen()));
              },
              c: c,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedAppCard(
            delay: 160,
            child: _buildNavTile(
              icon: Icons.palette_outlined,
              color: c.accent,
              title: 'Preferencias',
              subtitle: 'Tema, unidades, notificaciones',
              onTap: () {
                AppHaptics.light();
                Navigator.push(context,
                    AppPageRoute(builder: (_) => const PreferencesScreen()));
              },
              c: c,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedAppCard(
            delay: 240,
            child: _buildNavTile(
              icon: Icons.memory_rounded,
              color: _deviceColor(staleness, c),
              title: 'Mi dispositivo',
              subtitle: _deviceSubtitle(ref, staleness),
              onTap: () {
                AppHaptics.light();
                Navigator.push(context,
                    AppPageRoute(builder: (_) => const DeviceScreen()));
              },
              c: c,
            ),
          ),
          const SizedBox(height: 28),
          // Version footer
          Center(
            child: Text(
              'PlantyLink v${ref.watch(appVersionProvider).value ?? '…'}',
              style: TextStyle(fontSize: 11, color: c.textMuted),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _deviceColor(DataStaleness staleness, AppColorScheme c) {
    return switch (staleness.freshness) {
      DataFreshness.live => c.success,
      DataFreshness.stale => c.warning,
      DataFreshness.offline => c.error,
    };
  }

  /// "Invernadero · conectado · 2 vinculados" — active device name, data
  /// freshness state, and device count when more than one is linked.
  String _deviceSubtitle(WidgetRef ref, DataStaleness staleness) {
    final devices = ref.watch(linkedDevicesProvider).value ?? const [];
    final activeId = kDemoMode
        ? ref.watch(demoActiveDeviceProvider).value ?? DemoDataService.kFullDeviceId
        : ref.watch(deviceContextProvider).value?.esp32Id;

    String name = 'ESP32';
    for (final d in devices) {
      if (d.id == activeId) {
        name = d.nombre;
        break;
      }
    }

    final state = switch (staleness.freshness) {
      DataFreshness.live => 'conectado',
      DataFreshness.stale => 'sin datos recientes',
      DataFreshness.offline =>
        staleness.hasData ? 'desconectado' : 'sin datos',
    };

    final count = devices.length > 1 ? ' · ${devices.length} vinculados' : '';
    return '$name · $state$count';
  }

  Widget _buildUserHeader(BuildContext context, WidgetRef ref,
      AsyncValue<Map<String, dynamic>> userAsync, AppColorScheme c) {
    final user = userAsync.value ?? const {};
    final name = user['nombre']?.toString() ?? '';
    final authUser = FirebaseAuth.instance.currentUser;
    // Solo identidad de inicio de sesión — la ciudad no es una identidad y
    // mostrarla aquí era información incorrecta (Eje 5).
    final identity = authUser?.email ?? authUser?.phoneNumber ?? '';
    final experience = ref.watch(experienceProvider);
    final isNovato = experience == 'novato';

    return Material(
      color: c.cardBackground,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          AppHaptics.light();
          Navigator.push(context,
              AppPageRoute(builder: (_) => const ProfileSettingsScreen()));
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.cardBorder, width: 1.5),
          ),
          child: Row(
            children: [
              UserAvatar(user: user, size: 56, radius: 18),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'Usuario',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary),
                    ),
                    if (identity.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        identity,
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isNovato ? c.success : c.info)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isNovato ? Icons.spa_outlined : Icons.science_outlined,
                            size: 12,
                            color: isNovato ? c.success : c.info,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isNovato ? 'Principiante' : 'Avanzado',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isNovato ? c.success : c.info,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required AppColorScheme c,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusLg)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style: TextStyle(
              color: c.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(color: c.textMuted, fontSize: 12)),
      trailing: Icon(Icons.chevron_right_rounded, color: c.textMuted),
      onTap: onTap,
    );
  }
}
