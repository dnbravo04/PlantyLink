import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../models/sensor_data.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/app_card.dart';

enum _TimeRange {
  h1('1h', Duration(hours: 1)),
  h6('6h', Duration(hours: 6)),
  h24('24h', Duration(hours: 24)),
  d7('7d', Duration(days: 7)),
  all('Todo', Duration.zero);

  const _TimeRange(this.label, this.duration);
  final String label;
  final Duration duration;
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _TimeRange _selectedRange = _TimeRange.all;

  List<SensorData> _filterByRange(List<SensorData> history) {
    if (_selectedRange == _TimeRange.all) return history;
    final cutoff = DateTime.now().subtract(_selectedRange.duration);
    return history.where((s) => s.timestamp.isAfter(cutoff)).toList();
  }

  Future<void> _exportCsv(BuildContext context, List<SensorData> history) async {
    final buf = StringBuffer();
    buf.writeln('timestamp,temperatura,ph,conductividad,nivel_agua,nivel_fertilizante');
    final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
    for (final s in history) {
      buf.writeln([
        fmt.format(s.timestamp),
        s.temperatura?.toStringAsFixed(2) ?? '',
        s.ph?.toStringAsFixed(2) ?? '',
        s.conductividad?.toStringAsFixed(2) ?? '',
        s.nivelAguaTanque?.toStringAsFixed(1) ?? '',
        s.nivelFertilizanteTanque?.toStringAsFixed(1) ?? '',
      ].join(','));
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/historial_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buf.toString());
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Historial PlantyLink',
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyStreamProvider);
    final profileAsync = ref.watch(activePlantProfileProvider);
    final c = AppColors.of(context);

    return AppScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Historial de Datos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          historyAsync.whenData((h) => h).value?.isNotEmpty == true
              ? IconButton(
                  tooltip: 'Exportar CSV',
                  icon: const Icon(Icons.download_rounded),
                  onPressed: () => _exportCsv(context, historyAsync.value!),
                )
              : const SizedBox.shrink(),
        ],
      ),
      body: historyAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(c.primary),
          ),
        ),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: TextStyle(color: c.textSecondary),
          ),
        ),
        data: (history) {
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: c.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No hay datos de historial',
                    style: TextStyle(color: c.textMuted, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final filtered = _filterByRange(history);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTimeRangeSelector(c),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'Sin datos en este rango de tiempo',
                      style: TextStyle(color: c.textMuted, fontSize: 14),
                    ),
                  )
                else ...[
                  _ChartCard(
                    title: 'Temperatura (°C)',
                    lineColor: c.success,
                    history: filtered,
                    valueExtractor: (s) => s.temperatura ?? 0,
                    minLimit: profileAsync.value?.tempMin,
                    maxLimit: profileAsync.value?.tempMax,
                  ),
                  const SizedBox(height: 20),
                  _ChartCard(
                    title: 'pH',
                    lineColor: c.info,
                    history: filtered,
                    valueExtractor: (s) => s.ph ?? 0,
                    minLimit: profileAsync.value?.phMin,
                    maxLimit: profileAsync.value?.phMax,
                  ),
                  const SizedBox(height: 20),
                  _ChartCard(
                    title: 'Conductividad EC (mS/cm)',
                    lineColor: c.warning,
                    history: filtered,
                    valueExtractor: (s) => s.ecNormalized,
                    minLimit: profileAsync.value?.ecMin,
                    maxLimit: profileAsync.value?.ecMax,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeRangeSelector(AppColorScheme c) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: _TimeRange.values.map((range) {
          final selected = range == _selectedRange;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRange = range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? c.primary.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: selected
                      ? Border.all(color: c.primary.withValues(alpha: 0.4))
                      : null,
                ),
                child: Center(
                  child: Text(
                    range.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? c.primary : c.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
    final c = AppColors.of(context);

    final spots = List.generate(history.length, (i) {
      return FlSpot(i.toDouble(), valueExtractor(history[i]));
    });

    if (spots.isEmpty) return const SizedBox.shrink();

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

    final gridColor = c.cardBorder.withValues(alpha: 0.5);
    final limitLineColor = c.textMuted.withValues(alpha: 0.5);

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: c.textPrimary,
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
                    color: gridColor,
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
                            style: TextStyle(
                              color: c.textMuted,
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
                          style: TextStyle(
                            color: c.textMuted,
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
                        color: limitLineColor,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.centerRight,
                          labelResolver: (line) =>
                              'Min ${minLimit!.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: c.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    if (maxLimit != null)
                      HorizontalLine(
                        y: maxLimit!,
                        color: limitLineColor,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.centerRight,
                          labelResolver: (line) =>
                              'Max ${maxLimit!.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: c.textMuted,
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
