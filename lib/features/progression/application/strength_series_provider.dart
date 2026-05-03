import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/strength_formulas.dart';
import '../../../data/database_bootstrap.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/exercise_history_day.dart';
import '../../../data/models/exercise_type.dart';
import '../../../data/models/strength_point.dart';
import '../../../data/models/workout_set.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../exercises/application/exercise_history_provider.dart';
import '../../exercises/application/exercise_list_provider.dart';
import 'progression_range.dart';

part 'strength_series_provider.g.dart';

/// The exercise the user has currently selected for the strength chart,
/// or `null` when no exercise has been picked yet (initial state).
@Riverpod(keepAlive: true)
class StrengthExerciseSelection extends _$StrengthExerciseSelection {
  @override
  String? build() => null;

  void select(String? exerciseId) => state = exerciseId;
}

/// Weighted exercises that have at least one completed set with usable
/// weight + reps — i.e. the exercises the user can meaningfully chart.
/// Sorted by most-recent-session DESC so the picker surfaces what the
/// user is currently training.
///
/// Implementation: O(N) per-exercise reads; fine for dozens of
/// exercises. Replace with a single SQL aggregate if this ever shows up
/// in profiling.
@Riverpod(keepAlive: true)
Future<List<Exercise>> trackableExercises(Ref ref) async {
  await ref.watch(databaseBootstrapProvider.future);
  final List<Exercise> all = await ref.watch(exerciseListProvider.future);
  final List<Exercise> weighted = all
      .where((Exercise e) => e.type == ExerciseType.weighted)
      .toList(growable: false);

  final WorkoutRepository repo = ref.watch(workoutRepositoryProvider);

  final List<_TrackableEntry> annotated = <_TrackableEntry>[];
  for (final Exercise exercise in weighted) {
    final List<ExerciseHistoryDay> history =
        await repo.getExerciseHistoryByDay(exercise.id);
    DateTime? mostRecent;
    for (final ExerciseHistoryDay day in history) {
      final bool hasQualifying = day.sets.any(_isQualifyingSet);
      if (!hasQualifying) continue;
      if (mostRecent == null || day.workoutStartedAt.isAfter(mostRecent)) {
        mostRecent = day.workoutStartedAt;
      }
    }
    if (mostRecent != null) {
      annotated.add(_TrackableEntry(exercise: exercise, lastSession: mostRecent));
    }
  }

  annotated.sort(
    (_TrackableEntry a, _TrackableEntry b) =>
        b.lastSession.compareTo(a.lastSession),
  );
  return annotated
      .map((_TrackableEntry e) => e.exercise)
      .toList(growable: false);
}

class _TrackableEntry {
  const _TrackableEntry({required this.exercise, required this.lastSession});
  final Exercise exercise;
  final DateTime lastSession;
}

/// Per-exercise strength series: one [StrengthPoint] per session, where
/// each point is the best Epley-estimated 1RM achieved across that
/// session's qualifying sets. Returned ASC by session start time so the
/// chart can plot it without re-sorting.
///
/// Powered by the existing `WorkoutRepository.watchExerciseHistoryByDay`
/// stream so points appear in real time as sets are completed.
@Riverpod(keepAlive: true)
Stream<List<StrengthPoint>> exerciseStrengthSeries(
  Ref ref,
  String exerciseId,
) async* {
  await ref.watch(databaseBootstrapProvider.future);
  final WorkoutRepository repo = ref.watch(workoutRepositoryProvider);
  yield* repo.watchExerciseHistoryByDay(exerciseId).map(_mapHistoryToPoints);
}

/// Strength series filtered to the currently-selected
/// [StrengthRangeFilter] window.
@Riverpod(keepAlive: true)
AsyncValue<List<StrengthPoint>> filteredExerciseStrengthSeries(
  Ref ref,
  String exerciseId,
) {
  final AsyncValue<List<StrengthPoint>> series = ref.watch(
    exerciseStrengthSeriesProvider(exerciseId),
  );
  final ProgressionRange range = ref.watch(strengthRangeFilterProvider);
  return series.whenData((List<StrengthPoint> points) {
    final DateTime? cutoff = range.cutoffFrom(DateTime.now().toUtc());
    if (cutoff == null) return points;
    return points
        .where((StrengthPoint p) => !p.date.isBefore(cutoff))
        .toList(growable: false);
  });
}

/// All-time best lift for an exercise: the [StrengthPoint] with the highest
/// estimated 1RM across every completed session. `null` when the user has
/// no qualifying sets yet (and always `null` for non-weighted exercises,
/// whose series is empty by construction). Reactive — updates the moment a
/// new PR is logged.
@Riverpod(keepAlive: true)
AsyncValue<StrengthPoint?> exerciseAllTimePr(Ref ref, String exerciseId) {
  final AsyncValue<List<StrengthPoint>> series = ref.watch(
    exerciseStrengthSeriesProvider(exerciseId),
  );
  return series.whenData((List<StrengthPoint> points) {
    if (points.isEmpty) return null;
    return points.reduce(
      (StrengthPoint a, StrengthPoint b) =>
          b.oneRepMaxKg > a.oneRepMaxKg ? b : a,
    );
  });
}

/// IDs of every completed set that established a new estimated-1RM PR at
/// the time it was logged. Walks every qualifying set in chronological
/// order, tracking the running max — each set whose Epley 1RM strictly
/// exceeds all prior ones is a PR.
///
/// Empty for non-weighted exercises (no qualifying sets). Used by the
/// exercise history sheet to mark milestone sets with a trophy.
@Riverpod(keepAlive: true)
AsyncValue<Set<String>> exercisePrSetIds(Ref ref, String exerciseId) {
  final AsyncValue<List<ExerciseHistoryDay>> historyAsync = ref.watch(
    exerciseHistoryByDayProvider(exerciseId),
  );
  return historyAsync.whenData((List<ExerciseHistoryDay> days) {
    final Set<String> prIds = <String>{};
    double runningMax = 0;
    // `days` is newest-first; iterate in reverse so we visit the oldest
    // session first and can build up the running max chronologically.
    for (int i = days.length - 1; i >= 0; i--) {
      for (final WorkoutSet s in days[i].sets) {
        if (!_isQualifyingSet(s)) continue;
        final double? oneRm = StrengthFormulas.epley1RMKg(
          weightKg: s.weightKg,
          reps: s.reps,
        );
        if (oneRm == null) continue;
        if (oneRm > runningMax) {
          runningMax = oneRm;
          prIds.add(s.id);
        }
      }
    }
    return prIds;
  });
}

bool _isQualifyingSet(WorkoutSet s) {
  if (!s.completed) return false;
  // Warm-ups and drop sets aren't fair PR comparisons — warm-ups are
  // intentionally light, drops are fatigued continuations of a parent.
  if (!s.kind.countsTowardPrs) return false;
  if (s.weightKg == null || s.weightKg! <= 0) return false;
  if (s.reps == null || s.reps! <= 0) return false;
  return true;
}

List<StrengthPoint> _mapHistoryToPoints(List<ExerciseHistoryDay> days) {
  final List<StrengthPoint> out = <StrengthPoint>[];
  for (final ExerciseHistoryDay day in days) {
    StrengthPoint? best;
    for (final WorkoutSet s in day.sets) {
      if (!_isQualifyingSet(s)) continue;
      final double? oneRm = StrengthFormulas.epley1RMKg(
        weightKg: s.weightKg,
        reps: s.reps,
      );
      if (oneRm == null) continue;
      if (best == null || oneRm > best.oneRepMaxKg) {
        best = StrengthPoint(
          date: day.workoutStartedAt,
          oneRepMaxKg: oneRm,
          bestSetWeightKg: s.weightKg!,
          bestSetReps: s.reps!,
        );
      }
    }
    if (best != null) out.add(best);
  }
  out.sort((StrengthPoint a, StrengthPoint b) => a.date.compareTo(b.date));
  return out;
}
