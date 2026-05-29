/// Recommended pH correction for a hydroponic reservoir.
///
/// Calculated by [AgronomicService.calculatePHCorrection].
/// The estimated volume is approximate — always adjust slowly and retest.
class PhCorrection {
  final double currentPH;
  final double targetPH;
  final double volumeLiters;

  /// 'acid' (pH Down) or 'base' (pH Up).
  final String correctionType;

  /// Estimated mL of pH adjuster needed for [volumeLiters] of solution.
  final double estimatedMLNeeded;

  final String notes;

  const PhCorrection({
    required this.currentPH,
    required this.targetPH,
    required this.volumeLiters,
    required this.correctionType,
    required this.estimatedMLNeeded,
    required this.notes,
  });

  bool get needsAcid => correctionType == 'acid';
  double get delta => (targetPH - currentPH).abs();
}
