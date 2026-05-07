import 'workout_set_kind.dart';

class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.workoutExerciseId,
    required this.setNumber,
    required this.completed,
    this.weightKg,
    this.reps,
    this.distanceKm,
    this.durationSeconds,
    this.laps,
    this.floors,
    this.calories,
    this.completedAt,
    this.updatedAt,
    this.startedAt,
    this.kind = WorkoutSetKind.normal,
    this.parentSetId,
    this.rpe,
    this.note,
  });

  final String id;
  final String workoutExerciseId;
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final double? distanceKm;
  final int? durationSeconds;

  /// Pool laps for swimming sets. Cardio-only metric, populated when the
  /// exercise's `trackedMetrics` includes [CardioMetric.laps].
  final int? laps;

  /// Floors / flights climbed for stair-master sets. Cardio-only metric,
  /// populated when the exercise's `trackedMetrics` includes
  /// [CardioMetric.floors].
  final int? floors;

  /// Manually-entered calorie count for any cardio session that opts
  /// into the [CardioMetric.calories] metric.
  final int? calories;

  final bool completed;

  /// When the set was last marked completed. Set when `completed` flips
  /// false→true, cleared when it flips back. Used as the workout's
  /// `endedAt` timestamp during the auto-close-stale-workout flow so the
  /// recorded duration reflects training time rather than wall-clock idle.
  final DateTime? completedAt;

  /// When the set was last inserted/updated. Bumped on every mutation
  /// regardless of completion state — drives the inactivity timer for
  /// the auto-close flow even when the user is editing values without
  /// checking the completed box.
  final DateTime? updatedAt;

  /// When the user first interacted with the set (first edit of any field
  /// or first completion). Once captured it never moves — re-saves keep
  /// the original value. Combined with `completedAt` this gives true
  /// per-set timing for future analytics.
  final DateTime? startedAt;

  /// Set classification (warm-up / normal / drop / failure). Drives badge
  /// rendering, ordering, and which sets feed volume / PR / completion
  /// calculations.
  final WorkoutSetKind kind;

  /// Only set when [kind] is [WorkoutSetKind.drop]; points at the parent
  /// working set this drop belongs to. The UI uses this to indent the row
  /// under its parent and to render the drop chain in the PREVIOUS column.
  final String? parentSetId;

  /// Optional 1–10 per-set RPE ("Rate of Perceived Exertion"). Independent
  /// of the per-workout intensityScore on Workout. The summary screen
  /// auto-suggests the workout RPE from the max of these once any per-set
  /// RPE has been logged.
  final int? rpe;

  /// Free-text per-set note (e.g. "left shoulder felt tight"). Trimmed
  /// at write time; null/empty means "no note".
  final String? note;

  WorkoutSet copyWith({
    String? id,
    String? workoutExerciseId,
    int? setNumber,
    double? weightKg,
    int? reps,
    double? distanceKm,
    int? durationSeconds,
    int? laps,
    int? floors,
    int? calories,
    bool? completed,
    DateTime? completedAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    WorkoutSetKind? kind,
    String? parentSetId,
    int? rpe,
    String? note,
    bool clearWeightKg = false,
    bool clearReps = false,
    bool clearDistanceKm = false,
    bool clearDurationSeconds = false,
    bool clearLaps = false,
    bool clearFloors = false,
    bool clearCalories = false,
    bool clearCompletedAt = false,
    bool clearStartedAt = false,
    bool clearParentSetId = false,
    bool clearRpe = false,
    bool clearNote = false,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      setNumber: setNumber ?? this.setNumber,
      weightKg: clearWeightKg ? null : weightKg ?? this.weightKg,
      reps: clearReps ? null : reps ?? this.reps,
      distanceKm: clearDistanceKm ? null : distanceKm ?? this.distanceKm,
      durationSeconds: clearDurationSeconds
          ? null
          : durationSeconds ?? this.durationSeconds,
      laps: clearLaps ? null : laps ?? this.laps,
      floors: clearFloors ? null : floors ?? this.floors,
      calories: clearCalories ? null : calories ?? this.calories,
      completed: completed ?? this.completed,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: clearStartedAt ? null : startedAt ?? this.startedAt,
      kind: kind ?? this.kind,
      parentSetId: clearParentSetId ? null : parentSetId ?? this.parentSetId,
      rpe: clearRpe ? null : rpe ?? this.rpe,
      note: clearNote ? null : note ?? this.note,
    );
  }

  /// Convenience: a set has "extras" attached when anything beyond the
  /// default Normal/no-RPE/no-note shape is set. Used by the row to decide
  /// whether to render the small badge cluster.
  bool get hasExtras =>
      kind != WorkoutSetKind.normal ||
      rpe != null ||
      (note != null && note!.trim().isNotEmpty);
}
