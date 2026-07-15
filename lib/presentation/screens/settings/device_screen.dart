import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_config.dart';
import '../../../core/demo_data_service.dart';
import '../../../core/services/device_context.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/utils/app_page_route.dart';
import '../../../core/utils/haptics.dart';
import '../../../models/linked_device.dart';
import '../../../models/sensor_data.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/sensor_health_card.dart';
import '../../../app.dart';
import '../calibration_screen.dart';
import '../scheduling_screen.dart';

/// Device status, reconnection, calibration, and scheduling access.
class DeviceScreen extends ConsumerWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final sensorAsync = ref.watch(sensorProvider);
    final staleness =
        ref.watch(dataStalenessProvider).value ?? DataStaleness.none;

    final activeId = kDemoMode
        ? ref.watch(demoActiveDeviceProvider).value ?? DemoDataService.kFullDeviceId
        : ref.watch(deviceContextProvider).value?.esp32Id;
    final devices = ref.watch(linkedDevicesProvider).value ?? const [];
    var activeName = 'ESP32';
    for (final d in devices) {
      if (d.id == activeId) {
        activeName = d.nombre;
        break;
      }
    }

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Mi dispositivo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildDeviceStatusCard(
              sensorAsync, staleness, c, context, activeName, activeId),
          const SizedBox(height: 24),
          Text('Mis dispositivos',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary)),
          const SizedBox(height: 8),
          _buildDevicesCard(context, ref, c),
          const SizedBox(height: 16),
          // Diagnóstico de deriva de sensores (antes vivía en Agronomía).
          const SensorHealthCard(),
          const SizedBox(height: 16),
          _buildNavRow(
            icon: Icons.tune_rounded,
            color: c.info,
            title: 'Calibración de sensores',
            subtitle: 'pH y EC de 2 puntos',
            onTap: () => Navigator.push(context,
                AppPageRoute(builder: (_) => const CalibrationScreen())),
            c: c,
          ),
          const SizedBox(height: 8),
          _buildNavRow(
            icon: Icons.schedule_rounded,
            color: c.success,
            title: 'Programación de actuadores',
            subtitle: 'Bombas, ventiladores',
            onTap: () => Navigator.push(context,
                AppPageRoute(builder: (_) => const SchedulingScreen())),
            c: c,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusCard(
      AsyncValue<SensorData> sensorAsync,
      DataStaleness staleness,
      AppColorScheme c,
      BuildContext context,
      String activeName,
      String? activeId) {
    return sensorAsync.when(
      data: (sensor) {
        // Estado derivado de la frescura del timestamp, no del booleano
        // `conectado` que el firmware nunca vuelve a poner en false (Eje 4).
        final (statusColor, statusText) = switch (staleness.freshness) {
          DataFreshness.live => (c.success, '$activeName conectado'),
          DataFreshness.stale => (
              c.warning,
              '$activeName sin reportar hace ${staleness.ageMinutes} min',
            ),
          DataFreshness.offline => (c.error, '$activeName desconectado'),
        };
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.cardBorder, width: 1.5),
          ),
          child: Column(
            children: [
              Row(children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.cardBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.qr_code_2_rounded,
                      color: c.textSecondary, size: 16),
                ),
                const SizedBox(width: 12),
                Text('ID: ${activeId ?? '—'}',
                    style: TextStyle(fontSize: 13, color: c.textSecondary)),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.onboardingEsp32),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reconectar ESP32',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.info,
                    side: BorderSide(color: c.cardBorder, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          Center(child: CircularProgressIndicator(strokeWidth: 2, color: c.primary)),
      error: (_, _) =>
          Text('Error al cargar estado', style: TextStyle(color: c.textSecondary)),
    );
  }

  // ── Multi-device switcher ───────────────────────────────────────────────

  Widget _buildDevicesCard(
      BuildContext context, WidgetRef ref, AppColorScheme c) {
    final devicesAsync = ref.watch(linkedDevicesProvider);
    final activeId = kDemoMode
        ? ref.watch(demoActiveDeviceProvider).value ?? DemoDataService.kFullDeviceId
        : ref.watch(deviceContextProvider).value?.esp32Id;

    return Container(
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        children: [
          ...devicesAsync.value?.map(
                  (d) => _buildDeviceRow(context, ref, c, d, activeId)) ??
              const [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                ),
              ],
          Divider(height: 1, color: c.cardBorder),
          ListTile(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(16))),
            leading: Icon(Icons.add_circle_outline_rounded,
                color: c.primary, size: 22),
            title: Text('Agregar dispositivo',
                style: TextStyle(
                    color: c.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.onboardingEsp32),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(BuildContext context, WidgetRef ref,
      AppColorScheme c, LinkedDevice device, String? activeId) {
    final isActive = device.id == activeId;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isActive ? c.primary : c.textMuted).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.memory_rounded,
            color: isActive ? c.primary : c.textMuted, size: 20),
      ),
      title: Text(device.nombre,
          style: TextStyle(
              color: c.textPrimary,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
      subtitle: Text(
        isActive ? '${device.id} · activo' : device.id,
        style: TextStyle(
            color: isActive ? c.primary : c.textMuted, fontSize: 12),
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert_rounded, color: c.textMuted, size: 20),
        onSelected: (action) => switch (action) {
          'renombrar' => _renameDevice(context, ref, device),
          _ => _unlinkDevice(context, ref, device, isActive),
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'renombrar', child: Text('Renombrar')),
          PopupMenuItem(value: 'desvincular', child: Text('Desvincular')),
        ],
      ),
      onTap: isActive ? null : () => _switchDevice(context, ref, device),
    );
  }

  Future<void> _switchDevice(
      BuildContext context, WidgetRef ref, LinkedDevice device) async {
    AppHaptics.selection();
    if (kDemoMode) {
      ref.read(demoDataServiceProvider)?.switchDevice(device.id);
    } else {
      await ref
          .read(deviceServiceProvider)
          .cambiarDispositivoActivo(device.id);
    }
    if (context.mounted) {
      AppToast.show(context,
          message: 'Ahora ves ${device.nombre}', type: ToastType.success);
    }
  }

  Future<void> _renameDevice(
      BuildContext context, WidgetRef ref, LinkedDevice device) async {
    if (kDemoMode) {
      AppToast.show(context,
          message: 'No disponible en modo demo', type: ToastType.info);
      return;
    }
    final controller = TextEditingController(text: device.nombre);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar dispositivo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == device.nombre) return;
    await ref.read(deviceServiceProvider).renombrarDispositivo(device.id, name);
    if (context.mounted) {
      AppToast.show(context,
          message: 'Dispositivo renombrado', type: ToastType.success);
    }
  }

  Future<void> _unlinkDevice(BuildContext context, WidgetRef ref,
      LinkedDevice device, bool isActive) async {
    if (kDemoMode) {
      AppToast.show(context,
          message: 'No disponible en modo demo', type: ToastType.info);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Desvincular dispositivo?'),
        content: Text(isActive
            ? '${device.nombre} es tu dispositivo activo. Al desvincularlo '
                'se cambiará a otro dispositivo vinculado (si existe). '
                'Los datos del dispositivo no se borran.'
            : 'Podrás volver a vincular ${device.nombre} escaneando su '
                'etiqueta NFC o código QR. Sus datos no se borran.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.of(ctx).error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Desvincular')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(deviceServiceProvider).desvincularESP32(device.id);
    if (context.mounted) {
      AppToast.show(context,
          message: 'Dispositivo desvinculado', type: ToastType.info);
    }
  }

  Widget _buildNavRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required AppColorScheme c,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
                color: c.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: TextStyle(color: c.textMuted, fontSize: 12)),
        trailing: Icon(Icons.chevron_right_rounded, color: c.textMuted),
        onTap: onTap,
      ),
    );
  }
}
