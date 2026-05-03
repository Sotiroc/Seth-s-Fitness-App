import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessapp/data/db/app_database.dart';
import 'package:fitnessapp/data/models/exercise_muscle_group.dart';
import 'package:fitnessapp/data/models/gender.dart';
import 'package:fitnessapp/data/models/unit_system.dart';
import 'package:fitnessapp/data/models/user_profile.dart';
import 'package:fitnessapp/data/repositories/user_profile_repository.dart';

void main() {
  late AppDatabase database;
  late UserProfileRepository repo;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repo = UserProfileRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  group('UserProfileRepository.updateWeightFromLog', () {
    test('creates the profile row on demand when none exists', () async {
      expect(await repo.getProfile(), isNull);

      final UserProfile saved = await repo.updateWeightFromLog(78.0);

      expect(saved.weightKg, 78.0);
      // Verify the row actually persisted.
      final UserProfile? reread = await repo.getProfile();
      expect(reread, isNotNull);
      expect(reread!.weightKg, 78.0);
    });

    test('preserves every other field on an existing profile', () async {
      // Seed a profile with a wide spread of fields filled in.
      await repo.upsertProfile(
        name: 'Sam',
        ageYears: 30,
        gender: Gender.male,
        heightCm: 175,
        weightKg: 80,
        goalWeightKg: 75,
        bodyFatPercent: 18,
        diabetic: false,
        muscleGroupPriority: ExerciseMuscleGroup.back,
        unitSystem: UnitSystem.imperial,
      );

      final UserProfile updated = await repo.updateWeightFromLog(77.5);

      expect(updated.weightKg, 77.5);
      expect(updated.name, 'Sam');
      expect(updated.ageYears, 30);
      expect(updated.gender, Gender.male);
      expect(updated.heightCm, 175);
      expect(updated.goalWeightKg, 75);
      expect(updated.bodyFatPercent, 18);
      expect(updated.diabetic, false);
      expect(updated.muscleGroupPriority, ExerciseMuscleGroup.back);
      expect(updated.unitSystem, UnitSystem.imperial);
    });

    test('preserves muscleGoals when updating weight', () async {
      const Map<ExerciseMuscleGroup, int> goals = <ExerciseMuscleGroup, int>{
        ExerciseMuscleGroup.chest: 12,
        ExerciseMuscleGroup.back: 14,
      };
      await repo.updateMuscleGoals(goals);

      await repo.updateWeightFromLog(72.0);

      final UserProfile? after = await repo.getProfile();
      expect(after, isNotNull);
      expect(after!.muscleGoals, goals);
      expect(after.weightKg, 72.0);
    });

    test('no-ops when the value already matches stored weight', () async {
      await repo.upsertProfile(name: 'Sam', weightKg: 78.0);
      final UserProfile beforeUpdate = (await repo.getProfile())!;
      final DateTime updatedAtBefore = beforeUpdate.updatedAt;

      // The wait crosses a second boundary because Drift's default
      // `dateTime()` serializer stores Unix seconds — a real write would
      // produce a strictly later updatedAt.
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      final UserProfile result = await repo.updateWeightFromLog(78.0);

      // The returned profile is the existing row (no write happened).
      expect(result.weightKg, 78.0);
      expect(result.updatedAt, updatedAtBefore);

      // And the persisted row is byte-equal on the timestamp.
      final UserProfile reread = (await repo.getProfile())!;
      expect(reread.updatedAt, updatedAtBefore);
    });

    test('bumps updatedAt when weight actually changes', () async {
      await repo.upsertProfile(name: 'Sam', weightKg: 78.0);
      final DateTime updatedAtBefore = (await repo.getProfile())!.updatedAt;

      // Cross a second boundary so the post-update timestamp is strictly
      // later than the pre-update one (Drift stores at second precision).
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      await repo.updateWeightFromLog(77.0);

      final DateTime updatedAtAfter = (await repo.getProfile())!.updatedAt;
      expect(updatedAtAfter.isAfter(updatedAtBefore), isTrue);
    });
  });
}
