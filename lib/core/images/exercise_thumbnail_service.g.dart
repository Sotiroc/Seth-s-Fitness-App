// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_thumbnail_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(exerciseThumbnailService)
const exerciseThumbnailServiceProvider = ExerciseThumbnailServiceProvider._();

final class ExerciseThumbnailServiceProvider
    extends
        $FunctionalProvider<
          ExerciseThumbnailService,
          ExerciseThumbnailService,
          ExerciseThumbnailService
        >
    with $Provider<ExerciseThumbnailService> {
  const ExerciseThumbnailServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseThumbnailServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exerciseThumbnailServiceHash();

  @$internal
  @override
  $ProviderElement<ExerciseThumbnailService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExerciseThumbnailService create(Ref ref) {
    return exerciseThumbnailService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExerciseThumbnailService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExerciseThumbnailService>(value),
    );
  }
}

String _$exerciseThumbnailServiceHash() =>
    r'c0b7e477ee44a240e60e9ab2a226d9c8c586af52';
