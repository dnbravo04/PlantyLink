import 'package:flutter/material.dart';
import '../../../core/utils/units.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/sensor_data.dart';
import '../../../models/plant_profile.dart';

class SimpleMetric extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final bool isInRange;
  final String? unit;

  const SimpleMetric({
    super.key,
    required this.label,
    this.value,
    required this.icon,
    required this.isInRange,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInRange ? c.success : c.error,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isInRange ? Icons.check_circle : Icons.warning,
            color: isInRange ? c.success : c.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            isInRange ? '$label normal' : '$label fuera de rango',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isInRange ? c.success : c.error,
            ),
            textAlign: TextAlign.center,
          ),
          if (value != null) ...[
            const SizedBox(height: 4),
            Text(
              value!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SimpleMetricsGrid extends StatelessWidget {
  final SensorData sensor;
  final PlantProfile? profile;
  final UnitsPrefs units;

  const SimpleMetricsGrid({
    super.key,
    required this.sensor,
    this.profile,
    this.units = const UnitsPrefs(),
  });

  @override
  Widget build(BuildContext context) {
    final ecVal = sensor.ecNormalized;

    final tempInRange = _isTempInRange(sensor.temperatura ?? 0);
    final phInRange = _isPhInRange(sensor.ph ?? 0, profile);
    final ecInRange = _isEcInRange(ecVal, profile);
    final waterInRange = _isLevelInRange(sensor.nivelAguaTanque ?? 0);
    final fertInRange = _isLevelInRange(sensor.nivelFertilizanteTanque ?? 0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SimpleMetric(
                label: 'Temperatura',
                value:
                    '${units.formatTemp(sensor.temperatura ?? 0)}${units.tempUnit}',
                icon: Icons.thermostat_outlined,
                isInRange: tempInRange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SimpleMetric(
                label: 'pH',
                value: sensor.ph?.toStringAsFixed(1),
                icon: Icons.science_outlined,
                isInRange: phInRange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SimpleMetric(
                label: 'Conductividad',
                value: '${units.formatEc(ecVal)} ${units.ecUnit}',
                icon: Icons.electric_bolt_outlined,
                isInRange: ecInRange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SimpleMetric(
                label: 'Nivel Agua',
                value: '${sensor.nivelAguaTanque?.toStringAsFixed(0)}%',
                icon: Icons.water_drop_outlined,
                isInRange: waterInRange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SimpleMetric(
          label: 'Nivel Fertilizante',
          value: '${sensor.nivelFertilizanteTanque?.toStringAsFixed(0)}%',
          icon: Icons.eco_outlined,
          isInRange: fertInRange,
        ),
        // Cultivo en tierra: solo si el dispositivo reporta humedad de suelo.
        if (sensor.humedadSuelo != null) ...[
          const SizedBox(height: 8),
          SimpleMetric(
            label: 'Humedad de suelo',
            value: '${sensor.humedadSuelo!.toStringAsFixed(0)}%',
            icon: Icons.grass_outlined,
            isInRange: _isSoilInRange(sensor.humedadSuelo!, profile),
          ),
        ],
      ],
    );
  }

  bool _isTempInRange(double temp) {
    return temp >= 15 && temp <= 30;
  }

  bool _isSoilInRange(double soil, PlantProfile? profile) {
    final min = profile?.humedadSueloMin;
    final max = profile?.humedadSueloMax;
    if (min != null && soil < min) return false;
    if (max != null && soil > max) return false;
    return true;
  }

  bool _isPhInRange(double ph, PlantProfile? profile) {
    if (profile == null) return true;
    return ph >= profile.phMin && ph <= profile.phMax;
  }

  bool _isEcInRange(double ec, PlantProfile? profile) {
    if (profile == null) return true;
    return ec >= profile.ecMin && ec <= profile.ecMax;
  }

  bool _isLevelInRange(double level) {
    return level >= 20;
  }
}
