import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sensor_provider.dart';
import '../models/sensor_data.dart';
import '../core/firebase_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Color _getPhColor(double pH) {
    if (pH < 6.0) return const Color(0xFFFF6B6B);
    if (pH < 6.5) return const Color(0xFFFFA726);
    if (pH < 7.0) return const Color(0xFFFFCA28);
    if (pH < 8.0) return const Color(0xFF66BB6A);
    return const Color(0xFF43A047);
  }

  Color _getFertilizanteColor(double nivel) {
    if (nivel < 20) return const Color(0xFFFF6B6B);
    if (nivel < 40) return const Color(0xFFFFA726);
    if (nivel < 60) return const Color(0xFFFFCA28);
    if (nivel < 80) return const Color(0xFF66BB6A);
    return const Color(0xFF43A047);
  }

  Color _getConductividadColor(double conductividad) {
    if (conductividad < 800) return const Color(0xFFFF6B6B);
    if (conductividad < 1200) return const Color(0xFFFFA726);
    if (conductividad < 1600) return const Color(0xFFFFCA28);
    if (conductividad < 2000) return const Color(0xFF66BB6A);
    return const Color(0xFF43A047);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorAsync = ref.watch(sensorProvider);
    final plantaAsync = ref.watch(plantaActivaProvider);
    final service = ref.read(firebaseServiceProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header con título y configuración
              SliverToBoxAdapter(child: _buildHeader(plantaAsync, context)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Mediciones circulares
              SliverToBoxAdapter(child: _buildCircularMetrics(sensorAsync)),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // Controles de Bombas mejorados
              SliverToBoxAdapter(
                child: _buildPumpControls(sensorAsync, service),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // Estados del Sistema
              SliverToBoxAdapter(child: _buildSystemStatus(sensorAsync)),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<String> plantaAsync, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HydroTrack',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              plantaAsync.when(
                loading: () => const Text(
                  'Cargando...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                error: (_, _) => const Text(
                  'Sin configurar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                data: (planta) => GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/plantas'),
                  child: Row(
                    children: [
                      Text(
                        planta,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white38,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/history'),
                  child: const Icon(
                    Icons.history_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/plantas'),
                  child: const Icon(
                    Icons.eco_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularMetrics(AsyncValue<SensorData> sensorAsync) {
    return sensorAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      ),
      error: (_, _) => const Center(
        child: Text(
          'Error de conexión',
          style: TextStyle(color: Colors.white70),
        ),
      ),
      data: (sensor) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _CircularMetric(
              value: sensor.temperatura ?? 0,
              maxValue: 50,
              unit: '°C',
              label: 'Temperatura',
              color: _getTemperatureColor(sensor.temperatura ?? 0),
              icon: Icons.thermostat_outlined,
            ),
            const SizedBox(width: 20),
            _CircularMetric(
              value: sensor.ph ?? 0,
              maxValue: 14,
              unit: '',
              label: 'pH',
              color: _getPhColor(sensor.ph ?? 7),
              icon: Icons.science_outlined,
            ),
            const SizedBox(width: 20),
            _CircularMetric(
              value: sensor.conductividad ?? 0,
              maxValue: 3000,
              unit: 'mS/cm',
              label: 'Conductividad',
              color: _getConductividadColor(sensor.conductividad ?? 0),
              icon: Icons.electric_bolt_outlined,
            ),
            const SizedBox(width: 20),
            _CircularMetric(
              value: sensor.nivelAguaTanque ?? 0,
              maxValue: 100,
              unit: '%',
              label: 'Nivel Agua',
              color: _getWaterLevelColor(sensor.nivelAguaTanque ?? 0),
              icon: Icons.water_drop_outlined,
            ),
            const SizedBox(width: 20),
            _CircularMetric(
              value: sensor.nivelFertilizanteTanque ?? 0,
              maxValue: 100,
              unit: '%',
              label: 'Fertilizante',
              color: _getFertilizanteColor(sensor.nivelFertilizanteTanque ?? 0),
              icon: Icons.eco_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPumpControls(
    AsyncValue<SensorData> sensorAsync,
    FirebaseService service,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Control de Bombas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          sensorAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            error: (_, _) => const Text(
              'Error de conexión',
              style: TextStyle(color: Colors.white70),
            ),
            data: (sensor) => Column(
              children: [
                _PumpButton(
                  title: 'Bomba de Agua',
                  icon: Icons.water_drop,
                  isActive: sensor.bombaAgua ?? false,
                  color: const Color(0xFF42A5F5),
                  onToggle: (value) => service.controlarBombaAgua(value),
                ),
                const SizedBox(height: 16),
                _PumpButton(
                  title: 'Bomba Fertilizante',
                  icon: Icons.eco,
                  isActive: sensor.bombaFertilizante ?? false,
                  color: const Color(0xFF66BB6A),
                  onToggle: (value) =>
                      service.controlarBombaFertilizante(value),
                ),
                const SizedBox(height: 16),
                _PumpButton(
                  title: 'Dosificadora Ácido',
                  icon: Icons.science,
                  isActive: sensor.bombaDosificadoraAcido ?? false,
                  color: const Color(0xFFFFA726),
                  onToggle: (value) =>
                      service.controlarDosificadoraAcido(value),
                ),
                const SizedBox(height: 16),
                _PumpButton(
                  title: 'Dosificadora Básico',
                  icon: Icons.local_drink,
                  isActive: sensor.bombaDosificadoraBasico ?? false,
                  color: const Color(0xFFAB47BC),
                  onToggle: (value) =>
                      service.controlarDosificadoraBasico(value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus(AsyncValue<SensorData> sensorAsync) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estados del Sistema',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          sensorAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            error: (_, _) => const Text(
              'Error de conexión',
              style: TextStyle(color: Colors.white70),
            ),
            data: (sensor) => Column(
              children: [
                _StatusItem(
                  title: 'ESP32',
                  isActive: sensor.conectado ?? false,
                  icon: Icons.wifi,
                  color: const Color(0xFF66BB6A),
                ),
                const SizedBox(height: 16),
                _StatusItem(
                  title: 'Tanque de Agua',
                  isActive: sensor.nivelAgua ?? false,
                  icon: Icons.opacity,
                  color: const Color(0xFF42A5F5),
                ),
                const SizedBox(height: 16),
                _StatusItem(
                  title: 'Tanque Fertilizante',
                  isActive:
                      (sensor.nivelFertilizanteTanque != null &&
                      sensor.nivelFertilizanteTanque! > 20),
                  icon: Icons.eco,
                  color: const Color(0xFFAB47BC),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 15) return const Color(0xFF42A5F5);
    if (temp > 30) return const Color(0xFFFF6B6B);
    return const Color(0xFF66BB6A);
  }

  Color _getWaterLevelColor(double level) {
    if (level < 20) return const Color(0xFFFF6B6B);
    if (level < 50) return const Color(0xFFFFA726);
    return const Color(0xFF66BB6A);
  }
}

class _CircularMetric extends StatelessWidget {
  final double value;
  final double maxValue;
  final String unit;
  final String label;
  final Color color;
  final IconData icon;

  const _CircularMetric({
    required this.value,
    required this.maxValue,
    required this.unit,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / maxValue).clamp(0.0, 1.0);

    return SizedBox(
      width: 140,
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _CircularProgressPainter(
                progress: progress,
                color: color,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      '${value.toStringAsFixed(1)}$unit',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final strokeWidth = 12.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _PumpButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final Color color;
  final void Function(bool) onToggle;

  const _PumpButton({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!isActive),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)]
                : [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.02),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive
                      ? [color, color.withValues(alpha: 0.8)]
                      : [
                          color.withValues(alpha: 0.3),
                          color.withValues(alpha: 0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive ? 'Activada' : 'Desactivada',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive ? color : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 60,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? color : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isActive
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String title;
  final bool isActive;
  final IconData icon;
  final Color color;

  const _StatusItem({
    required this.title,
    required this.isActive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]
              : [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [color, color.withValues(alpha: 0.8)]
                    : [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white60,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isActive ? color : Colors.grey,
                  isActive
                      ? color.withValues(alpha: 0.8)
                      : Colors.grey.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              isActive ? 'Activo' : 'Inactivo',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
