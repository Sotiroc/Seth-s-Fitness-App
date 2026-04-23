import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:fitnessapp/data/db/app_database.dart';
import 'package:fitnessapp/data/database_bootstrap.dart';
import 'package:fitnessapp/data/db/database_providers.dart';
import 'package:fitnessapp/data/models/exercise.dart';
import 'package:fitnessapp/data/models/exercise_muscle_group.dart';
import 'package:fitnessapp/data/models/exercise_type.dart';
import 'package:fitnessapp/data/repositories/exercise_repository.dart';
import 'package:fitnessapp/data/repositories/repository_exceptions.dart';
import 'package:fitnessapp/features/exercises/application/exercise_editor_controller.dart';
import 'package:fitnessapp/features/exercises/application/exercise_list_provider.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;
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
  });

  tearDown(() async {
    await database.close();
  });

  test('filtered exercises react to query and type filters', () async {
    final Completer<void> seededListReady = Completer<void>();
    final ProviderSubscription<AsyncValue<List<Exercise>>> subscription =
        container.listen(exerciseListProvider, (previous, next) {
          if (next.hasValue && !seededListReady.isCompleted) {
            seededListReady.complete();
          }
        }, fireImmediately: true);
    addTearDown(subscription.close);

    await container.read(databaseBootstrapProvider.future);
    await seededListReady.future.timeout(const Duration(seconds: 5));

    final AsyncValue<List<Exercise>> initial = container.read(
      filteredExercisesProvider,
    );
    expect(initial.requireValue, hasLength(18));

    container.read(exerciseFilterProvider.notifier).setQuery('press');
    final List<String> queryResults = container
        .read(filteredExercisesProvider)
        .requireValue
        .map((exercise) => exercise.name)
        .toList(growable: false);

    expect(queryResults, <String>[
      'Bench Press',
      'Incline Dumbbell Press',
      'Leg Press',
      'Overhead Press',
    ]);

    container.read(exerciseFilterProvider.notifier).setQuery('');
    container
        .read(exerciseFilterProvider.notifier)
        .setType(ExerciseType.bodyweight);
    final List<String> typedResults = container
        .read(filteredExercisesProvider)
        .requireValue
        .map((exercise) => exercise.name)
        .toList(growable: false);

    expect(typedResults, <String>['Plank', 'Pull-Up', 'Push-Up', 'Sit-Up']);
  });

  test('createExercise stores a new exercise through the controller', () async {
    final Exercise created = await container
        .read(exerciseEditorControllerProvider.notifier)
        .createExercise(
          name: 'Cable Fly',
          type: ExerciseType.weighted,
          muscleGroup: ExerciseMuscleGroup.chest,
        );

    final Exercise stored = await container
        .read(exerciseRepositoryProvider)
        .getExerciseById(created.id);

    expect(stored.name, 'Cable Fly');
    expect(stored.type, ExerciseType.weighted);
    expect(stored.muscleGroup, ExerciseMuscleGroup.chest);
    expect(stored.thumbnailPath, isNull);
  });

  test(
    'updateExercise and deleteExercise work through the controller',
    () async {
      final ExerciseRepository repository = container.read(
        exerciseRepositoryProvider,
      );

      final Exercise created = await container
          .read(exerciseEditorControllerProvider.notifier)
          .createExercise(
            name: 'Row Machine',
            type: ExerciseType.cardio,
            muscleGroup: ExerciseMuscleGroup.cardio,
          );

      final Exercise updated = await container
          .read(exerciseEditorControllerProvider.notifier)
          .updateExercise(
            exercise: created,
            name: 'Row Machine Sprint',
            type: ExerciseType.cardio,
            muscleGroup: ExerciseMuscleGroup.back,
          );

      expect(updated.name, 'Row Machine Sprint');
      expect(updated.muscleGroup, ExerciseMuscleGroup.back);
      expect(updated.thumbnailPath, isNull);

      await container
          .read(exerciseEditorControllerProvider.notifier)
          .deleteExercise(updated);

      expect(
        () => repository.getExerciseById(updated.id),
        throwsA(isA<ExerciseNotFoundException>()),
      );
    },
  );
}
