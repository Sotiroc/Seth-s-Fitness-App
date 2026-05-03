import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessapp/data/db/app_database.dart';
import 'package:fitnessapp/data/models/exercise.dart';
import 'package:fitnessapp/data/models/exercise_muscle_group.dart';
import 'package:fitnessapp/data/models/exercise_type.dart';
import 'package:fitnessapp/data/repositories/app_settings_repository.dart';

abstract final class ExerciseFactory {
  static Exercise _make({
    required ExerciseType type,
    required ExerciseMuscleGroup muscleGroup,
    int? defaultRestSeconds,
  }) {
    final DateTime now = DateTime.utc(2026, 1, 1);
    return Exercise(
      id: 'test-${type.name}',
      name: 'Test ${type.name}',
      type: type,
      muscleGroup: muscleGroup,
      isDefault: false,
      createdAt: now,
      updatedAt: now,
      defaultRestSeconds: defaultRestSeconds,
    );
  }

  static Exercise weighted({int? defaultRestSeconds}) => _make(
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.chest,
    defaultRestSeconds: defaultRestSeconds,
  );
  static Exercise bodyweight({int? defaultRestSeconds}) => _make(
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.abs,
    defaultRestSeconds: defaultRestSeconds,
  );
  static Exercise cardio({int? defaultRestSeconds}) => _make(
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    defaultRestSeconds: defaultRestSeconds,
  );
}

void main() {
  late AppDatabase database;
  late AppSettingsRepository repo;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AppSettingsRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  group('AppSettingsRepository.restTimerEnabled', () {
    test('defaults to true when no row exists', () async {
      expect(await repo.getRestTimerEnabled(), isTrue);
    });

    test('round-trips a false value', () async {
      await repo.setRestTimerEnabled(false);
      expect(await repo.getRestTimerEnabled(), isFalse);
      await repo.setRestTimerEnabled(true);
      expect(await repo.getRestTimerEnabled(), isTrue);
    });

    test('watcher emits the current value and reacts to writes', () async {
      final Stream<bool> stream = repo.watchRestTimerEnabled().distinct();
      final List<bool> emissions = <bool>[];
      final sub = stream.listen(emissions.add);
      addTearDown(sub.cancel);

      // Allow the initial query to flush.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.setRestTimerEnabled(false);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.setRestTimerEnabled(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions, contains(true));
      expect(emissions, contains(false));
    });
  });

  group('AppSettingsRepository.defaultRestSeconds', () {
    test('defaults to null when no row exists', () async {
      expect(await repo.getDefaultRestSeconds(), isNull);
    });

    test('round-trips a value and clears via null', () async {
      await repo.setDefaultRestSeconds(90);
      expect(await repo.getDefaultRestSeconds(), 90);
      await repo.setDefaultRestSeconds(0);
      expect(await repo.getDefaultRestSeconds(), 0);
      await repo.setDefaultRestSeconds(null);
      expect(await repo.getDefaultRestSeconds(), isNull);
    });

    test('rejects negative or >3600 values', () async {
      expect(
        () => repo.setDefaultRestSeconds(-1),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repo.setDefaultRestSeconds(3601),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('decodes corrupt values back to null', () async {
      // Direct write past validation to mimic external corruption.
      await repo.setRestTimerEnabled(true); // unrelated; just to seed table
      // ignore: invalid_use_of_visible_for_testing_member
      await database
          .into(database.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              key: 'default_rest_seconds',
              value: const drift.Value<String>('garbage'),
            ),
          );
      expect(await repo.getDefaultRestSeconds(), isNull);
    });
  });

  group('Exercise.resolveRestSeconds', () {
    test('per-exercise override always wins', () {
      final exercise = ExerciseFactory.weighted(defaultRestSeconds: 45);
      expect(exercise.resolveRestSeconds(userDefault: 200), 45);
    });

    test('user default applies when no override', () {
      final exercise = ExerciseFactory.weighted();
      expect(exercise.resolveRestSeconds(userDefault: 75), 75);
    });

    test('falls back to type default when both null', () {
      expect(ExerciseFactory.weighted().resolveRestSeconds(), 120);
      expect(ExerciseFactory.bodyweight().resolveRestSeconds(), 60);
      expect(ExerciseFactory.cardio().resolveRestSeconds(), 0);
    });

    test('per-exercise 0 disables the timer even with a user default', () {
      final exercise = ExerciseFactory.weighted(defaultRestSeconds: 0);
      expect(exercise.resolveRestSeconds(userDefault: 90), 0);
    });

    test('user default 0 disables timer for exercises without override', () {
      final exercise = ExerciseFactory.weighted();
      expect(exercise.resolveRestSeconds(userDefault: 0), 0);
    });
  });
}
