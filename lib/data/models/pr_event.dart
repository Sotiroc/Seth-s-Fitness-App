import 'exercise_type.dart';

/// What kind of personal record this entry represents. Drives the row
/// label in the UI and disambiguates the value fields on [PrEvent].
///
/// PR types are derived per exercise type:
///
/// - **Weighted**: [bestSet], [e1rm], [repMax].
/// - **Bodyweight**: [mostRepsInSet], [mostRepsInWorkout].
/// - **Cardio**: [longestDistance], [longestDuration].
enum PrType {
  /// Heaviest single set ever for the exercise (weight × reps).
  /// Weighted exercises only.
  bestSet,

  /// Highest Epley-estimated one-rep max ever for the exercise.
  /// Weighted exercises only.
  e1rm,

  /// Heaviest weight at a specific rep count (e.g. a new 5RM). Tracked
  /// per distinct rep count the user has logged. Weighted exercises only.
  repMax,

  /// Most reps in a single set ever for the exercise. Bodyweight only.
  mostRepsInSet,

  /// Most reps across all sets in a single workout for the exercise —
  /// the "session volume" PR. Bodyweight only.
  mostRepsInWorkout,

  /// Longest distance covered in a single cardio set. Cardio only.
  longestDistance,

  /// Longest duration in a single cardio set. Cardio only.
  longestDuration,
}

/// One personal-record moment. Surfaced on the workout summary screen,
/// exercise history sheet, history list (badge + flat-PR mode), and the
/// home-page PR feed card.
///
/// PR data is fully derived — there is no `is_pr` flag in the database.
/// Walking every completed PR-eligible set in chronological order and
/// tracking per-exercise running maxes per [PrType] gives a stable feed
/// that automatically self-heals when the user edits or deletes earlier
/// sessions.
///
/// First-workout suppression: an exercise's first-ever completed workout
/// only establishes the baseline maxes; no PRs are emitted for it. The
/// next time the exercise appears, sets that exceed the baseline can
/// fire PRs. This stops "first leg day fires 30 PRs."
class PrEvent {
  const PrEvent({
    required this.type,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseType,
    required this.workoutId,
    required this.achievedAt,
    this.setId,
    this.weightKg,
    this.reps,
    this.distanceKm,
    this.durationSeconds,
    this.oneRepMaxKg,
    this.repCountForRepMax,
  });

  /// Which kind of record this entry captures. Together with
  /// [exerciseType] it tells the UI which value fields are populated.
  final PrType type;

  final String exerciseId;
  final String exerciseName;
  final ExerciseType exerciseType;

  /// The parent workout this PR was achieved in. Used by the History
  /// list to flag workouts that contained at least one PR, and by the
  /// flat-PR list mode to deep-link a row back to its workout.
  final String workoutId;

  /// The originating set's id. `null` for the
  /// [PrType.mostRepsInWorkout] aggregate, which spans multiple sets.
  final String? setId;

  /// The parent workout's `startedAt` timestamp (UTC). Drives ordering
  /// and "X days ago" labels.
  final DateTime achievedAt;

  // Value fields — which ones are populated depends on [type].

  /// Weighted PRs ([bestSet], [e1rm], [repMax]) — the lift's weight in kg.
  final double? weightKg;

  /// Weighted ([bestSet], [e1rm], [repMax]) and bodyweight
  /// ([mostRepsInSet], [mostRepsInWorkout]) — number of reps, or for
  /// [mostRepsInWorkout] the total reps across the session.
  final int? reps;

  /// Cardio ([longestDistance]) — distance in kilometres.
  final double? distanceKm;

  /// Cardio ([longestDuration]) — duration in seconds.
  final int? durationSeconds;

  /// Weighted ([e1rm], also informational on [bestSet] / [repMax]) —
  /// Epley-estimated 1RM in kg.
  final double? oneRepMaxKg;

  /// [PrType.repMax] only — the rep count this PR was set at (e.g. 5
  /// for a 5RM). Lets the UI render "5RM" / "8RM" labels.
  final int? repCountForRepMax;
}
