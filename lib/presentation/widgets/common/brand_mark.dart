import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Reusable PlantyLink brand mark.
///
/// Renders the colourful circular logo ("PlantyLink logo.png") and, optionally,
/// the "PlantyLink" wordmark ("PlantyLink letra.png"). The wordmark is a
/// fixed-colour (dark/green) PNG, so on dark surfaces it is tinted white to
/// stay legible.
class BrandMark extends StatelessWidget {
  static const String logoAsset = 'assets/branding/plantylink_logo.png';
  static const String wordmarkAsset = 'assets/branding/plantylink_wordmark.png';
  static const String fullAsset = 'assets/branding/plantylink_full.png';

  /// Diameter of the circular logo.
  final double logoSize;

  /// Whether to render the wordmark next to / under the logo.
  final bool showWordmark;

  /// Width of the wordmark image (its height scales automatically).
  final double wordmarkWidth;

  /// Gap between the logo and the wordmark.
  final double spacing;

  /// Lay the logo and wordmark out horizontally instead of stacked.
  final bool horizontal;

  /// Force the wordmark colour treatment: `true` tints it white (for dark or
  /// coloured surfaces), `false` keeps the original green. When `null` it
  /// follows the current theme brightness.
  final bool? onDarkSurface;

  const BrandMark({
    super.key,
    this.logoSize = 88,
    this.showWordmark = true,
    this.wordmarkWidth = 190,
    this.spacing = 16,
    this.horizontal = false,
    this.onDarkSurface,
  });

  @override
  Widget build(BuildContext context) {
    final tintWhite = onDarkSurface ?? AppColors.of(context).isDark;

    final logo = Image.asset(
      logoAsset,
      width: logoSize,
      height: logoSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (!showWordmark) return logo;

    Widget wordmark = Image.asset(
      wordmarkAsset,
      width: wordmarkWidth,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    if (tintWhite) {
      wordmark = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        child: wordmark,
      );
    }

    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [logo, SizedBox(width: spacing), Flexible(child: wordmark)],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [logo, SizedBox(height: spacing), wordmark],
    );
  }
}
