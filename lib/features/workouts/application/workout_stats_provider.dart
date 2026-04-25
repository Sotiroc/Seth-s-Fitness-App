import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/workout.dart';
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
