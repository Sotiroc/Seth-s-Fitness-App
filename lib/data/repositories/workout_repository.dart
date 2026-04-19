import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/database_providers.dart';
import '../models/database_mappers.dart';
import '../models/workout.dart';
import '../models/workout_detail.dart';
import 'repository_exceptions.dart';

part 'workout_repository.g.dart';

@Riverpod(keepAlive: true)
WorkoutRepository workoutRepository(Ref ref) {
  return WorkoutRepository(
    database: ref.watch(appDatabaseProvider),
    uuid: ref.watch(uuidProvider),
  );
}

class WorkoutRepository {
  WorkoutRepository({required AppDatabase database, required Uuid uuid})
    : _database = database,
      _uuid = uuid;

  final AppDatabase _database;
  final Uuid _uuid;

  Future<Workout> startWorkout({String? templateId, String? notes}) async {
    final WorkoutRow? activeRow = await (_database.select(
      _database.workouts,
    )..where((tbl) => tbl.endedAt.isNull())).getSingleOrNull();

    if (activeRow != null) {
      throw ActiveWorkoutAlreadyExistsException(activeRow.id);
    }

    final Workout workout = Workout(
      id: _uuid.v4(),
      startedAt: _utcNow(),
      templateId: templateId,
      notes: notes,
    );

    await _database
        .into(_database.workouts)
        .insert(
          WorkoutsCompanion.insert(
            id: workout.id,
            startedAt: workout.startedAt,
            endedAt: const Value<DateTime?>(null),
            templateId: Value<String?>(workout.templateId),
            notes: Value<String?>(workout.notes),
          ),
        );

    return workout;
  }

  Future<Workout?> getActiveWorkout() async {
    final WorkoutRow? row = await (_database.select(
      _database.workouts,
    )..where((tbl) => tbl.endedAt.isNull())).getSingleOrNull();
    return row?.toModel();
  }

  Future<Workout> endWorkout(String workoutId, {DateTime? endedAt}) async {
    final Workout existing = await getWorkoutById(
      workoutId,
    ).then((detail) => detail.workout);
    final Workout updated = existing.copyWith(endedAt: endedAt ?? _utcNow());

    await (_database.update(_database.workouts)
          ..where((tbl) => tbl.id.equals(workoutId)))
        .write(WorkoutsCompanion(endedAt: Value<DateTime?>(updated.endedAt)));

    return updated;
  }

  Future<void> cancelWorkout(String workoutId) async {
    final int deleted = await (_database.delete(
      _database.workouts,
    )..where((tbl) => tbl.id.equals(workoutId))).go();

    if (deleted == 0) {
      throw WorkoutNotFoundException(workoutId);
    }
  }

  Future<List<Workout>> listHistory() async {
    final List<WorkoutRow> rows =
        await (_database.select(_database.workouts)
              ..where((tbl) => tbl.endedAt.isNotNull())
              ..orderBy(<OrderingTerm Function(Workouts)>[
                (tbl) => OrderingTerm(
                  expression: tbl.endedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    return rows.map((row) => row.toModel()).toList(growable: false);
  }

  Future<List<Workout>> listAllWorkouts() async {
    final List<WorkoutRow> rows =
        await (_database.select(_database.workouts)
              ..orderBy(<OrderingTerm Function(Workouts)>[
                (tbl) => OrderingTerm(
                  expression: tbl.startedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    return rows.map((row) => row.toModel()).toList(growable: false);
  }

  Future<WorkoutDetail> getWorkoutById(String workoutId) async {
    final WorkoutRow? workoutRow = await (_database.select(
      _database.workouts,
    )..where((tbl) => tbl.id.equals(workoutId))).getSingleOrNull();

    if (workoutRow == null) {
      throw WorkoutNotFoundException(workoutId);
    }

    final List<WorkoutExerciseRow> workoutExerciseRows =
        await (_database.select(_database.workoutExercises)
              ..where((tbl) => tbl.workoutId.equals(workoutId))
              ..orderBy(<OrderingTerm Function(WorkoutExercises)>[
                (tbl) => OrderingTerm(expression: tbl.orderIndex),
              ]))
            .get();

    final List<String> exerciseIds = workoutExerciseRows
        .map((row) => row.exerciseId)
        .toList(growable: false);
    final Map<String, ExerciseRow> exerciseMap = await _loadExerciseMap(
      exerciseIds,
    );

    final List<WorkoutExerciseDetail> exercises = <WorkoutExerciseDetail>[];
    for (final WorkoutExerciseRow workoutExerciseRow in workoutExerciseRows) {
      final List<WorkoutSetRow> setRows =
          await (_database.select(_database.sets)
                ..where(
                  (tbl) => tbl.workoutExerciseId.equals(workoutExerciseRow.id),
                )
                ..orderBy(<OrderingTerm Function(Sets)>[
                  (tbl) => OrderingTerm(expression: tbl.setNumber),
                ]))
              .get();

      exercises.add(
        WorkoutExerciseDetail(
          workoutExercise: workoutExerciseRow.toModel(),
          exercise: exerciseMap[workoutExerciseRow.exerciseId]!.toModel(),
          sets: setRows.map((row) => row.toModel()).toList(growable: false),
        ),
      );
    }

    return WorkoutDetail(workout: workoutRow.toModel(), exercises: exercises);
  }

  Future<Map<String, ExerciseRow>> _loadExerciseMap(List<String> ids) async {
    if (ids.isEmpty) {
      return <String, ExerciseRow>{};
    }

    final List<ExerciseRow> rows = await (_database.select(
      _database.exercises,
    )..where((tbl) => tbl.id.isIn(ids))).get();
    return <String, ExerciseRow>{
      for (final ExerciseRow row in rows) row.id: row,
    };
  }

  DateTime _utcNow() => DateTime.now().toUtc();
}
