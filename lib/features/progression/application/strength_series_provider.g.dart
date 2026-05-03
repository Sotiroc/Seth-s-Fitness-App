// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strength_series_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The exercise the user has currently selected for the strength chart,
/// or `null` when no exercise has been picked yet (initial state).

@ProviderFor(StrengthExerciseSelection)
const strengthExerciseSelectionProvider = StrengthExerciseSelectionProvider._();

/// The exercise the user has currently selected for the strength chart,
/// or `null` when no exercise has been picked yet (initial state).
final class StrengthExerciseSelectionProvider
    extends $NotifierProvider<StrengthExerciseSelection, String?> {
  /// The exercise the user has currently selected for the strength chart,
  /// or `null` when no exercise has been picked yet (initial state).
  const StrengthExerciseSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'strengthExerciseSelectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$strengthExerciseSelectionHash();

  @$internal
  @override
  StrengthExerciseSelection create() => StrengthExerciseSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$strengthExerciseSelectionHash() =>
    r'9147e92cc41de02a906c7eeda9dccec76b9b94a7';

/// The exercise the user has currently selected for the strength chart,
/// or `null` when no exercise has been picked yet (initial state).

abstract class _$StrengthExerciseSelection extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Weighted exercises that have at least one completed set with usable
/// weight + reps — i.e. the exercises the user can meaningfully chart.
/// Sorted by most-recent-session DESC so the picker surfaces what the
/// user is currently training.
///
/// Implementation: O(N) per-exercise reads; fine for dozens of
/// exercises. Replace with a single SQL aggregate if this ever shows up
/// in profiling.

@ProviderFor(trackableExercises)
const trackableExercisesProvider = TrackableExercisesProvider._();

/// Weighted exercises that have at least one completed set with usable
/// weight + reps — i.e. the exercises the user can meaningfully chart.
/// Sorted by most-recent-session DESC so the picker surfaces what the
/// user is currently training.
///
/// Implementation: O(N) per-exercise reads; fine for dozens of
/// exercises. Replace with a single SQL aggregate if this ever shows up
/// in profiling.

final class TrackableExercisesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Exercise>>,
          List<Exercise>,
          FutureOr<List<Exercise>>
        >
    with $FutureModifier<List<Exercise>>, $FutureProvider<List<Exercise>> {
  /// Weighted exercises that have at least one completed set with usable
  /// weight + reps — i.e. the exercises the user can meaningfully chart.
  /// Sorted by most-recent-session DESC so the picker surfaces what the
  /// user is currently training.
  ///
  /// Implementation: O(N) per-exercise reads; fine for dozens of
  /// exercises. Replace with a single SQL aggregate if this ever shows up
  /// in profiling.
  const TrackableExercisesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trackableExercisesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trackableExercisesHash();

  @$internal
  @override
  $FutureProviderElement<List<Exercise>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Exercise>> create(Ref ref) {
    return trackableExercises(ref);
  }
}

String _$trackableExercisesHash() =>
    r'aabdee24edd7371a28bd964160478597fe64c9de';

/// Per-exercise strength series: one [StrengthPoint] per session, where
/// each point is the best Epley-estimated 1RM achieved across that
/// session's qualifying sets. Returned ASC by session start time so the
/// chart can plot it without re-sorting.
///
/// Powered by the existing `WorkoutRepository.watchExerciseHistoryByDay`
/// stream so points appear in real time as sets are completed.

@ProviderFor(exerciseStrengthSeries)
const exerciseStrengthSeriesProvider = ExerciseStrengthSeriesFamily._();

/// Per-exercise strength series: one [StrengthPoint] per session, where
/// each point is the best Epley-estimated 1RM achieved across that
/// session's qualifying sets. Returned ASC by session start time so the
/// chart can plot it without re-sorting.
///
/// Powered by the existing `WorkoutRepository.watchExerciseHistoryByDay`
/// stream so points appear in real time as sets are completed.

final class ExerciseStrengthSeriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StrengthPoint>>,
          List<StrengthPoint>,
          Stream<List<StrengthPoint>>
        >
    with
        $FutureModifier<List<StrengthPoint>>,
        $StreamProvider<List<StrengthPoint>> {
  /// Per-exercise strength series: one [StrengthPoint] per session, where
  /// each point is the best Epley-estimated 1RM achieved across that
  /// session's qualifying sets. Returned ASC by session start time so the
  /// chart can plot it without re-sorting.
  ///
  /// Powered by the existing `WorkoutRepository.watchExerciseHistoryByDay`
  /// stream so points appear in real time as sets are completed.
  const ExerciseStrengthSeriesProvider._({
    required ExerciseStrengthSeriesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'exerciseStrengthSeriesProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exerciseStrengthSeriesHash();

  @override
  String toString() {
    return r'exerciseStrengthSeriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<StrengthPoint>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<StrengthPoint>> create(Ref ref) {
    final argument = this.argument as String;
    return exerciseStrengthSeries(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseStrengthSeriesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exerciseStrengthSeriesHash() =>
    r'b1bbe8ff536b0422b016c5565cab7cfca450c358';

/// Per-exercise strength series: one [StrengthPoint] per session, where
/// each point is the best Epley-estimated 1RM achieved across that
/// session's qualifying sets. Returned ASC by session start time so the
/// chart can plot it without re-sorting.
///
/// Powered by the existing `WorkoutRepository.watchExerciseHistoryByDay`
/// stream so points appear in real time as sets are completed.

final class ExerciseStrengthSeriesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<StrengthPoint>>, String> {
  const ExerciseStrengthSeriesFamily._()
    : super(
        retry: null,
        name: r'exerciseStrengthSeriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Per-exercise strength series: one [StrengthPoint] per session, where
  /// each point is the best Epley-estimated 1RM achieved across that
  /// session's qualifying sets. Returned ASC by session start time so the
  /// chart can plot it without re-sorting.
  ///
  /// Powered by the existing `WorkoutRepository.watchExerciseHistoryByDay`
  /// stream so points appear in real time as sets are completed.

  ExerciseStrengthSeriesProvider call(String exerciseId) =>
      ExerciseStrengthSeriesProvider._(argument: exerciseId, from: this);

  @override
  String toString() => r'exerciseStrengthSeriesProvider';
}

/// Strength series filtered to the currently-selected
/// [StrengthRangeFilter] window.

@ProviderFor(filteredExerciseStrengthSeries)
const filteredExerciseStrengthSeriesProvider =
    FilteredExerciseStrengthSeriesFamily._();

/// Strength series filtered to the currently-selected
/// [StrengthRangeFilter] window.

final class FilteredExerciseStrengthSeriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StrengthPoint>>,
          AsyncValue<List<StrengthPoint>>,
          AsyncValue<List<StrengthPoint>>
        >
    with $Provider<AsyncValue<List<StrengthPoint>>> {
  /// Strength series filtered to the currently-selected
  /// [StrengthRangeFilter] window.
  const FilteredExerciseStrengthSeriesProvider._({
    required FilteredExerciseStrengthSeriesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filteredExerciseStrengthSeriesProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredExerciseStrengthSeriesHash();

  @override
  String toString() {
    return r'filteredExerciseStrengthSeriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<StrengthPoint>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<StrengthPoint>> create(Ref ref) {
    final argument = this.argument as String;
    return filteredExerciseStrengthSeries(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<StrengthPoint>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<StrengthPoint>>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredExerciseStrengthSeriesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredExerciseStrengthSeriesHash() =>
    r'5b4bf66fc10d2931cbc74dc75a6e65be86abf1d8';

/// Strength series filtered to the currently-selected
/// [StrengthRangeFilter] window.

final class FilteredExerciseStrengthSeriesFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<List<StrengthPoint>>, String> {
  const FilteredExerciseStrengthSeriesFamily._()
    : super(
        retry: null,
        name: r'filteredExerciseStrengthSeriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Strength series filtered to the currently-selected
  /// [StrengthRangeFilter] window.

  FilteredExerciseStrengthSeriesProvider call(String exerciseId) =>
      FilteredExerciseStrengthSeriesProvider._(
        argument: exerciseId,
        from: this,
      );

  @override
  String toString() => r'filteredExerciseStrengthSeriesProvider';
}

/// All-time best lift for an exercise: the [StrengthPoint] with the highest
/// estimated 1RM across every completed session. `null` when the user has
/// no qualifying sets yet (and always `null` for non-weighted exercises,
/// whose series is empty by construction). Reactive — updates the moment a
/// new PR is logged.

@ProviderFor(exerciseAllTimePr)
const exerciseAllTimePrProvider = ExerciseAllTimePrFamily._();

/// All-time best lift for an exercise: the [StrengthPoint] with the highest
/// estimated 1RM across every completed session. `null` when the user has
/// no qualifying sets yet (and always `null` for non-weighted exercises,
/// whose series is empty by construction). Reactive — updates the moment a
/// new PR is logged.

final class ExerciseAllTimePrProvider
    extends
        $FunctionalProvider<
          AsyncValue<StrengthPoint?>,
          AsyncValue<StrengthPoint?>,
          AsyncValue<StrengthPoint?>
        >
    with $Provider<AsyncValue<StrengthPoint?>> {
  /// All-time best lift for an exercise: the [StrengthPoint] with the highest
  /// estimated 1RM across every completed session. `null` when the user has
  /// no qualifying sets yet (and always `null` for non-weighted exercises,
  /// whose series is empty by construction). Reactive — updates the moment a
  /// new PR is logged.
  const ExerciseAllTimePrProvider._({
    required ExerciseAllTimePrFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'exerciseAllTimePrProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exerciseAllTimePrHash();

  @override
  String toString() {
    return r'exerciseAllTimePrProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<StrengthPoint?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<StrengthPoint?> create(Ref ref) {
    final argument = this.argument as String;
    return exerciseAllTimePr(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<StrengthPoint?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<StrengthPoint?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseAllTimePrProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exerciseAllTimePrHash() => r'5e5ffac8a0c333acc30c7a92aef707056945bf71';

/// All-time best lift for an exercise: the [StrengthPoint] with the highest
/// estimated 1RM across every completed session. `null` when the user has
/// no qualifying sets yet (and always `null` for non-weighted exercises,
/// whose series is empty by construction). Reactive — updates the moment a
/// new PR is logged.

final class ExerciseAllTimePrFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<StrengthPoint?>, String> {
  const ExerciseAllTimePrFamily._()
    : super(
        retry: null,
        name: r'exerciseAllTimePrProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// All-time best lift for an exercise: the [StrengthPoint] with the highest
  /// estimated 1RM across every completed session. `null` when the user has
  /// no qualifying sets yet (and always `null` for non-weighted exercises,
  /// whose series is empty by construction). Reactive — updates the moment a
  /// new PR is logged.

  ExerciseAllTimePrProvider call(String exerciseId) =>
      ExerciseAllTimePrProvider._(argument: exerciseId, from: this);

  @override
  String toString() => r'exerciseAllTimePrProvider';
}

/// IDs of every completed set that established a new estimated-1RM PR at
/// the time it was logged. Walks every qualifying set in chronological
/// order, tracking the running max — each set whose Epley 1RM strictly
/// exceeds all prior ones is a PR.
///
/// Empty for non-weighted exercises (no qualifying sets). Used by the
/// exercise history sheet to mark milestone sets with a trophy.

@ProviderFor(exercisePrSetIds)
const exercisePrSetIdsProvider = ExercisePrSetIdsFamily._();

/// IDs of every completed set that established a new estimated-1RM PR at
/// the time it was logged. Walks every qualifying set in chronological
/// order, tracking the running max — each set whose Epley 1RM strictly
/// exceeds all prior ones is a PR.
///
/// Empty for non-weighted exercises (no qualifying sets). Used by the
/// exercise history sheet to mark milestone sets with a trophy.

final class ExercisePrSetIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          AsyncValue<Set<String>>,
          AsyncValue<Set<String>>
        >
    with $Provider<AsyncValue<Set<String>>> {
  /// IDs of every completed set that established a new estimated-1RM PR at
  /// the time it was logged. Walks every qualifying set in chronological
  /// order, tracking the running max — each set whose Epley 1RM strictly
  /// exceeds all prior ones is a PR.
  ///
  /// Empty for non-weighted exercises (no qualifying sets). Used by the
  /// exercise history sheet to mark milestone sets with a trophy.
  const ExercisePrSetIdsProvider._({
    required ExercisePrSetIdsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'exercisePrSetIdsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exercisePrSetIdsHash();

  @override
  String toString() {
    return r'exercisePrSetIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<Set<String>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<Set<String>> create(Ref ref) {
    final argument = this.argument as String;
    return exercisePrSetIds(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Set<String>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Set<String>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExercisePrSetIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exercisePrSetIdsHash() => r'34b3bea215755b9a9931256e0ae0122539441495';

/// IDs of every completed set that established a new estimated-1RM PR at
/// the time it was logged. Walks every qualifying set in chronological
/// order, tracking the running max — each set whose Epley 1RM strictly
/// exceeds all prior ones is a PR.
///
/// Empty for non-weighted exercises (no qualifying sets). Used by the
/// exercise history sheet to mark milestone sets with a trophy.

final class ExercisePrSetIdsFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<Set<String>>, String> {
  const ExercisePrSetIdsFamily._()
    : super(
        retry: null,
        name: r'exercisePrSetIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// IDs of every completed set that established a new estimated-1RM PR at
  /// the time it was logged. Walks every qualifying set in chronological
  /// order, tracking the running max — each set whose Epley 1RM strictly
  /// exceeds all prior ones is a PR.
  ///
  /// Empty for non-weighted exercises (no qualifying sets). Used by the
  /// exercise history sheet to mark milestone sets with a trophy.

  ExercisePrSetIdsProvider call(String exerciseId) =>
      ExercisePrSetIdsProvider._(argument: exerciseId, from: this);

  @override
  String toString() => r'exercisePrSetIdsProvider';
}
