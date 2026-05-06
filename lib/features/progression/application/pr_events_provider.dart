import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/pr_event.dart';
import '../../../data/repositories/workout_repository.dart';

part 'pr_events_provider.g.dart';

/// Every PR ever achieved across every exercise, newest-first. Powered
/// by [WorkoutRepository.watchAllPrEvents] — a single SQL query plus a
/// linear chronological scan that detects best-set, e1RM, rep-range,
/// cardio distance / duration, and bodyweight rep PRs all in one pass.
///
/// Streams from Drift, so the feed re-emits live the moment a new PR
/// lands during a workout (or earlier sets are edited / deleted).
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

/// Most recent [maxItems] PRs, newest-first. Powers the home-page PR
/// feed card. Defaults to 20 entries — enough to show progress over
/// weeks without flooding the page.
@Riverpod(keepAlive: true)
AsyncValue<List<PrEvent>> recentPrEvents(Ref ref, {int maxItems = 20}) {
  final AsyncValue<List<PrEvent>> async = ref.watch(allPrEventsProvider);
  return async.whenData((List<PrEvent> events) {
    if (events.length <= maxItems) return events;
    return events.sublist(0, maxItems);
  });
}

/// Every PR achieved within a specific workout. Powers the "Records
/// this session" block on the workout summary screen, the celebration
/// popup that fires when the summary first opens, and the trophy badge
/// shown on workout cards in the history list.
///
/// Sorted newest-first within the workout — same ordering as
/// [allPrEventsProvider]. Empty list when the workout had no PRs (the
/// common case, especially for a user's first session per exercise).
@Riverpod(keepAlive: true)
AsyncValue<List<PrEvent>> prsForWorkout(Ref ref, String workoutId) {
  final AsyncValue<List<PrEvent>> async = ref.watch(allPrEventsProvider);
  return async.whenData((List<PrEvent> events) {
    return events
        .where((PrEvent e) => e.workoutId == workoutId)
        .toList(growable: false);
  });
}

/// Current personal-record bests for a single exercise. The map keys
/// are [PrType] values present on the exercise — the UI reads only the
/// types relevant to the exercise's [ExerciseType]. For [PrType.repMax]
/// every distinct rep count the user has ever logged appears under the
/// `repMaxes` field.
///
/// Used by the exercise history sheet's "Personal records" header.
class ExercisePrBests {
  const ExercisePrBests({
    this.bestSet,
    this.e1rm,
    this.mostRepsInSet,
    this.mostRepsInWorkout,
    this.longestDistance,
    this.longestDuration,
    this.repMaxes = const <int, PrEvent>{},
  });

  final PrEvent? bestSet;
  final PrEvent? e1rm;
  final PrEvent? mostRepsInSet;
  final PrEvent? mostRepsInWorkout;
  final PrEvent? longestDistance;
  final PrEvent? longestDuration;

  /// Heaviest weight the user has ever lifted at each rep count, keyed
  /// by reps. Empty for non-weighted exercises.
  final Map<int, PrEvent> repMaxes;

  bool get isEmpty =>
      bestSet == null &&
      e1rm == null &&
      mostRepsInSet == null &&
      mostRepsInWorkout == null &&
      longestDistance == null &&
      longestDuration == null &&
      repMaxes.isEmpty;
}

/// Latest PR per [PrType] for a single exercise. Walks the all-PRs
/// stream once and keeps the newest (and therefore highest, by the
/// detection rules) entry per type. Powers the "Personal records"
/// header on the exercise history sheet.
@Riverpod(keepAlive: true)
AsyncValue<ExercisePrBests> exerciseBests(Ref ref, String exerciseId) {
  final AsyncValue<List<PrEvent>> async = ref.watch(allPrEventsProvider);
  return async.whenData((List<PrEvent> events) {
    PrEvent? bestSet;
    PrEvent? e1rm;
    PrEvent? mostRepsInSet;
    PrEvent? mostRepsInWorkout;
    PrEvent? longestDistance;
    PrEvent? longestDuration;
    final Map<int, PrEvent> repMaxes = <int, PrEvent>{};

    // events are newest-first; walk from oldest to newest so the latest
    // PR of each type ends up stored last.
    for (int i = events.length - 1; i >= 0; i--) {
      final PrEvent e = events[i];
      if (e.exerciseId != exerciseId) continue;
      switch (e.type) {
        case PrType.bestSet:
          bestSet = e;
        case PrType.e1rm:
          e1rm = e;
        case PrType.mostRepsInSet:
          mostRepsInSet = e;
        case PrType.mostRepsInWorkout:
          mostRepsInWorkout = e;
        case PrType.longestDistance:
          longestDistance = e;
        case PrType.longestDuration:
          longestDuration = e;
        case PrType.repMax:
          final int? rc = e.repCountForRepMax;
          if (rc != null) repMaxes[rc] = e;
      }
    }

    return ExercisePrBests(
      bestSet: bestSet,
      e1rm: e1rm,
      mostRepsInSet: mostRepsInSet,
      mostRepsInWorkout: mostRepsInWorkout,
      longestDistance: longestDistance,
      longestDuration: longestDuration,
      repMaxes: Map<int, PrEvent>.unmodifiable(repMaxes),
    );
  });
}
