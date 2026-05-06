// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Page-local — only the exercise form mounts this. Auto-dispose so the
/// busy/error AsyncValue resets cleanly when the editor closes.

@ProviderFor(ExerciseEditorController)
const exerciseEditorControllerProvider = ExerciseEditorControllerProvider._();

/// Page-local — only the exercise form mounts this. Auto-dispose so the
/// busy/error AsyncValue resets cleanly when the editor closes.
final class ExerciseEditorControllerProvider
    extends $AsyncNotifierProvider<ExerciseEditorController, void> {
  /// Page-local — only the exercise form mounts this. Auto-dispose so the
  /// busy/error AsyncValue resets cleanly when the editor closes.
  const ExerciseEditorControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseEditorControllerProvider',
        isAutoDispose: true,
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
    r'6461529ecd34ba2c098eb564d63bc2ae10f3e1b1';

/// Page-local — only the exercise form mounts this. Auto-dispose so the
/// busy/error AsyncValue resets cleanly when the editor closes.

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
