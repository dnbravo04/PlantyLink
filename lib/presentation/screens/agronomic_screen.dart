import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/units.dart';
import '../../models/plant_profile.dart';
import '../../models/sensor_data.dart';
import '../../models/agronomic/growth_stage.dart';
import '../../models/agronomic/nutrient_recommendation.dart';
import '../../models/agronomic/ph_correction.dart';
import '../providers/app_providers.dart';
import '../providers/navigation_provider.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/animated_app_card.dart';
import '../widgets/common/app_toast.dart';

/// Surfaces the agronomic intelligence already computed by [AgronomicService]:
/// growth stage (from the persisted planting date), stage-specific nutrient
/// targets, an interactive pH-correction calculator, and sensor drift health.
class AgronomicScreen extends ConsumerWidget {
  const AgronomicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final profileAsync = ref.watch(activePlantProfileProvider);
    final plantingDateAsync = ref.watch(plantingDateProvider);
    final sensorAsync = ref.watch(sensorProvider);
    final service = ref.watch(agronomicServiceProvider);
    // Soil-first (Eje 3): la complejidad hidropónica (nutrición EC/NPK y
    // corrección de pH) solo aparece si el dispositivo es hidropónico.
    final isHydro = ref.watch(isHydroDeviceProvider);

    final profile = profileAsync.value;

    // ── Empty state: no active crop configured ──
    if (profile == null) {
      return _EmptyState(c: c, ref: ref);
    }

    final sensor = sensorAsync.value;
    final units = ref.watch(unitsProvider);
    final isNovato = ref.watch(experienceProvider) == 'novato';
    final plantingDate = plantingDateAsync.value;
    final daysSince =
        plantingDate == null ? null : _daysSince(plantingDate);
    final stage =
        daysSince == null ? null : service.calculateGrowthStage(daysSince);
    final recommendation =
        stage == null ? null : service.recommendDosing(profile, stage);

    return AppScaffold(
      body: RefreshIndicator(
        color: c.primary,
        backgroundColor: c.cardBackground,
        onRefresh: () async {
          AppHaptics.light();
          ref.invalidate(sensorProvider);
          ref.invalidate(historyStreamProvider);
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacingMd,
            ),
            children: [
              const SizedBox(height: AppTokens.spacingMd),
              _Header(profile: profile, c: c),
              const SizedBox(height: AppTokens.spacingLg),
              _GrowthStageCard(
                delay: 0,
                c: c,
                plantingDate: plantingDate,
                daysSince: daysSince,
                stage: stage,
                onPickDate: () => _pickPlantingDate(context, ref, plantingDate),
              ),
              const SizedBox(height: AppTokens.spacingMd),
              _DailyRecommendationsCard(
                delay: 80,
                c: c,
                sensor: sensor,
                profile: profile,
              ),
              // ── Solo hidroponía: nutrición EC/NPK y corrección de pH ──
              if (isHydro) ...[
                if (recommendation != null) ...[
                  const SizedBox(height: AppTokens.spacingMd),
                  _NutrientTargetsCard(
                    delay: 160,
                    c: c,
                    rec: recommendation,
                    currentPh: sensor?.ph,
                    currentEc: sensor?.ecNormalized,
                    units: units,
                    isNovato: isNovato,
                  ),
                ],
                const SizedBox(height: AppTokens.spacingMd),
                _PhCalculatorCard(
                  delay: 240,
                  c: c,
                  profile: profile,
                  sensorPh: sensor?.ph,
                ),
              ],
              const SizedBox(height: AppTokens.spacingLg),
              _Disclaimer(c: c),
              const SizedBox(height: AppTokens.spacingLg),
            ],
          ),
        ),
      ),
    );
  }

  static int _daysSince(DateTime date) {
    final now = DateTime.now();
    final d0 = DateTime(date.year, date.month, date.day);
    final d1 = DateTime(now.year, now.month, now.day);
    return d1.difference(d0).inDays;
  }

  Future<void> _pickPlantingDate(
    BuildContext context,
    WidgetRef ref,
    DateTime? current,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Fecha de siembra',
    );
    if (picked == null) return;
    AppHaptics.medium();
    await ref.read(plantRepositoryProvider)?.setPlantingDate(picked);
    if (context.mounted) {
      AppToast.show(
        context,
        message: 'Fecha de siembra actualizada',
        type: ToastType.success,
      );
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Header
// ════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.c});

  final PlantProfile profile;
  final AppColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          child: Text(
            profile.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        const SizedBox(width: AppTokens.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agronomía',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Recomendaciones para ${profile.nombre}',
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Growth stage card
// ════════════════════════════════════════════════════════════════════════════

class _GrowthStageCard extends StatelessWidget {
  const _GrowthStageCard({
    required this.delay,
    required this.c,
    required this.plantingDate,
    required this.daysSince,
    required this.stage,
    required this.onPickDate,
  });

  final int delay;
  final AppColorScheme c;
  final DateTime? plantingDate;
  final int? daysSince;
  final GrowthStage? stage;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return AnimatedAppCard(
      delay: delay,
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      child: plantingDate == null || stage == null || daysSince == null
          ? _buildUnset()
          : _buildStage(stage!, daysSince!, plantingDate!),
    );
  }

  Widget _buildUnset() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardTitle(icon: Icons.eco_rounded, label: 'Etapa de crecimiento', c: c),
        const SizedBox(height: AppTokens.spacingMd),
        Text(
          'Registra la fecha de siembra para calcular la etapa de crecimiento '
          'y ajustar las recomendaciones de nutrición.',
          style: TextStyle(fontSize: 13.5, color: c.textSecondary, height: 1.5),
        ),
        const SizedBox(height: AppTokens.spacingMd),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onPickDate,
            icon: const Icon(Icons.event_rounded, size: 18),
            label: const Text('Establecer fecha de siembra'),
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStage(GrowthStage stage, int days, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _CardTitle(
                icon: Icons.eco_rounded,
                label: 'Etapa de crecimiento',
                c: c,
              ),
            ),
            _Pill(text: stage.label, color: c.primary),
          ],
        ),
        const SizedBox(height: AppTokens.spacingMd),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$days',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                days == 1 ? 'día desde la siembra' : 'días desde la siembra',
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spacingLg),
        _StageTimeline(current: stage, c: c),
        const SizedBox(height: AppTokens.spacingMd),
        Text(
          stage.description,
          style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.5),
        ),
        const SizedBox(height: AppTokens.spacingSm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onPickDate,
            icon: const Icon(Icons.edit_calendar_rounded, size: 16),
            label: Text('Sembrado el ${_formatDate(date)} · editar'),
            style: TextButton.styleFrom(
              foregroundColor: c.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }
}

/// Five-segment horizontal timeline highlighting the current [GrowthStage].
class _StageTimeline extends StatelessWidget {
  const _StageTimeline({required this.current, required this.c});

  final GrowthStage current;
  final AppColorScheme c;

  static const _short = {
    GrowthStage.germination: 'Germ.',
    GrowthStage.seedling: 'Plántula',
    GrowthStage.vegetative: 'Veget.',
    GrowthStage.flowering: 'Flor.',
    GrowthStage.harvest: 'Cosecha',
  };

  @override
  Widget build(BuildContext context) {
    final stages = GrowthStage.values;
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < stages.length; i++) ...[
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= current.index
                        ? c.primary
                        : c.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                ),
              ),
              if (i < stages.length - 1) const SizedBox(width: 4),
            ],
          ],
        ),
        const SizedBox(height: AppTokens.spacingSm),
        Row(
          children: [
            for (var i = 0; i < stages.length; i++)
              Expanded(
                child: Text(
                  _short[stages[i]]!,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: stages[i] == current
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: stages[i] == current ? c.primary : c.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Nutrient targets card
// ════════════════════════════════════════════════════════════════════════════

class _NutrientTargetsCard extends StatelessWidget {
  const _NutrientTargetsCard({
    required this.delay,
    required this.c,
    required this.rec,
    required this.currentPh,
    required this.currentEc,
    required this.units,
    required this.isNovato,
  });

  final int delay;
  final AppColorScheme c;
  final NutrientRecommendation rec;
  final double? currentPh;
  final double? currentEc;
  final UnitsPrefs units;
  final bool isNovato;

  @override
  Widget build(BuildContext context) {
    return AnimatedAppCard(
      delay: delay,
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.science_rounded,
            label: 'Objetivos de nutrición',
            c: c,
          ),
          if (isNovato) ...[
            const SizedBox(height: AppTokens.spacingSm),
            _NoteBox(
              c: c,
              icon: Icons.school_outlined,
              text: 'EC mide cuánto nutriente hay disuelto en el agua; '
                  'NPK es la proporción nitrógeno-fósforo-potasio del '
                  'fertilizante. Mantén los valores dentro del rango objetivo.',
            ),
          ],
          const SizedBox(height: AppTokens.spacingMd),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  c: c,
                  label: 'Relación NPK',
                  value: rec.npkRatio,
                  accent: c.accent,
                ),
              ),
              const SizedBox(width: AppTokens.spacingSm),
              Expanded(
                child: _MetricTile(
                  c: c,
                  label: 'Dosis',
                  value: '${_fmt(rec.doseMlPerLiter)} mL/L',
                  accent: c.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingMd),
          _RangeRow(
            c: c,
            label: 'EC objetivo',
            unit: units.ecUnit,
            min: units.ecValue(rec.ecTargetMin),
            max: units.ecValue(rec.ecTargetMax),
            current: currentEc == null ? null : units.ecValue(currentEc!),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          _RangeRow(
            c: c,
            label: 'pH objetivo',
            unit: '',
            min: rec.phTargetMin,
            max: rec.phTargetMax,
            current: currentPh,
          ),
          const SizedBox(height: AppTokens.spacingMd),
          _NoteBox(c: c, text: rec.notes),
        ],
      ),
    );
  }
}

/// A target-range row that compares the live sensor value against min/max.
class _RangeRow extends StatelessWidget {
  const _RangeRow({
    required this.c,
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.current,
  });

  final AppColorScheme c;
  final String label;
  final String unit;
  final double min;
  final double max;
  final double? current;

  @override
  Widget build(BuildContext context) {
    final unitSuffix = unit.isEmpty ? '' : ' $unit';
    final target = '${_fmt(min)} – ${_fmt(max)}$unitSuffix';

    Color statusColor = c.textMuted;
    IconData? statusIcon;
    String statusText = '—';
    if (current != null) {
      if (current! < min) {
        statusColor = c.warning;
        statusIcon = Icons.arrow_downward_rounded;
        statusText = 'Bajo';
      } else if (current! > max) {
        statusColor = c.warning;
        statusIcon = Icons.arrow_upward_rounded;
        statusText = 'Alto';
      } else {
        statusColor = c.success;
        statusIcon = Icons.check_rounded;
        statusText = 'Óptimo';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingSm,
        vertical: AppTokens.spacingSm,
      ),
      decoration: BoxDecoration(
        color: c.background.withValues(alpha: c.isDark ? 0.4 : 0.6),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  target,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Actual',
                style: TextStyle(fontSize: 10, color: c.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                current == null ? '—' : '${_fmt(current!)}$unitSuffix',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppTokens.spacingSm),
          _StatusChip(
            color: statusColor,
            icon: statusIcon,
            text: statusText,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// pH correction calculator card (interactive)
// ════════════════════════════════════════════════════════════════════════════

class _PhCalculatorCard extends ConsumerStatefulWidget {
  const _PhCalculatorCard({
    required this.delay,
    required this.c,
    required this.profile,
    required this.sensorPh,
  });

  final int delay;
  final AppColorScheme c;
  final PlantProfile profile;
  final double? sensorPh;

  @override
  ConsumerState<_PhCalculatorCard> createState() => _PhCalculatorCardState();
}

class _PhCalculatorCardState extends ConsumerState<_PhCalculatorCard> {
  late double _currentPh;
  late double _targetPh;
  double _volume = 20;

  @override
  void initState() {
    super.initState();
    _targetPh = (widget.profile.phMin + widget.profile.phMax) / 2;
    _currentPh = widget.sensorPh ?? _targetPh;
  }

  void _adjust(void Function() mutate) {
    AppHaptics.light();
    setState(mutate);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final service = ref.read(agronomicServiceProvider);
    final atTarget = (_targetPh - _currentPh).abs() < 0.05;
    final PhCorrection correction = service.calculatePHCorrection(
      currentPH: _currentPh,
      targetPH: _targetPh,
      volumeLiters: _volume,
    );

    return AnimatedAppCard(
      delay: widget.delay,
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _CardTitle(
                  icon: Icons.calculate_rounded,
                  label: 'Corrección de pH',
                  c: c,
                ),
              ),
              if (widget.sensorPh != null)
                TextButton.icon(
                  onPressed: () =>
                      _adjust(() => _currentPh = widget.sensorPh!),
                  icon: const Icon(Icons.sync_rounded, size: 15),
                  label: const Text('Lectura'),
                  style: TextButton.styleFrom(
                    foregroundColor: c.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingMd),
          Row(
            children: [
              Expanded(
                child: _Stepper(
                  c: c,
                  label: 'pH actual',
                  value: _currentPh,
                  onMinus: () =>
                      _adjust(() => _currentPh = (_currentPh - 0.1).clamp(0, 14)),
                  onPlus: () =>
                      _adjust(() => _currentPh = (_currentPh + 0.1).clamp(0, 14)),
                ),
              ),
              const SizedBox(width: AppTokens.spacingSm),
              Expanded(
                child: _Stepper(
                  c: c,
                  label: 'pH objetivo',
                  value: _targetPh,
                  onMinus: () =>
                      _adjust(() => _targetPh = (_targetPh - 0.1).clamp(0, 14)),
                  onPlus: () =>
                      _adjust(() => _targetPh = (_targetPh + 0.1).clamp(0, 14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingMd),
          Row(
            children: [
              Text(
                'Volumen del tanque',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${_volume.toStringAsFixed(0)} L',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          Slider(
            value: _volume,
            min: 5,
            max: 200,
            divisions: 39,
            activeColor: c.primary,
            label: '${_volume.toStringAsFixed(0)} L',
            onChanged: (v) => setState(() => _volume = v),
          ),
          const SizedBox(height: AppTokens.spacingXs),
          atTarget
              ? _NoteBox(
                  c: c,
                  icon: Icons.check_circle_rounded,
                  accent: c.success,
                  text:
                      'El pH ya está en el objetivo. No se requiere corrección.',
                )
              : _CorrectionResult(c: c, correction: correction),
        ],
      ),
    );
  }
}

class _CorrectionResult extends StatelessWidget {
  const _CorrectionResult({required this.c, required this.correction});

  final AppColorScheme c;
  final PhCorrection correction;

  @override
  Widget build(BuildContext context) {
    final isAcid = correction.needsAcid;
    final accent = isAcid ? c.warning : c.info;
    final productLabel = isAcid ? 'Añadir pH Down' : 'Añadir pH Up';

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(text: productLabel, color: accent),
              const Spacer(),
              Text(
                '${_fmt(correction.estimatedMLNeeded)} mL',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(
            correction.notes,
            style: TextStyle(fontSize: 12.5, color: c.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Compact -/+ stepper with a monospace value readout.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.c,
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final AppColorScheme c;
  final String label;
  final double value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: c.background.withValues(alpha: c.isDark ? 0.4 : 0.6),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(color: c.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepButton(icon: Icons.remove_rounded, color: c, onTap: onMinus),
              Text(
                value.toStringAsFixed(1),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              _StepButton(icon: Icons.add_rounded, color: c, onTap: onPlus),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final AppColorScheme color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 18, color: color.primary),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Daily recommendations (soil-first, beginner-friendly)
// ════════════════════════════════════════════════════════════════════════════

/// Simple actionable checklist for the day. Derives what it can from the
/// live reading; falls back to general care tips when there's no data.
/// (La "Salud de sensores" se movió a Sistema → Mi dispositivo.)
class _DailyRecommendationsCard extends StatelessWidget {
  const _DailyRecommendationsCard({
    required this.delay,
    required this.c,
    required this.sensor,
    required this.profile,
  });

  final int delay;
  final AppColorScheme c;
  final SensorData? sensor;
  final PlantProfile profile;

  List<(IconData, Color, String)> _recommendations() {
    final items = <(IconData, Color, String)>[];

    final soil = sensor?.humedadSuelo;
    if (soil != null) {
      final min = profile.humedadSueloMin ?? 30;
      final max = profile.humedadSueloMax ?? 70;
      if (soil < min) {
        items.add((
          Icons.water_drop_rounded,
          c.warning,
          'El suelo está seco. Riega tu planta hoy.',
        ));
      } else if (soil > max) {
        items.add((
          Icons.pause_circle_rounded,
          c.info,
          'El suelo está muy húmedo. Espera antes de volver a regar.',
        ));
      } else {
        items.add((
          Icons.check_circle_rounded,
          c.success,
          'Humedad de suelo óptima. No requiere riego hoy.',
        ));
      }
    }

    final temp = sensor?.temperatura;
    if (temp != null) {
      if (temp < 15) {
        items.add((
          Icons.ac_unit_rounded,
          c.info,
          'Hace frío para tu planta. Aléjala de ventanas y corrientes de aire.',
        ));
      } else if (temp > 30) {
        items.add((
          Icons.wb_sunny_rounded,
          c.warning,
          'Hace calor. Dale sombra o mejora la ventilación.',
        ));
      } else {
        items.add((
          Icons.check_circle_rounded,
          c.success,
          'Temperatura ambiente adecuada para el cultivo.',
        ));
      }
    }

    // Tip general del día (estático por ahora).
    items.add((
      Icons.search_rounded,
      c.textMuted,
      'Revisa las hojas en busca de plagas o manchas.',
    ));

    if (items.length == 1) {
      // Sin datos de sensores: solo consejos generales.
      items.insert(0, (
        Icons.eco_rounded,
        c.success,
        'Conecta tu dispositivo para recibir recomendaciones personalizadas.',
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _recommendations();
    return AnimatedAppCard(
      delay: delay,
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.checklist_rounded,
            label: 'Recomendaciones diarias',
            c: c,
          ),
          const SizedBox(height: AppTokens.spacingXs),
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: items[i].$2.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                ),
                child: Icon(items[i].$1, color: items[i].$2, size: 18),
              ),
              title: Text(
                items[i].$3,
                style: TextStyle(
                  fontSize: 13.5,
                  color: c.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            if (i < items.length - 1)
              Divider(color: c.cardBorder, height: 1),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Empty state
// ════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.c, required this.ref});

  final AppColorScheme c;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spacingXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.primary.withValues(alpha: 0.08),
                  ),
                  child: Icon(
                    Icons.spa_rounded,
                    size: 56,
                    color: c.primary.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: AppTokens.spacingLg),
                Text(
                  'Sin cultivo configurado',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTokens.spacingSm),
                Text(
                  'Selecciona una planta en Sistema para recibir\n'
                  'recomendaciones agronómicas personalizadas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: c.textMuted, height: 1.5),
                ),
                const SizedBox(height: AppTokens.spacingLg),
                FilledButton.icon(
                  onPressed: () {
                    AppHaptics.light();
                    ref.read(selectedTabIndexProvider.notifier).select(3);
                  },
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Configurar cultivo'),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spacingLg,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Shared small widgets
// ════════════════════════════════════════════════════════════════════════════

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.label, required this.c});

  final IconData icon;
  final String label;
  final AppColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: c.primary),
        const SizedBox(width: AppTokens.spacingSm),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.c,
    required this.label,
    required this.value,
    required this.accent,
  });

  final AppColorScheme c;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMd,
        vertical: AppTokens.spacingSm,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: c.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.color, required this.text, this.icon});

  final Color color;
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({
    required this.c,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.accent,
  });

  final AppColorScheme c;
  final String text;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final a = accent ?? c.textMuted;
    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingSm),
      decoration: BoxDecoration(
        color: a.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: a),
          const SizedBox(width: AppTokens.spacingSm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                color: c.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.c});

  final AppColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Las recomendaciones son estimaciones basadas en los umbrales del perfil '
      'y la etapa de crecimiento. Ajusta los nutrientes gradualmente y vuelve a '
      'medir antes de dosificar de nuevo.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 11.5, color: c.textMuted, height: 1.5),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

// µS/cm values are in the hundreds/thousands — decimals add only noise.
String _fmt(double v) => v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';
