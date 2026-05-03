import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/database_providers.dart';
import '../models/database_mappers.dart';
import '../models/exercise.dart';
import '../models/exercise_muscle_group.dart';
import '../models/exercise_type.dart';
import '../seed/default_exercises.dart';
import 'repository_exceptions.dart';

part 'exercise_repository.g.dart';

const String _defaultExercisesSeededKey = 'default_exercises_seeded';

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

  Future<void> seedDefaultsIfNeeded() async {
    final AppSettingRow? seededSetting =
        await (_database.select(_database.appSettings)
              ..where((tbl) => tbl.key.equals(_defaultExercisesSeededKey)))
            .getSingleOrNull();

    if (seededSetting?.value == 'true') {
      return;
    }

    final DateTime now = _utcNow();

    await _database.transaction(() async {
      for (final DefaultExerciseSeed seed in defaultExerciseSeeds) {
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
              ),
            );
      }

      await _database
          .into(_database.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              key: _defaultExercisesSeededKey,
              value: const Value<String>('true'),
            ),
          );
    });
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
  }) async {
    final DateTime now = _utcNow();
    final String trimmedName = _validatedName(name);
    _validateRestSeconds(defaultRestSeconds);
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
          ),
        );

    return exercise;
  }

  Future<Exercise> updateExercise(Exercise exercise) async {
    await getExerciseById(exercise.id);
    _validateRestSeconds(exercise.defaultRestSeconds);

    final Exercise updatedExercise = exercise.copyWith(
      name: _validatedName(exercise.name),
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
}
