// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pr_events_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every PR ever achieved across every exercise, newest-first. Powered
/// by [WorkoutRepository.watchAllPrEvents] — a single SQL query plus a
/// linear chronological scan that detects best-set, e1RM, rep-range,
/// cardio distance / duration, and bodyweight rep PRs all in one pass.
///
/// Streams from Drift, so the feed re-emits live the moment a new PR
/// lands during a workout (or earlier sets are edited / deleted).

@ProviderFor(allPrEvents)
const allPrEventsProvider = AllPrEventsProvider._();

/// Every PR ever achieved across every exercise, newest-first. Powered
/// by [WorkoutRepository.watchAllPrEvents] — a single SQL query plus a
/// linear chronological scan that detects best-set, e1RM, rep-range,
/// cardio distance / duration, and bodyweight rep PRs all in one pass.
///
/// Streams from Drift, so the feed re-emits live the moment a new PR
/// lands during a workout (or earlier sets are edited / deleted).

final class AllPrEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PrEvent>>,
          List<PrEvent>,
          Stream<List<PrEvent>>
        >
    with $FutureModifier<List<PrEvent>>, $StreamProvider<List<PrEvent>> {
  /// Every PR ever achieved across every exercise, newest-first. Powered
  /// by [WorkoutRepository.watchAllPrEvents] — a single SQL query plus a
  /// linear chronological scan that detects best-set, e1RM, rep-range,
  /// cardio distance / duration, and bodyweight rep PRs all in one pass.
  ///
  /// Streams from Drift, so the feed re-emits live the moment a new PR
  /// lands during a workout (or earlier sets are edited / deleted).
  const AllPrEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allPrEventsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allPrEventsHash();

  @$internal
  @override
  $StreamProviderElement<List<PrEvent>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PrEvent>> create(Ref ref) {
    return allPrEvents(ref);
  }
}

String _$allPrEventsHash() => r'ae9bebeb747072b1cfcfc852178e5543217da681';

/// Count of PRs achieved in the current calendar month (local time).
/// Surfaced in the "PRs this month" hero stats tile.

@ProviderFor(monthlyPrCount)
const monthlyPrCountProvider = MonthlyPrCountProvider._();

/// Count of PRs achieved in the current calendar month (local time).
/// Surfaced in the "PRs this month" hero stats tile.

final class MonthlyPrCountProvider
    extends
        $FunctionalProvider<AsyncValue<int>, AsyncValue<int>, AsyncValue<int>>
    with $Provider<AsyncValue<int>> {
  /// Count of PRs achieved in the current calendar month (local time).
  /// Surfaced in the "PRs this month" hero stats tile.
  const MonthlyPrCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthlyPrCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthlyPrCountHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AsyncValue<int> create(Ref ref) {
    return monthlyPrCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<int>>(value),
    );
  }
}

String _$monthlyPrCountHash() => r'8b6d1412d1de6a354fe68316006c55d427f102f3';

/// Most recent [maxItems] PRs, newest-first. Powers the home-page PR
/// feed card. Defaults to 20 entries — enough to show progress over
/// weeks without flooding the page.

@ProviderFor(recentPrEvents)
const recentPrEventsProvider = RecentPrEventsFamily._();

/// Most recent [maxItems] PRs, newest-first. Powers the home-page PR
/// feed card. Defaults to 20 entries — enough to show progress over
/// weeks without flooding the page.

final class RecentPrEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PrEvent>>,
          AsyncValue<List<PrEvent>>,
          AsyncValue<List<PrEvent>>
        >
    with $Provider<AsyncValue<List<PrEvent>>> {
  /// Most recent [maxItems] PRs, newest-first. Powers the home-page PR
  /// feed card. Defaults to 20 entries — enough to show progress over
  /// weeks without flooding the page.
  const RecentPrEventsProvider._({
    required RecentPrEventsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'recentPrEventsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recentPrEventsHash();

  @override
  String toString() {
    return r'recentPrEventsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<PrEvent>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<PrEvent>> create(Ref ref) {
    final argument = this.argument as int;
    return recentPrEvents(ref, maxItems: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<PrEvent>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<PrEvent>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecentPrEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recentPrEventsHash() => r'02e7c6b5de4b1fa7f1ed4a3fdb001b2c6b11a70a';

/// Most recent [maxItems] PRs, newest-first. Powers the home-page PR
/// feed card. Defaults to 20 entries — enough to show progress over
/// weeks without flooding the page.

final class RecentPrEventsFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<List<PrEvent>>, int> {
  const RecentPrEventsFamily._()
    : super(
        retry: null,
        name: r'recentPrEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Most recent [maxItems] PRs, newest-first. Powers the home-page PR
  /// feed card. Defaults to 20 entries — enough to show progress over
  /// weeks without flooding the page.

  RecentPrEventsProvider call({int maxItems = 20}) =>
      RecentPrEventsProvider._(argument: maxItems, from: this);

  @override
  String toString() => r'recentPrEventsProvider';
}

/// Every PR achieved within a specific workout. Powers the "Records
/// this session" block on the workout summary screen, the celebration
/// popup that fires when the summary first opens, and the trophy badge
/// shown on workout cards in the history list.
///
/// Sorted newest-first within the workout — same ordering as
/// [allPrEventsProvider]. Empty list when the workout had no PRs (the
/// common case, especially for a user's first session per exercise).

@ProviderFor(prsForWorkout)
const prsForWorkoutProvider = PrsForWorkoutFamily._();

/// Every PR achieved within a specific workout. Powers the "Records
/// this session" block on the workout summary screen, the celebration
/// popup that fires when the summary first opens, and the trophy badge
/// shown on workout cards in the history list.
///
/// Sorted newest-first within the workout — same ordering as
/// [allPrEventsProvider]. Empty list when the workout had no PRs (the
/// common case, especially for a user's first session per exercise).

final class PrsForWorkoutProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PrEvent>>,
          AsyncValue<List<PrEvent>>,
          AsyncValue<List<PrEvent>>
        >
    with $Provider<AsyncValue<List<PrEvent>>> {
  /// Every PR achieved within a specific workout. Powers the "Records
  /// this session" block on the workout summary screen, the celebration
  /// popup that fires when the summary first opens, and the trophy badge
  /// shown on workout cards in the history list.
  ///
  /// Sorted newest-first within the workout — same ordering as
  /// [allPrEventsProvider]. Empty list when the workout had no PRs (the
  /// common case, especially for a user's first session per exercise).
  const PrsForWorkoutProvider._({
    required PrsForWorkoutFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'prsForWorkoutProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$prsForWorkoutHash();

  @override
  String toString() {
    return r'prsForWorkoutProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<PrEvent>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<PrEvent>> create(Ref ref) {
    final argument = this.argument as String;
    return prsForWorkout(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<PrEvent>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<PrEvent>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PrsForWorkoutProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$prsForWorkoutHash() => r'fa86fa6a9d697c2401572dc59a0b2655d03dbbab';

/// Every PR achieved within a specific workout. Powers the "Records
/// this session" block on the workout summary screen, the celebration
/// popup that fires when the summary first opens, and the trophy badge
/// shown on workout cards in the history list.
///
/// Sorted newest-first within the workout — same ordering as
/// [allPrEventsProvider]. Empty list when the workout had no PRs (the
/// common case, especially for a user's first session per exercise).

final class PrsForWorkoutFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<List<PrEvent>>, String> {
  const PrsForWorkoutFamily._()
    : super(
        retry: null,
        name: r'prsForWorkoutProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Every PR achieved within a specific workout. Powers the "Records
  /// this session" block on the workout summary screen, the celebration
  /// popup that fires when the summary first opens, and the trophy badge
  /// shown on workout cards in the history list.
  ///
  /// Sorted newest-first within the workout — same ordering as
  /// [allPrEventsProvider]. Empty list when the workout had no PRs (the
  /// common case, especially for a user's first session per exercise).

  PrsForWorkoutProvider call(String workoutId) =>
      PrsForWorkoutProvider._(argument: workoutId, from: this);

  @override
  String toString() => r'prsForWorkoutProvider';
}

/// Latest PR per [PrType] for a single exercise. Walks the all-PRs
/// stream once and keeps the newest (and therefore highest, by the
/// detection rules) entry per type. Powers the "Personal records"
/// header on the exercise history sheet.

@ProviderFor(exerciseBests)
const exerciseBestsProvider = ExerciseBestsFamily._();

/// Latest PR per [PrType] for a single exercise. Walks the all-PRs
/// stream once and keeps the newest (and therefore highest, by the
/// detection rules) entry per type. Powers the "Personal records"
/// header on the exercise history sheet.

final class ExerciseBestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ExercisePrBests>,
          AsyncValue<ExercisePrBests>,
          AsyncValue<ExercisePrBests>
        >
    with $Provider<AsyncValue<ExercisePrBests>> {
  /// Latest PR per [PrType] for a single exercise. Walks the all-PRs
  /// stream once and keeps the newest (and therefore highest, by the
  /// detection rules) entry per type. Powers the "Personal records"
  /// header on the exercise history sheet.
  const ExerciseBestsProvider._({
    required ExerciseBestsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'exerciseBestsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exerciseBestsHash();

  @override
  String toString() {
    return r'exerciseBestsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<ExercisePrBests>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<ExercisePrBests> create(Ref ref) {
    final argument = this.argument as String;
    return exerciseBests(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ExercisePrBests> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ExercisePrBests>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseBestsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exerciseBestsHash() => r'c6705be55318d127d68bb392355156027ec34497';

/// Latest PR per [PrType] for a single exercise. Walks the all-PRs
/// stream once and keeps the newest (and therefore highest, by the
/// detection rules) entry per type. Powers the "Personal records"
/// header on the exercise history sheet.

final class ExerciseBestsFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<ExercisePrBests>, String> {
  const ExerciseBestsFamily._()
    : super(
        retry: null,
        name: r'exerciseBestsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Latest PR per [PrType] for a single exercise. Walks the all-PRs
  /// stream once and keeps the newest (and therefore highest, by the
  /// detection rules) entry per type. Powers the "Personal records"
  /// header on the exercise history sheet.

  ExerciseBestsProvider call(String exerciseId) =>
      ExerciseBestsProvider._(argument: exerciseId, from: this);

  @override
  String toString() => r'exerciseBestsProvider';
}
