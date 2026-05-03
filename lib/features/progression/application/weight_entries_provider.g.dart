// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_entries_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Streams every body-weight entry in the database, ordered by
/// `measuredAt` ascending. Powers the Progression body-weight chart.

@ProviderFor(weightEntries)
const weightEntriesProvider = WeightEntriesProvider._();

/// Streams every body-weight entry in the database, ordered by
/// `measuredAt` ascending. Powers the Progression body-weight chart.

final class WeightEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WeightEntry>>,
          List<WeightEntry>,
          Stream<List<WeightEntry>>
        >
    with
        $FutureModifier<List<WeightEntry>>,
        $StreamProvider<List<WeightEntry>> {
  /// Streams every body-weight entry in the database, ordered by
  /// `measuredAt` ascending. Powers the Progression body-weight chart.
  const WeightEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weightEntriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weightEntriesHash();

  @$internal
  @override
  $StreamProviderElement<List<WeightEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WeightEntry>> create(Ref ref) {
    return weightEntries(ref);
  }
}

String _$weightEntriesHash() => r'1ff5f635323dc11738cace4054c9bf3097e3c119';

/// Body-weight entries scoped to the currently-selected
/// [BodyWeightRangeFilter]. Re-emits when the user changes range OR when
/// new entries are inserted/deleted.

@ProviderFor(filteredWeightEntries)
const filteredWeightEntriesProvider = FilteredWeightEntriesProvider._();

/// Body-weight entries scoped to the currently-selected
/// [BodyWeightRangeFilter]. Re-emits when the user changes range OR when
/// new entries are inserted/deleted.

final class FilteredWeightEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WeightEntry>>,
          AsyncValue<List<WeightEntry>>,
          AsyncValue<List<WeightEntry>>
        >
    with $Provider<AsyncValue<List<WeightEntry>>> {
  /// Body-weight entries scoped to the currently-selected
  /// [BodyWeightRangeFilter]. Re-emits when the user changes range OR when
  /// new entries are inserted/deleted.
  const FilteredWeightEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredWeightEntriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredWeightEntriesHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<WeightEntry>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<WeightEntry>> create(Ref ref) {
    return filteredWeightEntries(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<WeightEntry>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<WeightEntry>>>(
        value,
      ),
    );
  }
}

String _$filteredWeightEntriesHash() =>
    r'feff219afe17b9b92dc7883d6a487831a07fc36c';

/// The single most recent weight entry, or null when the log is empty.
/// Derived from [weightEntriesProvider] so it stays live as the user logs
/// new measurements (or any time the chart's data changes).
///
/// Used by the Profile screen's weight card so its current value and
/// "Logged today / N days ago" caption track the same source of truth as
/// the Progression chart.

@ProviderFor(latestWeightEntry)
const latestWeightEntryProvider = LatestWeightEntryProvider._();

/// The single most recent weight entry, or null when the log is empty.
/// Derived from [weightEntriesProvider] so it stays live as the user logs
/// new measurements (or any time the chart's data changes).
///
/// Used by the Profile screen's weight card so its current value and
/// "Logged today / N days ago" caption track the same source of truth as
/// the Progression chart.

final class LatestWeightEntryProvider
    extends
        $FunctionalProvider<
          AsyncValue<WeightEntry?>,
          AsyncValue<WeightEntry?>,
          AsyncValue<WeightEntry?>
        >
    with $Provider<AsyncValue<WeightEntry?>> {
  /// The single most recent weight entry, or null when the log is empty.
  /// Derived from [weightEntriesProvider] so it stays live as the user logs
  /// new measurements (or any time the chart's data changes).
  ///
  /// Used by the Profile screen's weight card so its current value and
  /// "Logged today / N days ago" caption track the same source of truth as
  /// the Progression chart.
  const LatestWeightEntryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'latestWeightEntryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$latestWeightEntryHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<WeightEntry?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<WeightEntry?> create(Ref ref) {
    return latestWeightEntry(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<WeightEntry?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<WeightEntry?>>(value),
    );
  }
}

String _$latestWeightEntryHash() => r'8b77c21030aaf3637c1606c405e0bc6ac2ee6836';

/// 30-day weight trend used by the Profile weight card's chip. The window is
/// hardcoded for now; if Profile and Progression ever need different windows
/// this can become a parameterised family provider.

@ProviderFor(weightTrend)
const weightTrendProvider = WeightTrendProvider._();

/// 30-day weight trend used by the Profile weight card's chip. The window is
/// hardcoded for now; if Profile and Progression ever need different windows
/// this can become a parameterised family provider.

final class WeightTrendProvider
    extends $FunctionalProvider<WeightTrend, WeightTrend, WeightTrend>
    with $Provider<WeightTrend> {
  /// 30-day weight trend used by the Profile weight card's chip. The window is
  /// hardcoded for now; if Profile and Progression ever need different windows
  /// this can become a parameterised family provider.
  const WeightTrendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weightTrendProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weightTrendHash();

  @$internal
  @override
  $ProviderElement<WeightTrend> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WeightTrend create(Ref ref) {
    return weightTrend(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeightTrend value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeightTrend>(value),
    );
  }
}

String _$weightTrendHash() => r'099987c8f019fd6953651fb4d49fd3f7403fb77a';
