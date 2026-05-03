/// One point on the per-exercise strength chart: the date of a session,
/// the best estimated 1RM achieved that session, and the source set that
/// produced it (so the tooltip can show "100 kg × 5 → est 1RM 116.7 kg").
class StrengthPoint {
  const StrengthPoint({
    required this.date,
    required this.oneRepMaxKg,
    required this.bestSetWeightKg,
    required this.bestSetReps,
  });

  /// Workout start time. UTC.
  final DateTime date;

  /// Best Epley-estimated 1RM across all completed sets in that session,
  /// in kilograms.
  final double oneRepMaxKg;

  /// Weight of the set that produced [oneRepMaxKg]. Surfaced in the chart
  /// tooltip alongside [bestSetReps].
  final double bestSetWeightKg;

  /// Reps of the set that produced [oneRepMaxKg].
  final int bestSetReps;
}
