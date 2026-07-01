import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Shared axis transition for settings → sub-screen navigation.
///
/// Content slides vertically (new screen up, old screen down) with a
/// crossfade. Duration: 400ms with easeInOutCubic.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required WidgetBuilder builder,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: AppTokens.curveSnappy,
              reverseCurve: Curves.easeIn,
            );

            // Incoming: slide up + fade in
            final slideIn = Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved);

            // Outgoing: slide down + fade out
            final slideOut = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(0, -0.04),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: AppTokens.curveSnappy,
            ));

            return SlideTransition(
              position: slideOut,
              child: FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: slideIn,
                  child: child,
                ),
              ),
            );
          },
        );
}
