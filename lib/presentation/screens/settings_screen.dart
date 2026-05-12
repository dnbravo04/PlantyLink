import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../models/plant_profile.dart';
import '../../models/sensor_data.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/dashboard/illuminated_button.dart';

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

  double _tempMin = 18;
  double _tempMax = 26;
  double _phMin = 5.5;
  double _phMax = 6.5;
  double _ecMin = 1.0;
  double _ecMax = 2.0;

  String _visualizationMode = 'tecnica';
  List<String> _activeSensors = [
    'temperatura',
    'ph',
    'conductividad',
    'nivel_agua_tanque',
    'nivel_fertilizante_tanque',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveUserProfile() async {
    final firebase = ref.read(firebaseServiceProvider);
    await firebase.updateUserProfile(
      _nameController.text.trim(),
      _cityController.text.trim(),
    );
  }

  Future<void> _toggleAlerts(bool enabled) async {
    final firebase = ref.read(firebaseServiceProvider);
    await firebase.setAlertsEnabled(enabled);
  }

  Future<void> _saveVisualizationMode(String mode) async {
    final firebase = ref.read(firebaseServiceProvider);
    await firebase.updateUserSettings({'modo_visualizacion': mode});
    setState(() => _visualizationMode = mode);
  }

  Future<void> _saveActiveSensors() async {
    final firebase = ref.read(firebaseServiceProvider);
    await firebase.updateUserSettings({'sensores_activos': _activeSensors});
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

    // Cargar configuración del usuario
    userAsync.whenData((user) {
      _visualizationMode = user['modo_visualizacion'] as String? ?? 'tecnica';
      final activeSensors =
          user['sensores_activos'] as List<dynamic>? ??
          [
            'temperatura',
            'ph',
            'conductividad',
            'nivel_agua_tanque',
            'nivel_fertilizante_tanque',
          ];
      _activeSensors = activeSensors.cast<String>();
    });

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
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
        final name = user['nombre']?.toString() ?? '';
        final city = user['ciudad']?.toString() ?? '';
        if (!_isEditingName) _nameController.text = name;
        if (!_isEditingCity) _cityController.text = city;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.cardBorder,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 8),
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
                      borderSide: const BorderSide(color: AppColors.cardBorder),
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
            color: isEditing ? AppColors.success : AppColors.textSecondary,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Text(
                profile?.emoji ?? '🌱',
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.nombre ?? 'Sin configurar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Planta activa',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/plantas'),
                child: const Text(
                  'Cambiar',
                  style: TextStyle(color: AppColors.info, fontSize: 13),
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
    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Text(
            'No hay cultivo activo para mostrar umbrales.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          );
        }
        // Sync local state once when profile loads
        _tempMin = profile.tempMin;
        _tempMax = profile.tempMax;
        _phMin = profile.phMin;
        _phMax = profile.phMax;
        _ecMin = profile.ecMin;
        _ecMax = profile.ecMax;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              _buildThresholdSlider(
                label: 'Temperatura (°C)',
                min: _tempMin,
                max: _tempMax,
                absMin: 0,
                absMax: 50,
                onChanged: (min, max) => setState(() {
                  _tempMin = min;
                  _tempMax = max;
                }),
              ),
              _buildThresholdSlider(
                label: 'pH',
                min: _phMin,
                max: _phMax,
                absMin: 0,
                absMax: 14,
                onChanged: (min, max) => setState(() {
                  _phMin = min;
                  _phMax = max;
                }),
              ),
              _buildThresholdSlider(
                label: 'EC (mS/cm)',
                min: _ecMin,
                max: _ecMax,
                absMin: 0,
                absMax: 5,
                divisions: 50,
                onChanged: (min, max) => setState(() {
                  _ecMin = min;
                  _ecMax = max;
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final plantRepo = ref.read(plantRepositoryProvider);
                        plantRepo.updateThresholds({
                          'temp_min': _tempMin,
                          'temp_max': _tempMax,
                          'ph_min': _phMin,
                          'ph_max': _phMax,
                          'ec_min': _ecMin,
                          'ec_max': _ecMax,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Guardar umbrales'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final plantRepo = ref.read(plantRepositoryProvider);
                        final catalog = plantRepo.availablePlants;
                        final match = catalog.firstWhere(
                          (p) => p.nombre == profile.nombre,
                          orElse: () => profile,
                        );
                        plantRepo.selectPlant(match);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, _) => const Text(
        'Error al cargar umbrales',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildThresholdSlider({
    required String label,
    required double min,
    required double max,
    required double absMin,
    required double absMax,
    int? divisions,
    required void Function(double min, double max) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Min: ${min.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: RangeSlider(
                  values: RangeValues(min, max),
                  min: absMin,
                  max: absMax,
                  divisions: divisions ?? (absMax - absMin).toInt() * 2,
                  activeColor: AppColors.success,
                  inactiveColor: AppColors.cardBorder,
                  onChanged: (values) => onChanged(values.start, values.end),
                ),
              ),
              Text(
                'Max: ${max.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsCard(AsyncValue<bool> alertsAsync) {
    final enabled = alertsAsync.value ?? true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Alertas activadas',
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
          IlluminatedButton(
            label: enabled ? 'Activadas' : 'Desactivadas',
            icon: enabled
                ? Icons.notifications_active
                : Icons.notifications_off,
            isActive: enabled,
            color: AppColors.warning,
            onTap: () => _toggleAlerts(!enabled),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: connected ? AppColors.success : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    connected ? 'ESP32 conectado' : 'ESP32 desconectado',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Versión 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/onboarding/esp32'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reconectar ESP32'),
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
                  GestureDetector(
                    onTap: () => _toggleSensor(sensor['key'] as String),
                    child: Container(
                      width: 44,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _activeSensors.contains(sensor['key'])
                            ? AppColors.success
                            : AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Center(
                        child: Icon(
                          _activeSensors.contains(sensor['key'])
                              ? Icons.check
                              : Icons.add,
                          color: _activeSensors.contains(sensor['key'])
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          size: 16,
                        ),
                      ),
                    ),
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
      child: ElevatedButton(
        onPressed: _signOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error.withValues(alpha: 0.15),
          foregroundColor: AppColors.error,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.error),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text(
          'Cerrar sesión',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
