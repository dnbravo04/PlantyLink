import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../providers/app_providers.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/app_scaffold.dart';

/// Preferences: theme, visualization mode, active sensors, notifications.
class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  List<String> _activeSensors = [
    'temperatura', 'ph', 'conductividad',
    'nivel_agua_tanque', 'nivel_fertilizante_tanque',
  ];
  bool _initialized = false;

  Future<void> _saveActiveSensors() async {
    try {
      await ref
          .read(userServiceProvider)
          ?.updateUserSettings({'sensores_activos': _activeSensors});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar sensores')));
      }
    }
  }

  void _toggleSensor(String sensorKey) {
    setState(() {
      if (_activeSensors.contains(sensorKey)) {
        _activeSensors.remove(sensorKey);
      } else {
        _activeSensors.add(sensorKey);
      }
    });
    _saveActiveSensors();
  }

  Future<void> _toggleAlerts(bool enabled) async {
    try {
      await ref.read(userServiceProvider)?.setAlertsEnabled(enabled);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al cambiar alertas')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final alertsAsync = ref.watch(alertsEnabledProvider);

    // Seed local state from the profile's current value. A ref.listen would
    // miss it: the provider is usually alive (dashboard watches it), so no
    // new emission arrives after this screen opens.
    final user = ref.watch(userProfileProvider).value;
    if (!_initialized && user != null) {
      _initialized = true;
      final sensors = user['sensores_activos'] as List<dynamic>?;
      if (sensors != null) _activeSensors = sensors.cast<String>();
    }

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Preferencias'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionTitle('Apariencia', c),
          const SizedBox(height: 8),
          _buildThemeCard(c),
          const SizedBox(height: 24),
          _buildSectionTitle('Nivel de experiencia', c),
          const SizedBox(height: 8),
          _buildExperienceCard(c),
          const SizedBox(height: 24),
          _buildSectionTitle('Modo de visualización', c),
          const SizedBox(height: 8),
          _buildVisualizationModeCard(c),
          const SizedBox(height: 24),
          _buildSectionTitle('Unidades', c),
          const SizedBox(height: 8),
          _buildUnitsCard(c),
          const SizedBox(height: 24),
          _buildSectionTitle('Sensores activos', c),
          const SizedBox(height: 8),
          _buildActiveSensorsCard(c),
          const SizedBox(height: 24),
          _buildSectionTitle('Notificaciones', c),
          const SizedBox(height: 8),
          _buildAlertsCard(alertsAsync, c),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppColorScheme c) {
    return Text(title,
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary));
  }

  Widget _buildThemeCard(AppColorScheme c) {
    final themeMode = ref.watch(themeModeProvider);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder, width: 1.5),
      ),
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
              value: ThemeMode.system,
              label: Text('Sistema'),
              icon: Icon(Icons.brightness_auto_rounded, size: 16)),
          ButtonSegment(
              value: ThemeMode.light,
              label: Text('Claro'),
              icon: Icon(Icons.light_mode_rounded, size: 16)),
          ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Oscuro'),
              icon: Icon(Icons.dark_mode_rounded, size: 16)),
        ],
        selected: {themeMode},
        onSelectionChanged: (modes) =>
            ref.read(themeModeProvider.notifier).set(modes.first),
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildExperienceCard(AppColorScheme c) {
    final experience = ref.watch(experienceProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeOption(
              label: 'Principiante',
              icon: Icons.spa_outlined,
              selected: experience == 'novato',
              color: c.success,
              c: c,
              onTap: () =>
                  ref.read(experienceProvider.notifier).set('novato'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModeOption(
              label: 'Avanzado',
              icon: Icons.science_outlined,
              selected: experience == 'avanzado',
              color: c.info,
              c: c,
              onTap: () =>
                  ref.read(experienceProvider.notifier).set('avanzado'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsCard(AppColorScheme c) {
    final units = ref.watch(unitsProvider);
    final notifier = ref.read(unitsProvider.notifier);

    Widget row(String label, List<(String, bool)> options,
        void Function(bool) onChanged, bool current) {
      return Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 14, color: c.textPrimary)),
          ),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            segments: [
              for (final (text, value) in options)
                ButtonSegment(value: value, label: Text(text)),
            ],
            selected: {current},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        children: [
          row('Temperatura', [('°C', false), ('°F', true)],
              notifier.setFahrenheit, units.fahrenheit),
          const SizedBox(height: 12),
          row('Conductividad', [('mS/cm', false), ('µS/cm', true)],
              notifier.setMicroSiemens, units.microSiemens),
        ],
      ),
    );
  }

  Widget _buildVisualizationModeCard(AppColorScheme c) {
    final mode = ref.watch(visualizationModeProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeOption(
              label: 'Vista Técnica',
              icon: Icons.speed_outlined,
              selected: mode == 'tecnica',
              color: c.info,
              c: c,
              onTap: () =>
                  ref.read(visualizationModeProvider.notifier).set('tecnica'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModeOption(
              label: 'Vista Sencilla',
              icon: Icons.visibility_outlined,
              selected: mode == 'sencilla',
              color: c.success,
              c: c,
              onTap: () =>
                  ref.read(visualizationModeProvider.notifier).set('sencilla'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSensorsCard(AppColorScheme c) {
    const sensors = [
      {'key': 'temperatura', 'label': 'Temperatura', 'icon': Icons.thermostat_outlined},
      {'key': 'ph', 'label': 'pH', 'icon': Icons.science_outlined},
      {'key': 'conductividad', 'label': 'Conductividad', 'icon': Icons.electric_bolt_outlined},
      {'key': 'nivel_agua_tanque', 'label': 'Nivel Agua', 'icon': Icons.water_drop_outlined},
      {'key': 'nivel_fertilizante_tanque', 'label': 'Nivel Fertilizante', 'icon': Icons.eco_outlined},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        children: sensors
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Icon(s['icon'] as IconData, color: c.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(s['label'] as String,
                            style: TextStyle(fontSize: 14, color: c.textPrimary))),
                    Switch(
                      value: _activeSensors.contains(s['key']),
                      onChanged: (_) => _toggleSensor(s['key'] as String),
                      activeThumbColor: c.success,
                    ),
                  ]),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildAlertsCard(AsyncValue<bool> alertsAsync, AppColorScheme c) {
    final enabled = alertsAsync.value ?? true;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
                enabled ? Icons.notifications_active : Icons.notifications_off,
                color: c.warning,
                size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notificaciones',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary)),
                const SizedBox(height: 2),
                Text('Alertas de sensores',
                    style: TextStyle(fontSize: 12, color: c.textSecondary)),
              ],
            ),
          ),
          Switch(
              value: enabled,
              onChanged: _toggleAlerts,
              activeThumbColor: c.warning),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final AppColorScheme c;
  final VoidCallback onTap;

  const _ModeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.c,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : c.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : c.cardBorder),
        ),
        child: Row(children: [
          Icon(icon,
              color: selected ? color : c.textSecondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: selected ? color : c.textPrimary,
                    fontWeight: FontWeight.w500)),
          ),
        ]),
      ),
    );
  }
}
