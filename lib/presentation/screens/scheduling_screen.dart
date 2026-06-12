import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/pump_schedule.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/app_card.dart';

const _actuadorLabels = {
  'bomba_agua': 'Bomba de agua',
  'bomba_fertilizante': 'Bomba de fertilizante',
  'ventilador': 'Ventilador',
};

const _actuadorIcons = {
  'bomba_agua': Icons.water_drop_rounded,
  'bomba_fertilizante': Icons.eco_rounded,
  'ventilador': Icons.air_rounded,
};

// 0=Mon … 6=Sun
const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

class SchedulingScreen extends ConsumerWidget {
  const SchedulingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final schedulesAsync = ref.watch(schedulesProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Programación de actuadores'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: c.primary,
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: schedulesAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: c.primary)),
        error: (e, _) => Center(
          child: Text('Error: $e', style: TextStyle(color: c.textSecondary)),
        ),
        data: (schedules) {
          if (schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule_rounded, size: 64, color: c.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No hay programaciones',
                    style: TextStyle(color: c.textMuted, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca + para agregar una',
                    style: TextStyle(color: c.textMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            itemCount: schedules.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final s = schedules[i];
              return _ScheduleTile(
                schedule: s,
                onToggle: (active) => ref
                    .read(scheduleServiceProvider)
                    ?.updateSchedule(s.copyWith(activo: active)),
                onDelete: () =>
                    ref.read(scheduleServiceProvider)?.deleteSchedule(s.id!),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _ScheduleDialog(
        onSave: (schedule) async =>
            ref.read(scheduleServiceProvider)?.addSchedule(schedule),
      ),
    );
  }
}

// ── Schedule tile ─────────────────────────────────────────────────────────────

class _ScheduleTile extends StatelessWidget {
  final PumpSchedule schedule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _ScheduleTile({
    required this.schedule,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final icon =
        _actuadorIcons[schedule.actuador] ?? Icons.power_settings_new_rounded;
    final label =
        _actuadorLabels[schedule.actuador] ?? schedule.actuador;
    final daysText = schedule.diasSemana.isEmpty
        ? 'Cada día'
        : schedule.diasSemana.map((d) => _dayLabels[d]).join(' · ');

    return AppCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (schedule.activo ? c.primary : c.textMuted)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: schedule.activo ? c.primary : c.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: schedule.activo ? c.textPrimary : c.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${schedule.horaInicio}  ·  ${schedule.duracionMinutos} min',
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  daysText,
                  style: TextStyle(color: c.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: schedule.activo,
            onChanged: onToggle,
            activeThumbColor: c.primary,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: c.error, size: 20),
            onPressed: onDelete,
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}

// ── Add schedule dialog ───────────────────────────────────────────────────────

class _ScheduleDialog extends StatefulWidget {
  final Future<void> Function(PumpSchedule) onSave;

  const _ScheduleDialog({required this.onSave});

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  String _actuador = 'bomba_agua';
  TimeOfDay _hora = TimeOfDay.now();
  final _duracionCtrl = TextEditingController(text: '5');
  final Set<int> _dias = {};
  bool _saving = false;

  @override
  void dispose() {
    _duracionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _hora);
    if (picked != null) setState(() => _hora = picked);
  }

  Future<void> _submit() async {
    final dur = int.tryParse(_duracionCtrl.text);
    if (dur == null || dur <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duración inválida.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final schedule = PumpSchedule(
        actuador: _actuador,
        horaInicio:
            '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}',
        duracionMinutos: dur,
        diasSemana: _dias.toList()..sort(),
      );
      await widget.onSave(schedule);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return AlertDialog(
      backgroundColor: c.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Nueva programación',
          style: TextStyle(color: c.textPrimary, fontSize: 17)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Actuator selector
            Text('Actuador',
                style: TextStyle(color: c.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _actuador,
              dropdownColor: c.cardBackground,
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: c.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.cardBorder),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _actuadorLabels.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _actuador = v!),
            ),
            const SizedBox(height: 16),

            // Time picker
            Text('Hora de inicio',
                style: TextStyle(color: c.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: c.primary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _hora.format(context),
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Duration
            Text('Duración (minutos)',
                style: TextStyle(color: c.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _duracionCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: c.background,
                suffixText: 'min',
                suffixStyle: TextStyle(color: c.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.cardBorder),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),

            // Days of week
            Text('Días (vacío = todos los días)',
                style: TextStyle(color: c.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final selected = _dias.contains(i);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _dias.remove(i);
                    } else {
                      _dias.add(i);
                    }
                  }),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: selected
                          ? c.primary
                          : c.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? c.primary
                            : c.cardBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _dayLabels[i],
                        style: TextStyle(
                          color: selected ? Colors.white : c.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child:
              Text('Cancelar', style: TextStyle(color: c.textSecondary)),
        ),
        TextButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: c.primary),
                )
              : Text('Guardar', style: TextStyle(color: c.primary)),
        ),
      ],
    );
  }
}
