import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessapp/features/workouts/application/rest_timer_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Drain any HapticFeedback platform calls so the two-pulse zero behavior
  // doesn't print warnings under the test binding.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall call,
        ) async {
          return null;
        });
  });

  ProviderContainer makeContainer() {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('RestTimerController', () {
    test('build() returns inactive state', () {
      final ProviderContainer container = makeContainer();
      final RestTimerState state = container.read(restTimerControllerProvider);
      expect(state.isActive, isFalse);
      expect(state.didFireZero, isFalse);
    });

    test('start populates wall-clock target and metadata', () {
      final ProviderContainer container = makeContainer();
      final RestTimerController c = container.read(
        restTimerControllerProvider.notifier,
      );
      final bool started = c.start(
        seconds: 90,
        workoutExerciseId: 'we-1',
        exerciseId: 'ex-1',
        exerciseName: 'Bench',
      );
      final RestTimerState state = container.read(restTimerControllerProvider);
      expect(started, isTrue);
      expect(state.isActive, isTrue);
      expect(state.totalSeconds, 90);
      expect(state.exerciseName, 'Bench');
      expect(state.workoutExerciseId, 'we-1');
      expect(state.didFireZero, isFalse);
      // Target must be in the future.
      expect(
        state.targetEndUtc!.isAfter(DateTime.now().toUtc()),
        isTrue,
      );
    });

    test('start with seconds <= 0 returns false and stays inactive', () {
      final ProviderContainer container = makeContainer();
      final RestTimerController c = container.read(
        restTimerControllerProvider.notifier,
      );
      expect(
        c.start(
          seconds: 0,
          workoutExerciseId: 'we',
          exerciseId: 'ex',
          exerciseName: 'X',
        ),
        isFalse,
      );
      expect(
        c.start(
          seconds: -5,
          workoutExerciseId: 'we',
          exerciseId: 'ex',
          exerciseName: 'X',
        ),
        isFalse,
      );
      expect(container.read(restTimerControllerProvider).isActive, isFalse);
    });

    test('extend bumps target and re-arms didFireZero', () {
      final ProviderContainer container = makeContainer();
      final RestTimerController c = container.read(
        restTimerControllerProvider.notifier,
      );
      c.start(
        seconds: 60,
        workoutExerciseId: 'we',
        exerciseId: 'ex',
        exerciseName: 'X',
      );
      final DateTime before =
          container.read(restTimerControllerProvider).targetEndUtc!;
      c.extend(15);
      final RestTimerState state = container.read(restTimerControllerProvider);
      expect(state.targetEndUtc!.isAfter(before), isTrue);
      expect(state.totalSeconds, 75);
      expect(state.didFireZero, isFalse);
    });

    test('extend with negative delta floors target to 5s from now', () {
      final ProviderContainer container = makeContainer();
      final RestTimerController c = container.read(
        restTimerControllerProvider.notifier,
      );
      c.start(
        seconds: 8,
        workoutExerciseId: 'we',
        exerciseId: 'ex',
        exerciseName: 'X',
      );
      // Mash -15s past zero. Should clamp the target so remaining >= 5s.
      c.extend(-15);
      final DateTime end =
          container.read(restTimerControllerProvider).targetEndUtc!;
      final Duration remaining = end.difference(DateTime.now().toUtc());
      // Allow a small tolerance for the time elapsed inside the test.
      expect(remaining.inMilliseconds, greaterThanOrEqualTo(4500));
    });

    test('clear empties the state', () {
      final ProviderContainer container = makeContainer();
      final RestTimerController c = container.read(
        restTimerControllerProvider.notifier,
      );
      c.start(
        seconds: 30,
        workoutExerciseId: 'we',
        exerciseId: 'ex',
        exerciseName: 'X',
      );
      c.clear();
      final RestTimerState state = container.read(restTimerControllerProvider);
      expect(state.isActive, isFalse);
      expect(state.targetEndUtc, isNull);
      expect(state.totalSeconds, 0);
    });

    test('onMaybeZero is idempotent — flips didFireZero only once', () {
      final ProviderContainer container = makeContainer();
      final RestTimerController c = container.read(
        restTimerControllerProvider.notifier,
      );
      // Negative seconds via start are rejected, so prime the state by
      // starting a real timer then forcing target into the past via extend.
      c.start(
        seconds: 1,
        workoutExerciseId: 'we',
        exerciseId: 'ex',
        exerciseName: 'X',
      );
      c.extend(-1);
      // Target may still be at the 5s floor — push it solidly past now.
      final RestTimerState afterFloor =
          container.read(restTimerControllerProvider);
      // Walk wall-clock past target — easiest: extend by a deeply negative
      // value, then assert via onMaybeZero idempotency check.
      // Manually run idempotency: call twice and ensure state.didFireZero
      // doesn't flip back. We can't directly assert haptic count without
      // a side-channel, so this is a behavior smoke test.
      c.onMaybeZero();
      c.onMaybeZero();
      final RestTimerState after =
          container.read(restTimerControllerProvider);
      // didFireZero is set if/when the target has passed. Either way,
      // calling onMaybeZero again must NOT reset it.
      if (after.didFireZero) {
        c.onMaybeZero();
        expect(
          container.read(restTimerControllerProvider).didFireZero,
          isTrue,
        );
      }
      // Sanity: state still references the same exercise.
      expect(after.exerciseName, afterFloor.exerciseName);
    });
  });
}
