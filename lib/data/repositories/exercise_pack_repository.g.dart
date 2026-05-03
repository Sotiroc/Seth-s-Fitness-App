// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_pack_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(exercisePackRepository)
const exercisePackRepositoryProvider = ExercisePackRepositoryProvider._();

final class ExercisePackRepositoryProvider
    extends
        $FunctionalProvider<
          ExercisePackRepository,
          ExercisePackRepository,
          ExercisePackRepository
        >
    with $Provider<ExercisePackRepository> {
  const ExercisePackRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exercisePackRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exercisePackRepositoryHash();

  @$internal
  @override
  $ProviderElement<ExercisePackRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExercisePackRepository create(Ref ref) {
    return exercisePackRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExercisePackRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExercisePackRepository>(value),
    );
  }
}

String _$exercisePackRepositoryHash() =>
    r'06eafb05056471d70f18c5d31acdf13ebc5267e6';
