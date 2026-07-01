import 'package:flutter/services.dart';

/// Standardized haptic feedback across PlantyLink.
///
/// Usage: `AppHaptics.light()` for state changes, `AppHaptics.medium()`
/// for confirmed actions, `AppHaptics.selection()` for tab/scroll events.
sealed class AppHaptics {
  AppHaptics._();

  /// Light tap — state changes: toggles, selections, tab switches.
  static void light() => HapticFeedback.lightImpact();

  /// Medium tap — confirmed actions: profile saved, device linked.
  static void medium() => HapticFeedback.mediumImpact();

  /// Heavy tap — destructive or critical: delete account, acid dosing.
  static void heavy() => HapticFeedback.heavyImpact();

  /// Tick — scrolling through items, paging.
  static void selection() => HapticFeedback.selectionClick();
}
