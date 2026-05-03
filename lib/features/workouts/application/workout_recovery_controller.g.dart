// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_recovery_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the auto-close-stale-workout recovery flow.
///
/// On app cold-start and on `AppLifecycleState.resumed`, [app.dart] calls
/// [checkForStaleWorkout]. If the user's active workout has been idle past
/// the threshold, the repository auto-closes it (or silently discards an
/// empty one) and this controller exposes the recovered workout for the
/// dialog to render.
///
/// The four user-facing dialog actions ([confirmSave], [confirmDiscard],
/// [reopenForEditing], [dismissRecovery]) all clear the `recoveredWorkout`
/// state once they finish.

@ProviderFor(WorkoutRecoveryController)
const workoutRecoveryControllerProvider = WorkoutRecoveryControllerProvider._();

/// Owns the auto-close-stale-workout recovery flow.
///
/// On app cold-start and on `AppLifecycleState.resumed`, [app.dart] calls
/// [checkForStaleWorkout]. If the user's active workout has been idle past
/// the threshold, the repository auto-closes it (or silently discards an
/// empty one) and this controller exposes the recovered workout for the
/// dialog to render.
///
/// The four user-facing dialog actions ([confirmSave], [confirmDiscard],
/// [reopenForEditing], [dismissRecovery]) all clear the `recoveredWorkout`
/// state once they finish.
final class WorkoutRecoveryControllerProvider
    extends $NotifierProvider<WorkoutRecoveryController, WorkoutRecoveryState> {
  /// Owns the auto-close-stale-workout recovery flow.
  ///
  /// On app cold-start and on `AppLifecycleState.resumed`, [app.dart] calls
  /// [checkForStaleWorkout]. If the user's active workout has been idle past
  /// the threshold, the repository auto-closes it (or silently discards an
  /// empty one) and this controller exposes the recovered workout for the
  /// dialog to render.
  ///
  /// The four user-facing dialog actions ([confirmSave], [confirmDiscard],
  /// [reopenForEditing], [dismissRecovery]) all clear the `recoveredWorkout`
  /// state once they finish.
  const WorkoutRecoveryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutRecoveryControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutRecoveryControllerHash();

  @$internal
  @override
  WorkoutRecoveryController create() => WorkoutRecoveryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkoutRecoveryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkoutRecoveryState>(value),
    );
  }
}

String _$workoutRecoveryControllerHash() =>
    r'ebf331e619dc48c2194fb41e891336d16befda35';

/// Owns the auto-close-stale-workout recovery flow.
///
/// On app cold-start and on `AppLifecycleState.resumed`, [app.dart] calls
/// [checkForStaleWorkout]. If the user's active workout has been idle past
/// the threshold, the repository auto-closes it (or silently discards an
/// empty one) and this controller exposes the recovered workout for the
/// dialog to render.
///
/// The four user-facing dialog actions ([confirmSave], [confirmDiscard],
/// [reopenForEditing], [dismissRecovery]) all clear the `recoveredWorkout`
/// state once they finish.

abstract class _$WorkoutRecoveryController
    extends $Notifier<WorkoutRecoveryState> {
  WorkoutRecoveryState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<WorkoutRecoveryState, WorkoutRecoveryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WorkoutRecoveryState, WorkoutRecoveryState>,
              WorkoutRecoveryState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
