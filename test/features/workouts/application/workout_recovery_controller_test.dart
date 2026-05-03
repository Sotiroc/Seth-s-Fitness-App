import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:fitnessapp/data/db/app_database.dart';
import 'package:fitnessapp/data/db/database_providers.dart';
import 'package:fitnessapp/data/models/workout.dart';
import 'package:fitnessapp/data/models/workout_set.dart';
import 'package:fitnessapp/data/repositories/exercise_repository.dart';
import 'package:fitnessapp/data/repositories/workout_repository.dart';
import 'package:fitnessapp/data/seed/default_exercises.dart';
import 'package:fitnessapp/features/workouts/application/workout_recovery_controller.dart';

/// End-to-end tests for [WorkoutRecoveryController]. Drives the controller
/// against a real in-memory Drift database via the same providers the app
/// wires up, so behavior matches production. Skips the dialog/UI layer.
void main() {
  late AppDatabase database;
  late ProviderContainer container;
  late WorkoutRepository repo;
  late ExerciseRepository exerciseRepo;
  const Uuid uuid = Uuid();

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => database),
        uuidProvider.overrideWith((ref) => uuid),
      ],
    );
    addTearDown(container.dispose);
    repo = container.read(workoutRepositoryProvider);
    exerciseRepo = ExerciseRepository(database: database, uuid: uuid);
    await exerciseRepo.seedDefaultsIfNeeded();
  });

  tearDown(() async {
    await database.close();
  });

  /// Starts a workout, adds one Bench Press exercise + one completed set.
  /// Returns the workout id.
  Future<String> seedActiveWithCompletedSet() async {
    final Workout workout = await repo.startWorkout();
    final String exerciseId = defaultExerciseSeeds
        .firstWhere((seed) => seed.name == 'Bench Press')
        .id;
    final detail = await repo.addExerciseToWorkout(
      workoutId: workout.id,
      exerciseId: exerciseId,
    );
    final WorkoutSet set =
        await repo.addSetToWorkoutExercise(detail.workoutExercise.id);
    await repo.updateWorkoutSet(
      workoutSetId: set.id,
      weightKg: 80,
      reps: 5,
      distanceKm: null,
      durationSeconds: null,
      completed: true,
    );
    return workout.id;
  }

  Future<void> backdate(String workoutId, DateTime at) async {
    final exerciseRows = await (database.select(database.workoutExercises)
          ..where((tbl) => tbl.workoutId.equals(workoutId)))
        .get();
    final exerciseIds =
        exerciseRows.map((row) => row.id).toList(growable: false);
    if (exerciseIds.isNotEmpty) {
      await (database.update(database.sets)
            ..where((tbl) => tbl.workoutExerciseId.isIn(exerciseIds)))
          .write(SetsCompanion(
        updatedAt: drift.Value<DateTime?>(at),
        completedAt: drift.Value<DateTime?>(at),
      ));
    }
    await (database.update(database.workoutExercises)
          ..where((tbl) => tbl.workoutId.equals(workoutId)))
        .write(WorkoutExercisesCompanion(
      createdAt: drift.Value<DateTime?>(at),
    ));
    await (database.update(database.workouts)
          ..where((tbl) => tbl.id.equals(workoutId)))
        .write(WorkoutsCompanion(startedAt: drift.Value<DateTime>(at)));
  }

  test('cold-start with stale workout populates recoveredWorkout', () async {
    final String workoutId = await seedActiveWithCompletedSet();
    final DateTime longAgo = DateTime.utc(2024, 1, 1, 10);
    await backdate(workoutId, longAgo);

    await container
        .read(workoutRecoveryControllerProvider.notifier)
        .checkForStaleWorkout(
          threshold: const Duration(hours: 1),
          now: longAgo.add(const Duration(hours: 2)),
        );

    final state = container.read(workoutRecoveryControllerProvider);
    expect(state.recoveredWorkout, isNotNull);
    expect(state.recoveredWorkout!.workout.id, workoutId);
    expect(state.recoveredWorkout!.workout.endedAt?.toUtc(), longAgo);
    expect(state.inFlight, isFalse);
  });

  test('cold-start with no active workout leaves state clean', () async {
    await container
        .read(workoutRecoveryControllerProvider.notifier)
        .checkForStaleWorkout(threshold: const Duration(hours: 1));

    final state = container.read(workoutRecoveryControllerProvider);
    expect(state.recoveredWorkout, isNull);
    expect(state.resumedBanner, isFalse);
    expect(state.inFlight, isFalse);
  });

  test('cold-start with fresh workout leaves state clean', () async {
    await seedActiveWithCompletedSet();

    await container
        .read(workoutRecoveryControllerProvider.notifier)
        .checkForStaleWorkout(
          threshold: const Duration(hours: 1),
          now: DateTime.now().toUtc().add(const Duration(minutes: 5)),
        );

    final state = container.read(workoutRecoveryControllerProvider);
    expect(state.recoveredWorkout, isNull);
  });

  test('checkForStaleWorkout is idempotent across rapid double-fire', () async {
    final String workoutId = await seedActiveWithCompletedSet();
    final DateTime longAgo = DateTime.utc(2024, 1, 1, 10);
    await backdate(workoutId, longAgo);

    final notifier =
        container.read(workoutRecoveryControllerProvider.notifier);
    final DateTime now = longAgo.add(const Duration(hours: 2));
    // Kick both calls in parallel — the second should short-circuit on
    // either the inFlight or recoveredWorkout guard.
    await Future.wait([
      notifier.checkForStaleWorkout(
        threshold: const Duration(hours: 1),
        now: now,
      ),
      notifier.checkForStaleWorkout(
        threshold: const Duration(hours: 1),
        now: now,
      ),
    ]);

    final state = container.read(workoutRecoveryControllerProvider);
    expect(state.recoveredWorkout, isNotNull);
    // The workout was closed exactly once — re-querying gives a finished
    // workout, but the autoCloseIfStale guard re-reads endedAt inside its
    // transaction so a duplicate close-attempt would be a no-op anyway.
    final detail = await repo.getWorkoutById(workoutId);
    expect(detail.workout.endedAt, isNotNull);
  });

  test('dismissRecovery clears state', () async {
    final String workoutId = await seedActiveWithCompletedSet();
    final DateTime longAgo = DateTime.utc(2024, 1, 1, 10);
    await backdate(workoutId, longAgo);

    final notifier =
        container.read(workoutRecoveryControllerProvider.notifier);
    await notifier.checkForStaleWorkout(
      threshold: const Duration(hours: 1),
      now: longAgo.add(const Duration(hours: 2)),
    );
    expect(
      container.read(workoutRecoveryControllerProvider).recoveredWorkout,
      isNotNull,
    );

    notifier.dismissRecovery();
    expect(
      container.read(workoutRecoveryControllerProvider).recoveredWorkout,
      isNull,
    );
  });

  test('reopenForEditing reactivates and sets banner flag', () async {
    final String workoutId = await seedActiveWithCompletedSet();
    final DateTime longAgo = DateTime.utc(2024, 1, 1, 10);
    await backdate(workoutId, longAgo);

    final notifier =
        container.read(workoutRecoveryControllerProvider.notifier);
    await notifier.checkForStaleWorkout(
      threshold: const Duration(hours: 1),
      now: longAgo.add(const Duration(hours: 2)),
    );
    await notifier.reopenForEditing();

    final state = container.read(workoutRecoveryControllerProvider);
    expect(state.recoveredWorkout, isNull);
    expect(state.resumedBanner, isTrue);

    final reopened = await repo.getWorkoutById(workoutId);
    expect(reopened.workout.isActive, isTrue);
  });

  test('confirmDiscard deletes the recovered workout', () async {
    final String workoutId = await seedActiveWithCompletedSet();
    final DateTime longAgo = DateTime.utc(2024, 1, 1, 10);
    await backdate(workoutId, longAgo);

    final notifier =
        container.read(workoutRecoveryControllerProvider.notifier);
    await notifier.checkForStaleWorkout(
      threshold: const Duration(hours: 1),
      now: longAgo.add(const Duration(hours: 2)),
    );
    await notifier.confirmDiscard();

    final state = container.read(workoutRecoveryControllerProvider);
    expect(state.recoveredWorkout, isNull);
    final list = await repo.listAllWorkouts();
    expect(list, isEmpty);
  });

  test('confirmSave persists name, endedAt, and intensity edits', () async {
    final String workoutId = await seedActiveWithCompletedSet();
    final DateTime longAgo = DateTime.utc(2024, 1, 1, 10);
    await backdate(workoutId, longAgo);

    final notifier =
        container.read(workoutRecoveryControllerProvider.notifier);
    await notifier.checkForStaleWorkout(
      threshold: const Duration(hours: 1),
      now: longAgo.add(const Duration(hours: 2)),
    );

    final DateTime newEnd = longAgo.add(const Duration(minutes: 30));
    await notifier.confirmSave(
      name: 'Recovered session',
      endedAt: newEnd,
      intensityScore: 7,
    );

    final state = container.read(workoutRecoveryControllerProvider);
    expect(state.recoveredWorkout, isNull);

    final detail = await repo.getWorkoutById(workoutId);
    expect(detail.workout.name, 'Recovered session');
    expect(detail.workout.intensityScore, 7);
    expect(detail.workout.endedAt?.toUtc(), newEnd);
  });

  test('clearResumedBanner toggles the flag off', () async {
    final String workoutId = await seedActiveWithCompletedSet();
    final DateTime longAgo = DateTime.utc(2024, 1, 1, 10);
    await backdate(workoutId, longAgo);

    final notifier =
        container.read(workoutRecoveryControllerProvider.notifier);
    await notifier.checkForStaleWorkout(
      threshold: const Duration(hours: 1),
      now: longAgo.add(const Duration(hours: 2)),
    );
    await notifier.reopenForEditing();
    expect(
      container.read(workoutRecoveryControllerProvider).resumedBanner,
      isTrue,
    );

    notifier.clearResumedBanner();
    expect(
      container.read(workoutRecoveryControllerProvider).resumedBanner,
      isFalse,
    );
  });
}
