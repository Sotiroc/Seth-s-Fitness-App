// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WorkoutSessionController)
const workoutSessionControllerProvider = WorkoutSessionControllerProvider._();

final class WorkoutSessionControllerProvider
    extends $AsyncNotifierProvider<WorkoutSessionController, void> {
  const WorkoutSessionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutSessionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutSessionControllerHash();

  @$internal
  @override
  WorkoutSessionController create() => WorkoutSessionController();
}

String _$workoutSessionControllerHash() =>
    r'786e00b797e6603ae23790c9da80992ecda01a87';

abstract class _$WorkoutSessionController extends $AsyncNotifier<void> {
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
