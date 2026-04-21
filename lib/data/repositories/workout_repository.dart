import 'dart:async';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/database_providers.dart';
import '../models/database_mappers.dart';
import '../models/exercise.dart';
import '../models/exercise_type.dart';
import '../models/workout.dart';
import '../models/workout_detail.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
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

  Future<WorkoutDetail?> getActiveWorkoutDetail() async {
    final Workout? workout = await getActiveWorkout();
    if (workout == null) {
      return null;
    }
    return getWorkoutById(workout.id);
  }

  Stream<WorkoutDetail?> watchActiveWorkoutDetail() {
    late final StreamController<WorkoutDetail?> controller;
    final List<StreamSubscription<Object?>> subscriptions =
        <StreamSubscription<Object?>>[];
    bool closed = false;
    bool loading = false;
    bool queued = false;

    Future<void> emitCurrent() async {
      if (closed) {
        return;
      }
      if (loading) {
        queued = true;
        return;
      }

      loading = true;
      try {
        controller.add(await getActiveWorkoutDetail());
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      } finally {
        loading = false;
      }

      if (queued && !closed) {
        queued = false;
        unawaited(emitCurrent());
      }
    }

    void scheduleEmit() {
      unawaited(emitCurrent());
    }

    controller = StreamController<WorkoutDetail?>.broadcast(
      onListen: () {
        subscriptions.addAll(<StreamSubscription<Object?>>[
          _database.tableUpdates(
            TableUpdateQuery.onTable(_database.workouts),
          ).listen((_) => scheduleEmit()),
          _database.tableUpdates(
            TableUpdateQuery.onTable(_database.workoutExercises),
          ).listen((_) => scheduleEmit()),
          _database.tableUpdates(
            TableUpdateQuery.onTable(_database.sets),
          ).listen((_) => scheduleEmit()),
          _database.tableUpdates(
            TableUpdateQuery.onTable(_database.exercises),
          ).listen((_) => scheduleEmit()),
        ]);
        scheduleEmit();
      },
      onCancel: () async {
        closed = true;
        for (final StreamSubscription<Object?> subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );

    return controller.stream;
  }

  Future<Workout> updateWorkoutNotes({
    required String workoutId,
    required String? notes,
  }) async {
    final WorkoutRow workoutRow = await _requireActiveWorkoutRow(workoutId);
    final Workout updated = workoutRow.toModel().copyWith(
      notes: _trimmed(notes),
    );

    await (_database.update(_database.workouts)
          ..where((tbl) => tbl.id.equals(workoutId)))
        .write(WorkoutsCompanion(notes: Value<String?>(updated.notes)));

    return updated;
  }

  Future<WorkoutExerciseDetail> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
  }) async {
    await _requireActiveWorkoutRow(workoutId);
    final ExerciseRow exerciseRow = await _getExerciseRow(exerciseId);
    final int orderIndex = await _nextWorkoutExerciseOrderIndex(workoutId);
    final String workoutExerciseId = _uuid.v4();

    await _database
        .into(_database.workoutExercises)
        .insert(
          WorkoutExercisesCompanion.insert(
            id: workoutExerciseId,
            workoutId: workoutId,
            exerciseId: exerciseId,
            orderIndex: orderIndex,
          ),
        );

    return WorkoutExerciseDetail(
      workoutExercise: WorkoutExercise(
        id: workoutExerciseId,
        workoutId: workoutId,
        exerciseId: exerciseId,
        orderIndex: orderIndex,
      ),
      exercise: exerciseRow.toModel(),
      sets: const <WorkoutSet>[],
    );
  }

  Future<WorkoutSet> addSetToWorkoutExercise(String workoutExerciseId) async {
    final _WorkoutExerciseContext context = await _getWorkoutExerciseContext(
      workoutExerciseId,
    );
    _ensureWorkoutIsActive(context.workout);
    final int setNumber = await _nextSetNumber(workoutExerciseId);
    final WorkoutSet workoutSet = WorkoutSet(
      id: _uuid.v4(),
      workoutExerciseId: workoutExerciseId,
      setNumber: setNumber,
      completed: false,
    );

    await _database
        .into(_database.sets)
        .insert(
          SetsCompanion.insert(
            id: workoutSet.id,
            workoutExerciseId: workoutSet.workoutExerciseId,
            setNumber: workoutSet.setNumber,
            weightKg: const Value<double?>(null),
            reps: const Value<int?>(null),
            distanceKm: const Value<double?>(null),
            durationSeconds: const Value<int?>(null),
            completed: Value<bool>(workoutSet.completed),
          ),
        );

    return workoutSet;
  }

  Future<WorkoutSet> updateWorkoutSet({
    required String workoutSetId,
    required double? weightKg,
    required int? reps,
    required double? distanceKm,
    required int? durationSeconds,
    required bool completed,
  }) async {
    final WorkoutSetRow setRow = await _getWorkoutSetRow(workoutSetId);
    final _WorkoutExerciseContext context = await _getWorkoutExerciseContext(
      setRow.workoutExerciseId,
    );
    _ensureWorkoutIsActive(context.workout);
    _validateSetValues(
      exerciseType: context.exercise.type,
      weightKg: weightKg,
      reps: reps,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      completed: completed,
    );

    final WorkoutSet updated = setRow.toModel().copyWith(
      weightKg: weightKg,
      reps: reps,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      completed: completed,
      clearWeightKg: weightKg == null,
      clearReps: reps == null,
      clearDistanceKm: distanceKm == null,
      clearDurationSeconds: durationSeconds == null,
    );

    await (_database.update(
      _database.sets,
    )..where((tbl) => tbl.id.equals(workoutSetId))).write(
      SetsCompanion(
        weightKg: Value<double?>(updated.weightKg),
        reps: Value<int?>(updated.reps),
        distanceKm: Value<double?>(updated.distanceKm),
        durationSeconds: Value<int?>(updated.durationSeconds),
        completed: Value<bool>(updated.completed),
      ),
    );

    return updated;
  }

  Future<Workout> endWorkout(String workoutId, {DateTime? endedAt}) async {
    final Workout existing = (await getWorkoutById(workoutId)).workout;
    _ensureWorkoutIsActive(existing);
    final Workout updated = existing.copyWith(endedAt: endedAt ?? _utcNow());

    await (_database.update(_database.workouts)
          ..where((tbl) => tbl.id.equals(workoutId)))
        .write(WorkoutsCompanion(endedAt: Value<DateTime?>(updated.endedAt)));

    return updated;
  }

  Future<void> cancelWorkout(String workoutId) async {
    final WorkoutRow workoutRow = await _getWorkoutRow(workoutId);
    _ensureWorkoutIsActive(workoutRow.toModel());
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

    return _buildWorkoutDetail(workoutRow);
  }

  Future<WorkoutDetail> _buildWorkoutDetail(WorkoutRow workoutRow) async {
    final List<WorkoutExerciseRow> workoutExerciseRows =
        await _loadWorkoutExerciseRows(workoutRow.id);
    final Map<String, ExerciseRow> exerciseMap = await _loadExerciseMap(
      workoutExerciseRows.map((row) => row.exerciseId).toList(growable: false),
    );
    final Map<String, List<WorkoutSet>> setsByWorkoutExerciseId =
        await _loadWorkoutSetsByWorkoutExercise(
          workoutExerciseRows.map((row) => row.id).toList(growable: false),
        );

    final List<WorkoutExerciseDetail> exercises = workoutExerciseRows.map((row) {
      return WorkoutExerciseDetail(
        workoutExercise: row.toModel(),
        exercise: exerciseMap[row.exerciseId]!.toModel(),
        sets: setsByWorkoutExerciseId[row.id] ?? const <WorkoutSet>[],
      );
    }).toList(growable: false);

    return WorkoutDetail(workout: workoutRow.toModel(), exercises: exercises);
  }

  Future<List<WorkoutExerciseRow>> _loadWorkoutExerciseRows(
    String workoutId,
  ) async {
    return (_database.select(_database.workoutExercises)
          ..where((tbl) => tbl.workoutId.equals(workoutId))
          ..orderBy(<OrderingTerm Function(WorkoutExercises)>[
            (tbl) => OrderingTerm(expression: tbl.orderIndex),
          ]))
        .get();
  }

  Future<Map<String, List<WorkoutSet>>> _loadWorkoutSetsByWorkoutExercise(
    List<String> workoutExerciseIds,
  ) async {
    if (workoutExerciseIds.isEmpty) {
      return <String, List<WorkoutSet>>{};
    }

    final List<WorkoutSetRow> setRows = await (_database.select(_database.sets)
          ..where((tbl) => tbl.workoutExerciseId.isIn(workoutExerciseIds))
          ..orderBy(<OrderingTerm Function(Sets)>[
            (tbl) => OrderingTerm(expression: tbl.workoutExerciseId),
            (tbl) => OrderingTerm(expression: tbl.setNumber),
          ]))
        .get();

    final Map<String, List<WorkoutSet>> setsByWorkoutExerciseId =
        <String, List<WorkoutSet>>{};
    for (final WorkoutSetRow row in setRows) {
      setsByWorkoutExerciseId
          .putIfAbsent(row.workoutExerciseId, () => <WorkoutSet>[])
          .add(row.toModel());
    }

    return <String, List<WorkoutSet>>{
      for (final MapEntry<String, List<WorkoutSet>> entry
          in setsByWorkoutExerciseId.entries)
        entry.key: List<WorkoutSet>.unmodifiable(entry.value),
    };
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

  Future<WorkoutRow> _getWorkoutRow(String workoutId) async {
    final WorkoutRow? row = await (_database.select(
      _database.workouts,
    )..where((tbl) => tbl.id.equals(workoutId))).getSingleOrNull();

    if (row == null) {
      throw WorkoutNotFoundException(workoutId);
    }

    return row;
  }

  Future<WorkoutRow> _requireActiveWorkoutRow(String workoutId) async {
    final WorkoutRow row = await _getWorkoutRow(workoutId);
    _ensureWorkoutIsActive(row.toModel());
    return row;
  }

  Future<ExerciseRow> _getExerciseRow(String exerciseId) async {
    final ExerciseRow? row = await (_database.select(
      _database.exercises,
    )..where((tbl) => tbl.id.equals(exerciseId))).getSingleOrNull();

    if (row == null) {
      throw ExerciseNotFoundException(exerciseId);
    }

    return row;
  }

  Future<WorkoutSetRow> _getWorkoutSetRow(String workoutSetId) async {
    final WorkoutSetRow? row = await (_database.select(
      _database.sets,
    )..where((tbl) => tbl.id.equals(workoutSetId))).getSingleOrNull();

    if (row == null) {
      throw WorkoutSetNotFoundException(workoutSetId);
    }

    return row;
  }

  Future<_WorkoutExerciseContext> _getWorkoutExerciseContext(
    String workoutExerciseId,
  ) async {
    final WorkoutExerciseRow? workoutExerciseRow = await (_database.select(
      _database.workoutExercises,
    )..where((tbl) => tbl.id.equals(workoutExerciseId))).getSingleOrNull();

    if (workoutExerciseRow == null) {
      throw WorkoutExerciseNotFoundException(workoutExerciseId);
    }

    final WorkoutRow workoutRow = await _getWorkoutRow(
      workoutExerciseRow.workoutId,
    );
    final ExerciseRow exerciseRow = await _getExerciseRow(
      workoutExerciseRow.exerciseId,
    );

    return _WorkoutExerciseContext(
      workoutExercise: workoutExerciseRow,
      workout: workoutRow.toModel(),
      exercise: exerciseRow.toModel(),
    );
  }

  Future<int> _nextWorkoutExerciseOrderIndex(String workoutId) async {
    final int? currentMax =
        await (_database.selectOnly(_database.workoutExercises)
              ..addColumns(<Expression<Object>>[
                _database.workoutExercises.orderIndex.max(),
              ])
              ..where(_database.workoutExercises.workoutId.equals(workoutId)))
            .map((row) => row.read(_database.workoutExercises.orderIndex.max()))
            .getSingle();

    return (currentMax ?? -1) + 1;
  }

  Future<int> _nextSetNumber(String workoutExerciseId) async {
    final int? currentMax =
        await (_database.selectOnly(_database.sets)
              ..addColumns(<Expression<Object>>[_database.sets.setNumber.max()])
              ..where(
                _database.sets.workoutExerciseId.equals(workoutExerciseId),
              ))
            .map((row) => row.read(_database.sets.setNumber.max()))
            .getSingle();

    return (currentMax ?? 0) + 1;
  }

  void _ensureWorkoutIsActive(Workout workout) {
    if (!workout.isActive) {
      throw WorkoutNotActiveException(workout.id);
    }
  }

  void _validateSetValues({
    required ExerciseType exerciseType,
    required double? weightKg,
    required int? reps,
    required double? distanceKm,
    required int? durationSeconds,
    required bool completed,
  }) {
    if (weightKg != null && weightKg < 0) {
      throw InvalidWorkoutSetException('Weight must be 0 or higher.');
    }
    if (reps != null && reps <= 0) {
      throw InvalidWorkoutSetException('Reps must be greater than 0.');
    }
    if (distanceKm != null && distanceKm < 0) {
      throw InvalidWorkoutSetException('Distance must be 0 or higher.');
    }
    if (durationSeconds != null && durationSeconds <= 0) {
      throw InvalidWorkoutSetException('Duration must be greater than 0.');
    }

    switch (exerciseType) {
      case ExerciseType.weighted:
        if (distanceKm != null || durationSeconds != null) {
          throw InvalidWorkoutSetException(
            'Weighted exercises only support kg and reps.',
          );
        }
        if (completed && (weightKg == null || reps == null)) {
          throw InvalidWorkoutSetException(
            'Completed weighted sets require kg and reps.',
          );
        }
        return;
      case ExerciseType.bodyweight:
        if (weightKg != null || distanceKm != null || durationSeconds != null) {
          throw InvalidWorkoutSetException(
            'Bodyweight exercises only support reps.',
          );
        }
        if (completed && reps == null) {
          throw InvalidWorkoutSetException(
            'Completed bodyweight sets require reps.',
          );
        }
        return;
      case ExerciseType.cardio:
        if (weightKg != null || reps != null) {
          throw InvalidWorkoutSetException(
            'Cardio exercises only support distance and time.',
          );
        }
        if (completed && (distanceKm == null || durationSeconds == null)) {
          throw InvalidWorkoutSetException(
            'Completed cardio sets require distance and time.',
          );
        }
        return;
    }
  }

  String? _trimmed(String? value) {
    final String? trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  DateTime _utcNow() => DateTime.now().toUtc();
}

class _WorkoutExerciseContext {
  const _WorkoutExerciseContext({
    required this.workoutExercise,
    required this.workout,
    required this.exercise,
  });

  final WorkoutExerciseRow workoutExercise;
  final Workout workout;
  final Exercise exercise;
}
