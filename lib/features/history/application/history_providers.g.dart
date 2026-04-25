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
