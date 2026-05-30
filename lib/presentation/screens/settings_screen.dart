import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../models/plant_profile.dart';
import '../../models/sensor_data.dart';
import '../providers/app_providers.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/common/app_scaffold.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isEditingName = false;
  bool _isEditingCity = false;

  // Threshold sliders — initialized once from Firebase on first load.
  double _tempMin = 18;
  double _tempMax = 26;
  double _phMin = 5.5;
  double _phMax = 6.5;
  double _ecMin = 1.0;
  double _ecMax = 2.0;
  bool _thresholdInitialized = false;

  // User settings — initialized once from Firebase on first load.
  String _visualizationMode = 'tecnica';
  List<String> _activeSensors = [
    'temperatura',
    'ph',
    'conductividad',
    'nivel_agua_tanque',
    'nivel_fertilizante_tanque',
  ];
  bool _profileSettingsInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveUserProfile() async {
    try {
      await ref.read(profileServiceProvider).updateUserProfile(
            _nameController.text.trim(),
            _cityController.text.trim(),
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar perfil')),
        );
      }
    }
  }

  Future<void> _toggleAlerts(bool enabled) async {
    try {
      await ref.read(profileServiceProvider).setAlertsEnabled(enabled);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cambiar alertas')),
        );
      }
    }
  }

  Future<void> _saveVisualizationMode(String mode) async {
    setState(() => _visualizationMode = mode);
    try {
      await ref
          .read(profileServiceProvider)
          .updateUserSettings({'modo_visualizacion': mode});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar modo de visualización')),
        );
      }
    }
  }

  Future<void> _saveActiveSensors() async {
    try {
      await ref
          .read(profileServiceProvider)
          .updateUserSettings({'sensores_activos': _activeSensors});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar sensores')),
        );
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

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dc = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: dc.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Cerrar sesión',
            style: TextStyle(color: dc.textPrimary, fontSize: 18),
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(color: dc.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancelar',
                style: TextStyle(color: dc.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Cerrar sesión',
                style: TextStyle(color: dc.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/onboarding/vinculacion',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final userAsync = ref.watch(userProfileProvider);
    final profileAsync = ref.watch(activePlantProfileProvider);
    final alertsAsync = ref.watch(alertsEnabledProvider);
    final sensorAsync = ref.watch(sensorProvider);

    // Initialize threshold sliders once, the first time the profile loads.
    ref.listen<AsyncValue<PlantProfile?>>(activePlantProfileProvider,
        (_, next) {
      next.whenData((profile) {
        if (profile != null && !_thresholdInitialized) {
          setState(() {
            _thresholdInitialized = true;
            _tempMin = profile.tempMin;
            _tempMax = profile.tempMax;
            _phMin = profile.phMin;
            _phMax = profile.phMax;
            _ecMin = profile.ecMin;
            _ecMax = profile.ecMax;
          });
        }
      });
    });

    // Initialize user-preference fields once, on first load.
    ref.listen<AsyncValue<Map<String, dynamic>>>(userProfileProvider,
        (_, next) {
      next.whenData((user) {
        if (!_profileSettingsInitialized) {
          final viz = user['modo_visualizacion'] as String? ?? 'tecnica';
          final sensors = user['sensores_activos'] as List<dynamic>?;
          setState(() {
            _profileSettingsInitialized = true;
            _visualizationMode = viz;
            if (sensors != null) {
              _activeSensors = sensors.cast<String>();
            }
          });
          if (!_isEditingName) {
            _nameController.text = user['nombre']?.toString() ?? '';
          }
          if (!_isEditingCity) {
            _cityController.text = user['ciudad']?.toString() ?? '';
          }
        }
      });
    });

    return AppScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Configuración'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _buildSectionTitle('Perfil de usuario', c),
            const SizedBox(height: 8),
            _buildProfileCard(userAsync, c),
            const SizedBox(height: 24),

            _buildSectionTitle('Cultivo activo', c),
            const SizedBox(height: 8),
            _buildActivePlantCard(profileAsync, c),
            const SizedBox(height: 24),

            _buildSectionTitle('Umbrales personalizados', c),
            const SizedBox(height: 8),
            _buildThresholdsCard(profileAsync, c),
            const SizedBox(height: 24),

            _buildSectionTitle('Sensores activos', c),
            const SizedBox(height: 8),
            _buildActiveSensorsCard(c),
            const SizedBox(height: 24),

            _buildSectionTitle('Modo de visualización', c),
            const SizedBox(height: 8),
            _buildVisualizationModeCard(c),
            const SizedBox(height: 24),

            _buildSectionTitle('Apariencia', c),
            const SizedBox(height: 8),
            _buildThemeCard(c),
            const SizedBox(height: 24),

            _buildSectionTitle('Notificaciones', c),
            const SizedBox(height: 8),
            _buildAlertsCard(alertsAsync, c),
            const SizedBox(height: 24),

            _buildSectionTitle('Sistema', c),
            const SizedBox(height: 8),
            _buildSystemCard(sensorAsync, c),
            const SizedBox(height: 24),

            _buildSectionTitle('Cuenta', c),
            const SizedBox(height: 8),
            _buildSignOutButton(c),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppColorScheme c) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
    );
  }

  Widget _buildProfileCard(
    AsyncValue<Map<String, dynamic>> userAsync,
    AppColorScheme c,
  ) {
    return userAsync.when(
      data: (user) {
        final name = _nameController.text.isNotEmpty
            ? _nameController.text
            : user['nombre']?.toString() ?? '';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                c.cardBackground,
                c.cardBackground.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: c.cardBorder.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.info, c.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: c.info.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildEditableRow(
                label: 'Nombre',
                controller: _nameController,
                isEditing: _isEditingName,
                onEdit: () => setState(() => _isEditingName = true),
                onSave: () {
                  setState(() => _isEditingName = false);
                  _saveUserProfile();
                },
                c: c,
              ),
              const SizedBox(height: 12),
              _buildEditableRow(
                label: 'Ciudad',
                controller: _cityController,
                isEditing: _isEditingCity,
                onEdit: () => setState(() => _isEditingCity = true),
                onSave: () {
                  setState(() => _isEditingCity = false);
                  _saveUserProfile();
                },
                c: c,
              ),
            ],
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
      ),
      error: (_, _) => Text(
        'Error al cargar perfil',
        style: TextStyle(color: c.textSecondary),
      ),
    );
  }

  Widget _buildEditableRow({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required AppColorScheme c,
  }) {
    return Row(
      children: [
        Expanded(
          child: isEditing
              ? TextField(
                  controller: controller,
                  style: TextStyle(color: c.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: TextStyle(color: c.textSecondary, fontSize: 12),
                    filled: true,
                    fillColor: c.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.cardBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  autofocus: true,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 11, color: c.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.text.isEmpty ? '—' : controller.text,
                      style: TextStyle(fontSize: 14, color: c.textPrimary),
                    ),
                  ],
                ),
        ),
        IconButton(
          icon: Icon(
            isEditing ? Icons.check : Icons.edit,
            color: isEditing ? c.success : c.textSecondary,
            size: 18,
          ),
          onPressed: isEditing ? onSave : onEdit,
        ),
      ],
    );
  }

  Widget _buildActivePlantCard(
    AsyncValue<PlantProfile?> profileAsync,
    AppColorScheme c,
  ) {
    return profileAsync.when(
      data: (profile) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                c.cardBackground,
                c.cardBackground.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: c.cardBorder.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      c.success.withValues(alpha: 0.2),
                      c.success.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: c.success.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    profile?.emoji ?? '🌱',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.nombre ?? 'Sin configurar',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: c.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Planta activa',
                          style: TextStyle(
                            fontSize: 12,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => ref.read(selectedTabIndexProvider.notifier).select(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        c.info.withValues(alpha: 0.15),
                        c.info.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: c.info.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'Cambiar',
                    style: TextStyle(
                      color: c.info,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
      ),
      error: (_, _) => Text(
        'Error al cargar cultivo',
        style: TextStyle(color: c.textSecondary),
      ),
    );
  }

  Widget _buildThresholdsCard(
    AsyncValue<PlantProfile?> profileAsync,
    AppColorScheme c,
  ) {
    if (!_thresholdInitialized) {
      return profileAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
        ),
        error: (_, _) => Text(
          'Error al cargar umbrales',
          style: TextStyle(color: c.textSecondary),
        ),
        data: (profile) {
          if (profile == null) {
            return Text(
              'No hay cultivo activo para mostrar umbrales.',
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            );
          }
          return Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            c.cardBackground,
            c.cardBackground.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: c.cardBorder.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildThresholdSlider(
            label: 'Temperatura (°C)',
            icon: Icons.thermostat,
            color: c.warning,
            min: _tempMin,
            max: _tempMax,
            absMin: 0,
            absMax: 50,
            onChanged: (min, max) => setState(() {
              _tempMin = min;
              _tempMax = max;
            }),
            c: c,
          ),
          _buildThresholdSlider(
            label: 'pH',
            icon: Icons.science,
            color: c.info,
            min: _phMin,
            max: _phMax,
            absMin: 0,
            absMax: 14,
            onChanged: (min, max) => setState(() {
              _phMin = min;
              _phMax = max;
            }),
            c: c,
          ),
          _buildThresholdSlider(
            label: 'EC (mS/cm)',
            icon: Icons.electric_bolt,
            color: c.accent,
            min: _ecMin,
            max: _ecMax,
            absMin: 0,
            absMax: 5,
            divisions: 50,
            onChanged: (min, max) => setState(() {
              _ecMin = min;
              _ecMax = max;
            }),
            c: c,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        c.info.withValues(alpha: 0.2),
                        c.info.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: c.info.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(plantRepositoryProvider)
                            .updateThresholds({
                          'temp_min': _tempMin,
                          'temp_max': _tempMax,
                          'ph_min': _phMin,
                          'ph_max': _phMax,
                          'ec_min': _ecMin,
                          'ec_max': _ecMax,
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Umbrales guardados'),
                            ),
                          );
                        }
                      } catch (_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error al guardar umbrales'),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: c.info,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Guardar umbrales',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final catalog =
                        ref.read(plantRepositoryProvider).availablePlants;
                    final profile =
                        ref.read(activePlantProfileProvider).value;
                    if (profile == null) return;
                    final match = catalog.firstWhere(
                      (p) => p.nombre == profile.nombre,
                      orElse: () => profile,
                    );
                    ref.read(plantRepositoryProvider).selectPlant(match);
                    setState(() => _thresholdInitialized = false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textSecondary,
                    side: BorderSide(color: c.cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Restablecer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSlider({
    required String label,
    required IconData icon,
    required Color color,
    required double min,
    required double max,
    required double absMin,
    required double absMax,
    int? divisions,
    required void Function(double min, double max) onChanged,
    required AppColorScheme c,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: c.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Min: ${min.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RangeSlider(
                  values: RangeValues(min, max),
                  min: absMin,
                  max: absMax,
                  divisions: divisions ?? (absMax - absMin).toInt() * 2,
                  activeColor: color,
                  inactiveColor: c.cardBorder,
                  onChanged: (values) => onChanged(values.start, values.end),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Max: ${max.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(AppColorScheme c) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: c.cardBorder.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: c.info.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: c.info,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tema',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDark ? 'Modo oscuro' : 'Modo claro',
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
            activeThumbColor: c.info,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsCard(AsyncValue<bool> alertsAsync, AppColorScheme c) {
    final enabled = alertsAsync.value ?? true;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            c.cardBackground,
            c.cardBackground.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: c.cardBorder.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  c.warning.withValues(alpha: 0.2),
                  c.warning.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: c.warning.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              enabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: c.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notificaciones',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Alertas de sensores',
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: _toggleAlerts,
            activeThumbColor: c.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCard(AsyncValue<SensorData> sensorAsync, AppColorScheme c) {
    return sensorAsync.when(
      data: (sensor) {
        final connected = sensor.conectado ?? false;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                c.cardBackground,
                c.cardBackground.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: c.cardBorder.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: connected ? c.success : c.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (connected ? c.success : c.error)
                              .withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    connected ? 'ESP32 conectado' : 'ESP32 desconectado',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.cardBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: c.textSecondary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Versión 1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/onboarding/esp32'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.info,
                    side: BorderSide(color: c.cardBorder, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Reconectar ESP32',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
      ),
      error: (_, _) => Text(
        'Error al cargar estado',
        style: TextStyle(color: c.textSecondary),
      ),
    );
  }

  Widget _buildActiveSensorsCard(AppColorScheme c) {
    final sensors = [
      {
        'key': 'temperatura',
        'label': 'Temperatura',
        'icon': Icons.thermostat_outlined,
      },
      {'key': 'ph', 'label': 'pH', 'icon': Icons.science_outlined},
      {
        'key': 'conductividad',
        'label': 'Conductividad',
        'icon': Icons.electric_bolt_outlined,
      },
      {
        'key': 'nivel_agua_tanque',
        'label': 'Nivel Agua',
        'icon': Icons.water_drop_outlined,
      },
      {
        'key': 'nivel_fertilizante_tanque',
        'label': 'Nivel Fertilizante',
        'icon': Icons.eco_outlined,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona los sensores que quieres ver en el dashboard',
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          ...sensors.map(
            (sensor) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    sensor['icon'] as IconData,
                    color: c.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sensor['label'] as String,
                      style: TextStyle(fontSize: 14, color: c.textPrimary),
                    ),
                  ),
                  Switch(
                    value: _activeSensors.contains(sensor['key']),
                    onChanged: (_) =>
                        _toggleSensor(sensor['key'] as String),
                    activeThumbColor: c.success,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizationModeCard(AppColorScheme c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona cómo quieres ver las métricas',
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _saveVisualizationMode('tecnica'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _visualizationMode == 'tecnica'
                          ? c.info.withValues(alpha: 0.15)
                          : c.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _visualizationMode == 'tecnica'
                            ? c.info
                            : c.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.speed_outlined,
                          color: _visualizationMode == 'tecnica'
                              ? c.info
                              : c.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vista Técnica',
                            style: TextStyle(
                              fontSize: 14,
                              color: _visualizationMode == 'tecnica'
                                  ? c.info
                                  : c.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _saveVisualizationMode('sencilla'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _visualizationMode == 'sencilla'
                          ? c.success.withValues(alpha: 0.15)
                          : c.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _visualizationMode == 'sencilla'
                            ? c.success
                            : c.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          color: _visualizationMode == 'sencilla'
                              ? c.success
                              : c.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vista Sencilla',
                            style: TextStyle(
                              fontSize: 14,
                              color: _visualizationMode == 'sencilla'
                                  ? c.success
                                  : c.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(AppColorScheme c) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              c.error.withValues(alpha: 0.15),
              c.error.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: c.error.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: c.error.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _signOut,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: c.error,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 20),
              SizedBox(width: 10),
              Text(
                'Cerrar sesión',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
