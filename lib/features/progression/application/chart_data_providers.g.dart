// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chart_data_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Page-local — only mounted while the progression tab is in view.
/// Auto-disposes when the user navigates away; the underlying weight
/// entries provider is global, so revisiting the tab feels instant.

@ProviderFor(bodyWeightChartData)
const bodyWeightChartDataProvider = BodyWeightChartDataProvider._();

/// Page-local — only mounted while the progression tab is in view.
/// Auto-disposes when the user navigates away; the underlying weight
/// entries provider is global, so revisiting the tab feels instant.

final class BodyWeightChartDataProvider
    extends
        $FunctionalProvider<
          BodyWeightChartData?,
          BodyWeightChartData?,
          BodyWeightChartData?
        >
    with $Provider<BodyWeightChartData?> {
  /// Page-local — only mounted while the progression tab is in view.
  /// Auto-disposes when the user navigates away; the underlying weight
  /// entries provider is global, so revisiting the tab feels instant.
  const BodyWeightChartDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bodyWeightChartDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bodyWeightChartDataHash();

  @$internal
  @override
  $ProviderElement<BodyWeightChartData?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BodyWeightChartData? create(Ref ref) {
    return bodyWeightChartData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BodyWeightChartData? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BodyWeightChartData?>(value),
    );
  }
}

String _$bodyWeightChartDataHash() =>
    r'4aab1ce9a47d8cc91b56256e1a6a868177ad561b';

/// Page-local strength chart inputs, auto-disposed alongside the
/// strength series provider it derives from.

@ProviderFor(strengthChartData)
const strengthChartDataProvider = StrengthChartDataFamily._();

/// Page-local strength chart inputs, auto-disposed alongside the
/// strength series provider it derives from.

final class StrengthChartDataProvider
    extends
        $FunctionalProvider<
          StrengthChartData?,
          StrengthChartData?,
          StrengthChartData?
        >
    with $Provider<StrengthChartData?> {
  /// Page-local strength chart inputs, auto-disposed alongside the
  /// strength series provider it derives from.
  const StrengthChartDataProvider._({
    required StrengthChartDataFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'strengthChartDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$strengthChartDataHash();

  @override
  String toString() {
    return r'strengthChartDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<StrengthChartData?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StrengthChartData? create(Ref ref) {
    final argument = this.argument as String;
    return strengthChartData(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StrengthChartData? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StrengthChartData?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StrengthChartDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$strengthChartDataHash() => r'd2103a504b100ae9fa8ad27eb1dd2ca1e595f97b';

/// Page-local strength chart inputs, auto-disposed alongside the
/// strength series provider it derives from.

final class StrengthChartDataFamily extends $Family
    with $FunctionalFamilyOverride<StrengthChartData?, String> {
  const StrengthChartDataFamily._()
    : super(
        retry: null,
        name: r'strengthChartDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Page-local strength chart inputs, auto-disposed alongside the
  /// strength series provider it derives from.

  StrengthChartDataProvider call(String exerciseId) =>
      StrengthChartDataProvider._(argument: exerciseId, from: this);

  @override
  String toString() => r'strengthChartDataProvider';
}
