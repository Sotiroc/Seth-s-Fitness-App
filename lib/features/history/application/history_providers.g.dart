// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workoutHistory)
const workoutHistoryProvider = WorkoutHistoryProvider._();

final class WorkoutHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Workout>>,
          List<Workout>,
          Stream<List<Workout>>
        >
    with $FutureModifier<List<Workout>>, $StreamProvider<List<Workout>> {
  const WorkoutHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutHistoryHash();

  @$internal
  @override
  $StreamProviderElement<List<Workout>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Workout>> create(Ref ref) {
    return workoutHistory(ref);
  }
}

String _$workoutHistoryHash() => r'c8123a5b9a01e7905c296239d41f25a08e3be39c';

@ProviderFor(workoutDetail)
const workoutDetailProvider = WorkoutDetailFamily._();

final class WorkoutDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkoutDetail>,
          WorkoutDetail,
          Stream<WorkoutDetail>
        >
    with $FutureModifier<WorkoutDetail>, $StreamProvider<WorkoutDetail> {
  const WorkoutDetailProvider._({
    required WorkoutDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workoutDetailProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workoutDetailHash();

  @override
  String toString() {
    return r'workoutDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<WorkoutDetail> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<WorkoutDetail> create(Ref ref) {
    final argument = this.argument as String;
    return workoutDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkoutDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workoutDetailHash() => r'1d24832497d921685817c682861c2c632794c2f7';

final class WorkoutDetailFamily extends $Family
    with $FunctionalFamilyOverride<Stream<WorkoutDetail>, String> {
  const WorkoutDetailFamily._()
    : super(
        retry: null,
        name: r'workoutDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  WorkoutDetailProvider call(String workoutId) =>
      WorkoutDetailProvider._(argument: workoutId, from: this);

  @override
  String toString() => r'workoutDetailProvider';
}

/// Structural shell for the workout-detail screen — workout row + ordered
/// (workoutExercise, exercise) pairs, with no per-set data. Re-emits only
/// when the workout itself, its exercise list, or an exercise definition
/// changes — so per-set tweaks (kind / RPE / note) don't flicker the
/// hero or section labels.

@ProviderFor(workoutStructure)
const workoutStructureProvider = WorkoutStructureFamily._();

/// Structural shell for the workout-detail screen — workout row + ordered
/// (workoutExercise, exercise) pairs, with no per-set data. Re-emits only
/// when the workout itself, its exercise list, or an exercise definition
/// changes — so per-set tweaks (kind / RPE / note) don't flicker the
/// hero or section labels.

final class WorkoutStructureProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkoutStructure>,
          WorkoutStructure,
          Stream<WorkoutStructure>
        >
    with $FutureModifier<WorkoutStructure>, $StreamProvider<WorkoutStructure> {
  /// Structural shell for the workout-detail screen — workout row + ordered
  /// (workoutExercise, exercise) pairs, with no per-set data. Re-emits only
  /// when the workout itself, its exercise list, or an exercise definition
  /// changes — so per-set tweaks (kind / RPE / note) don't flicker the
  /// hero or section labels.
  const WorkoutStructureProvider._({
    required WorkoutStructureFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workoutStructureProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workoutStructureHash();

  @override
  String toString() {
    return r'workoutStructureProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<WorkoutStructure> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<WorkoutStructure> create(Ref ref) {
    final argument = this.argument as String;
    return workoutStructure(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkoutStructureProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workoutStructureHash() => r'5abcd5a44f5c5b88a25d433cd84750e96daba31c';

/// Structural shell for the workout-detail screen — workout row + ordered
/// (workoutExercise, exercise) pairs, with no per-set data. Re-emits only
/// when the workout itself, its exercise list, or an exercise definition
/// changes — so per-set tweaks (kind / RPE / note) don't flicker the
/// hero or section labels.

final class WorkoutStructureFamily extends $Family
    with $FunctionalFamilyOverride<Stream<WorkoutStructure>, String> {
  const WorkoutStructureFamily._()
    : super(
        retry: null,
        name: r'workoutStructureProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Structural shell for the workout-detail screen — workout row + ordered
  /// (workoutExercise, exercise) pairs, with no per-set data. Re-emits only
  /// when the workout itself, its exercise list, or an exercise definition
  /// changes — so per-set tweaks (kind / RPE / note) don't flicker the
  /// hero or section labels.

  WorkoutStructureProvider call(String workoutId) =>
      WorkoutStructureProvider._(argument: workoutId, from: this);

  @override
  String toString() => r'workoutStructureProvider';
}

/// Per-card sets stream. Each detail-screen exercise card watches its
/// own slice so editing one set's kind/RPE only rebuilds the affected
/// card, not the whole detail.

@ProviderFor(workoutExerciseSets)
const workoutExerciseSetsProvider = WorkoutExerciseSetsFamily._();

/// Per-card sets stream. Each detail-screen exercise card watches its
/// own slice so editing one set's kind/RPE only rebuilds the affected
/// card, not the whole detail.

final class WorkoutExerciseSetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkoutSet>>,
          List<WorkoutSet>,
          Stream<List<WorkoutSet>>
        >
    with $FutureModifier<List<WorkoutSet>>, $StreamProvider<List<WorkoutSet>> {
  /// Per-card sets stream. Each detail-screen exercise card watches its
  /// own slice so editing one set's kind/RPE only rebuilds the affected
  /// card, not the whole detail.
  const WorkoutExerciseSetsProvider._({
    required WorkoutExerciseSetsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workoutExerciseSetsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workoutExerciseSetsHash();

  @override
  String toString() {
    return r'workoutExerciseSetsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<WorkoutSet>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WorkoutSet>> create(Ref ref) {
    final argument = this.argument as String;
    return workoutExerciseSets(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkoutExerciseSetsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workoutExerciseSetsHash() =>
    r'b7a0a5fc77ab0d1472d34dd3ff5cdee0bb6fe9dd';

/// Per-card sets stream. Each detail-screen exercise card watches its
/// own slice so editing one set's kind/RPE only rebuilds the affected
/// card, not the whole detail.

final class WorkoutExerciseSetsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<WorkoutSet>>, String> {
  const WorkoutExerciseSetsFamily._()
    : super(
        retry: null,
        name: r'workoutExerciseSetsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Per-card sets stream. Each detail-screen exercise card watches its
  /// own slice so editing one set's kind/RPE only rebuilds the affected
  /// card, not the whole detail.

  WorkoutExerciseSetsProvider call(String workoutExerciseId) =>
      WorkoutExerciseSetsProvider._(argument: workoutExerciseId, from: this);

  @override
  String toString() => r'workoutExerciseSetsProvider';
}

/// Per-workout list of exercises (id + name, in display order) for every
/// finished workout. Powers the History search/filter:
/// - the Exercise chip ANDs against the id set,
/// - the search text ANDs against any matching name (and the workout
///   name, which lives on the workout itself).

@ProviderFor(historyExercisesByWorkout)
const historyExercisesByWorkoutProvider = HistoryExercisesByWorkoutProvider._();

/// Per-workout list of exercises (id + name, in display order) for every
/// finished workout. Powers the History search/filter:
/// - the Exercise chip ANDs against the id set,
/// - the search text ANDs against any matching name (and the workout
///   name, which lives on the workout itself).

final class HistoryExercisesByWorkoutProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, List<({String id, String name})>>>,
          Map<String, List<({String id, String name})>>,
          Stream<Map<String, List<({String id, String name})>>>
        >
    with
        $FutureModifier<Map<String, List<({String id, String name})>>>,
        $StreamProvider<Map<String, List<({String id, String name})>>> {
  /// Per-workout list of exercises (id + name, in display order) for every
  /// finished workout. Powers the History search/filter:
  /// - the Exercise chip ANDs against the id set,
  /// - the search text ANDs against any matching name (and the workout
  ///   name, which lives on the workout itself).
  const HistoryExercisesByWorkoutProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyExercisesByWorkoutProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyExercisesByWorkoutHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, List<({String id, String name})>>>
  $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, List<({String id, String name})>>> create(Ref ref) {
    return historyExercisesByWorkout(ref);
  }
}

String _$historyExercisesByWorkoutHash() =>
    r'1f2d12f8512b9a506d5292b6b04a809f08c386be';

/// Set of workout ids that contain at least one PR. Backs the "PRs only"
/// filter chip — derived from the existing PR feed so the same Epley-
/// based detection logic powers both surfaces.

@ProviderFor(prWorkoutIds)
const prWorkoutIdsProvider = PrWorkoutIdsProvider._();

/// Set of workout ids that contain at least one PR. Backs the "PRs only"
/// filter chip — derived from the existing PR feed so the same Epley-
/// based detection logic powers both surfaces.

final class PrWorkoutIdsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// Set of workout ids that contain at least one PR. Backs the "PRs only"
  /// filter chip — derived from the existing PR feed so the same Epley-
  /// based detection logic powers both surfaces.
  const PrWorkoutIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'prWorkoutIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prWorkoutIdsHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return prWorkoutIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$prWorkoutIdsHash() => r'948923523b0953ec7671c4078ee7f0fbd50ea9cb';

/// Set of finished workout ids that have at least one non-empty note,
/// at any level (workout, exercise, or set). Backs the "Notes" filter
/// chip — streams from Drift so the chip's result updates the moment a
/// note is typed or cleared.

@ProviderFor(notesWorkoutIds)
const notesWorkoutIdsProvider = NotesWorkoutIdsProvider._();

/// Set of finished workout ids that have at least one non-empty note,
/// at any level (workout, exercise, or set). Backs the "Notes" filter
/// chip — streams from Drift so the chip's result updates the moment a
/// note is typed or cleared.

final class NotesWorkoutIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          Stream<Set<String>>
        >
    with $FutureModifier<Set<String>>, $StreamProvider<Set<String>> {
  /// Set of finished workout ids that have at least one non-empty note,
  /// at any level (workout, exercise, or set). Backs the "Notes" filter
  /// chip — streams from Drift so the chip's result updates the moment a
  /// note is typed or cleared.
  const NotesWorkoutIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notesWorkoutIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notesWorkoutIdsHash();

  @$internal
  @override
  $StreamProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<String>> create(Ref ref) {
    return notesWorkoutIds(ref);
  }
}

String _$notesWorkoutIdsHash() => r'66af4b29dde2daa1170912e9fd7926d65c30c8c5';

/// Stable, ordered comma-joined string of finished workout ids. Recomputes on
/// every history emission, but only changes value when the *set* of finished
/// workouts itself changes — so the set-count provider keyed off this doesn't
/// refetch on unrelated workout-row updates (e.g. a renamed past session).

@ProviderFor(historyWorkoutIdsSignature)
const historyWorkoutIdsSignatureProvider =
    HistoryWorkoutIdsSignatureProvider._();

/// Stable, ordered comma-joined string of finished workout ids. Recomputes on
/// every history emission, but only changes value when the *set* of finished
/// workouts itself changes — so the set-count provider keyed off this doesn't
/// refetch on unrelated workout-row updates (e.g. a renamed past session).

final class HistoryWorkoutIdsSignatureProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Stable, ordered comma-joined string of finished workout ids. Recomputes on
  /// every history emission, but only changes value when the *set* of finished
  /// workouts itself changes — so the set-count provider keyed off this doesn't
  /// refetch on unrelated workout-row updates (e.g. a renamed past session).
  const HistoryWorkoutIdsSignatureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyWorkoutIdsSignatureProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyWorkoutIdsSignatureHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return historyWorkoutIdsSignature(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$historyWorkoutIdsSignatureHash() =>
    r'0d4d30cd44ef292729b51a76e5d2fc77d623e8ab';

/// Map of workoutId → completed-set count for every workout in history.
/// Used by the history list to render a sets tally on each tile. Depends on
/// [historyWorkoutIdsSignatureProvider] so it only re-runs when workouts are
/// added or removed.

@ProviderFor(historyCompletedSetCounts)
const historyCompletedSetCountsProvider = HistoryCompletedSetCountsProvider._();

/// Map of workoutId → completed-set count for every workout in history.
/// Used by the history list to render a sets tally on each tile. Depends on
/// [historyWorkoutIdsSignatureProvider] so it only re-runs when workouts are
/// added or removed.

final class HistoryCompletedSetCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, int>>,
          Map<String, int>,
          FutureOr<Map<String, int>>
        >
    with $FutureModifier<Map<String, int>>, $FutureProvider<Map<String, int>> {
  /// Map of workoutId → completed-set count for every workout in history.
  /// Used by the history list to render a sets tally on each tile. Depends on
  /// [historyWorkoutIdsSignatureProvider] so it only re-runs when workouts are
  /// added or removed.
  const HistoryCompletedSetCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyCompletedSetCountsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyCompletedSetCountsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, int>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, int>> create(Ref ref) {
    return historyCompletedSetCounts(ref);
  }
}

String _$historyCompletedSetCountsHash() =>
    r'76638e999c022b34df84929b8bf91f848e01e309';

/// Filtered history grouped into month sections, newest month first. Pre-
/// formats the section labels once per filter change so scrolling the
/// list doesn't re-bucket workouts and re-parse month names on every
/// frame.

@ProviderFor(historyGroupedByMonth)
const historyGroupedByMonthProvider = HistoryGroupedByMonthProvider._();

/// Filtered history grouped into month sections, newest month first. Pre-
/// formats the section labels once per filter change so scrolling the
/// list doesn't re-bucket workouts and re-parse month names on every
/// frame.

final class HistoryGroupedByMonthProvider
    extends
        $FunctionalProvider<
          List<HistorySection>,
          List<HistorySection>,
          List<HistorySection>
        >
    with $Provider<List<HistorySection>> {
  /// Filtered history grouped into month sections, newest month first. Pre-
  /// formats the section labels once per filter change so scrolling the
  /// list doesn't re-bucket workouts and re-parse month names on every
  /// frame.
  const HistoryGroupedByMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyGroupedByMonthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyGroupedByMonthHash();

  @$internal
  @override
  $ProviderElement<List<HistorySection>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<HistorySection> create(Ref ref) {
    return historyGroupedByMonth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<HistorySection> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<HistorySection>>(value),
    );
  }
}

String _$historyGroupedByMonthHash() =>
    r'12e35597b391677de4359f249497ebd1f2974aab';

/// History list with the active [HistoryFilter] applied. ANDs together
/// the search text, exercise selection, date range, PRs-only and
/// has-notes toggles — same ordering as the underlying history (newest
/// first).
///
/// Returns the *finished* workouts only; the in-progress active workout
/// is rendered separately and pinned regardless of filters.

@ProviderFor(filteredHistory)
const filteredHistoryProvider = FilteredHistoryProvider._();

/// History list with the active [HistoryFilter] applied. ANDs together
/// the search text, exercise selection, date range, PRs-only and
/// has-notes toggles — same ordering as the underlying history (newest
/// first).
///
/// Returns the *finished* workouts only; the in-progress active workout
/// is rendered separately and pinned regardless of filters.

final class FilteredHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Workout>>,
          AsyncValue<List<Workout>>,
          AsyncValue<List<Workout>>
        >
    with $Provider<AsyncValue<List<Workout>>> {
  /// History list with the active [HistoryFilter] applied. ANDs together
  /// the search text, exercise selection, date range, PRs-only and
  /// has-notes toggles — same ordering as the underlying history (newest
  /// first).
  ///
  /// Returns the *finished* workouts only; the in-progress active workout
  /// is rendered separately and pinned regardless of filters.
  const FilteredHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredHistoryHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Workout>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Workout>> create(Ref ref) {
    return filteredHistory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Workout>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Workout>>>(value),
    );
  }
}

String _$filteredHistoryHash() => r'4b0888fd7f664909562b923f5b99ee02f1627bd8';
