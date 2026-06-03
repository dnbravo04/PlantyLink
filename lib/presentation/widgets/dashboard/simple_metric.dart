import 'package:flutter/material.dart';
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
              style: TextStyle(fontSize: 12, color: c.textSecondary),
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

  const SimpleMetricsGrid({super.key, required this.sensor, this.profile});

  @override
  Widget build(BuildContext context) {
    final ecRaw = sensor.conductividad ?? 0;
    final ecVal = ecRaw > 10 ? ecRaw / 1000 : ecRaw;

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
                value: '${sensor.temperatura?.toStringAsFixed(1)}°C',
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
                value: '${ecVal.toStringAsFixed(2)} mS/cm',
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
      ],
    );
  }

  bool _isTempInRange(double temp) {
    return temp >= 15 && temp <= 30;
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
