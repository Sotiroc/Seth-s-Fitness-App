/// The "type" of a logged set within an exercise.
///
/// - [normal] is the default working set. Counts toward total volume, the
///   X/Y completion counter, and PR detection.
/// - [warmUp] is a preparatory set. Excluded from volume, completion
///   counters, and PRs. Renders above working sets in row order.
/// - [drop] is a child of a parent working set (drop set). Indented under
///   its parent. Counts toward volume, but is excluded from PR detection
///   so a 60×4 drop following a 100×8 doesn't masquerade as a PR.
/// - [failure] is a working set the user pushed to true muscular failure.
///   Counts toward volume and PRs (it's still a working set with weight
///   and reps); the marker is informational. RPE 10 implies failure.
enum WorkoutSetKind {
  normal,
  warmUp,
  drop,
  failure;

  /// Tolerant decoder used by the database mapper. Falls back to [normal]
  /// for unknown values so a future-rename or write-from-newer-build
  /// doesn't crash older builds reading the row.
  static WorkoutSetKind fromName(String? raw) {
    if (raw == null) return WorkoutSetKind.normal;
    for (final WorkoutSetKind value in WorkoutSetKind.values) {
      if (value.name == raw) return value;
    }
    return WorkoutSetKind.normal;
  }

  /// True for the kinds that represent the "main work" of an exercise —
  /// counted toward volume and the X/Y completion fraction. Warm-ups are
  /// excluded; drops and failure sets remain working sets.
  bool get countsAsWorkingSet =>
      this == WorkoutSetKind.normal ||
      this == WorkoutSetKind.drop ||
      this == WorkoutSetKind.failure;

  /// True only for the kinds eligible for PR detection. Warm-ups are
  /// excluded (too light), and drop sets are excluded too — a drop is a
  /// fatigued continuation of the parent and not a fair PR comparison.
  bool get countsTowardPrs =>
      this == WorkoutSetKind.normal || this == WorkoutSetKind.failure;
}
