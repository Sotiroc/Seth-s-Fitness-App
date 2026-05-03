/// One personal-record moment: the set that bumped the user's estimated
/// 1RM for an exercise above all prior sets.
///
/// Surfaced in the PR feed on the Progression page and used to count
/// PRs-per-month in the hero stats strip. Computed on the fly by walking
/// every completed weighted set in chronological order and tracking the
/// running max per exercise — no stored "is_pr" flag, so the timeline
/// stays correct even if the user deletes earlier sets.
class PrEvent {
  const PrEvent({
    required this.exerciseId,
    required this.exerciseName,
    required this.setId,
    required this.weightKg,
    required this.reps,
    required this.oneRepMaxKg,
    required this.achievedAt,
  });

  final String exerciseId;
  final String exerciseName;
  final String setId;
  final double weightKg;
  final int reps;

  /// Epley-estimated 1RM for the source set in kilograms. By construction
  /// this is strictly greater than every prior PR on the same exercise.
  final double oneRepMaxKg;

  /// The parent workout's `startedAt` timestamp (UTC). Used for
  /// chronological ordering and "achieved N days ago" labels.
  final DateTime achievedAt;
}
