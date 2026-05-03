import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/exercise_muscle_group.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../history/application/history_providers.dart';

part 'workout_stats_provider.g.dart';

/// Aggregate stats for a bucket of workouts (month, week, etc.).
class WorkoutPeriodStats {
  const WorkoutPeriodStats({required this.count, required this.totalDuration});

  final int count;
  final Duration totalDuration;

  static const WorkoutPeriodStats empty = WorkoutPeriodStats(
    count: 0,
    totalDuration: Duration.zero,
  );
}

/// Stats for the current calendar month (local time). Rebuilds whenever the
/// underlying history stream emits — e.g. after finishing a workout.
@Riverpod(keepAlive: true)
AsyncValue<WorkoutPeriodStats> monthlyWorkoutStats(Ref ref) {
  final AsyncValue<List<Workout>> history = ref.watch(workoutHistoryProvider);
  return history.whenData((List<Workout> workouts) {
    final DateTime now = DateTime.now();
    final int y = now.year;
    final int m = now.month;

    int count = 0;
    Duration total = Duration.zero;
    for (final Workout w in workouts) {
      final DateTime? ended = w.endedAt;
      if (ended == null) continue;
      final DateTime localEnd = ended.toLocal();
      if (localEnd.year != y || localEnd.month != m) continue;
      count += 1;
      total += ended.difference(w.startedAt);
    }

    return WorkoutPeriodStats(count: count, totalDuration: total);
  });
}

/// Returns the local (Mon 00:00, next-Mon 00:00) half-open range that
/// represents "this week" for volume tracking. ISO week (Monday start) is
/// the convention lifters use; programs like 5/3/1, RP, and PPL all reset
/// volume each Monday.
({DateTime start, DateTime end}) currentTrainingWeek({DateTime? now}) {
  final DateTime today = (now ?? DateTime.now()).toLocal();
  // DateTime.weekday: Mon=1 ... Sun=7. Subtract (weekday-1) days to land on
  // Monday, then truncate to midnight.
  final DateTime monday = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(Duration(days: today.weekday - 1));
  final DateTime nextMonday = monday.add(const Duration(days: 7));
  return (start: monday, end: nextMonday);
}

/// Completed sets grouped by muscle group for the current training week
/// (Monday-Sunday, local time). Streams from Drift so the count ticks up
/// in real time as the user completes sets in the active workout.
@Riverpod(keepAlive: true)
Stream<Map<ExerciseMuscleGroup, int>> weeklyMuscleGroupSets(Ref ref) {
  final WorkoutRepository repo = ref.watch(workoutRepositoryProvider);
  final ({DateTime start, DateTime end}) week = currentTrainingWeek();
  return repo.watchSetCountsByMuscleGroup(
    rangeStart: week.start,
    rangeEnd: week.end,
  );
}

/// Total cardio minutes completed in the current training week (Monday-
/// Sunday, local time). Cardio progress is naturally measured in time, not
/// set count, so the in-workout strip surfaces this for the cardio pill
/// instead of the set fraction. Streams from Drift; updates the moment a
/// cardio set is marked complete.
@Riverpod(keepAlive: true)
Stream<int> weeklyCardioMinutes(Ref ref) {
  final WorkoutRepository repo = ref.watch(workoutRepositoryProvider);
  final ({DateTime start, DateTime end}) week = currentTrainingWeek();
  return repo
      .watchCardioDurationSecondsForRange(
        rangeStart: week.start,
        rangeEnd: week.end,
      )
      .map((int totalSeconds) => totalSeconds ~/ 60);
}

/// Total tonnage (kg × reps) completed in the current training week.
/// Powers the "Volume this week" tile in the Progression hero strip.
/// Streams from Drift; updates live as sets complete.
@Riverpod(keepAlive: true)
Stream<double> weeklyVolumeKg(Ref ref) {
  final WorkoutRepository repo = ref.watch(workoutRepositoryProvider);
  final ({DateTime start, DateTime end}) week = currentTrainingWeek();
  return repo.watchTotalVolumeKgForRange(
    rangeStart: week.start,
    rangeEnd: week.end,
  );
}

/// Per-day completed set counts for the last [weeks] ISO weeks, keyed by
/// local-midnight DateTime. Drives the GitHub-style training calendar
/// heatmap on the Progression page; the heatmap reads its preferred
/// window length from `calendarRangeFilterProvider`.
@Riverpod(keepAlive: true)
Stream<Map<DateTime, int>> dailyTrainingSetCounts(
  Ref ref, {
  int weeks = 12,
}) {
  final WorkoutRepository repo = ref.watch(workoutRepositoryProvider);
  // [weeks] columns ending at next Monday so the current week is fully
  // visible (no half-empty trailing column the user is presently filling).
  final ({DateTime start, DateTime end}) thisWeek = currentTrainingWeek();
  final DateTime rangeStart = thisWeek.start.subtract(
    Duration(days: 7 * (weeks - 1)),
  );
  return repo.watchDailySetCountsForRange(
    rangeStart: rangeStart,
    rangeEnd: thisWeek.end,
  );
}

/// Number of consecutive ISO weeks (Mon-Sun) ending at the current week
/// in which the user finished at least one workout. Hits 0 when the
/// current week has no finished workouts; otherwise grows back through
/// history. Used by the "Streak" tile in the hero strip.
///
/// Synchronously-derived from [workoutHistoryProvider] so it doesn't open
/// a new Drift stream — re-emits whenever history does.
@Riverpod(keepAlive: true)
AsyncValue<int> workoutStreakWeeks(Ref ref) {
  final AsyncValue<List<Workout>> async = ref.watch(workoutHistoryProvider);
  return async.whenData((List<Workout> workouts) {
    if (workouts.isEmpty) return 0;
    // Build the set of Monday-anchored ISO weeks that contain at least
    // one finished workout (workoutHistoryProvider already filters to
    // finished). Comparing by Monday timestamps is timezone-stable.
    final Set<int> trainedWeeks = <int>{};
    for (final Workout w in workouts) {
      final DateTime ended = (w.endedAt ?? w.startedAt).toLocal();
      final ({DateTime start, DateTime end}) week = currentTrainingWeek(
        now: ended,
      );
      trainedWeeks.add(week.start.millisecondsSinceEpoch);
    }
    // Walk backward from this week until we hit a week without training.
    int streak = 0;
    DateTime cursor = currentTrainingWeek().start;
    while (trainedWeeks.contains(cursor.millisecondsSinceEpoch)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 7));
    }
    return streak;
  });
}
