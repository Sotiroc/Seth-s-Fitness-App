import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/workout.dart';
import '../../../data/models/workout_detail.dart';
import '../../../data/repositories/workout_repository.dart';
import 'workout_recovery_state.dart';

part 'workout_recovery_controller.g.dart';

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
@Riverpod(keepAlive: true)
class WorkoutRecoveryController extends _$WorkoutRecoveryController {
  @override
  WorkoutRecoveryState build() => WorkoutRecoveryState.initial;

  /// Runs the auto-close repository check. If a workout was just closed,
  /// fetches its detail and stores it in state so the dialog renders.
  ///
  /// Idempotent: short-circuits if already in flight or if the dialog is
  /// already showing a recovered workout (handles the cold-start +
  /// resumed double-fire case).
  Future<void> checkForStaleWorkout({
    Duration threshold = const Duration(hours: 1),
    DateTime? now,
  }) async {
    if (state.inFlight || state.recoveredWorkout != null) return;
    state = state.copyWith(inFlight: true);
    try {
      final WorkoutRepository repo = ref.read(workoutRepositoryProvider);
      final Workout? closed = await repo.autoCloseIfStale(
        threshold: threshold,
        now: now,
      );
      if (closed == null) {
        state = state.copyWith(inFlight: false);
        return;
      }
      final WorkoutDetail detail = await repo.getWorkoutById(closed.id);
      state = WorkoutRecoveryState(
        recoveredWorkout: detail,
        resumedBanner: state.resumedBanner,
      );
    } catch (_) {
      state = state.copyWith(inFlight: false);
      rethrow;
    }
  }

  /// Closes the dialog without further changes (auto-close edits stay).
  void dismissRecovery() {
    state = state.copyWith(clearRecoveredWorkout: true, inFlight: false);
  }

  /// Re-activates the recovered workout so the user can keep logging.
  /// Sets [WorkoutRecoveryState.resumedBanner] so the active workout
  /// screen knows to surface its "paused due to inactivity" banner.
  Future<void> reopenForEditing() async {
    final WorkoutDetail? recovered = state.recoveredWorkout;
    if (recovered == null) return;
    await ref
        .read(workoutRepositoryProvider)
        .reopenWorkout(recovered.workout.id);
    state = const WorkoutRecoveryState(resumedBanner: true);
  }

  /// Persists user edits (workout name, end time, intensity score) to
  /// the already-finished workout, then closes the dialog.
  Future<void> confirmSave({
    String? name,
    DateTime? endedAt,
    int? intensityScore,
  }) async {
    final WorkoutDetail? recovered = state.recoveredWorkout;
    if (recovered == null) return;
    final WorkoutRepository repo = ref.read(workoutRepositoryProvider);
    final String workoutId = recovered.workout.id;

    if (name != recovered.workout.name) {
      await repo.updateWorkoutName(workoutId: workoutId, name: name);
    }
    if (intensityScore != recovered.workout.intensityScore) {
      await repo.updateWorkoutIntensityScore(
        workoutId: workoutId,
        score: intensityScore,
      );
    }
    if (endedAt != null && endedAt != recovered.workout.endedAt) {
      await repo.adjustEndedAt(workoutId, endedAt);
    }

    state = state.copyWith(clearRecoveredWorkout: true, inFlight: false);
  }

  /// Permanently deletes the recovered workout.
  Future<void> confirmDiscard() async {
    final WorkoutDetail? recovered = state.recoveredWorkout;
    if (recovered == null) return;
    await ref
        .read(workoutRepositoryProvider)
        .deleteFinishedWorkout(recovered.workout.id);
    state = state.copyWith(clearRecoveredWorkout: true, inFlight: false);
  }

  /// Dismisses the post-resume banner shown on the active workout screen.
  void clearResumedBanner() {
    if (!state.resumedBanner) return;
    state = state.copyWith(resumedBanner: false);
  }
}
