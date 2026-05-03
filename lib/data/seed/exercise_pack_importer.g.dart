// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_pack_importer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(exercisePackImporter)
const exercisePackImporterProvider = ExercisePackImporterProvider._();

final class ExercisePackImporterProvider
    extends
        $FunctionalProvider<
          ExercisePackImporter,
          ExercisePackImporter,
          ExercisePackImporter
        >
    with $Provider<ExercisePackImporter> {
  const ExercisePackImporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exercisePackImporterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exercisePackImporterHash();

  @$internal
  @override
  $ProviderElement<ExercisePackImporter> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExercisePackImporter create(Ref ref) {
    return exercisePackImporter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExercisePackImporter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExercisePackImporter>(value),
    );
  }
}

String _$exercisePackImporterHash() =>
    r'b520c5ce3d8bc34e51838fb5ced3f3ca83ad671f';
