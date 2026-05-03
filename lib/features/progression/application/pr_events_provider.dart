import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/pr_event.dart';
import '../../../data/repositories/workout_repository.dart';

part 'pr_events_provider.g.dart';

/// Every PR ever achieved across every weighted exercise, newest-first.
/// Each entry corresponds to one set whose Epley-estimated 1RM strictly
/// exceeded all prior sets on the same exercise at the time it was
/// logged.
///
/// Powered by `WorkoutRepository.watchAllPrEvents` — a single SQL query
/// + linear scan. Streams from Drift, so the feed re-emits live the
/// moment a new PR lands during a workout.
@Riverpod(keepAlive: true)
Stream<List<PrEvent>> allPrEvents(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(workoutRepositoryProvider).watchAllPrEvents();
}

/// Count of PRs achieved in the current calendar month (local time).
/// Surfaced in the "PRs this month" hero stats tile.
@Riverpod(keepAlive: true)
AsyncValue<int> monthlyPrCount(Ref ref) {
  final AsyncValue<List<PrEvent>> async = ref.watch(allPrEventsProvider);
  return async.whenData((List<PrEvent> events) {
    final DateTime now = DateTime.now();
    final int y = now.year;
    final int m = now.month;
    int count = 0;
    for (final PrEvent e in events) {
      final DateTime local = e.achievedAt.toLocal();
      if (local.year == y && local.month == m) count += 1;
    }
    return count;
  });
}

/// Most recent [maxItems] PRs, newest-first. Powers the PR feed card.
/// Defaults to 20 entries — enough to show progress over weeks without
/// flooding the page.
@Riverpod(keepAlive: true)
AsyncValue<List<PrEvent>> recentPrEvents(Ref ref, {int maxItems = 20}) {
  final AsyncValue<List<PrEvent>> async = ref.watch(allPrEventsProvider);
  return async.whenData((List<PrEvent> events) {
    if (events.length <= maxItems) return events;
    return events.sublist(0, maxItems);
  });
}
