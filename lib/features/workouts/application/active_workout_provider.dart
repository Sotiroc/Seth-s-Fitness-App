import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout_detail.dart';
import '../../../data/models/workout_set.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../exercises/application/exercise_list_provider.dart';

part 'active_workout_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<WorkoutDetail?> activeWorkoutDetail(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(workoutRepositoryProvider).watchActiveWorkoutDetail();
}

/// Exercises offered in the add-exercise picker. Tracks the same active-
/// pack filter used by the library list so toggling a pack off in
/// settings instantly removes those exercises from the picker too.
/// User-created exercises always appear regardless of pack toggles.
@Riverpod(keepAlive: true)
AsyncValue<List<Exercise>> workoutExerciseOptions(Ref ref) {
  return ref.watch(packAwareExerciseListProvider);
}

/// Stable identity of the active workout: workout id plus an ordered list of
/// exercise ids. Recomputes whenever [activeWorkoutDetailProvider] emits, but
/// only changes value when the workout itself or its exercise list changes —
/// so dependents that key off this don't rebuild on every set edit.
@Riverpod(keepAlive: true)
String activeWorkoutSignature(Ref ref) {
  final WorkoutDetail? detail = ref
      .watch(activeWorkoutDetailProvider)
      .asData
      ?.value;
  if (detail == null) return '';
  final Iterable<String> ids = detail.exercises.map((e) => e.exercise.id);
  return '${detail.workout.id}|${ids.join(',')}';
}

/// Most recent completed-workout sets for each exercise in the active
/// workout, keyed by exerciseId. Powers the "Previous" column on the
/// active workout screen.
///
/// Depends on [activeWorkoutSignatureProvider] (a stable string), not on the
/// full workout detail, so per-set edits — which emit a new detail on every
/// keystroke — do not trigger a refetch. The query only re-runs when the
/// active workout itself changes, or when an exercise is added / removed.
@Riverpod(keepAlive: true)
Future<Map<String, List<WorkoutSet>>> activeWorkoutPreviousSets(Ref ref) async {
  final String signature = ref.watch(activeWorkoutSignatureProvider);
  if (signature.isEmpty) return const <String, List<WorkoutSet>>{};

  final WorkoutDetail? detail = ref
      .read(activeWorkoutDetailProvider)
      .asData
      ?.value;
  if (detail == null || detail.exercises.isEmpty) {
    return const <String, List<WorkoutSet>>{};
  }
  final List<String> exerciseIds = detail.exercises
      .map((e) => e.exercise.id)
      .toList(growable: false);
  return ref
      .read(workoutRepositoryProvider)
      .getLastCompletedSetsForExercises(
        exerciseIds: exerciseIds,
        excludeWorkoutId: detail.workout.id,
      );
}

/// One-shot loader for a finished workout (summary screen).
@Riverpod(keepAlive: true)
Future<WorkoutDetail> workoutDetailById(Ref ref, String id) async {
  await ref.watch(databaseBootstrapProvider.future);
  return ref.watch(workoutRepositoryProvider).getWorkoutById(id);
}
