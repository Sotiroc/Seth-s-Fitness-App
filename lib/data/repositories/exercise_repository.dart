import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/database_providers.dart';
import '../models/database_mappers.dart';
import '../models/exercise.dart';
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
                thumbnailPath: const Value<String?>(null),
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
    String? thumbnailPath,
    bool isDefault = false,
  }) async {
    final DateTime now = _utcNow();
    final String trimmedName = _validatedName(name);
    final Exercise exercise = Exercise(
      id: _uuid.v4(),
      name: trimmedName,
      type: type,
      thumbnailPath: thumbnailPath,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );

    await _database
        .into(_database.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: exercise.id,
            name: exercise.name,
            type: exercise.type,
            thumbnailPath: Value<String?>(exercise.thumbnailPath),
            isDefault: Value<bool>(exercise.isDefault),
            createdAt: exercise.createdAt,
            updatedAt: exercise.updatedAt,
          ),
        );

    return exercise;
  }

  Future<Exercise> updateExercise(Exercise exercise) async {
    await getExerciseById(exercise.id);

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
        thumbnailPath: Value<String?>(updatedExercise.thumbnailPath),
        isDefault: Value<bool>(updatedExercise.isDefault),
        updatedAt: Value<DateTime>(updatedExercise.updatedAt),
      ),
    );

    return updatedExercise;
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
}
