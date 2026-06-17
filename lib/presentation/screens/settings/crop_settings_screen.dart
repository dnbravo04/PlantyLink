import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../models/plant_profile.dart';
import '../../providers/app_providers.dart';
import '../plant_selector_screen.dart';
import '../../widgets/common/app_scaffold.dart';

/// Active crop and threshold configuration screen.
class CropSettingsScreen extends ConsumerStatefulWidget {
  const CropSettingsScreen({super.key});

  @override
  ConsumerState<CropSettingsScreen> createState() => _CropSettingsScreenState();
}

class _CropSettingsScreenState extends ConsumerState<CropSettingsScreen> {
  double _tempMin = 18, _tempMax = 26;
  double _phMin = 5.5, _phMax = 6.5;
  double _ecMin = 1.0, _ecMax = 2.0;
  bool _thresholdInitialized = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final profileAsync = ref.watch(activePlantProfileProvider);

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

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Mi cultivo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionTitle('Cultivo activo', c),
          const SizedBox(height: 8),
          _buildActivePlantCard(profileAsync, c),
          const SizedBox(height: 24),
          _buildSectionTitle('Umbrales personalizados', c),
          const SizedBox(height: 8),
          _buildThresholdsCard(profileAsync, c),
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

  Widget _buildActivePlantCard(
      AsyncValue<PlantProfile?> profileAsync, AppColorScheme c) {
    return profileAsync.when(
      data: (profile) {
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: c.success.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Center(
                    child: Text(profile?.emoji ?? '🌱',
                        style: const TextStyle(fontSize: 32))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile?.nombre ?? 'Sin configurar',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: c.success, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Planta activa',
                          style:
                              TextStyle(fontSize: 12, color: c.textSecondary)),
                    ]),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PlantSelectorScreen())),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: c.info.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Text('Cambiar',
                      style: TextStyle(
                          color: c.info,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          Center(child: CircularProgressIndicator(strokeWidth: 2, color: c.primary)),
      error: (_, _) =>
          Text('Error al cargar cultivo', style: TextStyle(color: c.textSecondary)),
    );
  }

  Widget _buildThresholdsCard(
      AsyncValue<PlantProfile?> profileAsync, AppColorScheme c) {
    if (!_thresholdInitialized) {
      return profileAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(strokeWidth: 2, color: c.primary)),
        error: (_, _) =>
            Text('Error al cargar umbrales', style: TextStyle(color: c.textSecondary)),
        data: (profile) {
          if (profile == null) {
            return Text('No hay cultivo activo para mostrar umbrales.',
                style: TextStyle(color: c.textSecondary, fontSize: 13));
          }
          return Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: c.primary));
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder, width: 1.5),
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
              onChanged: (min, max) =>
                  setState(() { _tempMin = min; _tempMax = max; }),
              c: c),
          _buildThresholdSlider(
              label: 'pH',
              icon: Icons.science,
              color: c.info,
              min: _phMin,
              max: _phMax,
              absMin: 0,
              absMax: 14,
              onChanged: (min, max) =>
                  setState(() { _phMin = min; _phMax = max; }),
              c: c),
          _buildThresholdSlider(
              label: 'EC (mS/cm)',
              icon: Icons.electric_bolt,
              color: c.accent,
              min: _ecMin,
              max: _ecMax,
              absMin: 0,
              absMax: 5,
              divisions: 50,
              onChanged: (min, max) =>
                  setState(() { _ecMin = min; _ecMax = max; }),
              c: c),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    try {
                      await ref.read(plantRepositoryProvider)?.updateThresholds({
                        'temp_min': _tempMin,
                        'temp_max': _tempMax,
                        'ph_min': _phMin,
                        'ph_max': _phMax,
                        'ec_min': _ecMin,
                        'ec_max': _ecMax,
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Umbrales guardados')));
                      }
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Error al guardar umbrales')));
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: c.info,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Guardar umbrales',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final repo = ref.read(plantRepositoryProvider);
                    if (repo == null) return;
                    final catalog = repo.availablePlants;
                    final profile =
                        ref.read(activePlantProfileProvider).value;
                    if (profile == null) return;
                    final match = catalog.firstWhere(
                        (p) => p.nombre == profile.nombre,
                        orElse: () => profile);
                    repo.selectPlant(match);
                    setState(() => _thresholdInitialized = false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textSecondary,
                    side: BorderSide(color: c.cardBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
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
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: c.textSecondary,
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text('Min: ${min.toStringAsFixed(1)}',
                  style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.w600)),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text('Max: ${max.toStringAsFixed(1)}',
                  style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ),
          ]),
        ],
      ),
    );
  }
}
