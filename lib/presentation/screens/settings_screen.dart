import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_color_scheme.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_scaffold.dart';
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
    final sensorAsync = ref.watch(sensorProvider);

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
          _buildUserHeader(userAsync, c),
          const SizedBox(height: 20),
          _buildNavTile(
            icon: Icons.person_outline_rounded,
            color: c.info,
            title: 'Perfil y cuenta',
            subtitle: 'Nombre, ciudad, contraseña',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileSettingsScreen())),
            c: c,
          ),
          const SizedBox(height: 8),
          _buildNavTile(
            icon: Icons.eco_rounded,
            color: c.success,
            title: 'Mi cultivo',
            subtitle: profileAsync.when(
              data: (p) => p?.nombre ?? 'Sin configurar',
              loading: () => 'Cargando...',
              error: (_, _) => 'Error',
            ),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CropSettingsScreen())),
            c: c,
          ),
          const SizedBox(height: 8),
          _buildNavTile(
            icon: Icons.palette_outlined,
            color: c.accent,
            title: 'Preferencias',
            subtitle: 'Tema, sensores, notificaciones',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PreferencesScreen())),
            c: c,
          ),
          const SizedBox(height: 8),
          _buildNavTile(
            icon: Icons.memory_rounded,
            color: _deviceColor(sensorAsync, c),
            title: 'Mi dispositivo',
            subtitle: sensorAsync.when(
              data: (s) => (s.conectado ?? false)
                  ? 'ESP32 conectado'
                  : 'ESP32 desconectado',
              loading: () => 'Verificando...',
              error: (_, _) => 'Error de conexión',
            ),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DeviceScreen())),
            c: c,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _deviceColor(AsyncValue sensorAsync, AppColorScheme c) {
    return sensorAsync.whenOrNull(
          data: (s) => (s.conectado ?? false) ? c.success : c.error,
        ) ??
        c.textSecondary;
  }

  Widget _buildUserHeader(
      AsyncValue<Map<String, dynamic>> userAsync, AppColorScheme c) {
    return userAsync.when(
      data: (user) {
        final name = user['nombre']?.toString() ?? '';
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.cardBorder, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.info, c.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
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
                    const SizedBox(height: 2),
                    Text(
                      user['ciudad']?.toString() ?? '',
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          Center(child: CircularProgressIndicator(strokeWidth: 2, color: c.primary)),
      error: (_, _) =>
          Text('Error al cargar perfil', style: TextStyle(color: c.textSecondary)),
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
    return Container(
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      ),
    );
  }
}
