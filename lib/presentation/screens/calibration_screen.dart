import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/demo_mode_banner.dart';

// CalibrationService provider is now centralized in app_providers.dart
// as `calibrationServiceProvider` with device-scoped paths.

class CalibrationScreen extends ConsumerStatefulWidget {
  const CalibrationScreen({super.key});

  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends ConsumerState<CalibrationScreen> {
  bool _saving = false;

  // ── pH live readings ──────────────────────────────────────────────────────
  double? get _currentPh =>
      ref.watch(sensorProvider).value?.ph;

  // ── EC live reading ───────────────────────────────────────────────────────
  double? get _currentEc =>
      ref.watch(sensorProvider).value?.ecNormalized;

  Future<void> _calibratePh(double buffer) async {
    final reading = _currentPh;
    if (reading == null) {
      _snack('No hay lectura de pH disponible.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(calibrationServiceProvider)?.savePhCalibrationPoint(
            buffer: buffer,
            rawReading: reading,
          );
      _snack('Punto pH ${buffer.toStringAsFixed(1)} guardado (sensor: ${reading.toStringAsFixed(2)})');
    } catch (e) {
      _snack('No se pudo guardar la calibración. Intenta de nuevo.',
          error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _calibrateEc(double knownEc) async {
    final reading = _currentEc;
    if (reading == null) {
      _snack('No hay lectura de EC disponible.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(calibrationServiceProvider)?.saveEcCalibration(
            knownEc: knownEc,
            rawReading: reading,
          );
      _snack('EC calibrado (${reading.toStringAsFixed(2)} → ${knownEc.toStringAsFixed(2)} mS/cm)');
    } catch (e) {
      _snack('No se pudo guardar la calibración. Intenta de nuevo.',
          error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetPh() async {
    setState(() => _saving = true);
    try {
      await ref.read(calibrationServiceProvider)?.clearPhCalibration();
      _snack('Calibración de pH restablecida.');
    } catch (_) {
      _snack('Error al restablecer.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetEc() async {
    setState(() => _saving = true);
    try {
      await ref.read(calibrationServiceProvider)?.clearEcCalibration();
      _snack('Calibración de EC restablecida.');
    } catch (_) {
      _snack('Error al restablecer.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    AppToast.show(context,
        message: msg, type: error ? ToastType.error : ToastType.success);
  }

  // ── EC custom value dialog ─────────────────────────────────────────────────
  Future<void> _showEcDialog() async {
    final ctrl = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final dc = AppColors.of(ctx);
          return AlertDialog(
            backgroundColor: dc.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Solución de referencia EC', style: TextStyle(color: dc.textPrimary)),
            content: TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Conductividad conocida (mS/cm)',
                labelStyle: TextStyle(color: dc.textMuted),
                suffixText: 'mS/cm',
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: dc.textSecondary))),
              TextButton(onPressed: () => Navigator.pop(ctx, true),  child: Text('Calibrar',  style: TextStyle(color: dc.primary))),
            ],
          );
        },
      );
      if (confirmed != true) return;
      final value = double.tryParse(ctrl.text.replaceAll(',', '.'));
      if (value == null || value <= 0) {
        _snack('Valor inválido.', error: true);
        return;
      }
      await _calibrateEc(value);
    } finally {
      ctrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final currentPh = _currentPh;
    final currentEc = _currentEc;
    final cal = ref.watch(calibrationDataProvider).value ?? {};

    final phLowRaw    = cal['ph_low_raw'] as num?;
    final phHighRaw   = cal['ph_high_raw'] as num?;
    final ecFactor    = cal['ec_factor'] as num?;
    final ecKnown     = cal['ec_known'] as num?;
    final hasPhCal    = phLowRaw != null || phHighRaw != null;
    final hasEcCal    = ecFactor != null;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Calibración de sensores'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const DemoModeBanner(),
            // ── Info banner ────────────────────────────────────────────────
            AppCard(
              margin: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: c.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Los valores de calibración se guardan en Firebase y el ESP32 los aplica automáticamente al leer los sensores.',
                      style: TextStyle(color: c.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // ── pH ─────────────────────────────────────────────────────────
            _SectionTitle('Calibración de pH', color: c.info),
            const SizedBox(height: 4),
            Text(
              'Calibración de 2 puntos. Sumerge el sensor en cada solución tampón y presiona el botón cuando la lectura sea estable.',
              style: TextStyle(color: c.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _LiveReading(
              label: 'Lectura actual pH',
              value: currentPh?.toStringAsFixed(2) ?? '—',
              color: c.info,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CalibrationButton(
                    label: 'Tampón pH 4.0',
                    subtitle: phLowRaw != null
                        ? 'Raw: ${phLowRaw.toStringAsFixed(2)} ✓'
                        : 'Sin calibrar',
                    color: c.info,
                    onTap: _saving ? null : () => _calibratePh(4.0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CalibrationButton(
                    label: 'Tampón pH 7.0',
                    subtitle: phHighRaw != null
                        ? 'Raw: ${phHighRaw.toStringAsFixed(2)} ✓'
                        : 'Sin calibrar',
                    color: c.info,
                    onTap: _saving ? null : () => _calibratePh(7.0),
                  ),
                ),
              ],
            ),
            if (hasPhCal) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                icon: Icon(Icons.restart_alt_rounded, size: 16, color: c.textMuted),
                label: Text('Restablecer calibración pH', style: TextStyle(color: c.textMuted, fontSize: 12)),
                onPressed: _saving ? null : _resetPh,
              ),
            ],

            const SizedBox(height: 28),

            // ── EC ─────────────────────────────────────────────────────────
            _SectionTitle('Calibración de EC', color: c.warning),
            const SizedBox(height: 4),
            Text(
              'Calibración de 1 punto. Sumerge el sensor en una solución de conductividad conocida e ingresa el valor.',
              style: TextStyle(color: c.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _LiveReading(
              label: 'Lectura actual EC',
              value: currentEc != null ? '${currentEc.toStringAsFixed(2)} mS/cm' : '—',
              color: c.warning,
            ),
            const SizedBox(height: 12),
            if (hasEcCal)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Factor actual: ×${ecFactor.toStringAsFixed(3)}  (${ecKnown?.toStringAsFixed(2)} mS/cm)',
                  style: TextStyle(color: c.success, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            _CalibrationButton(
              label: 'Calibrar EC con solución conocida',
              subtitle: hasEcCal ? 'Factor guardado ✓' : 'Sin calibrar',
              color: c.warning,
              onTap: _saving ? null : _showEcDialog,
            ),
            if (hasEcCal) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                icon: Icon(Icons.restart_alt_rounded, size: 16, color: c.textMuted),
                label: Text('Restablecer calibración EC', style: TextStyle(color: c.textMuted, fontSize: 12)),
                onPressed: _saving ? null : _resetEc,
              ),
            ],

            if (_saving) ...[
              const SizedBox(height: 24),
              Center(child: CircularProgressIndicator(color: c.primary)),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Small shared widgets ───────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionTitle(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
    );
  }
}

class _LiveReading extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _LiveReading({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Icon(Icons.sensors_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: c.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CalibrationButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  const _CalibrationButton({required this.label, required this.subtitle, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: c.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
