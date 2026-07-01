import 'package:flutter/material.dart';

/// A small colored dot that pulses (scales) to indicate live status.
///
/// Pulse speed adapts to severity:
/// - Normal (green): slow 3s pulse
/// - Warning (amber): medium 1.5s pulse
/// - Critical (red): fast 0.8s pulse
/// - Offline (grey): no pulse, reduced opacity
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  final bool isOffline;
  final Duration? pulseDuration;

  const PulsingDot({
    super.key,
    required this.color,
    this.size = 8,
    this.isOffline = false,
    this.pulseDuration,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  Duration get _effectiveDuration {
    if (widget.pulseDuration != null) return widget.pulseDuration!;
    if (widget.isOffline) return const Duration(seconds: 3);
    // Guess severity by hue
    final hue = HSLColor.fromColor(widget.color).hue;
    if (hue < 30 || hue > 330) return const Duration(milliseconds: 800); // red
    if (hue < 60) return const Duration(milliseconds: 1500); // amber
    return const Duration(seconds: 3); // green / other
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _effectiveDuration);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (!widget.isOffline) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingDot old) {
    super.didUpdateWidget(old);
    if (widget.isOffline != old.isOffline || widget.color != old.color) {
      _ctrl.duration = _effectiveDuration;
      if (widget.isOffline) {
        _ctrl.stop();
        _ctrl.value = 0;
      } else {
        _ctrl.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: widget.isOffline
          ? const AlwaysStoppedAnimation(1.0)
          : _scaleAnim,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isOffline
              ? widget.color.withValues(alpha: 0.4)
              : widget.color,
          boxShadow: widget.isOffline
              ? null
              : [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
        ),
      ),
    );
  }
}
