import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/plant_profile.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/app_card.dart';

class PlantSelectorScreen extends ConsumerWidget {
  const PlantSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantRepo = ref.read(plantRepositoryProvider);
    final plants = plantRepo.availablePlants;

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Seleccionar Cultivo'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: plants.length,
        itemBuilder: (context, i) {
          final planta = plants[i];
          return _PlantCard(
            planta: planta,
            onTap: () async {
              await plantRepo.selectPlant(planta);
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
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 16),
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
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Temp: ${planta.tempMin}\u2013${planta.tempMax}\u00b0C',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'pH: ${planta.phMin}\u2013${planta.phMax}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'EC: ${planta.ecMin}\u2013${planta.ecMax} mS/cm',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
