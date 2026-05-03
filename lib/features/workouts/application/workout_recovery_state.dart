import '../../../data/models/workout_detail.dart';

/// Snapshot of the auto-close-stale-workout flow's UI state.
///
/// - [recoveredWorkout]: a workout that the auto-close logic just moved
///   from active → finished. Non-null means the recovery dialog should
///   be visible.
/// - [resumedBanner]: shown inside the active workout screen after the
///   user picks "Edit / Add" in the recovery dialog (we re-activate the
///   workout and want to make it obvious why they're back inside it).
/// - [inFlight]: true while [WorkoutRecoveryController.checkForStaleWorkout]
///   is mid-flight. Prevents the rapid-fire case where cold-start and
///   `AppLifecycleState.resumed` both kick the check at the same time.
class WorkoutRecoveryState {
  const WorkoutRecoveryState({
    this.recoveredWorkout,
    this.resumedBanner = false,
    this.inFlight = false,
  });

  final WorkoutDetail? recoveredWorkout;
  final bool resumedBanner;
  final bool inFlight;

  static const WorkoutRecoveryState initial = WorkoutRecoveryState();

  WorkoutRecoveryState copyWith({
    WorkoutDetail? recoveredWorkout,
    bool? resumedBanner,
    bool? inFlight,
    bool clearRecoveredWorkout = false,
  }) {
    return WorkoutRecoveryState(
      recoveredWorkout: clearRecoveredWorkout
          ? null
          : recoveredWorkout ?? this.recoveredWorkout,
      resumedBanner: resumedBanner ?? this.resumedBanner,
      inFlight: inFlight ?? this.inFlight,
    );
  }
}
