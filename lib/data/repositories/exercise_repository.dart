import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/database_providers.dart';
import '../models/cardio_metric.dart';
import '../models/database_mappers.dart';
import '../models/exercise.dart';
import '../models/exercise_equipment.dart';
import '../models/exercise_muscle_group.dart';
import '../models/exercise_type.dart';
import '../seed/default_exercises.dart';
import 'repository_exceptions.dart';

part 'exercise_repository.g.dart';

/// Legacy single-flag key used by v1 of the seeder. Kept around for the
/// migration path in [ExerciseRepository.seedDefaultsIfNeeded].
const String _legacySeededFlagKey = 'default_exercises_seeded';

/// Comma-separated list of seed UUIDs the app has ever offered to this
/// install. The seeder only inserts seeds whose ids are NOT in this list,
/// so additions to the seed catalogue land on the next boot and removals
/// from the user's local database (delete, rename, etc.) are never
/// "healed" back into existence.
const String _seededExerciseIdsKey = 'seeded_exercise_ids';

/// IDs that shipped in the original v1 seed list. When we encounter an
/// install that has the legacy single flag set but no per-id tracking,
/// we mark these as already-seen so the user keeps any deletions and
/// customisations they made under the old behaviour.
const Set<String> _v1LegacySeedIds = <String>{
  '6f7c82cf-6f43-4e0b-ae08-d9e5f5a2d101', // Bench Press
  '17c4d0e0-6ae7-4e8f-8b5f-6a6c3d6d2102', // Incline Dumbbell Press
  '0f3e8cf0-c3ad-4a46-a8f5-0d0a8d8b3103', // Overhead Press
  'b710d151-5591-4ac6-b13e-f7c1b5b04104', // Pull-Up
  '5b24d3c9-1b61-4ff8-8f5a-77f7a0f65105', // Barbell Row
  '0c3af544-113e-4e52-873a-42790f9b8106', // Lat Pulldown
  'd83a9d2e-2785-4d88-a3a9-e12f1f065107', // Seated Cable Row
  '7fe2f8f4-b5b8-456a-93ff-b8f0b8cf7108', // Squat
  '2fd3b643-905b-4d12-b1e9-2d978bd99109', // Deadlift
  '8dd7fdb2-79a2-482a-a64d-8edab0ce310a', // Romanian Deadlift
  '0f8f1943-7679-4602-b75a-0e8c19a0410b', // Leg Press
  'ff0b2209-c470-46bb-80e8-5171ea6d610c', // Bicep Curl
  'ea79f0f7-a32f-4f8d-a90a-9cd2864d910d', // Tricep Pushdown
  'd2e0ab93-cb1d-4c14-9a9a-a7307d2bb10e', // Plank
  'd5b74e62-cf52-4fdd-b933-278baab5e10f', // Push-Up
  '9a7f6c81-e94d-43ea-8a53-d79ec66d6110', // Sit-Up
  '278738fe-7c99-4761-a6c6-9a09be2a5111', // Treadmill
  'e40fc26a-9c4d-4aa0-9201-c99fb7d9d112', // Stationary Bike
};

@Riverpod(keepAlive: true)
ExerciseRepository exerciseRepository(Ref ref) {
  return ExerciseRepository(
    database: ref.watch(appDatabaseProvider),
    uuid: ref.watch(uuidProvider),
  );
}

class ExerciseRepository {
  ExerciseRepository({required AppDatabase database, required Uuid uuid})
    : _database = database,
      _uuid = uuid;

  final AppDatabase _database;
  final Uuid _uuid;

  /// Adds any default exercises this install hasn't seen yet, without
  /// touching anything the user has already created, renamed, or deleted.
  ///
  /// Mechanism:
  /// 1. Read `seeded_exercise_ids` (comma-separated UUIDs) from settings.
  /// 2. If absent and the legacy `default_exercises_seeded == 'true'` flag
  ///    is set, treat the v1 seed IDs as already-seen — the user's old
  ///    install was already offered them once.
  /// 3. For every entry in [defaultExerciseSeeds] whose id is NOT in the
  ///    seen set, INSERT it (using insertOnConflictDoNothing as cheap
  ///    insurance against orphan rows) and add the id to the seen set.
  /// 4. Persist the updated seen set + clear the legacy flag.
  ///
  /// Existing rows are NEVER updated — a user who renamed "Squat" to
  /// "Back Squat" keeps their rename. A user who deleted "Treadmill"
  /// won't see it reappear.
  Future<void> seedDefaultsIfNeeded() async {
    final DateTime now = _utcNow();

    await _database.transaction(() async {
      final Set<String> seenIds = await _readSeenSeedIds();

      bool changed = false;
      for (final DefaultExerciseSeed seed in defaultExerciseSeeds) {
        if (seenIds.contains(seed.id)) continue;
        await _database
            .into(_database.exercises)
            .insertOnConflictUpdate(
              ExercisesCompanion.insert(
                id: seed.id,
                name: seed.name,
                type: seed.type,
                muscleGroup: Value<ExerciseMuscleGroup>(seed.muscleGroup),
                thumbnailPath: const Value<String?>(null),
                thumbnailBytes: const Value<Uint8List?>(null),
                isDefault: const Value<bool>(true),
                createdAt: now,
                updatedAt: now,
                trackedMetrics: Value<String?>(
                  seed.trackedMetrics?.encode(),
                ),
                equipment: Value<String?>(seed.equipment.name),
                formCue: Value<String?>(seed.formCue),
              ),
            );
        seenIds.add(seed.id);
        changed = true;
      }

      if (changed) {
        await _writeSeenSeedIds(seenIds);
      }
    });
  }

  /// Reads the seen-seed-id set from `app_settings`, applying the v1→v2
  /// migration when only the legacy flag is present.
  Future<Set<String>> _readSeenSeedIds() async {
    final AppSettingRow? row = await (_database.select(_database.appSettings)
          ..where((tbl) => tbl.key.equals(_seededExerciseIdsKey)))
        .getSingleOrNull();
    if (row != null && row.value != null && row.value!.isNotEmpty) {
      final Set<String> ids = <String>{
        for (final String token in row.value!.split(','))
          if (token.trim().isNotEmpty) token.trim(),
      };
      return ids;
    }

    // No new-format key. If the legacy flag is set, the user was already
    // offered the v1 seeds — treat those as seen so we don't re-add any
    // they deleted.
    final AppSettingRow? legacy =
        await (_database.select(_database.appSettings)
              ..where((tbl) => tbl.key.equals(_legacySeededFlagKey)))
            .getSingleOrNull();
    if (legacy?.value == 'true') {
      return Set<String>.from(_v1LegacySeedIds);
    }

    return <String>{};
  }

  Future<void> _writeSeenSeedIds(Set<String> ids) async {
    final String encoded = ids.join(',');
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _seededExerciseIdsKey,
            value: Value<String>(encoded),
          ),
        );
    // Clear the legacy flag now that we've migrated to per-id tracking.
    await (_database.delete(
      _database.appSettings,
    )..where((tbl) => tbl.key.equals(_legacySeededFlagKey))).go();
  }

  Future<List<Exercise>> getAllExercises() async {
    final List<ExerciseRow> rows =
        await (_database.select(_database.exercises)
              ..orderBy(<OrderingTerm Function(Exercises)>[
                (tbl) => OrderingTerm(expression: tbl.name),
              ]))
            .get();
    return rows.map((row) => row.toModel()).toList(growable: false);
  }

  Stream<List<Exercise>> watchAllExercises() {
    final Stream<List<ExerciseRow>> rows =
        (_database.select(_database.exercises)
              ..orderBy(<OrderingTerm Function(Exercises)>[
                (tbl) => OrderingTerm(expression: tbl.name),
              ]))
            .watch();

    return rows.map(
      (items) => items.map((row) => row.toModel()).toList(growable: false),
    );
  }

  Future<List<Exercise>> getExercisesByType(ExerciseType type) async {
    final List<ExerciseRow> rows =
        await (_database.select(_database.exercises)
              ..where((tbl) => tbl.type.equals(type.name))
              ..orderBy(<OrderingTerm Function(Exercises)>[
                (tbl) => OrderingTerm(expression: tbl.name),
              ]))
            .get();
    return rows.map((row) => row.toModel()).toList(growable: false);
  }

  Future<Exercise> getExerciseById(String exerciseId) async {
    final ExerciseRow? row = await (_database.select(
      _database.exercises,
    )..where((tbl) => tbl.id.equals(exerciseId))).getSingleOrNull();

    if (row == null) {
      throw ExerciseNotFoundException(exerciseId);
    }

    return row.toModel();
  }

  Stream<Exercise?> watchExerciseById(String exerciseId) {
    final Stream<ExerciseRow?> rowStream = (_database.select(
      _database.exercises,
    )..where((tbl) => tbl.id.equals(exerciseId))).watchSingleOrNull();

    return rowStream.map((row) => row?.toModel());
  }

  Future<Exercise> createExercise({
    required String name,
    required ExerciseType type,
    required ExerciseMuscleGroup muscleGroup,
    String? thumbnailPath,
    Uint8List? thumbnailBytes,
    bool isDefault = false,
    int? defaultRestSeconds,
    List<CardioMetric>? trackedMetrics,
    ExerciseEquipment? equipment,
    String? formCue,
  }) async {
    final DateTime now = _utcNow();
    final String trimmedName = _validatedName(name);
    _validateRestSeconds(defaultRestSeconds);
    _validateCardioMetrics(type: type, metrics: trackedMetrics);
    final String? trimmedFormCue = _trimmedOrNull(formCue);
    final Exercise exercise = Exercise(
      id: _uuid.v4(),
      name: trimmedName,
      type: type,
      muscleGroup: muscleGroup,
      thumbnailPath: thumbnailPath,
      thumbnailBytes: thumbnailBytes,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
      defaultRestSeconds: defaultRestSeconds,
      trackedMetrics: type == ExerciseType.cardio ? trackedMetrics : null,
      equipment: equipment,
      formCue: trimmedFormCue,
    );

    await _database
        .into(_database.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: exercise.id,
            name: exercise.name,
            type: exercise.type,
            muscleGroup: Value<ExerciseMuscleGroup>(exercise.muscleGroup),
            thumbnailPath: Value<String?>(exercise.thumbnailPath),
            thumbnailBytes: Value<Uint8List?>(exercise.thumbnailBytes),
            isDefault: Value<bool>(exercise.isDefault),
            createdAt: exercise.createdAt,
            updatedAt: exercise.updatedAt,
            defaultRestSeconds: Value<int?>(exercise.defaultRestSeconds),
            trackedMetrics: Value<String?>(
              exercise.trackedMetrics?.encode(),
            ),
            equipment: Value<String?>(exercise.equipment?.name),
            formCue: Value<String?>(exercise.formCue),
          ),
        );

    return exercise;
  }

  Future<Exercise> updateExercise(Exercise exercise) async {
    await getExerciseById(exercise.id);
    _validateRestSeconds(exercise.defaultRestSeconds);
    _validateCardioMetrics(
      type: exercise.type,
      metrics: exercise.trackedMetrics,
    );

    final Exercise updatedExercise = exercise.copyWith(
      name: _validatedName(exercise.name),
      formCue: _trimmedOrNull(exercise.formCue),
      clearFormCue: _trimmedOrNull(exercise.formCue) == null,
      updatedAt: _utcNow(),
    );

    await (_database.update(
      _database.exercises,
    )..where((tbl) => tbl.id.equals(updatedExercise.id))).write(
      ExercisesCompanion(
        name: Value<String>(updatedExercise.name.trim()),
        type: Value<ExerciseType>(updatedExercise.type),
        muscleGroup: Value<ExerciseMuscleGroup>(updatedExercise.muscleGroup),
        thumbnailPath: Value<String?>(updatedExercise.thumbnailPath),
        thumbnailBytes: Value<Uint8List?>(updatedExercise.thumbnailBytes),
        isDefault: Value<bool>(updatedExercise.isDefault),
        updatedAt: Value<DateTime>(updatedExercise.updatedAt),
        defaultRestSeconds: Value<int?>(updatedExercise.defaultRestSeconds),
        // For non-cardio types, the column is forced null so a user
        // converting cardio→weighted doesn't leave stale metrics behind.
        trackedMetrics: Value<String?>(
          updatedExercise.type == ExerciseType.cardio
              ? updatedExercise.trackedMetrics?.encode()
              : null,
        ),
        equipment: Value<String?>(updatedExercise.equipment?.name),
        formCue: Value<String?>(updatedExercise.formCue),
      ),
    );

    return updatedExercise;
  }

  /// Updates only the rest-timer override for an exercise. `null` clears
  /// the override (resolution falls back to the user-level default or
  /// per-type default). `0` explicitly disables the timer for this
  /// exercise even when the user has set a global default.
  Future<Exercise> updateExerciseRestSeconds({
    required String exerciseId,
    required int? restSeconds,
  }) async {
    _validateRestSeconds(restSeconds);
    final Exercise existing = await getExerciseById(exerciseId);
    final DateTime now = _utcNow();
    await (_database.update(
      _database.exercises,
    )..where((tbl) => tbl.id.equals(exerciseId))).write(
      ExercisesCompanion(
        defaultRestSeconds: Value<int?>(restSeconds),
        updatedAt: Value<DateTime>(now),
      ),
    );
    return existing.copyWith(
      defaultRestSeconds: restSeconds,
      clearDefaultRestSeconds: restSeconds == null,
      updatedAt: now,
    );
  }

  Future<void> deleteExercise(String exerciseId) async {
    await getExerciseById(exerciseId);

    final int templateReferences =
        await (_database.selectOnly(_database.templateExercises)
              ..addColumns(<Expression<Object>>[
                _database.templateExercises.id.count(),
              ])
              ..where(
                _database.templateExercises.exerciseId.equals(exerciseId),
              ))
            .map((row) => row.read(_database.templateExercises.id.count()) ?? 0)
            .getSingle();

    final int workoutReferences =
        await (_database.selectOnly(_database.workoutExercises)
              ..addColumns(<Expression<Object>>[
                _database.workoutExercises.id.count(),
              ])
              ..where(_database.workoutExercises.exerciseId.equals(exerciseId)))
            .map((row) => row.read(_database.workoutExercises.id.count()) ?? 0)
            .getSingle();

    if (templateReferences > 0 || workoutReferences > 0) {
      throw ExerciseDeleteBlockedException(exerciseId);
    }

    await (_database.delete(
      _database.exercises,
    )..where((tbl) => tbl.id.equals(exerciseId))).go();
  }

  DateTime _utcNow() => DateTime.now().toUtc();

  String _validatedName(String name) {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw InvalidExerciseNameException();
    }
    return trimmedName;
  }

  void _validateRestSeconds(int? restSeconds) {
    if (restSeconds == null) return;
    if (restSeconds < 0 || restSeconds > 3600) {
      throw InvalidExerciseRestException();
    }
  }

  void _validateCardioMetrics({
    required ExerciseType type,
    required List<CardioMetric>? metrics,
  }) {
    if (type != ExerciseType.cardio) return;
    if (metrics == null) return;
    if (metrics.isEmpty) {
      throw InvalidExerciseMetricsException();
    }
  }

  String? _trimmedOrNull(String? value) {
    if (value == null) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
