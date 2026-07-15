import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/units.dart';
import '../../../models/plant_profile.dart';
import '../../../models/sensor_data.dart';
import '../../providers/data_staleness_provider.dart';

/// Plain-language state of a single metric for the beginner "Resumen" view.
enum _Mood { good, low, high }

/// One metric translated to human language: no jargon, no raw thresholds.
class _FriendlyMetric {
  final String label;
  final String status; // e.g. "Necesita agua"
  final String value; // e.g. "48%"
  final IconData icon;
  final double progress; // 0.0–1.0 ring fill
  final _Mood mood;

  const _FriendlyMetric({
    required this.label,
    required this.status,
    required this.value,
    required this.icon,
    required this.progress,
    required this.mood,
  });

  bool get isOk => mood == _Mood.good;
}

/// Beginner-friendly dashboard summary ("Resumen" view).
///
/// Instead of raw sensor cards, shows a hero ring with the overall plant
/// state in plain language ("Tu planta está feliz") plus one small ring per
/// available metric with actionable phrasing ("Necesita agua", "Hace calor").
///
/// Soil-first: pH/EC/tank metrics only appear when [showHydro] is true
/// (capability model, decisión P1 de ROADMAP_PRODUCTO.md).
class SimpleMetricsGrid extends StatelessWidget {
  final SensorData sensor;
  final PlantProfile? profile;
  final UnitsPrefs units;
  final bool showHydro;
  final DataFreshness freshness;

  const SimpleMetricsGrid({
    super.key,
    required this.sensor,
    this.profile,
    this.units = const UnitsPrefs(),
    this.showHydro = false,
    this.freshness = DataFreshness.live,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final metrics = _buildMetrics(c);
    final issues = metrics.where((m) => !m.isOk).toList();

    final content = Column(
      children: [
        _HeroStatusCard(
          c: c,
          total: metrics.length,
          issues: issues,
          freshness: freshness,
        ),
        const SizedBox(height: AppTokens.spacingSm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTokens.spacingSm,
          crossAxisSpacing: AppTokens.spacingSm,
          childAspectRatio: 1.05,
          children: [
            for (final m in metrics) _MetricRingCard(metric: m, c: c),
          ],
        ),
      ],
    );

    // Stale/offline data must not look alive (Eje 4).
    final opacity = switch (freshness) {
      DataFreshness.live => 1.0,
      DataFreshness.stale => 0.6,
      DataFreshness.offline => 0.45,
    };
    return opacity == 1.0 ? content : Opacity(opacity: opacity, child: content);
  }

  // ── Metric translation (numbers → plain language) ────────────────────────

  List<_FriendlyMetric> _buildMetrics(AppColorScheme c) {
    final metrics = <_FriendlyMetric>[];

    final soil = sensor.humedadSuelo;
    if (soil != null) {
      final min = profile?.humedadSueloMin ?? 30;
      final max = profile?.humedadSueloMax ?? 70;
      final mood = soil < min
          ? _Mood.low
          : soil > max
              ? _Mood.high
              : _Mood.good;
      metrics.add(_FriendlyMetric(
        label: 'Humedad de suelo',
        status: switch (mood) {
          _Mood.good => 'Bien hidratada',
          _Mood.low => 'Necesita agua',
          _Mood.high => 'Demasiada agua',
        },
        value: '${soil.toStringAsFixed(0)}%',
        icon: Icons.grass_rounded,
        progress: (soil / 100).clamp(0.0, 1.0),
        mood: mood,
      ));
    }

    final air = sensor.humedadAire;
    if (air != null) {
      final mood = air < 40
          ? _Mood.low
          : air > 75
              ? _Mood.high
              : _Mood.good;
      metrics.add(_FriendlyMetric(
        label: 'Aire',
        status: switch (mood) {
          _Mood.good => 'Ambiente cómodo',
          _Mood.low => 'Aire muy seco',
          _Mood.high => 'Aire muy húmedo',
        },
        value: '${air.toStringAsFixed(0)}%',
        icon: Icons.air_rounded,
        progress: (air / 100).clamp(0.0, 1.0),
        mood: mood,
      ));
    }

    final temp = sensor.temperatura;
    if (temp != null) {
      final mood = temp < 15
          ? _Mood.low
          : temp > 30
              ? _Mood.high
              : _Mood.good;
      metrics.add(_FriendlyMetric(
        label: 'Temperatura',
        status: switch (mood) {
          _Mood.good => 'Agradable',
          _Mood.low => 'Hace frío',
          _Mood.high => 'Hace calor',
        },
        value: '${units.formatTemp(temp)}${units.tempUnit}',
        icon: Icons.thermostat_rounded,
        progress: (temp / 40).clamp(0.0, 1.0),
        mood: mood,
      ));
    }

    if (!showHydro) return metrics;

    // ── Hydroponic-only metrics ───────────────────────────────────────────
    final ph = sensor.ph;
    if (ph != null) {
      final min = profile?.phMin ?? 5.5;
      final max = profile?.phMax ?? 7.0;
      final mood = ph < min
          ? _Mood.low
          : ph > max
              ? _Mood.high
              : _Mood.good;
      metrics.add(_FriendlyMetric(
        label: 'Agua (pH)',
        status: mood == _Mood.good ? 'Agua saludable' : 'Agua desequilibrada',
        value: ph.toStringAsFixed(1),
        icon: Icons.science_rounded,
        progress: (ph / 14).clamp(0.0, 1.0),
        mood: mood,
      ));
    }

    final ec = sensor.ecNormalized;
    final ecMax = profile?.ecMax ?? 3.0;
    final ecMood = profile == null
        ? _Mood.good
        : ec < profile!.ecMin
            ? _Mood.low
            : ec > profile!.ecMax
                ? _Mood.high
                : _Mood.good;
    metrics.add(_FriendlyMetric(
      label: 'Nutrientes',
      status: switch (ecMood) {
        _Mood.good => 'Alimento adecuado',
        _Mood.low => 'Faltan nutrientes',
        _Mood.high => 'Exceso de nutrientes',
      },
      value: '${units.formatEc(ec)} ${units.ecUnit}',
      icon: Icons.electric_bolt_rounded,
      progress: (ec / (ecMax * 1.5)).clamp(0.0, 1.0),
      mood: ecMood,
    ));

    final water = sensor.nivelAguaTanque;
    if (water != null) {
      final mood = water < 20 ? _Mood.low : _Mood.good;
      metrics.add(_FriendlyMetric(
        label: 'Tanque de agua',
        status: mood == _Mood.good ? 'Agua suficiente' : 'Rellena el tanque',
        value: '${water.toStringAsFixed(0)}%',
        icon: Icons.water_drop_rounded,
        progress: (water / 100).clamp(0.0, 1.0),
        mood: mood,
      ));
    }

    final fert = sensor.nivelFertilizanteTanque;
    if (fert != null) {
      final mood = fert < 20 ? _Mood.low : _Mood.good;
      metrics.add(_FriendlyMetric(
        label: 'Fertilizante',
        status: mood == _Mood.good ? 'Nivel suficiente' : 'Queda poco',
        value: '${fert.toStringAsFixed(0)}%',
        icon: Icons.eco_rounded,
        progress: (fert / 100).clamp(0.0, 1.0),
        mood: mood,
      ));
    }

    return metrics;
  }
}

// ── Hero: overall plant state ───────────────────────────────────────────────

class _HeroStatusCard extends StatelessWidget {
  final AppColorScheme c;
  final int total;
  final List<_FriendlyMetric> issues;
  final DataFreshness freshness;

  const _HeroStatusCard({
    required this.c,
    required this.total,
    required this.issues,
    required this.freshness,
  });

  @override
  Widget build(BuildContext context) {
    final okCount = total - issues.length;
    final progress = total == 0 ? 0.0 : okCount / total;

    final (color, icon, title, subtitle) = switch (issues.length) {
      0 => (
          c.success,
          Icons.sentiment_very_satisfied_rounded,
          '¡Tu planta está feliz!',
          'Todo está en orden. Sigue así.',
        ),
      1 => (
          c.warning,
          Icons.sentiment_neutral_rounded,
          'Tu planta necesita atención',
          '${issues.first.label}: ${issues.first.status.toLowerCase()}.',
        ),
      _ => (
          c.error,
          Icons.sentiment_dissatisfied_rounded,
          'Tu planta necesita ayuda',
          'Hay ${issues.length} cosas por revisar. Empieza por: '
              '${issues.first.status.toLowerCase()}.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: c.cardBorder),
        boxShadow: AppTokens.shadowSubtle(c.isDark),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                color: color,
                trackColor: c.cardBorder,
                strokeWidth: 7,
              ),
              child: Center(child: Icon(icon, color: color, size: 38)),
            ),
          ),
          const SizedBox(width: AppTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: c.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (freshness != DataFreshness.live) ...[
                  const SizedBox(height: 6),
                  Text(
                    freshness == DataFreshness.stale
                        ? 'Basado en datos de hace unos minutos'
                        : 'Basado en la última lectura recibida',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Per-metric ring card ────────────────────────────────────────────────────

class _MetricRingCard extends StatelessWidget {
  final _FriendlyMetric metric;
  final AppColorScheme c;

  const _MetricRingCard({required this.metric, required this.c});

  @override
  Widget build(BuildContext context) {
    final color = switch (metric.mood) {
      _Mood.good => c.success,
      _Mood.low => c.warning,
      _Mood.high => c.error,
    };

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingSm),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: c.cardBorder),
        boxShadow: AppTokens.shadowSubtle(c.isDark),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CustomPaint(
              painter: _RingPainter(
                progress: metric.progress,
                color: color,
                trackColor: c.cardBorder,
                strokeWidth: 5,
              ),
              child: Center(child: Icon(metric.icon, color: color, size: 22)),
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(
            metric.label,
            style: TextStyle(fontSize: 11, color: c.textMuted),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            metric.status,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            metric.value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ring painter (shared by hero + metric cards) ────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      progress != old.progress ||
      color != old.color ||
      trackColor != old.trackColor;
}
