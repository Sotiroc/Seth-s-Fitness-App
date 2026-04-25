// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExerciseEditorController)
const exerciseEditorControllerProvider = ExerciseEditorControllerProvider._();

final class ExerciseEditorControllerProvider
    extends $AsyncNotifierProvider<ExerciseEditorController, void> {
  const ExerciseEditorControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseEditorControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exerciseEditorControllerHash();

  @$internal
  @override
  ExerciseEditorController create() => ExerciseEditorController();
}

String _$exerciseEditorControllerHash() =>
    r'dd7afd008ec287533b353ea477921d973519b6f6';

abstract class _$ExerciseEditorController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
