import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout_detail.dart';
import '../../../data/models/workout_set.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/repositories/workout_repository.dart';

part 'active_workout_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<WorkoutDetail?> activeWorkoutDetail(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(workoutRepositoryProvider).watchActiveWorkoutDetail();
}

@Riverpod(keepAlive: true)
Future<List<Exercise>> workoutExerciseOptions(Ref ref) async {
  await ref.watch(databaseBootstrapProvider.future);
  return ref.watch(exerciseRepositoryProvider).getAllExercises();
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
/// Watches [activeWorkoutSignatureProvider] (a stable string), not the full
/// workout detail, so per-set edits — which emit a new detail on every
/// keystroke — do not trigger a refetch. When the signature changes (an
/// exercise added or removed), only the *new* exercise ids are fetched
/// from the repository; previously-fetched exercises are served from a
/// per-workout cache held on the notifier instance, so a 6-exercise
/// workout where one exercise was just added does one lookup instead of
/// six.
@Riverpod(keepAlive: true)
class ActiveWorkoutPreviousSets extends _$ActiveWorkoutPreviousSets {
  final Map<String, List<WorkoutSet>> _cache = <String, List<WorkoutSet>>{};
  final Set<String> _queriedIds = <String>{};
  String _scopedToWorkoutId = '';

  @override
  Future<Map<String, List<WorkoutSet>>> build() async {
    final String signature = ref.watch(activeWorkoutSignatureProvider);
    if (signature.isEmpty) {
      _resetCache();
      return const <String, List<WorkoutSet>>{};
    }

    final WorkoutDetail? detail = ref
        .read(activeWorkoutDetailProvider)
        .asData
        ?.value;
    if (detail == null || detail.exercises.isEmpty) {
      _resetCache();
      return const <String, List<WorkoutSet>>{};
    }

    // Different workout entirely — drop everything we cached for the
    // previous one. Cache is scoped to a single workout's lifetime.
    if (_scopedToWorkoutId != detail.workout.id) {
      _resetCache();
      _scopedToWorkoutId = detail.workout.id;
    }

    final List<String> currentIds = detail.exercises
        .map((e) => e.exercise.id)
        .toList(growable: false);
    final List<String> missingIds = <String>[
      for (final String id in currentIds)
        if (!_queriedIds.contains(id)) id,
    ];

    if (missingIds.isNotEmpty) {
      final Map<String, List<WorkoutSet>> fetched = await ref
          .read(workoutRepositoryProvider)
          .getLastCompletedSetsForExercises(
            exerciseIds: missingIds,
            excludeWorkoutId: detail.workout.id,
          );
      // Mark every requested id as queried, even those without a hit, so
      // re-emissions don't re-walk history for exercises with no prior
      // sessions.
      _queriedIds.addAll(missingIds);
      _cache.addAll(fetched);
    }

    return <String, List<WorkoutSet>>{
      for (final String id in currentIds)
        if (_cache.containsKey(id)) id: _cache[id]!,
    };
  }

  void _resetCache() {
    _cache.clear();
    _queriedIds.clear();
    _scopedToWorkoutId = '';
  }
}

/// One-shot loader for a finished workout (summary screen).
@Riverpod(keepAlive: true)
Future<WorkoutDetail> workoutDetailById(Ref ref, String id) async {
  await ref.watch(databaseBootstrapProvider.future);
  return ref.watch(workoutRepositoryProvider).getWorkoutById(id);
}
