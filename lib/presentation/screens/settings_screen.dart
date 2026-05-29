import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
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
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
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
    final userAsync = ref.watch(userProfileProvider);
    final profileAsync = ref.watch(activePlantProfileProvider);
    final alertsAsync = ref.watch(alertsEnabledProvider);
    final sensorAsync = ref.watch(sensorProvider);

    // Initialize threshold sliders once, the first time the profile loads.
    // Using ref.listen avoids mutating state during build — the callback fires
    // only when activePlantProfileProvider emits a new value.
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
          final viz =
              user['modo_visualizacion'] as String? ?? 'tecnica';
          final sensors = user['sensores_activos'] as List<dynamic>?;
          setState(() {
            _profileSettingsInitialized = true;
            _visualizationMode = viz;
            if (sensors != null) {
              _activeSensors = sensors.cast<String>();
            }
          });
          // Pre-fill text controllers from Firebase (only while not editing).
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
            _buildSectionTitle('Perfil de usuario'),
            const SizedBox(height: 8),
            _buildProfileCard(userAsync),
            const SizedBox(height: 24),

            _buildSectionTitle('Cultivo activo'),
            const SizedBox(height: 8),
            _buildActivePlantCard(profileAsync),
            const SizedBox(height: 24),

            _buildSectionTitle('Umbrales personalizados'),
            const SizedBox(height: 8),
            _buildThresholdsCard(profileAsync),
            const SizedBox(height: 24),

            _buildSectionTitle('Sensores activos'),
            const SizedBox(height: 8),
            _buildActiveSensorsCard(),
            const SizedBox(height: 24),

            _buildSectionTitle('Modo de visualización'),
            const SizedBox(height: 8),
            _buildVisualizationModeCard(),
            const SizedBox(height: 24),

            _buildSectionTitle('Apariencia'),
            const SizedBox(height: 8),
            _buildThemeCard(),
            const SizedBox(height: 24),

            _buildSectionTitle('Notificaciones'),
            const SizedBox(height: 8),
            _buildAlertsCard(alertsAsync),
            const SizedBox(height: 24),

            _buildSectionTitle('Sistema'),
            const SizedBox(height: 8),
            _buildSystemCard(sensorAsync),
            const SizedBox(height: 24),

            _buildSectionTitle('Cuenta'),
            const SizedBox(height: 8),
            _buildSignOutButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildProfileCard(AsyncValue<Map<String, dynamic>> userAsync) {
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
                AppColors.cardBackground,
                AppColors.cardBackground.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardBorder.withValues(alpha: 0.2),
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
                  gradient: const LinearGradient(
                    colors: [AppColors.info, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.info.withValues(alpha: 0.4),
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
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, _) => const Text(
        'Error al cargar perfil',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildEditableRow({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEdit,
    required VoidCallback onSave,
  }) {
    return Row(
      children: [
        Expanded(
          child: isEditing
              ? TextField(
                  controller: controller,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.cardBorder),
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
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.text.isEmpty ? '—' : controller.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
        ),
        IconButton(
          icon: Icon(
            isEditing ? Icons.check : Icons.edit,
            color:
                isEditing ? AppColors.success : AppColors.textSecondary,
            size: 18,
          ),
          onPressed: isEditing ? onSave : onEdit,
        ),
      ],
    );
  }

  Widget _buildActivePlantCard(AsyncValue<PlantProfile?> profileAsync) {
    return profileAsync.when(
      data: (profile) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cardBackground,
                AppColors.cardBackground.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardBorder.withValues(alpha: 0.15),
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
                      AppColors.success.withValues(alpha: 0.2),
                      AppColors.success.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
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
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Planta activa',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Fix S-03: "Cambiar" is now a proper tappable button.
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
                        AppColors.info.withValues(alpha: 0.15),
                        AppColors.info.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Text(
                    'Cambiar',
                    style: TextStyle(
                      color: AppColors.info,
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
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, _) => const Text(
        'Error al cargar cultivo',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildThresholdsCard(AsyncValue<PlantProfile?> profileAsync) {
    // Show placeholder until the profile has loaded and initialized the sliders.
    if (!_thresholdInitialized) {
      return profileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, _) => const Text(
          'Error al cargar umbrales',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        data: (profile) {
          if (profile == null) {
            return const Text(
              'No hay cultivo activo para mostrar umbrales.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            );
          }
          // First data arrived but ref.listen hasn't fired yet — show spinner.
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardBackground,
            AppColors.cardBackground.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardBorder.withValues(alpha: 0.15),
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
            color: AppColors.warning,
            min: _tempMin,
            max: _tempMax,
            absMin: 0,
            absMax: 50,
            onChanged: (min, max) =>
                setState(() {
                  _tempMin = min;
                  _tempMax = max;
                }),
          ),
          _buildThresholdSlider(
            label: 'pH',
            icon: Icons.science,
            color: AppColors.info,
            min: _phMin,
            max: _phMax,
            absMin: 0,
            absMax: 14,
            onChanged: (min, max) =>
                setState(() {
                  _phMin = min;
                  _phMax = max;
                }),
          ),
          _buildThresholdSlider(
            label: 'EC (mS/cm)',
            icon: Icons.electric_bolt,
            color: AppColors.accent,
            min: _ecMin,
            max: _ecMax,
            absMin: 0,
            absMax: 5,
            divisions: 50,
            onChanged: (min, max) =>
                setState(() {
                  _ecMin = min;
                  _ecMax = max;
                }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.info.withValues(alpha: 0.2),
                        AppColors.info.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.4),
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
                      foregroundColor: AppColors.info,
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
                    final catalog = ref.read(plantRepositoryProvider).availablePlants;
                    final profile = ref.read(activePlantProfileProvider).value;
                    if (profile == null) return;
                    final match = catalog.firstWhere(
                      (p) => p.nombre == profile.nombre,
                      orElse: () => profile,
                    );
                    ref.read(plantRepositoryProvider).selectPlant(match);
                    // Reset initialization so sliders reload from the reset profile.
                    setState(() => _thresholdInitialized = false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.cardBorder),
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
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
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
                  inactiveColor: AppColors.cardBorder,
                  onChanged: (values) =>
                      onChanged(values.start, values.end),
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

  Widget _buildThemeCard() {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardBorder.withValues(alpha: 0.15),
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
              color: AppColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: AppColors.info,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tema',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDark ? 'Modo oscuro' : 'Modo claro',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
            activeThumbColor: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsCard(AsyncValue<bool> alertsAsync) {
    final enabled = alertsAsync.value ?? true;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardBackground,
            AppColors.cardBackground.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardBorder.withValues(alpha: 0.15),
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
                  AppColors.warning.withValues(alpha: 0.2),
                  AppColors.warning.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              enabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notificaciones',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Alertas de sensores',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: _toggleAlerts,
            activeThumbColor: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCard(AsyncValue<SensorData> sensorAsync) {
    return sensorAsync.when(
      data: (sensor) {
        final connected = sensor.conectado ?? false;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cardBackground,
                AppColors.cardBackground.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardBorder.withValues(alpha: 0.15),
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
                      color: connected ? AppColors.success : AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (connected
                                  ? AppColors.success
                                  : AppColors.error)
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
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
                      color: AppColors.cardBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Versión 1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
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
                    foregroundColor: AppColors.info,
                    side: const BorderSide(
                      color: AppColors.cardBorder,
                      width: 1.5,
                    ),
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
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, _) => const Text(
        'Error al cargar estado',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildActiveSensorsCard() {
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona los sensores que quieres ver en el dashboard',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ...sensors.map(
            (sensor) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    sensor['icon'] as IconData,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sensor['label'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Switch(
                    value: _activeSensors.contains(sensor['key']),
                    onChanged: (_) =>
                        _toggleSensor(sensor['key'] as String),
                    activeThumbColor: AppColors.success,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizationModeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona cómo quieres ver las métricas',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                          ? AppColors.info.withValues(alpha: 0.15)
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _visualizationMode == 'tecnica'
                            ? AppColors.info
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.speed_outlined,
                          color: _visualizationMode == 'tecnica'
                              ? AppColors.info
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vista Técnica',
                            style: TextStyle(
                              fontSize: 14,
                              color: _visualizationMode == 'tecnica'
                                  ? AppColors.info
                                  : AppColors.textPrimary,
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
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _visualizationMode == 'sencilla'
                            ? AppColors.success
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          color: _visualizationMode == 'sencilla'
                              ? AppColors.success
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vista Sencilla',
                            style: TextStyle(
                              fontSize: 14,
                              color: _visualizationMode == 'sencilla'
                                  ? AppColors.success
                                  : AppColors.textPrimary,
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

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.error.withValues(alpha: 0.15),
              AppColors.error.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _signOut,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.error,
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
