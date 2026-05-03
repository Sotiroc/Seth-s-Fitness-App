/// Pure functions for strength estimates derived from a single completed
/// set. Kept dependency-free so providers and tests can use them without
/// pulling Drift or Riverpod.
abstract final class StrengthFormulas {
  /// Epley estimated one-rep max in kilograms:
  ///
  /// ```
  /// 1RM = weight × (1 + reps / 30)
  /// ```
  ///
  /// Returns `null` when inputs aren't usable — missing weight, missing
  /// reps, or non-positive values. `reps == 1` correctly returns the
  /// original weight (the formula degenerates to `weight × 1`).
  static double? epley1RMKg({double? weightKg, int? reps}) {
    if (weightKg == null || reps == null) return null;
    if (weightKg <= 0 || reps <= 0) return null;
    return weightKg * (1.0 + reps / 30.0);
  }
}
