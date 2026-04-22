import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:fitnessapp/data/db/app_database.dart';
import 'package:fitnessapp/data/models/exercise.dart';
import 'package:fitnessapp/data/models/exercise_type.dart';
import 'package:fitnessapp/data/models/template_detail.dart';
import 'package:fitnessapp/data/models/template_exercise.dart';
import 'package:fitnessapp/data/models/workout.dart';
import 'package:fitnessapp/data/models/workout_detail.dart';
import 'package:fitnessapp/data/models/workout_set.dart';
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
      );

      final Exercise updated = await exerciseRepository.updateExercise(
        created.copyWith(
          name: 'Farmer Carry Sled',
          thumbnailPath: '/tmp/sled.png',
        ),
      );

      final Exercise fetched = await exerciseRepository.getExerciseById(
        updated.id,
      );
      final List<Exercise> cardioExercises = await exerciseRepository
          .getExercisesByType(ExerciseType.cardio);

      expect(fetched.name, 'Farmer Carry Sled');
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
        ),
        throwsA(isA<InvalidExerciseNameException>()),
      );
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
}
