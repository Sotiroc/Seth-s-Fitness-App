import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/workout.dart';
import '../../../data/models/workout_detail.dart';
import '../../../data/models/workout_exercise.dart';
import '../../../data/models/workout_set.dart';
import '../../../data/models/workout_set_kind.dart';
import '../../../data/repositories/workout_repository.dart';

part 'workout_session_controller.g.dart';

@Riverpod(keepAlive: true)
class WorkoutSessionController extends _$WorkoutSessionController {
  @override
  FutureOr<void> build() {}

  Future<Workout> startEmptyWorkout({String? notes}) {
    return _runMutation(() async {
      final Workout workout = await ref
          .read(workoutRepositoryProvider)
          .startWorkout(notes: notes);
      return workout;
    });
  }

  Future<Workout> updateWorkoutNotes({
    required String workoutId,
    required String? notes,
  }) {
    return _runMutation(() async {
      final Workout workout = await ref
          .read(workoutRepositoryProvider)
          .updateWorkoutNotes(workoutId: workoutId, notes: notes);
      return workout;
    });
  }

  Future<Workout> updateWorkoutName({
    required String workoutId,
    required String? name,
  }) {
    return _runMutation(() async {
      final Workout workout = await ref
          .read(workoutRepositoryProvider)
          .updateWorkoutName(workoutId: workoutId, name: name);
      return workout;
    });
  }

  Future<Workout> updateWorkoutIntensityScore({
    required String workoutId,
    required int? score,
  }) {
    return _runMutation(() async {
      final Workout workout = await ref
          .read(workoutRepositoryProvider)
          .updateWorkoutIntensityScore(workoutId: workoutId, score: score);
      return workout;
    });
  }

  Future<WorkoutExerciseDetail> addExercise({
    required String workoutId,
    required String exerciseId,
  }) {
    return _runMutation(() async {
      final WorkoutRepository repo = ref.read(workoutRepositoryProvider);
      final WorkoutExerciseDetail detail = await repo.addExerciseToWorkout(
        workoutId: workoutId,
        exerciseId: exerciseId,
      );
      final WorkoutSet firstSet = await repo.addSetToWorkoutExercise(
        detail.workoutExercise.id,
      );
      return WorkoutExerciseDetail(
        workoutExercise: detail.workoutExercise,
        exercise: detail.exercise,
        sets: <WorkoutSet>[firstSet],
      );
    });
  }

  Future<void> removeExercise(String workoutExerciseId) {
    return _runMutation(() async {
      await ref
          .read(workoutRepositoryProvider)
          .removeExerciseFromWorkout(workoutExerciseId);
    });
  }

  /// Updates the free-text note attached to a single workout-exercise
  /// instance (the per-workout-exercise note, not the global exercise
  /// definition). Pass `null` or empty string to clear it.
  Future<WorkoutExercise> updateExerciseNotes({
    required String workoutExerciseId,
    required String? notes,
  }) {
    return _runMutation(() async {
      final WorkoutExercise updated = await ref
          .read(workoutRepositoryProvider)
          .updateWorkoutExerciseNotes(
            workoutExerciseId: workoutExerciseId,
            notes: notes,
          );
      return updated;
    });
  }

  Future<WorkoutSet> addSet(
    String workoutExerciseId, {
    WorkoutSetKind kind = WorkoutSetKind.normal,
    String? parentSetId,
  }) {
    return _runMutation(() async {
      final WorkoutSet workoutSet = await ref
          .read(workoutRepositoryProvider)
          .addSetToWorkoutExercise(
            workoutExerciseId,
            kind: kind,
            parentSetId: parentSetId,
          );
      return workoutSet;
    });
  }

  /// Updates the "extras" attached to a set: kind (warm-up / normal / drop /
  /// failure), per-set RPE, and free-text note. The weight/reps/completed
  /// path stays on [updateSet].
  Future<WorkoutSet> updateSetExtras({
    required String workoutSetId,
    required WorkoutSetKind kind,
    int? rpe,
    String? note,
    String? parentSetId,
  }) {
    return _runMutation(() async {
      final WorkoutSet workoutSet = await ref
          .read(workoutRepositoryProvider)
          .updateWorkoutSetExtras(
            workoutSetId: workoutSetId,
            kind: kind,
            rpe: rpe,
            note: note,
            parentSetId: parentSetId,
          );
      return workoutSet;
    });
  }

  Future<void> removeSet(String workoutSetId) {
    return _runMutation(() async {
      await ref.read(workoutRepositoryProvider).deleteWorkoutSet(workoutSetId);
    });
  }

  Future<WorkoutSet> updateSet({
    required String workoutSetId,
    required double? weightKg,
    required int? reps,
    required double? distanceKm,
    required int? durationSeconds,
    required bool completed,
  }) {
    return _runMutation(() async {
      final WorkoutSet workoutSet = await ref
          .read(workoutRepositoryProvider)
          .updateWorkoutSet(
            workoutSetId: workoutSetId,
            weightKg: weightKg,
            reps: reps,
            distanceKm: distanceKm,
            durationSeconds: durationSeconds,
            completed: completed,
          );
      return workoutSet;
    });
  }

  Future<Workout> finishWorkout(String workoutId) {
    return _runMutation(() async {
      final Workout workout = await ref
          .read(workoutRepositoryProvider)
          .endWorkout(workoutId);
      return workout;
    });
  }

  Future<void> cancelWorkout(String workoutId) {
    return _runMutation(() async {
      await ref.read(workoutRepositoryProvider).cancelWorkout(workoutId);
    });
  }

  Future<T> _runMutation<T>(Future<T> Function() action) async {
    state = const AsyncLoading();
    try {
      final T result = await action();
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
