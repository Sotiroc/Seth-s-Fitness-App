// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_filter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the persistent History search/filter state. `keepAlive` so the
/// user's filters survive popping into a workout detail and back, per the
/// spec: "Search and filters persist across navigation. Reset only via
/// 'Clear all.'"

@ProviderFor(HistoryFilterController)
const historyFilterControllerProvider = HistoryFilterControllerProvider._();

/// Holds the persistent History search/filter state. `keepAlive` so the
/// user's filters survive popping into a workout detail and back, per the
/// spec: "Search and filters persist across navigation. Reset only via
/// 'Clear all.'"
final class HistoryFilterControllerProvider
    extends $NotifierProvider<HistoryFilterController, HistoryFilter> {
  /// Holds the persistent History search/filter state. `keepAlive` so the
  /// user's filters survive popping into a workout detail and back, per the
  /// spec: "Search and filters persist across navigation. Reset only via
  /// 'Clear all.'"
  const HistoryFilterControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyFilterControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyFilterControllerHash();

  @$internal
  @override
  HistoryFilterController create() => HistoryFilterController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryFilter>(value),
    );
  }
}

String _$historyFilterControllerHash() =>
    r'6f2caf4dda749e8f6e71dc87c5fb6e2e1a0d3c9a';

/// Holds the persistent History search/filter state. `keepAlive` so the
/// user's filters survive popping into a workout detail and back, per the
/// spec: "Search and filters persist across navigation. Reset only via
/// 'Clear all.'"

abstract class _$HistoryFilterController extends $Notifier<HistoryFilter> {
  HistoryFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<HistoryFilter, HistoryFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HistoryFilter, HistoryFilter>,
              HistoryFilter,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
