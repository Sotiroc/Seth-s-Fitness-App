import 'dart:async';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rest_timer_controller.g.dart';

/// Immutable state for the rest-timer overlay. `targetEndUtc == null`
/// means "inactive" (sheet hidden). The wall-clock target end time —
/// rather than a counting-down integer — lets the timer self-heal when
/// a backgrounded browser tab resumes after a long throttle.
class RestTimerState {
  const RestTimerState({
    this.targetEndUtc,
    this.totalSeconds = 0,
    this.workoutExerciseId,
    this.exerciseId,
    this.exerciseName,
    this.didFireZero = false,
  });

  final DateTime? targetEndUtc;
  final int totalSeconds;
  final String? workoutExerciseId;
  final String? exerciseId;
  final String? exerciseName;
  final bool didFireZero;

  bool get isActive => targetEndUtc != null;

  RestTimerState copyWith({
    DateTime? targetEndUtc,
    int? totalSeconds,
    String? workoutExerciseId,
    String? exerciseId,
    String? exerciseName,
    bool? didFireZero,
  }) {
    return RestTimerState(
      targetEndUtc: targetEndUtc ?? this.targetEndUtc,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      didFireZero: didFireZero ?? this.didFireZero,
    );
  }
}

/// Drives the bottom-sheet overlay shown during inter-set rest. Exposed as a
/// `keepAlive` Riverpod notifier so dismissing the sheet (or navigating away
/// briefly) doesn't lose the running timer.
@Riverpod(keepAlive: true)
class RestTimerController extends _$RestTimerController {
  Timer? _ticker;
  // Two short pulses ~110ms apart at zero — feels like a discrete "ding"
  // through the wrist on a phone, even on PWA Vibration API timing.
  static const Duration _zeroHapticGap = Duration(milliseconds: 110);
  // Floor for negative `extend` so button-mashing -15s past zero doesn't
  // produce a "0:00 stuck" UI state.
  static const Duration _negativeExtendFloor = Duration(seconds: 5);

  @override
  RestTimerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
      _ticker = null;
    });
    return const RestTimerState();
  }

  /// Starts a fresh timer. Replaces any in-flight one. Returns `false`
  /// (no-op) if `seconds <= 0` so callers can treat that case as "no
  /// timer for this exercise" without a separate code path.
  bool start({
    required int seconds,
    required String workoutExerciseId,
    required String exerciseId,
    required String exerciseName,
  }) {
    if (seconds <= 0) return false;
    final DateTime now = DateTime.now().toUtc();
    state = RestTimerState(
      targetEndUtc: now.add(Duration(seconds: seconds)),
      totalSeconds: seconds,
      workoutExerciseId: workoutExerciseId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
    );
    _startTicker();
    return true;
  }

  /// Adds [deltaSeconds] (positive or negative) to the running target.
  /// Negative deltas floor at `now + 5s`. Re-arms the zero-haptic guard so
  /// extending past zero fires the haptic again on the new zero.
  void extend(int deltaSeconds) {
    final DateTime? end = state.targetEndUtc;
    if (end == null) return;
    final DateTime now = DateTime.now().toUtc();
    final DateTime proposed = end.add(Duration(seconds: deltaSeconds));
    final DateTime floor = now.add(_negativeExtendFloor);
    final DateTime next = (deltaSeconds < 0 && proposed.isBefore(floor))
        ? floor
        : proposed;
    state = state.copyWith(
      targetEndUtc: next,
      totalSeconds: state.totalSeconds + deltaSeconds,
      didFireZero: false,
    );
    if (_ticker == null) _startTicker();
  }

  /// Skip / dismiss without firing the zero haptic.
  void clear() {
    _ticker?.cancel();
    _ticker = null;
    state = const RestTimerState();
  }

  /// Idempotent zero check — fires the haptic at most once per timer
  /// instance. Called both from the internal ticker and from the sheet's
  /// resume hook so a backgrounded tab resumes-past-zero still pulses.
  void onMaybeZero() {
    final DateTime? end = state.targetEndUtc;
    if (end == null || state.didFireZero) return;
    final DateTime now = DateTime.now().toUtc();
    if (!now.isBefore(end)) {
      _firePulses();
      state = state.copyWith(didFireZero: true);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      onMaybeZero();
    });
  }

  void _firePulses() {
    HapticFeedback.mediumImpact();
    Future<void>.delayed(_zeroHapticGap, () {
      HapticFeedback.mediumImpact();
    });
  }
}
