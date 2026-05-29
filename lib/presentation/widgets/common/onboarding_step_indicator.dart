import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';

/// 3-step progress indicator used across onboarding screens.
class OnboardingStepIndicator extends StatelessWidget {
  final int currentStep; // 1, 2, or 3
  final AppColorScheme colors;

  const OnboardingStepIndicator({
    super.key,
    required this.currentStep,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepDot(step: 1, current: currentStep, label: 'Cuenta',      colors: colors),
        _StepLine(active: currentStep > 1, colors: colors),
        _StepDot(step: 2, current: currentStep, label: 'Perfil',      colors: colors),
        _StepLine(active: currentStep > 2, colors: colors),
        _StepDot(step: 3, current: currentStep, label: 'Dispositivo', colors: colors),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int step, current;
  final String label;
  final AppColorScheme colors;

  const _StepDot({
    required this.step,
    required this.current,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c        = colors;
    final isActive = step == current;
    final isDone   = step < current;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isActive || isDone) ? c.primary : c.cardBorder,
            boxShadow: isActive
                ? [BoxShadow(color: c.primary.withValues(alpha: 0.4), blurRadius: 8)]
                : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: (isActive || isDone) ? Colors.white : c.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? c.primary : c.textMuted,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool active;
  final AppColorScheme colors;

  const _StepLine({required this.active, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: active ? colors.primary : colors.cardBorder,
      ),
    );
  }
}
