import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/sensor_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyStreamProvider);

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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Historial de Datos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
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
              style: const TextStyle(color: Colors.white70),
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
                      style: TextStyle(color: Colors.white60, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final data = history[index];
                return _HistoryCard(data: data);
              },
            );
          },
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HistoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final timestamp = data['timestamp'] as int?;
    final dateTime = timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : DateTime.now();
    final formattedTime = DateFormat('HH:mm:ss').format(dateTime);
    final formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
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
                      Colors.green.withValues(alpha: 0.3),
                      Colors.green.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MetricRow(
            label: 'Temperatura',
            value:
                '${(data['temperatura'] as num?)?.toStringAsFixed(1) ?? 'N/A'}°C',
            icon: Icons.thermostat_outlined,
            color: const Color(0xFFFF6B6B),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            label: 'pH',
            value: (data['ph'] as num?)?.toStringAsFixed(1) ?? 'N/A',
            icon: Icons.science_outlined,
            color: const Color(0xFF66BB6A),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            label: 'Conductividad',
            value:
                '${(data['conductividad'] as num?)?.toStringAsFixed(0) ?? 'N/A'} mS/cm',
            icon: Icons.electric_bolt_outlined,
            color: const Color(0xFF42A5F5),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            label: 'Nivel Agua',
            value:
                '${(data['nivel_agua_tanque'] as num?)?.toStringAsFixed(1) ?? 'N/A'}%',
            icon: Icons.water_drop_outlined,
            color: const Color(0xFF26C6DA),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
