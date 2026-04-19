import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/workout.dart';
import '../../../data/models/workout_detail.dart';
import '../../../data/models/workout_set.dart';
import '../../../data/repositories/workout_repository.dart';
import 'active_workout_provider.dart';

final AsyncNotifierProvider<WorkoutSessionController, void>
workoutSessionControllerProvider =
    AsyncNotifierProvider<WorkoutSessionController, void>(
      WorkoutSessionController.new,
    );

class WorkoutSessionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<Workout> startEmptyWorkout({String? notes}) {
    return _runMutation(() async {
      final Workout workout = await ref
          .read(workoutRepositoryProvider)
          .startWorkout(notes: notes);
      _invalidateWorkoutState();
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
      _invalidateWorkoutState();
      return workout;
    });
  }

  Future<WorkoutExerciseDetail> addExercise({
    required String workoutId,
    required String exerciseId,
  }) {
    return _runMutation(() async {
      final WorkoutExerciseDetail detail = await ref
          .read(workoutRepositoryProvider)
          .addExerciseToWorkout(workoutId: workoutId, exerciseId: exerciseId);
      _invalidateWorkoutState();
      return detail;
    });
  }

  Future<WorkoutSet> addSet(String workoutExerciseId) {
    return _runMutation(() async {
      final WorkoutSet workoutSet = await ref
          .read(workoutRepositoryProvider)
          .addSetToWorkoutExercise(workoutExerciseId);
      _invalidateWorkoutState();
      return workoutSet;
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
      _invalidateWorkoutState();
      return workoutSet;
    });
  }

  Future<Workout> finishWorkout(String workoutId) {
    return _runMutation(() async {
      final Workout workout = await ref
          .read(workoutRepositoryProvider)
          .endWorkout(workoutId);
      _invalidateWorkoutState();
      return workout;
    });
  }

  Future<void> cancelWorkout(String workoutId) {
    return _runMutation(() async {
      await ref.read(workoutRepositoryProvider).cancelWorkout(workoutId);
      _invalidateWorkoutState();
    });
  }

  void _invalidateWorkoutState() {
    ref.invalidate(activeWorkoutDetailProvider);
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
