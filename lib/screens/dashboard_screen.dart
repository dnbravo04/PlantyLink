import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sensor_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorAsync = ref.watch(sensorProvider);
    final plantaAsync = ref.watch(plantaActivaProvider);
    final service = ref.read(firebaseServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HydroTrack 🌱'),
        actions: [
          IconButton(
            icon: const Icon(Icons.eco),
            onPressed: () => Navigator.pushNamed(context, '/plantas'),
          ),
        ],
      ),
      body: sensorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sensor) {
          Future(() {
            ref.read(historialProvider.notifier).update((state) {
              final nuevo = [...state, sensor];
              return nuevo.length > 60
                  ? nuevo.sublist(nuevo.length - 60)
                  : nuevo;
            });
          });

          // Alertas basadas en perfil activo
          final alertas = <String>[];
          if (sensor.temperatura != null && sensor.temperatura! > 30) {
            alertas.add(
              '🌡️ Temperatura alta: ${sensor.temperatura!.toStringAsFixed(1)}°C',
            );
          }
          if (sensor.temperatura != null && sensor.temperatura! < 15) {
            alertas.add(
              '❄️ Temperatura baja: ${sensor.temperatura!.toStringAsFixed(1)}°C',
            );
          }
          if (sensor.humedad != null && sensor.humedad! < 60) {
            alertas.add(
              '🏜️ Humedad baja: ${sensor.humedad!.toStringAsFixed(1)}%',
            );
          }
          if (sensor.nivelAgua != null && sensor.nivelAgua! == false) {
            alertas.add('⚠️ Nivel de agua bajo');
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Planta activa
              plantaAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (planta) => Card(
                  color: Colors.green.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.eco, color: Colors.green),
                    title: Text(
                      'Cultivo activo: $planta',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/plantas'),
                      child: const Text('Cambiar'),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tarjetas de sensores
              Row(
                children: [
                  _SensorCard(
                    label: 'Temperatura',
                    value: sensor.temperatura != null
                        ? '${sensor.temperatura!.toStringAsFixed(1)}°C'
                        : 'N/A',
                    icon: Icons.thermostat,
                  ),
                  const SizedBox(width: 8),
                  _SensorCard(
                    label: 'Humedad',
                    value: sensor.humedad != null
                        ? '${sensor.humedad!.toStringAsFixed(1)}%'
                        : 'N/A',
                    icon: Icons.water_drop,
                  ),
                  const SizedBox(width: 8),
                  _SensorCard(
                    label: 'Agua',
                    value: sensor.nivelAgua != null
                        ? (sensor.nivelAgua! == true ? 'OK' : 'BAJO')
                        : 'N/A',
                    icon: Icons.opacity,
                    color: sensor.nivelAgua != null
                        ? (sensor.nivelAgua! == true
                              ? Colors.green
                              : Colors.red)
                        : Colors.grey,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Botón de riego
              FilledButton.icon(
                icon: const Icon(Icons.water),
                label: const Text('Riego manual (10s)'),
                onPressed: () async {
                  await service.activarBomba();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('💧 Bomba activada por 10 segundos'),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 24),

              // Alertas
              const Text(
                'Estado del sistema',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (alertas.isNotEmpty)
                ...alertas.map(
                  (a) => Card(
                    color: Colors.orange.shade50,
                    child: ListTile(
                      leading: const Icon(
                        Icons.warning_amber,
                        color: Colors.orange,
                      ),
                      title: Text(a),
                    ),
                  ),
                )
              else
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Todo en rango normal ✓'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? color;

  const _SensorCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
