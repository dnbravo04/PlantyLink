import 'package:flutter/material.dart';
import 'app_color_scheme.dart';

/// Centralized color palette for PlantyLink.
///
/// - Static `const` fields (e.g. [AppColors.background]) point to the **dark**
///   theme values and exist for backward compatibility with existing widgets
///   that use them in `const` contexts.
/// - Use [AppColors.of(context)] in new code to get the correct palette for
///   the current brightness (dark or light).
sealed class AppColors {
  AppColors._();

  // ── Dark theme backward-compat static consts ─────────────────────────────
  static const Color background    = Color(0xFF07110E);
  static const Color cardBackground = Color(0xFF0F1F18);
  static const Color cardBorder    = Color(0xFF1E3A2C);
  static const Color primary       = Color(0xFF10B981);
  static const Color success       = Color(0xFF34D399);
  static const Color warning       = Color(0xFFF59E0B);
  static const Color error         = Color(0xFFEF4444);
  static const Color info          = Color(0xFF38BDF8); // Sky-400 (blue, distinct from success)
  static const Color accent        = Color(0xFF6EE7B7); // Emerald-300 (lighter than primary)
  static const Color textPrimary   = Color(0xFFECFDF5);
  static const Color textSecondary = Color(0xFF6EE7B7);
  static const Color textMuted     = Color(0xFF5B8A72); // Raised from 0x2D5944 for WCAG 4.5:1
  static const Color textDisabled  = Color(0xFF3D5C4A); // Raised from 0x1E3A2C for visibility

  // ── Full dark scheme (warm grays) ─────────────────────────────────────────
  static const AppColorScheme dark = AppColorScheme(
    brightness:     Brightness.dark,
    background:     Color(0xFF0C0F0E), // Warmer dark background
    cardBackground: Color(0xFF141A17), // Slightly warmer card
    cardBorder:     Color(0xFF243830), // More visible borders
    primary:        Color(0xFF10B981),
    success:        Color(0xFF34D399),
    warning:        Color(0xFFF59E0B),
    error:          Color(0xFFEF4444),
    info:           Color(0xFF38BDF8), // Sky-400 — distinct from success green
    accent:         Color(0xFF6EE7B7), // Emerald-300 — lighter complement to primary
    textPrimary:    Color(0xFFECFDF5),
    textSecondary:  Color(0xFF6EE7B7),
    textMuted:      Color(0xFF5B8A72), // WCAG 4.5:1 on 0x07110E background
    textDisabled:   Color(0xFF3D5C4A), // Visible but clearly disabled
  );

  // ── Full light scheme (warm palette) ────────────────────────────────────
  static const AppColorScheme light = AppColorScheme(
    brightness:     Brightness.light,
    background:     Color(0xFFFAFAF5), // Warm cream instead of mint green
    cardBackground: Color(0xFFFFFFFF),
    cardBorder:     Color(0xFFE8E5DC), // Warm beige instead of green
    primary:        Color(0xFF059669),
    success:        Color(0xFF10B981),
    warning:        Color(0xFFD97706),
    error:          Color(0xFFDC2626),
    info:           Color(0xFF0284C7), // Sky-600 — distinct blue for information
    accent:         Color(0xFFF97316), // Warm orange for secondary CTAs
    textPrimary:    Color(0xFF1A1A1A), // Neutral dark instead of teal
    textSecondary:  Color(0xFF4B5563), // Gray-600 for readability
    textMuted:      Color(0xFF9CA3AF), // Gray-400
    textDisabled:   Color(0xFFD1D5DB), // Gray-300
  );

  /// Returns the scheme matching the current [BuildContext] brightness.
  static AppColorScheme of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
