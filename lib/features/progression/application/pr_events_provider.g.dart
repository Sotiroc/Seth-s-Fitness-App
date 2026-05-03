// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pr_events_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every PR ever achieved across every weighted exercise, newest-first.
/// Each entry corresponds to one set whose Epley-estimated 1RM strictly
/// exceeded all prior sets on the same exercise at the time it was
/// logged.
///
/// Powered by `WorkoutRepository.watchAllPrEvents` — a single SQL query
/// + linear scan. Streams from Drift, so the feed re-emits live the
/// moment a new PR lands during a workout.

@ProviderFor(allPrEvents)
const allPrEventsProvider = AllPrEventsProvider._();

/// Every PR ever achieved across every weighted exercise, newest-first.
/// Each entry corresponds to one set whose Epley-estimated 1RM strictly
/// exceeded all prior sets on the same exercise at the time it was
/// logged.
///
/// Powered by `WorkoutRepository.watchAllPrEvents` — a single SQL query
/// + linear scan. Streams from Drift, so the feed re-emits live the
/// moment a new PR lands during a workout.

final class AllPrEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PrEvent>>,
          List<PrEvent>,
          Stream<List<PrEvent>>
        >
    with $FutureModifier<List<PrEvent>>, $StreamProvider<List<PrEvent>> {
  /// Every PR ever achieved across every weighted exercise, newest-first.
  /// Each entry corresponds to one set whose Epley-estimated 1RM strictly
  /// exceeded all prior sets on the same exercise at the time it was
  /// logged.
  ///
  /// Powered by `WorkoutRepository.watchAllPrEvents` — a single SQL query
  /// + linear scan. Streams from Drift, so the feed re-emits live the
  /// moment a new PR lands during a workout.
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

/// Most recent [maxItems] PRs, newest-first. Powers the PR feed card.
/// Defaults to 20 entries — enough to show progress over weeks without
/// flooding the page.

@ProviderFor(recentPrEvents)
const recentPrEventsProvider = RecentPrEventsFamily._();

/// Most recent [maxItems] PRs, newest-first. Powers the PR feed card.
/// Defaults to 20 entries — enough to show progress over weeks without
/// flooding the page.

final class RecentPrEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PrEvent>>,
          AsyncValue<List<PrEvent>>,
          AsyncValue<List<PrEvent>>
        >
    with $Provider<AsyncValue<List<PrEvent>>> {
  /// Most recent [maxItems] PRs, newest-first. Powers the PR feed card.
  /// Defaults to 20 entries — enough to show progress over weeks without
  /// flooding the page.
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

/// Most recent [maxItems] PRs, newest-first. Powers the PR feed card.
/// Defaults to 20 entries — enough to show progress over weeks without
/// flooding the page.

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

  /// Most recent [maxItems] PRs, newest-first. Powers the PR feed card.
  /// Defaults to 20 entries — enough to show progress over weeks without
  /// flooding the page.

  RecentPrEventsProvider call({int maxItems = 20}) =>
      RecentPrEventsProvider._(argument: maxItems, from: this);

  @override
  String toString() => r'recentPrEventsProvider';
}
