// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progression_range.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Currently-selected window for the body-weight chart. Defaults to 3M
/// — long enough to show a meaningful trend, short enough that the line
/// has texture rather than looking like a flat year-overview.

@ProviderFor(BodyWeightRangeFilter)
const bodyWeightRangeFilterProvider = BodyWeightRangeFilterProvider._();

/// Currently-selected window for the body-weight chart. Defaults to 3M
/// — long enough to show a meaningful trend, short enough that the line
/// has texture rather than looking like a flat year-overview.
final class BodyWeightRangeFilterProvider
    extends $NotifierProvider<BodyWeightRangeFilter, ProgressionRange> {
  /// Currently-selected window for the body-weight chart. Defaults to 3M
  /// — long enough to show a meaningful trend, short enough that the line
  /// has texture rather than looking like a flat year-overview.
  const BodyWeightRangeFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bodyWeightRangeFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bodyWeightRangeFilterHash();

  @$internal
  @override
  BodyWeightRangeFilter create() => BodyWeightRangeFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgressionRange value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgressionRange>(value),
    );
  }
}

String _$bodyWeightRangeFilterHash() =>
    r'4608ad934d19a279e222145924959df2dc66749e';

/// Currently-selected window for the body-weight chart. Defaults to 3M
/// — long enough to show a meaningful trend, short enough that the line
/// has texture rather than looking like a flat year-overview.

abstract class _$BodyWeightRangeFilter extends $Notifier<ProgressionRange> {
  ProgressionRange build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ProgressionRange, ProgressionRange>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProgressionRange, ProgressionRange>,
              ProgressionRange,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Currently-selected window for the per-exercise strength chart.

@ProviderFor(StrengthRangeFilter)
const strengthRangeFilterProvider = StrengthRangeFilterProvider._();

/// Currently-selected window for the per-exercise strength chart.
final class StrengthRangeFilterProvider
    extends $NotifierProvider<StrengthRangeFilter, ProgressionRange> {
  /// Currently-selected window for the per-exercise strength chart.
  const StrengthRangeFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'strengthRangeFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$strengthRangeFilterHash();

  @$internal
  @override
  StrengthRangeFilter create() => StrengthRangeFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgressionRange value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgressionRange>(value),
    );
  }
}

String _$strengthRangeFilterHash() =>
    r'bf61cdccd4e8f931cbfd9c82d640f0e99c7f1dae';

/// Currently-selected window for the per-exercise strength chart.

abstract class _$StrengthRangeFilter extends $Notifier<ProgressionRange> {
  ProgressionRange build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ProgressionRange, ProgressionRange>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProgressionRange, ProgressionRange>,
              ProgressionRange,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
