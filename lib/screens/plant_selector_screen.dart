import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plant_profile.dart';
import '../providers/sensor_provider.dart';

class PlantSelectorScreen extends ConsumerWidget {
  const PlantSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(firebaseServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar cultivo')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: PlantCatalog.plantas.length,
        itemBuilder: (context, i) {
          final planta = PlantCatalog.plantas[i];
          return Card(
            child: ListTile(
              leading: Text(planta.emoji, style: const TextStyle(fontSize: 32)),
              title: Text(
                planta.nombre,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Temp: ${planta.tempMin}–${planta.tempMax}°C  '
                'Humedad: ${planta.humMin}–${planta.humMax}%  '
                'pH: ${planta.phMin}–${planta.phMax}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await service.activarPerfil(planta);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${planta.emoji} Perfil ${planta.nombre} activado',
                      ),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
