import 'exercise_type.dart';

/// One PR captured at recap-generation time. Stored as JSON inside the
/// recap row so later edits to the source workout/set don't mutate the
/// snapshot. Mirrors the relevant fields of [PrEvent] but is detached
/// from the live workout graph (no exerciseId / setId).
class WeeklyRecapPr {
  const WeeklyRecapPr({
    required this.exerciseName,
    required this.exerciseType,
    required this.type,
    this.weightKg,
    this.reps,
    this.distanceKm,
    this.durationSeconds,
    this.laps,
    this.floors,
    this.calories,
    this.oneRepMaxKg,
    this.repCountForRepMax,
  });

  final String exerciseName;
  final ExerciseType exerciseType;

  /// Stored as the [PrType.name] string at write time. Decoded tolerantly
  /// so renaming an enum value later doesn't crash old snapshots.
  final String type;

  final double? weightKg;
  final int? reps;
  final double? distanceKm;
  final int? durationSeconds;
  final int? laps;
  final int? floors;
  final int? calories;
  final double? oneRepMaxKg;
  final int? repCountForRepMax;
}

/// Persisted summary of one calendar week (Mon→Sun in the user's local
/// time, stored as UTC at the boundaries). Generated automatically by
/// [WeeklyRecapRepository.generateRecapsIfNeeded] on app open.
class WeeklyRecap {
  const WeeklyRecap({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.workoutCount,
    required this.totalVolumeKg,
    required this.totalDurationSeconds,
    required this.prs,
    required this.dailyVolumeKg,
    required this.generatedAt,
    this.averageRpe,
    this.prevWorkoutCount,
    this.prevTotalVolumeKg,
  });

  final String id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int workoutCount;
  final double totalVolumeKg;
  final int totalDurationSeconds;
  final double? averageRpe;
  final List<WeeklyRecapPr> prs;

  /// Length-7 list of kg volume per day, Mon→Sun.
  final List<double> dailyVolumeKg;
  final int? prevWorkoutCount;
  final double? prevTotalVolumeKg;
  final DateTime generatedAt;

  int get prCount => prs.length;
}
