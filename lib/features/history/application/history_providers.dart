import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/pr_event.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/workout_detail.dart';
import '../../../data/models/workout_set.dart';
import '../../../data/models/workout_structure.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../progression/application/pr_events_provider.dart';
import 'history_filter.dart';

part 'history_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<List<Workout>> workoutHistory(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(workoutRepositoryProvider).watchHistory();
}

@Riverpod(keepAlive: true)
Stream<WorkoutDetail> workoutDetail(Ref ref, String workoutId) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(workoutRepositoryProvider).watchWorkoutDetail(workoutId);
}

/// Structural shell for the workout-detail screen — workout row + ordered
/// (workoutExercise, exercise) pairs, with no per-set data. Re-emits only
/// when the workout itself, its exercise list, or an exercise definition
/// changes — so per-set tweaks (kind / RPE / note) don't flicker the
/// hero or section labels.
@Riverpod(keepAlive: true)
Stream<WorkoutStructure> workoutStructure(Ref ref, String workoutId) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(workoutRepositoryProvider).watchWorkoutStructure(workoutId);
}

/// Per-card sets stream. Each detail-screen exercise card watches its
/// own slice so editing one set's kind/RPE only rebuilds the affected
/// card, not the whole detail.
@Riverpod(keepAlive: true)
Stream<List<WorkoutSet>> workoutExerciseSets(
  Ref ref,
  String workoutExerciseId,
) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref
      .watch(workoutRepositoryProvider)
      .watchSetsForWorkoutExercise(workoutExerciseId);
}

/// Per-workout list of exercises (id + name, in display order) for every
/// finished workout. Powers the History search/filter:
/// - the Exercise chip ANDs against the id set,
/// - the search text ANDs against any matching name (and the workout
///   name, which lives on the workout itself).
@Riverpod(keepAlive: true)
Stream<Map<String, List<({String id, String name})>>>
historyExercisesByWorkout(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref
      .watch(workoutRepositoryProvider)
      .watchExercisesByFinishedWorkout();
}

/// Set of workout ids that contain at least one PR. Backs the "PRs only"
/// filter chip — derived from the existing PR feed so the same Epley-
/// based detection logic powers both surfaces.
@Riverpod(keepAlive: true)
Set<String> prWorkoutIds(Ref ref) {
  final List<PrEvent>? events = ref.watch(allPrEventsProvider).asData?.value;
  if (events == null || events.isEmpty) return const <String>{};
  return Set<String>.unmodifiable(<String>{
    for (final PrEvent e in events) e.workoutId,
  });
}

/// Set of finished workout ids that have at least one non-empty note,
/// at any level (workout, exercise, or set). Backs the "Notes" filter
/// chip — streams from Drift so the chip's result updates the moment a
/// note is typed or cleared.
@Riverpod(keepAlive: true)
Stream<Set<String>> notesWorkoutIds(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(workoutRepositoryProvider).watchWorkoutsWithAnyNote();
}

/// Stable, ordered comma-joined string of finished workout ids. Recomputes on
/// every history emission, but only changes value when the *set* of finished
/// workouts itself changes — so the set-count provider keyed off this doesn't
/// refetch on unrelated workout-row updates (e.g. a renamed past session).
@Riverpod(keepAlive: true)
String historyWorkoutIdsSignature(Ref ref) {
  final List<Workout>? workouts = ref
      .watch(workoutHistoryProvider)
      .asData
      ?.value;
  if (workouts == null || workouts.isEmpty) return '';
  return workouts.map((w) => w.id).join(',');
}

/// Map of workoutId → completed-set count for every workout in history.
/// Used by the history list to render a sets tally on each tile. Depends on
/// [historyWorkoutIdsSignatureProvider] so it only re-runs when workouts are
/// added or removed.
@Riverpod(keepAlive: true)
Future<Map<String, int>> historyCompletedSetCounts(Ref ref) async {
  final String signature = ref.watch(historyWorkoutIdsSignatureProvider);
  if (signature.isEmpty) return const <String, int>{};
  final List<String> ids = signature.split(',');
  return ref
      .read(workoutRepositoryProvider)
      .getCompletedSetCountsForWorkouts(ids);
}

/// One month-bucket of finished workouts in display order. The
/// `title` is pre-formatted (e.g. "March" for current year, "March 2024"
/// for older years) so the list renderer just reads strings instead of
/// parsing keys per row.
class HistorySection {
  const HistorySection({required this.title, required this.workouts});

  final String title;
  final List<Workout> workouts;
}

const List<String> _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Filtered history grouped into month sections, newest month first. Pre-
/// formats the section labels once per filter change so scrolling the
/// list doesn't re-bucket workouts and re-parse month names on every
/// frame.
@Riverpod(keepAlive: true)
List<HistorySection> historyGroupedByMonth(Ref ref) {
  final List<Workout>? items = ref.watch(filteredHistoryProvider).asData?.value;
  if (items == null || items.isEmpty) return const <HistorySection>[];

  final Map<String, List<Workout>> buckets = <String, List<Workout>>{};
  for (final Workout w in items) {
    final DateTime d = w.startedAt.toLocal();
    final String key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
    buckets.putIfAbsent(key, () => <Workout>[]).add(w);
  }

  final List<String> keys = buckets.keys.toList()
    ..sort((String a, String b) => b.compareTo(a));
  final int currentYear = DateTime.now().year;

  return keys.map((String key) {
    final List<String> parts = key.split('-');
    final int year = int.parse(parts[0]);
    final int month = int.parse(parts[1]);
    final String monthName = _monthNames[month - 1];
    return HistorySection(
      title: year == currentYear ? monthName : '$monthName $year',
      workouts: List<Workout>.unmodifiable(buckets[key]!),
    );
  }).toList(growable: false);
}

/// History list with the active [HistoryFilter] applied. ANDs together
/// the search text, exercise selection, date range, PRs-only and
/// has-notes toggles — same ordering as the underlying history (newest
/// first).
///
/// Returns the *finished* workouts only; the in-progress active workout
/// is rendered separately and pinned regardless of filters.
@Riverpod(keepAlive: true)
AsyncValue<List<Workout>> filteredHistory(Ref ref) {
  final AsyncValue<List<Workout>> historyAsync = ref.watch(
    workoutHistoryProvider,
  );
  final AsyncValue<Map<String, List<({String id, String name})>>>
  exercisesAsync = ref.watch(historyExercisesByWorkoutProvider);
  final HistoryFilter filter = ref.watch(historyFilterControllerProvider);
  final Set<String> prWorkouts = ref.watch(prWorkoutIdsProvider);
  final Set<String> notesWorkouts =
      ref.watch(notesWorkoutIdsProvider).asData?.value ?? const <String>{};

  return historyAsync.whenData((List<Workout> workouts) {
    final List<Workout> finished = workouts
        .where((Workout w) => w.endedAt != null)
        .toList(growable: false);
    if (!filter.hasAnyFilter) return finished;

    final Map<String, List<({String id, String name})>> byWorkout =
        exercisesAsync.asData?.value ??
        const <String, List<({String id, String name})>>{};
    final HistoryDateBounds bounds = filter.dateBounds(DateTime.now());
    final String normalizedQuery = filter.query.trim().toLowerCase();

    return finished
        .where(
          (Workout w) => _matches(
            workout: w,
            normalizedQuery: normalizedQuery,
            filter: filter,
            bounds: bounds,
            exercises: byWorkout[w.id] ?? const <({String id, String name})>[],
            prWorkoutIds: prWorkouts,
            notesWorkoutIds: notesWorkouts,
          ),
        )
        .toList(growable: false);
  });
}

bool _matches({
  required Workout workout,
  required String normalizedQuery,
  required HistoryFilter filter,
  required HistoryDateBounds bounds,
  required List<({String id, String name})> exercises,
  required Set<String> prWorkoutIds,
  required Set<String> notesWorkoutIds,
}) {
  if (filter.exerciseIds.isNotEmpty) {
    final bool hasAny = exercises.any(
      (({String id, String name}) e) => filter.exerciseIds.contains(e.id),
    );
    if (!hasAny) return false;
  }

  if (!bounds.contains(workout.startedAt)) return false;

  if (filter.prsOnly && !prWorkoutIds.contains(workout.id)) return false;

  if (filter.hasNotes && !notesWorkoutIds.contains(workout.id)) return false;

  if (normalizedQuery.isNotEmpty) {
    final bool nameMatches =
        (workout.name ?? '').toLowerCase().contains(normalizedQuery);
    if (!nameMatches) {
      final bool exerciseMatches = exercises.any(
        (({String id, String name}) e) =>
            e.name.toLowerCase().contains(normalizedQuery),
      );
      if (!exerciseMatches) return false;
    }
  }

  return true;
}
