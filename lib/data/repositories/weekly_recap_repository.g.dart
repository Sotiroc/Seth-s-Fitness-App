// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_recap_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(weeklyRecapRepository)
const weeklyRecapRepositoryProvider = WeeklyRecapRepositoryProvider._();

final class WeeklyRecapRepositoryProvider
    extends
        $FunctionalProvider<
          WeeklyRecapRepository,
          WeeklyRecapRepository,
          WeeklyRecapRepository
        >
    with $Provider<WeeklyRecapRepository> {
  const WeeklyRecapRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weeklyRecapRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weeklyRecapRepositoryHash();

  @$internal
  @override
  $ProviderElement<WeeklyRecapRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WeeklyRecapRepository create(Ref ref) {
    return weeklyRecapRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeeklyRecapRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeeklyRecapRepository>(value),
    );
  }
}

String _$weeklyRecapRepositoryHash() =>
    r'2c2a508859965af2555cd93533d568b62aeccb6d';
