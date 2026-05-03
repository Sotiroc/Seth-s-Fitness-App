import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../db/app_database.dart';
import '../db/database_providers.dart';
import '../models/database_mappers.dart';
import '../models/exercise_muscle_group.dart';
import '../models/gender.dart';
import '../models/unit_system.dart';
import '../models/user_profile.dart';

part 'user_profile_repository.g.dart';

@Riverpod(keepAlive: true)
UserProfileRepository userProfileRepository(Ref ref) {
  return UserProfileRepository(database: ref.watch(appDatabaseProvider));
}

class UserProfileRepository {
  UserProfileRepository({required AppDatabase database}) : _database = database;

  static const String _profileId = 'me';

  final AppDatabase _database;

  Future<UserProfile?> getProfile() async {
    final UserProfileRow? row = await (_database.select(
      _database.userProfiles,
    )..where((tbl) => tbl.id.equals(_profileId))).getSingleOrNull();
    return row?.toModel();
  }

  Stream<UserProfile?> watchProfile() {
    return (_database.select(_database.userProfiles)
          ..where((tbl) => tbl.id.equals(_profileId)))
        .watchSingleOrNull()
        .map((UserProfileRow? row) => row?.toModel());
  }

  Future<UserProfile> upsertProfile({
    String? name,
    int? ageYears,
    Gender? gender,
    double? heightCm,
    double? weightKg,
    double? goalWeightKg,
    double? bodyFatPercent,
    bool? diabetic,
    ExerciseMuscleGroup? muscleGroupPriority,
    UnitSystem unitSystem = UnitSystem.metric,
  }) async {
    final DateTime now = _utcNow();
    final UserProfile? existing = await getProfile();

    final String? trimmedName = _normalizeName(name);

    await _database
        .into(_database.userProfiles)
        .insertOnConflictUpdate(
          UserProfilesCompanion.insert(
            id: const Value<String>(_profileId),
            name: Value<String?>(trimmedName),
            ageYears: Value<int?>(ageYears),
            gender: Value<Gender?>(gender),
            heightCm: Value<double?>(heightCm),
            weightKg: Value<double?>(weightKg),
            goalWeightKg: Value<double?>(goalWeightKg),
            bodyFatPercent: Value<double?>(bodyFatPercent),
            diabetic: Value<bool?>(diabetic),
            muscleGroupPriority: Value<ExerciseMuscleGroup?>(
              muscleGroupPriority,
            ),
            // Preserve any existing muscle goals — this method doesn't touch
            // them. Use `updateMuscleGoals` to change them.
            muscleGoalsJson: Value<String?>(
              encodeMuscleGoalsJson(existing?.muscleGoals),
            ),
            unitSystem: Value<UnitSystem>(unitSystem),
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );

    final UserProfile? saved = await getProfile();
    if (saved == null) {
      throw StateError('UserProfile upsert returned no row.');
    }
    return saved;
  }

  /// Update only the user's unit system, preserving every other field.
  /// Creates the profile row if it doesn't exist yet so the toggle works
  /// even before the user has filled in their profile.
  Future<UserProfile> updateUnitSystem(UnitSystem unitSystem) async {
    final DateTime now = _utcNow();
    final UserProfile? existing = await getProfile();

    await _database
        .into(_database.userProfiles)
        .insertOnConflictUpdate(
          UserProfilesCompanion.insert(
            id: const Value<String>(_profileId),
            name: Value<String?>(existing?.name),
            ageYears: Value<int?>(existing?.ageYears),
            gender: Value<Gender?>(existing?.gender),
            heightCm: Value<double?>(existing?.heightCm),
            weightKg: Value<double?>(existing?.weightKg),
            goalWeightKg: Value<double?>(existing?.goalWeightKg),
            bodyFatPercent: Value<double?>(existing?.bodyFatPercent),
            diabetic: Value<bool?>(existing?.diabetic),
            muscleGroupPriority: Value<ExerciseMuscleGroup?>(
              existing?.muscleGroupPriority,
            ),
            muscleGoalsJson: Value<String?>(
              encodeMuscleGoalsJson(existing?.muscleGoals),
            ),
            unitSystem: Value<UnitSystem>(unitSystem),
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );

    final UserProfile? saved = await getProfile();
    if (saved == null) {
      throw StateError('UserProfile upsert returned no row.');
    }
    return saved;
  }

  /// Sync `profile.weightKg` to a fresh measurement coming from the weight
  /// log. Used by the reverse-sync path after [WeightEntryRepository.logEntry]
  /// when the new entry is the chronologically latest, so BMI / goal-delta
  /// stay anchored to the user's current body weight.
  ///
  /// No-ops when [weightKg] already matches the stored value to avoid
  /// pointless writes that would refire watchers downstream. Creates the
  /// profile row on demand so this works even before the user has filled
  /// in any other profile fields.
  ///
  /// Returns the post-update [UserProfile]; on no-op returns the existing
  /// profile unchanged.
  Future<UserProfile> updateWeightFromLog(double weightKg) async {
    final DateTime now = _utcNow();
    final UserProfile? existing = await getProfile();

    if (existing != null && existing.weightKg == weightKg) {
      return existing;
    }

    await _database
        .into(_database.userProfiles)
        .insertOnConflictUpdate(
          UserProfilesCompanion.insert(
            id: const Value<String>(_profileId),
            name: Value<String?>(existing?.name),
            ageYears: Value<int?>(existing?.ageYears),
            gender: Value<Gender?>(existing?.gender),
            heightCm: Value<double?>(existing?.heightCm),
            weightKg: Value<double?>(weightKg),
            goalWeightKg: Value<double?>(existing?.goalWeightKg),
            bodyFatPercent: Value<double?>(existing?.bodyFatPercent),
            diabetic: Value<bool?>(existing?.diabetic),
            muscleGroupPriority: Value<ExerciseMuscleGroup?>(
              existing?.muscleGroupPriority,
            ),
            muscleGoalsJson: Value<String?>(
              encodeMuscleGoalsJson(existing?.muscleGoals),
            ),
            unitSystem: Value<UnitSystem>(
              existing?.unitSystem ?? UnitSystem.metric,
            ),
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );

    final UserProfile? saved = await getProfile();
    if (saved == null) {
      throw StateError('UserProfile upsert returned no row.');
    }
    return saved;
  }

  /// Persist the user's per-muscle weekly set goals. Creates the profile
  /// row if it doesn't yet exist (matches the singleton-on-demand pattern
  /// the rest of the profile flow uses).
  Future<UserProfile> updateMuscleGoals(
    Map<ExerciseMuscleGroup, int> goals,
  ) async {
    final DateTime now = _utcNow();
    final UserProfile? existing = await getProfile();

    await _database
        .into(_database.userProfiles)
        .insertOnConflictUpdate(
          UserProfilesCompanion.insert(
            id: const Value<String>(_profileId),
            name: Value<String?>(existing?.name),
            ageYears: Value<int?>(existing?.ageYears),
            gender: Value<Gender?>(existing?.gender),
            heightCm: Value<double?>(existing?.heightCm),
            weightKg: Value<double?>(existing?.weightKg),
            goalWeightKg: Value<double?>(existing?.goalWeightKg),
            bodyFatPercent: Value<double?>(existing?.bodyFatPercent),
            diabetic: Value<bool?>(existing?.diabetic),
            muscleGroupPriority: Value<ExerciseMuscleGroup?>(
              existing?.muscleGroupPriority,
            ),
            muscleGoalsJson: Value<String?>(encodeMuscleGoalsJson(goals)),
            unitSystem: Value<UnitSystem>(
              existing?.unitSystem ?? UnitSystem.metric,
            ),
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );

    final UserProfile? saved = await getProfile();
    if (saved == null) {
      throw StateError('UserProfile upsert returned no row.');
    }
    return saved;
  }

  static String? _normalizeName(String? name) {
    if (name == null) return null;
    final String trimmed = name.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime _utcNow() => DateTime.now().toUtc();
}
