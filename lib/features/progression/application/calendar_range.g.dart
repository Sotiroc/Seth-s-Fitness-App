// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_range.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Currently-selected window for the training calendar heatmap.

@ProviderFor(CalendarRangeFilter)
const calendarRangeFilterProvider = CalendarRangeFilterProvider._();

/// Currently-selected window for the training calendar heatmap.
final class CalendarRangeFilterProvider
    extends $NotifierProvider<CalendarRangeFilter, CalendarRange> {
  /// Currently-selected window for the training calendar heatmap.
  const CalendarRangeFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarRangeFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarRangeFilterHash();

  @$internal
  @override
  CalendarRangeFilter create() => CalendarRangeFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarRange value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarRange>(value),
    );
  }
}

String _$calendarRangeFilterHash() =>
    r'9a0f2672d4b3a0d96c0f05edd9ce859ce7f5e369';

/// Currently-selected window for the training calendar heatmap.

abstract class _$CalendarRangeFilter extends $Notifier<CalendarRange> {
  CalendarRange build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<CalendarRange, CalendarRange>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarRange, CalendarRange>,
              CalendarRange,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
