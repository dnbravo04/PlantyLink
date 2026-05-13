import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/sensor_data.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/app_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyStreamProvider);
    final profileAsync = ref.watch(activePlantProfileProvider);

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Historial de Datos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (history) {
          if (history.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.white30),
                  SizedBox(height: 16),
                  Text(
                    'No hay datos de historial',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _ChartCard(
                  title: 'Temperatura (\u00b0C)',
                  lineColor: AppColors.success,
                  history: history,
                  valueExtractor: (s) => s.temperatura ?? 0,
                  minLimit: profileAsync.value?.tempMin,
                  maxLimit: profileAsync.value?.tempMax,
                ),
                const SizedBox(height: 20),
                _ChartCard(
                  title: 'pH',
                  lineColor: AppColors.info,
                  history: history,
                  valueExtractor: (s) => s.ph ?? 0,
                  minLimit: profileAsync.value?.phMin,
                  maxLimit: profileAsync.value?.phMax,
                ),
                const SizedBox(height: 20),
                _ChartCard(
                  title: 'Conductividad EC (mS/cm)',
                  lineColor: AppColors.warning,
                  history: history,
                  valueExtractor: (s) {
                    final raw = s.conductividad ?? 0;
                    return raw > 10 ? raw / 1000 : raw;
                  },
                  minLimit: profileAsync.value?.ecMin,
                  maxLimit: profileAsync.value?.ecMax,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Color lineColor;
  final List<SensorData> history;
  final double Function(SensorData) valueExtractor;
  final double? minLimit;
  final double? maxLimit;

  const _ChartCard({
    required this.title,
    required this.lineColor,
    required this.history,
    required this.valueExtractor,
    this.minLimit,
    this.maxLimit,
  });

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(history.length, (i) {
      return FlSpot(i.toDouble(), valueExtractor(history[i]));
    });

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.2;
    final bottom = minY - padding;
    final top = maxY + padding;

    final adjustedMinY = minLimit != null && minLimit! < bottom
        ? minLimit!
        : bottom;
    final adjustedMaxY = maxLimit != null && maxLimit! > top ? maxLimit! : top;

    final xInterval = history.length > 6
        ? (history.length / 5).floorToDouble().clamp(1.0, double.infinity)
        : 1.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (history.length - 1).toDouble(),
                minY: adjustedMinY,
                maxY: adjustedMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: xInterval,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= history.length) {
                          return const SizedBox.shrink();
                        }
                        final time = history[index].timestamp;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('HH:mm').format(time),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withValues(alpha: 0.12),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (minLimit != null)
                      HorizontalLine(
                        y: minLimit!,
                        color: Colors.white.withValues(alpha: 0.35),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.centerRight,
                          labelResolver: (line) =>
                              'Min ${minLimit!.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    if (maxLimit != null)
                      HorizontalLine(
                        y: maxLimit!,
                        color: Colors.white.withValues(alpha: 0.35),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.centerRight,
                          labelResolver: (line) =>
                              'Max ${maxLimit!.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
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
    );
  }
}
