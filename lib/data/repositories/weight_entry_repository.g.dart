// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_entry_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(weightEntryRepository)
const weightEntryRepositoryProvider = WeightEntryRepositoryProvider._();

final class WeightEntryRepositoryProvider
    extends
        $FunctionalProvider<
          WeightEntryRepository,
          WeightEntryRepository,
          WeightEntryRepository
        >
    with $Provider<WeightEntryRepository> {
  const WeightEntryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weightEntryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weightEntryRepositoryHash();

  @$internal
  @override
  $ProviderElement<WeightEntryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WeightEntryRepository create(Ref ref) {
    return weightEntryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeightEntryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeightEntryRepository>(value),
    );
  }
}

String _$weightEntryRepositoryHash() =>
    r'2e968cbd4613b60c89f39c85bcc56b0416479e09';
