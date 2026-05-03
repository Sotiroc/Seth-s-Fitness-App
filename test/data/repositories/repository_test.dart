import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:fitnessapp/data/db/app_database.dart';
import 'package:fitnessapp/data/models/exercise.dart';
import 'package:fitnessapp/data/models/exercise_muscle_group.dart';
import 'package:fitnessapp/data/models/exercise_type.dart';
import 'package:fitnessapp/data/models/template_detail.dart';
import 'package:fitnessapp/data/models/template_exercise.dart';
import 'package:fitnessapp/data/models/workout.dart';
import 'package:fitnessapp/data/models/workout_detail.dart';
import 'package:fitnessapp/data/models/workout_set.dart';
import 'package:fitnessapp/data/models/workout_set_kind.dart';
import 'package:fitnessapp/data/models/workout_template.dart';
import 'package:fitnessapp/data/repositories/exercise_repository.dart';
import 'package:fitnessapp/data/repositories/repository_exceptions.dart';
import 'package:fitnessapp/data/repositories/template_repository.dart';
import 'package:fitnessapp/data/repositories/workout_repository.dart';
import 'package:fitnessapp/data/seed/default_exercises.dart';

void main() {
  late AppDatabase database;
  late ExerciseRepository exerciseRepository;
  late WorkoutRepository workoutRepository;
  late TemplateRepository templateRepository;
  const Uuid uuid = Uuid();

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    exerciseRepository = ExerciseRepository(database: database, uuid: uuid);
    workoutRepository = WorkoutRepository(database: database, uuid: uuid);
    templateRepository = TemplateRepository(database: database, uuid: uuid);
  });

  tearDown(() async {
    await database.close();
  });

  group('ExerciseRepository', () {
    test('seeds defaults once without duplicating rows', () async {
      await exerciseRepository.seedDefaultsIfNeeded();
      await exerciseRepository.seedDefaultsIfNeeded();

      final List<Exercise> exercises = await exerciseRepository
          .getAllExercises();

      expect(exercises, hasLength(18));
      expect(
        exercises.where((exercise) => exercise.name == 'Bench Press'),
        hasLength(1),
      );
    });

    test('supports create, update, get, filter, and delete', () async {
      final Exercise created = await exerciseRepository.createExercise(
        name: 'Farmer Carry',
        type: ExerciseType.cardio,
        muscleGroup: ExerciseMuscleGroup.cardio,
      );

      final Exercise updated = await exerciseRepository.updateExercise(
        created.copyWith(
          name: 'Farmer Carry Sled',
          muscleGroup: ExerciseMuscleGroup.back,
          thumbnailPath: '/tmp/sled.png',
        ),
      );

      final Exercise fetched = await exerciseRepository.getExerciseById(
        updated.id,
      );
      final List<Exercise> cardioExercises = await exerciseRepository
          .getExercisesByType(ExerciseType.cardio);

      expect(fetched.name, 'Farmer Carry Sled');
      expect(fetched.muscleGroup, ExerciseMuscleGroup.back);
      expect(fetched.thumbnailPath, '/tmp/sled.png');
      expect(
        cardioExercises.any((exercise) => exercise.id == created.id),
        isTrue,
      );

      await exerciseRepository.deleteExercise(created.id);

      expect(
        () => exerciseRepository.getExerciseById(created.id),
        throwsA(isA<ExerciseNotFoundException>()),
      );
    });

    test('rejects blank exercise names', () async {
      expect(
        () => exerciseRepository.createExercise(
          name: '   ',
          type: ExerciseType.weighted,
          muscleGroup: ExerciseMuscleGroup.chest,
        ),
        throwsA(isA<InvalidExerciseNameException>()),
      );
    });

    test('stores muscle groups for seeded and custom exercises', () async {
      await exerciseRepository.seedDefaultsIfNeeded();

      final Exercise seededBench = (await exerciseRepository.getAllExercises())
          .firstWhere((exercise) => exercise.name == 'Bench Press');
      final Exercise custom = await exerciseRepository.createExercise(
        name: 'Cable Crunch',
        type: ExerciseType.bodyweight,
        muscleGroup: ExerciseMuscleGroup.abs,
      );

      final Exercise updated = await exerciseRepository.updateExercise(
        custom.copyWith(muscleGroup: ExerciseMuscleGroup.chest),
      );

      expect(seededBench.muscleGroup, ExerciseMuscleGroup.chest);
      expect(updated.muscleGroup, ExerciseMuscleGroup.chest);
    });

    test(
      'blocks delete when the exercise is referenced by workout data',
      () async {
        await exerciseRepository.seedDefaultsIfNeeded();
        final String exerciseId = defaultExerciseSeeds.first.id;
        final workout = await workoutRepository.startWorkout();

        await database
            .into(database.workoutExercises)
            .insert(
              WorkoutExercisesCompanion.insert(
                id: uuid.v4(),
                workoutId: workout.id,
                exerciseId: exerciseId,
                orderIndex: 0,
              ),
            );

        expect(
          () => exerciseRepository.deleteExercise(exerciseId),
          throwsA(isA<ExerciseDeleteBlockedException>()),
        );
      },
    );
  });

  group('WorkoutRepository', () {
    test('starts only one active workout at a time', () async {
      final workout = await workoutRepository.startWorkout();

      expect(workout.isActive, isTrue);
      expect(
        workoutRepository.startWorkout(),
        throwsA(isA<ActiveWorkoutAlreadyExistsException>()),
      );
    });

    test('ends and cancels workouts correctly', () async {
      final Workout first = await workoutRepository.startWorkout(
        notes: 'Leg day',
      );
      final Workout ended = await workoutRepository.endWorkout(first.id);
      final Workout second = await workoutRepository.startWorkout();

      await workoutRepository.cancelWorkout(second.id);

      final List workouts = await workoutRepository.listAllWorkouts();
      final List history = await workoutRepository.listHistory();

      expect(ended.endedAt, isNotNull);
      expect(workouts, hasLength(1));
      expect(history, hasLength(1));
      expect(history.first.id, first.id);
    });

    test('returns history and nested workout detail', () async {
      await exerciseRepository.seedDefaultsIfNeeded();
      final Workout workout = await workoutRepository.startWorkout();
      final String exerciseId = defaultExerciseSeeds.first.id;
      final String workoutExerciseId = uuid.v4();

      await database
          .into(database.workoutExercises)
          .insert(
            WorkoutExercisesCompanion.insert(
              id: workoutExerciseId,
              workoutId: workout.id,
              exerciseId: exerciseId,
              orderIndex: 0,
            ),
          );

      await database
          .into(database.sets)
          .insert(
            SetsCompanion.insert(
              id: uuid.v4(),
              workoutExerciseId: workoutExerciseId,
              setNumber: 1,
              weightKg: const drift.Value<double>(80),
              reps: const drift.Value<int>(5),
              distanceKm: const drift.Value<double?>(null),
              durationSeconds: const drift.Value<int?>(null),
              completed: const drift.Value<bool>(true),
            ),
          );

      await workoutRepository.endWorkout(workout.id);

      final history = await workoutRepository.listHistory();
      final detail = await workoutRepository.getWorkoutById(workout.id);

      expect(history, hasLength(1));
      expect(detail.exercises, hasLength(1));
      expect(detail.exercises.first.exercise.name, 'Bench Press');
      expect(detail.exercises.first.sets, hasLength(1));
      expect(detail.exercises.first.sets.first.weightKg, 80);
      expect(detail.exercises.first.sets.first.reps, 5);
    });

    test(
      'supports adding exercises, sets, notes, and typed set updates',
      () async {
        await exerciseRepository.seedDefaultsIfNeeded();
        final Workout workout = await workoutRepository.startWorkout(
          notes: '  Upper body  ',
        );

        final String weightedExerciseId = defaultExerciseSeeds
            .firstWhere((seed) => seed.name == 'Bench Press')
            .id;
        final String bodyweightExerciseId = defaultExerciseSeeds
            .firstWhere((seed) => seed.name == 'Pull-Up')
            .id;
        final String cardioExerciseId = defaultExerciseSeeds
            .firstWhere((seed) => seed.name == 'Treadmill')
            .id;

        final weightedDetail = await workoutRepository.addExerciseToWorkout(
          workoutId: workout.id,
          exerciseId: weightedExerciseId,
        );
        final bodyweightDetail = await workoutRepository.addExerciseToWorkout(
          workoutId: workout.id,
          exerciseId: bodyweightExerciseId,
        );
        final cardioDetail = await workoutRepository.addExerciseToWorkout(
          workoutId: workout.id,
          exerciseId: cardioExerciseId,
        );

        final WorkoutSet weightedSet = await workoutRepository
            .addSetToWorkoutExercise(weightedDetail.workoutExercise.id);
        final WorkoutSet bodyweightSet = await workoutRepository
            .addSetToWorkoutExercise(bodyweightDetail.workoutExercise.id);
        final WorkoutSet cardioSet = await workoutRepository
            .addSetToWorkoutExercise(cardioDetail.workoutExercise.id);

        await workoutRepository.updateWorkoutNotes(
          workoutId: workout.id,
          notes: '  Push and cardio  ',
        );
        await workoutRepository.updateWorkoutSet(
          workoutSetId: weightedSet.id,
          weightKg: 82.5,
          reps: 6,
          distanceKm: null,
          durationSeconds: null,
          completed: true,
        );
        await workoutRepository.updateWorkoutSet(
          workoutSetId: bodyweightSet.id,
          weightKg: null,
          reps: 8,
          distanceKm: null,
          durationSeconds: null,
          completed: true,
        );
        await workoutRepository.updateWorkoutSet(
          workoutSetId: cardioSet.id,
          weightKg: null,
          reps: null,
          distanceKm: 2.4,
          durationSeconds: 900,
          completed: true,
        );

        final WorkoutDetail detail = await workoutRepository.getWorkoutById(
          workout.id,
        );

        expect(detail.workout.notes, 'Push and cardio');
        expect(detail.exercises, hasLength(3));
        expect(detail.exercises[0].exercise.name, 'Bench Press');
        expect(detail.exercises[0].sets.single.weightKg, 82.5);
        expect(detail.exercises[0].sets.single.reps, 6);
        expect(detail.exercises[1].exercise.name, 'Pull-Up');
        expect(detail.exercises[1].sets.single.reps, 8);
        expect(detail.exercises[1].sets.single.weightKg, isNull);
        expect(detail.exercises[2].exercise.name, 'Treadmill');
        expect(detail.exercises[2].sets.single.distanceKm, 2.4);
        expect(detail.exercises[2].sets.single.durationSeconds, 900);

        // Activity-tracking timestamps populated by the auto-close flow:
        // every WorkoutExercise gets a createdAt and every WorkoutSet
        // mutation bumps updatedAt. Completion sets completedAt.
        for (final ex in detail.exercises) {
          expect(ex.workoutExercise.createdAt, isNotNull);
          for (final s in ex.sets) {
            expect(s.updatedAt, isNotNull);
            expect(s.completedAt, isNotNull, reason: 'completed sets get a timestamp');
          }
        }
      },
    );

    test(
      'rejects invalid set values and blocks mutations on ended workouts',
      () async {
        await exerciseRepository.seedDefaultsIfNeeded();
        final Workout workout = await workoutRepository.startWorkout();
        final String exerciseId = defaultExerciseSeeds
            .firstWhere((seed) => seed.name == 'Bench Press')
            .id;
        final weightedDetail = await workoutRepository.addExerciseToWorkout(
          workoutId: workout.id,
          exerciseId: exerciseId,
        );
        final WorkoutSet workoutSet = await workoutRepository
            .addSetToWorkoutExercise(weightedDetail.workoutExercise.id);

        expect(
          () => workoutRepository.updateWorkoutSet(
            workoutSetId: workoutSet.id,
            weightKg: null,
            reps: 5,
            distanceKm: null,
            durationSeconds: null,
            completed: true,
          ),
          throwsA(isA<InvalidWorkoutSetException>()),
        );

        await workoutRepository.endWorkout(workout.id);

        expect(
          () => workoutRepository.addSetToWorkoutExercise(
            weightedDetail.workoutExercise.id,
          ),
          throwsA(isA<WorkoutNotActiveException>()),
        );
        expect(
          () => workoutRepository.updateWorkoutNotes(
            workoutId: workout.id,
            notes: 'Late edit',
          ),
          throwsA(isA<WorkoutNotActiveException>()),
        );
        expect(
          () => workoutRepository.cancelWorkout(workout.id),
          throwsA(isA<WorkoutNotActiveException>()),
        );
      },
    );

    test('watches a workout starting without manual invalidation', () async {
      final Future<WorkoutDetail?> detailFuture = workoutRepository
          .watchActiveWorkoutDetail()
          .firstWhere((detail) => detail != null)
          .timeout(const Duration(seconds: 2));

      final Workout workout = await workoutRepository.startWorkout();
      final WorkoutDetail detail = (await detailFuture)!;

      expect(detail.workout.id, workout.id);
      expect(detail.workout.isActive, isTrue);
      expect(detail.exercises, isEmpty);
    });

    test(
      'watches nested exercise and set updates for the active workout',
      () async {
        await exerciseRepository.seedDefaultsIfNeeded();
        final Workout workout = await workoutRepository.startWorkout();
        final String exerciseId = defaultExerciseSeeds
            .firstWhere((seed) => seed.name == 'Bench Press')
            .id;

        final Future<WorkoutDetail?> detailFuture = workoutRepository
            .watchActiveWorkoutDetail()
            .firstWhere(
              (detail) =>
                  detail != null &&
                  detail.workout.id == workout.id &&
                  detail.exercises.length == 1 &&
                  detail.exercises.first.sets.length == 1 &&
                  detail.exercises.first.sets.first.completed,
            )
            .timeout(const Duration(seconds: 2));

        final WorkoutExerciseDetail exerciseDetail = await workoutRepository
            .addExerciseToWorkout(
              workoutId: workout.id,
              exerciseId: exerciseId,
            );
        final WorkoutSet workoutSet = await workoutRepository
            .addSetToWorkoutExercise(exerciseDetail.workoutExercise.id);

        await workoutRepository.updateWorkoutSet(
          workoutSetId: workoutSet.id,
          weightKg: 80,
          reps: 5,
          distanceKm: null,
          durationSeconds: null,
          completed: true,
        );

        final WorkoutDetail detail = (await detailFuture)!;

        expect(detail.exercises.single.exercise.name, 'Bench Press');
        expect(detail.exercises.single.sets.single.weightKg, 80);
        expect(detail.exercises.single.sets.single.reps, 5);
        expect(detail.exercises.single.sets.single.completed, isTrue);
      },
    );

    test(
      'watchHistory emits completed workouts in newest-first order',
      () async {
        final List<List<Workout>> emissions = <List<Workout>>[];
        final subscription = workoutRepository.watchHistory().listen(
          emissions.add,
        );
        addTearDown(subscription.cancel);

        final Workout first = await workoutRepository.startWorkout();
        await workoutRepository.endWorkout(
          first.id,
          endedAt: DateTime.utc(2026, 4, 21, 8),
        );
        final Workout second = await workoutRepository.startWorkout();
        await workoutRepository.endWorkout(
          second.id,
          endedAt: DateTime.utc(2026, 4, 21, 9),
        );
        await pumpEventQueue();

        expect(emissions, isNotEmpty);
        expect(emissions.last.map((workout) => workout.id).toList(), <String>[
          second.id,
          first.id,
        ]);
      },
    );

    group('intensity score', () {
      test('is null on a freshly started workout', () async {
        final Workout workout = await workoutRepository.startWorkout();
        expect(workout.intensityScore, isNull);

        final WorkoutDetail detail = await workoutRepository.getWorkoutById(
          workout.id,
        );
        expect(detail.workout.intensityScore, isNull);
      });

      test('persists a value and reads it back', () async {
        final Workout workout = await workoutRepository.startWorkout();

        final Workout updated = await workoutRepository
            .updateWorkoutIntensityScore(workoutId: workout.id, score: 7);

        expect(updated.intensityScore, 7);
        final WorkoutDetail detail = await workoutRepository.getWorkoutById(
          workout.id,
        );
        expect(detail.workout.intensityScore, 7);
      });

      test('clamps below 1 up to 1', () async {
        final Workout workout = await workoutRepository.startWorkout();

        final Workout updated = await workoutRepository
            .updateWorkoutIntensityScore(workoutId: workout.id, score: 0);

        expect(updated.intensityScore, 1);
      });

      test('clamps above 10 down to 10', () async {
        final Workout workout = await workoutRepository.startWorkout();

        final Workout updated = await workoutRepository
            .updateWorkoutIntensityScore(workoutId: workout.id, score: 11);

        expect(updated.intensityScore, 10);
      });

      test('null clears a previously set score', () async {
        final Workout workout = await workoutRepository.startWorkout();
        await workoutRepository.updateWorkoutIntensityScore(
          workoutId: workout.id,
          score: 5,
        );

        final Workout cleared = await workoutRepository
            .updateWorkoutIntensityScore(workoutId: workout.id, score: null);

        expect(cleared.intensityScore, isNull);
        final WorkoutDetail detail = await workoutRepository.getWorkoutById(
          workout.id,
        );
        expect(detail.workout.intensityScore, isNull);
      });

      test('can be set on a finished workout from the summary screen',
          () async {
        final Workout workout = await workoutRepository.startWorkout();
        await workoutRepository.endWorkout(workout.id);

        final Workout updated = await workoutRepository
            .updateWorkoutIntensityScore(workoutId: workout.id, score: 8);

        expect(updated.intensityScore, 8);
        expect(updated.isActive, isFalse);
      });
    });

    group('staleness and auto-close', () {
      Future<({Workout workout, String setId})>
      seedActiveWithCompletedSet() async {
        await exerciseRepository.seedDefaultsIfNeeded();
        final Workout workout = await workoutRepository.startWorkout();
        final String exerciseId = defaultExerciseSeeds
            .firstWhere((seed) => seed.name == 'Bench Press')
            .id;
        final detail = await workoutRepository.addExerciseToWorkout(
          workoutId: workout.id,
          exerciseId: exerciseId,
        );
        final WorkoutSet set =
            await workoutRepository.addSetToWorkoutExercise(
          detail.workoutExercise.id,
        );
        await workoutRepository.updateWorkoutSet(
          workoutSetId: set.id,
          weightKg: 80,
          reps: 5,
          distanceKm: null,
          durationSeconds: null,
          completed: true,
        );
        return (workout: workout, setId: set.id);
      }

      // Backdates a completed set's updatedAt + completedAt so the
      // staleness snapshot's "last activity" appears to be `at`. The
      // exercise's createdAt and the workout's startedAt are bumped
      // back too, otherwise they would be the most-recent timestamps
      // and shadow the set's. Uses Drift's typed update API so the
      // value passes through the same DateTime serializer the repo uses.
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

      test('closes a stale workout at the last completed set time', () async {
        final seeded = await seedActiveWithCompletedSet();
        final DateTime longAgo = DateTime.utc(2024, 1, 1, 10);
        await backdate(seeded.workout.id, longAgo);

        // Sanity-check: the snapshot should reflect the backdate.
        final snapshot =
            await workoutRepository.getStalenessSnapshot(seeded.workout.id);
        expect(
          snapshot.lastCompletedSetAt?.toUtc(),
          longAgo,
          reason: 'snapshot.lastCompletedSetAt should match backdate',
        );

        final Workout? closed = await workoutRepository.autoCloseIfStale(
          threshold: const Duration(hours: 1),
          now: longAgo.add(const Duration(hours: 2)),
        );

        expect(closed, isNotNull);
        expect(closed!.id, seeded.workout.id);
        expect(
          closed.endedAt?.toUtc(),
          longAgo,
          reason: 'endedAt should match the last completed set time',
        );

        final WorkoutDetail detail =
            await workoutRepository.getWorkoutById(seeded.workout.id);
        expect(detail.workout.endedAt?.toUtc(), longAgo);
      });

      test('silently discards a stale workout with zero completed sets',
          () async {
        await exerciseRepository.seedDefaultsIfNeeded();
        final Workout workout = await workoutRepository.startWorkout();
        final String exerciseId = defaultExerciseSeeds
            .firstWhere((seed) => seed.name == 'Bench Press')
            .id;
        final detail = await workoutRepository.addExerciseToWorkout(
          workoutId: workout.id,
          exerciseId: exerciseId,
        );
        // Add an uncompleted set (no completedAt).
        await workoutRepository.addSetToWorkoutExercise(
          detail.workoutExercise.id,
        );

        final DateTime longAgo = DateTime.utc(2024, 1, 1, 10);
        await backdate(workout.id, longAgo);

        final Workout? closed = await workoutRepository.autoCloseIfStale(
          threshold: const Duration(hours: 1),
          now: longAgo.add(const Duration(hours: 2)),
        );

        expect(closed, isNull, reason: 'no popup for empty discard');
        expect(
          () => workoutRepository.getWorkoutById(workout.id),
          throwsA(isA<WorkoutNotFoundException>()),
          reason: 'workout was deleted',
        );
      });

      test('is a no-op when activity is within the threshold', () async {
        final seeded = await seedActiveWithCompletedSet();
        final DateTime now = DateTime.now().toUtc();

        final Workout? closed = await workoutRepository.autoCloseIfStale(
          threshold: const Duration(hours: 1),
          now: now.add(const Duration(minutes: 5)),
        );

        expect(closed, isNull);
        final WorkoutDetail detail =
            await workoutRepository.getWorkoutById(seeded.workout.id);
        expect(detail.workout.endedAt, isNull,
            reason: 'workout still active');
      });

      test('is a no-op when no active workout exists', () async {
        final Workout? closed = await workoutRepository.autoCloseIfStale(
          threshold: const Duration(hours: 1),
        );
        expect(closed, isNull);
      });

      test('reopenWorkout clears endedAt on a finished workout', () async {
        final Workout workout = await workoutRepository.startWorkout();
        await workoutRepository.endWorkout(workout.id);

        final Workout reopened = await workoutRepository.reopenWorkout(
          workout.id,
        );

        expect(reopened.endedAt, isNull);
        expect(reopened.isActive, isTrue);
      });

      test('reopenWorkout rejects a workout that is still active', () async {
        final Workout workout = await workoutRepository.startWorkout();
        expect(
          () => workoutRepository.reopenWorkout(workout.id),
          throwsA(isA<WorkoutNotEndedException>()),
        );
      });

      test('reopenWorkout rejects when another workout is active', () async {
        final Workout finished = await workoutRepository.startWorkout();
        await workoutRepository.endWorkout(finished.id);
        // Start a second active one.
        await workoutRepository.startWorkout();
        expect(
          () => workoutRepository.reopenWorkout(finished.id),
          throwsA(isA<ActiveWorkoutAlreadyExistsException>()),
        );
      });

      test('adjustEndedAt updates a finished workout endedAt', () async {
        final Workout workout = await workoutRepository.startWorkout();
        await workoutRepository.endWorkout(workout.id);
        final DateTime newEnd = DateTime.utc(2024, 1, 1, 12);

        final Workout adjusted =
            await workoutRepository.adjustEndedAt(workout.id, newEnd);

        expect(adjusted.endedAt, newEnd);
      });

      test('adjustEndedAt rejects an active workout', () async {
        final Workout workout = await workoutRepository.startWorkout();
        expect(
          () => workoutRepository.adjustEndedAt(
            workout.id,
            DateTime.utc(2024, 1, 1, 12),
          ),
          throwsA(isA<WorkoutNotEndedException>()),
        );
      });

      test('deleteFinishedWorkout removes a closed workout', () async {
        final Workout workout = await workoutRepository.startWorkout();
        await workoutRepository.endWorkout(workout.id);

        await workoutRepository.deleteFinishedWorkout(workout.id);

        expect(
          () => workoutRepository.getWorkoutById(workout.id),
          throwsA(isA<WorkoutNotFoundException>()),
        );
      });

      test('completedAt clears when a set is unmarked complete', () async {
        final seeded = await seedActiveWithCompletedSet();
        // Toggle back to incomplete.
        final WorkoutSet toggled = await workoutRepository.updateWorkoutSet(
          workoutSetId: seeded.setId,
          weightKg: 80,
          reps: 5,
          distanceKm: null,
          durationSeconds: null,
          completed: false,
        );
        expect(toggled.completed, isFalse);
        expect(toggled.completedAt, isNull);
      });

      test('completedAt is preserved on re-save of an already-completed set',
          () async {
        final seeded = await seedActiveWithCompletedSet();
        final WorkoutDetail before =
            await workoutRepository.getWorkoutById(seeded.workout.id);
        final DateTime? originalCompletedAt =
            before.exercises.single.sets.single.completedAt;
        expect(originalCompletedAt, isNotNull);

        // Re-save with same completed=true; should not bump completedAt.
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await workoutRepository.updateWorkoutSet(
          workoutSetId: seeded.setId,
          weightKg: 82,
          reps: 5,
          distanceKm: null,
          durationSeconds: null,
          completed: true,
        );

        final WorkoutDetail after =
            await workoutRepository.getWorkoutById(seeded.workout.id);
        expect(
          after.exercises.single.sets.single.completedAt,
          originalCompletedAt,
        );
      });
    });

    group('set kinds, RPE, notes, and drop sets', () {
      test('addSet defaults to normal kind with no parent / RPE / note',
          () async {
        await exerciseRepository.seedDefaultsIfNeeded();
        final Workout workout = await workoutRepository.startWorkout();
        final WorkoutExerciseDetail ex =
            await workoutRepository.addExerciseToWorkout(
          workoutId: workout.id,
          exerciseId: defaultExerciseSeeds
              .firstWhere((s) => s.name == 'Bench Press')
              .id,
        );

        final WorkoutSet seeded = await workoutRepository
            .addSetToWorkoutExercise(ex.workoutExercise.id);

        expect(seeded.kind, WorkoutSetKind.normal);
        expect(seeded.parentSetId, isNull);
        expect(seeded.rpe, isNull);
        expect(seeded.note, isNull);
      });

      test('updateWorkoutSetExtras persists kind, rpe, and trimmed note',
          () async {
        await exerciseRepository.seedDefaultsIfNeeded();
        final Workout workout = await workoutRepository.startWorkout();
        final WorkoutExerciseDetail ex =
            await workoutRepository.addExerciseToWorkout(
          workoutId: workout.id,
          exerciseId: defaultExerciseSeeds
              .firstWhere((s) => s.name == 'Bench Press')
              .id,
        );
        final WorkoutSet seeded = await workoutRepository
            .addSetToWorkoutExercise(ex.workoutExercise.id);

        await workoutRepository.updateWorkoutSetExtras(
          workoutSetId: seeded.id,
          kind: WorkoutSetKind.warmUp,
          rpe: 7,
          note: '  felt fine  ',
        );

        final WorkoutDetail after =
            await workoutRepository.getWorkoutById(workout.id);
        final WorkoutSet refreshed = after.exercises.single.sets.single;
        expect(refreshed.kind, WorkoutSetKind.warmUp);
        expect(refreshed.rpe, 7);
        expect(refreshed.note, 'felt fine');
      });

      test('drop sets require a parent and reference one', () async {
        await exerciseRepository.seedDefaultsIfNeeded();
        final Workout workout = await workoutRepository.startWorkout();
        final WorkoutExerciseDetail ex =
            await workoutRepository.addExerciseToWorkout(
          workoutId: workout.id,
          exerciseId: defaultExerciseSeeds
              .firstWhere((s) => s.name == 'Bench Press')
              .id,
        );
        final WorkoutSet parent = await workoutRepository
            .addSetToWorkoutExercise(ex.workoutExercise.id);

        // Reject drop without parent.
        expect(
          () => workoutRepository.addSetToWorkoutExercise(
            ex.workoutExercise.id,
            kind: WorkoutSetKind.drop,
          ),
          throwsA(isA<InvalidWorkoutSetException>()),
        );

        // Accept drop with parent.
        final WorkoutSet drop = await workoutRepository
            .addSetToWorkoutExercise(
          ex.workoutExercise.id,
          kind: WorkoutSetKind.drop,
          parentSetId: parent.id,
        );
        expect(drop.kind, WorkoutSetKind.drop);
        expect(drop.parentSetId, parent.id);
      });

      test('deleting a parent re-parents drop children', () async {
        await exerciseRepository.seedDefaultsIfNeeded();
        final Workout workout = await workoutRepository.startWorkout();
        final WorkoutExerciseDetail ex =
            await workoutRepository.addExerciseToWorkout(
          workoutId: workout.id,
          exerciseId: defaultExerciseSeeds
              .firstWhere((s) => s.name == 'Bench Press')
              .id,
        );
        final WorkoutSet parent1 = await workoutRepository
            .addSetToWorkoutExercise(ex.workoutExercise.id);
        final WorkoutSet child = await workoutRepository
            .addSetToWorkoutExercise(
          ex.workoutExercise.id,
          kind: WorkoutSetKind.drop,
          parentSetId: parent1.id,
        );

        await workoutRepository.deleteWorkoutSet(parent1.id);

        final WorkoutDetail after =
            await workoutRepository.getWorkoutById(workout.id);
        final WorkoutSet refreshedChild =
            after.exercises.single.sets.firstWhere((s) => s.id == child.id);
        // parent1 had no parent of its own → child detaches cleanly.
        expect(refreshedChild.parentSetId, isNull);
      });

      test('warm-ups are excluded from completed-set counts', () async {
        await exerciseRepository.seedDefaultsIfNeeded();
        final Workout workout = await workoutRepository.startWorkout();
        final WorkoutExerciseDetail ex =
            await workoutRepository.addExerciseToWorkout(
          workoutId: workout.id,
          exerciseId: defaultExerciseSeeds
              .firstWhere((s) => s.name == 'Bench Press')
              .id,
        );
        final WorkoutSet warmUp = await workoutRepository
            .addSetToWorkoutExercise(ex.workoutExercise.id);
        await workoutRepository.updateWorkoutSetExtras(
          workoutSetId: warmUp.id,
          kind: WorkoutSetKind.warmUp,
        );
        await workoutRepository.updateWorkoutSet(
          workoutSetId: warmUp.id,
          weightKg: 40,
          reps: 10,
          distanceKm: null,
          durationSeconds: null,
          completed: true,
        );
        final WorkoutSet working = await workoutRepository
            .addSetToWorkoutExercise(ex.workoutExercise.id);
        await workoutRepository.updateWorkoutSet(
          workoutSetId: working.id,
          weightKg: 80,
          reps: 6,
          distanceKm: null,
          durationSeconds: null,
          completed: true,
        );
        await workoutRepository.endWorkout(workout.id);

        final Map<String, int> counts = await workoutRepository
            .getCompletedSetCountsForWorkouts(<String>[workout.id]);

        // Only the working set should be counted; warm-up is excluded.
        expect(counts[workout.id], 1);
      });
    });
  });

  group('TemplateRepository', () {
    test('supports CRUD and creates workouts from templates', () async {
      await exerciseRepository.seedDefaultsIfNeeded();
      final WorkoutTemplate template = await templateRepository.createTemplate(
        name: 'Push Day',
        exercises: <TemplateExerciseDraft>[
          TemplateExerciseDraft(
            exerciseId: defaultExerciseSeeds[0].id,
            orderIndex: 0,
            defaultSets: 3,
          ),
          TemplateExerciseDraft(
            exerciseId: defaultExerciseSeeds[1].id,
            orderIndex: 1,
            defaultSets: 4,
          ),
        ],
      );

      final WorkoutTemplate updated = await templateRepository.updateTemplate(
        template: template.copyWith(name: 'Updated Push Day'),
        exercises: <TemplateExerciseDraft>[
          TemplateExerciseDraft(
            exerciseId: defaultExerciseSeeds[2].id,
            orderIndex: 0,
            defaultSets: 5,
          ),
        ],
      );

      final detail = await templateRepository.getTemplateById(template.id);
      final workout = await templateRepository.createWorkoutFromTemplate(
        template.id,
      );
      final workoutDetail = await workoutRepository.getWorkoutById(workout.id);

      expect(updated.name, 'Updated Push Day');
      expect(detail.exercises, hasLength(1));
      expect(detail.exercises.first.exercise.name, 'Overhead Press');
      expect(detail.exercises.first.templateExercise.defaultSets, 5);
      expect(workout.templateId, template.id);
      expect(workoutDetail.exercises, hasLength(1));
      expect(workoutDetail.exercises.first.exercise.name, 'Overhead Press');
      expect(workoutDetail.exercises.first.sets, hasLength(5));
      expect(workoutDetail.exercises.first.sets.first.setNumber, 1);
      expect(workoutDetail.exercises.first.sets.last.setNumber, 5);
      expect(
        workoutDetail.exercises.first.sets.every((set) => !set.completed),
        isTrue,
      );

      await templateRepository.deleteTemplate(template.id);

      final templates = await templateRepository.getAllTemplates();
      expect(templates, isEmpty);
    });

    test('rejects blank template names', () async {
      expect(
        () => templateRepository.createTemplate(name: '   '),
        throwsA(isA<InvalidWorkoutTemplateNameException>()),
      );
    });

    test(
      'watches template detail updates without manual invalidation',
      () async {
        await exerciseRepository.seedDefaultsIfNeeded();
        final WorkoutTemplate template = await templateRepository
            .createTemplate(name: 'Pull Day');
        final String exerciseId = defaultExerciseSeeds
            .firstWhere((seed) => seed.name == 'Lat Pulldown')
            .id;

        final Future<TemplateDetail> detailFuture = templateRepository
            .watchTemplateById(template.id)
            .firstWhere(
              (detail) =>
                  detail.template.id == template.id &&
                  detail.template.name == 'Pull Day Updated' &&
                  detail.exercises.length == 1,
            )
            .timeout(const Duration(seconds: 2));

        await templateRepository.updateTemplate(
          template: template.copyWith(name: 'Pull Day Updated'),
          exercises: <TemplateExerciseDraft>[
            TemplateExerciseDraft(
              exerciseId: exerciseId,
              orderIndex: 0,
              defaultSets: 4,
            ),
          ],
        );

        final TemplateDetail detail = await detailFuture;

        expect(detail.template.name, 'Pull Day Updated');
        expect(detail.exercises.single.exercise.name, 'Lat Pulldown');
        expect(detail.exercises.single.templateExercise.defaultSets, 4);
      },
    );
  });

  group('Rest timer metadata', () {
    Future<({Workout workout, String workoutExerciseId, String exerciseId})>
    seedActiveWorkout() async {
      final Exercise exercise = await exerciseRepository.createExercise(
        name: 'Squat',
        type: ExerciseType.weighted,
        muscleGroup: ExerciseMuscleGroup.legs,
      );
      final Workout workout = await workoutRepository.startWorkout();
      final String workoutExerciseId = uuid.v4();
      await database
          .into(database.workoutExercises)
          .insert(
            WorkoutExercisesCompanion.insert(
              id: workoutExerciseId,
              workoutId: workout.id,
              exerciseId: exercise.id,
              orderIndex: 0,
            ),
          );
      return (
        workout: workout,
        workoutExerciseId: workoutExerciseId,
        exerciseId: exercise.id,
      );
    }

    test(
      'addSetToWorkoutExercise leaves startedAt null until first edit',
      () async {
        final ctx = await seedActiveWorkout();
        final WorkoutSet created = await workoutRepository
            .addSetToWorkoutExercise(ctx.workoutExerciseId);
        expect(created.startedAt, isNull);
      },
    );

    test('updateWorkoutSet captures startedAt on first edit and pins it',
        () async {
      final ctx = await seedActiveWorkout();
      final WorkoutSet created = await workoutRepository
          .addSetToWorkoutExercise(ctx.workoutExerciseId);

      final WorkoutSet firstEdit = await workoutRepository.updateWorkoutSet(
        workoutSetId: created.id,
        weightKg: 60,
        reps: 5,
        distanceKm: null,
        durationSeconds: null,
        completed: false,
      );
      expect(firstEdit.startedAt, isNotNull);

      // Wait one tick so any new "now" would visibly differ.
      await Future<void>.delayed(const Duration(milliseconds: 5));

      final WorkoutSet secondEdit = await workoutRepository.updateWorkoutSet(
        workoutSetId: created.id,
        weightKg: 65,
        reps: 5,
        distanceKm: null,
        durationSeconds: null,
        completed: true,
      );
      // Drift stores DateTime as Unix seconds and reads back local-zoned,
      // so the returned values can differ in subseconds and timezone
      // presentation. Compare as milliseconds-since-epoch — timezone-
      // agnostic and within the second-level precision the column has.
      expect(
        secondEdit.startedAt!.millisecondsSinceEpoch ~/ 1000,
        firstEdit.startedAt!.millisecondsSinceEpoch ~/ 1000,
      );
      expect(secondEdit.completedAt, isNotNull);
    });

    test('Exercise.effectiveRestSeconds returns per-type defaults', () async {
      final Exercise weighted = await exerciseRepository.createExercise(
        name: 'Row',
        type: ExerciseType.weighted,
        muscleGroup: ExerciseMuscleGroup.back,
      );
      final Exercise bodyweight = await exerciseRepository.createExercise(
        name: 'Push-up',
        type: ExerciseType.bodyweight,
        muscleGroup: ExerciseMuscleGroup.chest,
      );
      final Exercise cardio = await exerciseRepository.createExercise(
        name: 'Treadmill',
        type: ExerciseType.cardio,
        muscleGroup: ExerciseMuscleGroup.cardio,
      );
      expect(weighted.effectiveRestSeconds, 120);
      expect(bodyweight.effectiveRestSeconds, 60);
      expect(cardio.effectiveRestSeconds, 0);
    });

    test('updateExerciseRestSeconds round-trips, clears, and validates',
        () async {
      final Exercise created = await exerciseRepository.createExercise(
        name: 'Bench',
        type: ExerciseType.weighted,
        muscleGroup: ExerciseMuscleGroup.chest,
      );
      expect(created.defaultRestSeconds, isNull);
      expect(created.effectiveRestSeconds, 120);

      final Exercise withOverride =
          await exerciseRepository.updateExerciseRestSeconds(
        exerciseId: created.id,
        restSeconds: 45,
      );
      expect(withOverride.defaultRestSeconds, 45);
      expect(withOverride.effectiveRestSeconds, 45);

      final Exercise cleared =
          await exerciseRepository.updateExerciseRestSeconds(
        exerciseId: created.id,
        restSeconds: null,
      );
      expect(cleared.defaultRestSeconds, isNull);
      expect(cleared.effectiveRestSeconds, 120);

      expect(
        () => exerciseRepository.updateExerciseRestSeconds(
          exerciseId: created.id,
          restSeconds: -1,
        ),
        throwsA(isA<InvalidExerciseRestException>()),
      );
      expect(
        () => exerciseRepository.updateExerciseRestSeconds(
          exerciseId: created.id,
          restSeconds: 3601,
        ),
        throwsA(isA<InvalidExerciseRestException>()),
      );
    });

    test('createExercise persists defaultRestSeconds and refetches',
        () async {
      final Exercise created = await exerciseRepository.createExercise(
        name: 'Pull-up',
        type: ExerciseType.bodyweight,
        muscleGroup: ExerciseMuscleGroup.back,
        defaultRestSeconds: 75,
      );
      expect(created.defaultRestSeconds, 75);
      final Exercise fetched =
          await exerciseRepository.getExerciseById(created.id);
      expect(fetched.defaultRestSeconds, 75);
    });
  });
}
