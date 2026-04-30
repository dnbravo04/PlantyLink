import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plant_profile.dart';
import '../providers/sensor_provider.dart';

class PlantSelectorScreen extends ConsumerWidget {
  const PlantSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoService = ref.read(demoDataServiceProvider);

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
            'Seleccionar Cultivo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: demoService.plants.length,
          itemBuilder: (context, i) {
            final planta = demoService.plants[i];
            return _PlantCard(
              planta: planta,
              onTap: () async {
                await demoService.changePlant(i);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${planta.emoji} Perfil ${planta.nombre} activado',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  final PlantProfile planta;
  final VoidCallback onTap;

  const _PlantCard({required this.planta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.3),
                    Colors.green.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(planta.emoji, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planta.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Temp: ${planta.tempMin}–${planta.tempMax}°C',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  Text(
                    'Humedad: ${planta.humMin}–${planta.humMax}%',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  Text(
                    'pH: ${planta.phMin}–${planta.phMax}',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white60, size: 24),
          ],
        ),
      ),
    );
  }
}
