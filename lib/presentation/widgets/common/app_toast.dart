import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_tokens.dart';

/// Toast notification type determines icon and accent color.
enum ToastType { success, warning, error, info }

/// Floating toast that slides in from the top with auto-dismiss.
///
/// Usage:
/// ```dart
/// AppToast.show(context, message: 'Guardado', type: ToastType.success);
/// ```
class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppTokens.durationNormal,
      reverseDuration: AppTokens.durationFast,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppTokens.curveSnappy));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    _ctrl.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _ctrl.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  (IconData, Color) _typeConfig(AppColorScheme c) => switch (widget.type) {
    ToastType.success => (Icons.check_circle_rounded, c.success),
    ToastType.warning => (Icons.warning_rounded, c.warning),
    ToastType.error   => (Icons.error_rounded, c.error),
    ToastType.info    => (Icons.info_rounded, c.info),
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (icon, accentColor) = _typeConfig(c);
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + AppTokens.spacingMd,
      left: AppTokens.spacingMd,
      right: AppTokens.spacingMd,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacingMd,
                vertical: AppTokens.spacingMd,
              ),
              decoration: BoxDecoration(
                color: c.cardBackground,
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                ),
                boxShadow: AppTokens.shadowMedium(c.isDark),
              ),
              child: Row(
                children: [
                  Icon(icon, color: accentColor, size: 20),
                  const SizedBox(width: AppTokens.spacingSm),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
