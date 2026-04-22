import 'dart:async';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/database_providers.dart';
import '../models/database_mappers.dart';
import '../models/template_detail.dart';
import '../models/template_exercise.dart';
import '../models/workout.dart';
import '../models/workout_template.dart';
import 'repository_exceptions.dart';

part 'template_repository.g.dart';

@Riverpod(keepAlive: true)
TemplateRepository templateRepository(Ref ref) {
  return TemplateRepository(
    database: ref.watch(appDatabaseProvider),
    uuid: ref.watch(uuidProvider),
  );
}

class TemplateRepository {
  TemplateRepository({required AppDatabase database, required Uuid uuid})
    : _database = database,
      _uuid = uuid;

  final AppDatabase _database;
  final Uuid _uuid;

  Future<List<WorkoutTemplate>> getAllTemplates() async {
    final List<WorkoutTemplateRow> rows =
        await (_database.select(_database.workoutTemplates)
              ..orderBy(<OrderingTerm Function(WorkoutTemplates)>[
                (tbl) => OrderingTerm(
                  expression: tbl.updatedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    return rows.map((row) => row.toModel()).toList(growable: false);
  }

  Stream<List<WorkoutTemplate>> watchAllTemplates() {
    final Stream<List<WorkoutTemplateRow>> rows =
        (_database.select(_database.workoutTemplates)
              ..orderBy(<OrderingTerm Function(WorkoutTemplates)>[
                (tbl) => OrderingTerm(
                  expression: tbl.updatedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .watch();

    return rows.map(
      (items) => items.map((row) => row.toModel()).toList(growable: false),
    );
  }

  Future<TemplateDetail> getTemplateById(String templateId) async {
    final WorkoutTemplateRow? templateRow = await (_database.select(
      _database.workoutTemplates,
    )..where((tbl) => tbl.id.equals(templateId))).getSingleOrNull();

    if (templateRow == null) {
      throw WorkoutTemplateNotFoundException(templateId);
    }

    final List<TemplateExerciseRow> exerciseRows =
        await (_database.select(_database.templateExercises)
              ..where((tbl) => tbl.templateId.equals(templateId))
              ..orderBy(<OrderingTerm Function(TemplateExercises)>[
                (tbl) => OrderingTerm(expression: tbl.orderIndex),
              ]))
            .get();

    final List<String> exerciseIds = exerciseRows
        .map((row) => row.exerciseId)
        .toList(growable: false);
    final Map<String, ExerciseRow> exerciseMap = await _loadExerciseMap(
      exerciseIds,
    );

    return TemplateDetail(
      template: templateRow.toModel(),
      exercises: exerciseRows
          .map(
            (row) => TemplateExerciseDetail(
              templateExercise: row.toModel(),
              exercise: exerciseMap[row.exerciseId]!.toModel(),
            ),
          )
          .toList(growable: false),
    );
  }

  Stream<TemplateDetail> watchTemplateById(String templateId) {
    late final StreamController<TemplateDetail> controller;
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
        controller.add(await getTemplateById(templateId));
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

    controller = StreamController<TemplateDetail>.broadcast(
      onListen: () {
        subscriptions.addAll(<StreamSubscription<Object?>>[
          _database
              .tableUpdates(
                TableUpdateQuery.onTable(_database.workoutTemplates),
              )
              .listen((_) => scheduleEmit()),
          _database
              .tableUpdates(
                TableUpdateQuery.onTable(_database.templateExercises),
              )
              .listen((_) => scheduleEmit()),
          _database
              .tableUpdates(TableUpdateQuery.onTable(_database.exercises))
              .listen((_) => scheduleEmit()),
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

  Future<WorkoutTemplate> createTemplate({
    required String name,
    List<TemplateExerciseDraft> exercises = const <TemplateExerciseDraft>[],
  }) async {
    final DateTime now = _utcNow();
    final WorkoutTemplate template = WorkoutTemplate(
      id: _uuid.v4(),
      name: _validatedName(name),
      createdAt: now,
      updatedAt: now,
    );

    await _database.transaction(() async {
      await _database
          .into(_database.workoutTemplates)
          .insert(
            WorkoutTemplatesCompanion.insert(
              id: template.id,
              name: template.name,
              createdAt: template.createdAt,
              updatedAt: template.updatedAt,
            ),
          );

      await _replaceTemplateExercises(template.id, exercises);
    });

    return template;
  }

  Future<WorkoutTemplate> updateTemplate({
    required WorkoutTemplate template,
    required List<TemplateExerciseDraft> exercises,
  }) async {
    await getTemplateById(template.id);
    final WorkoutTemplate updated = template.copyWith(updatedAt: _utcNow());

    await _database.transaction(() async {
      await (_database.update(
        _database.workoutTemplates,
      )..where((tbl) => tbl.id.equals(updated.id))).write(
        WorkoutTemplatesCompanion(
          name: Value<String>(_validatedName(updated.name)),
          updatedAt: Value<DateTime>(updated.updatedAt),
        ),
      );

      await (_database.delete(
        _database.templateExercises,
      )..where((tbl) => tbl.templateId.equals(updated.id))).go();

      await _replaceTemplateExercises(updated.id, exercises);
    });

    return updated;
  }

  Future<void> deleteTemplate(String templateId) async {
    final int deleted = await (_database.delete(
      _database.workoutTemplates,
    )..where((tbl) => tbl.id.equals(templateId))).go();

    if (deleted == 0) {
      throw WorkoutTemplateNotFoundException(templateId);
    }
  }

  Future<Workout> createWorkoutFromTemplate(String templateId) async {
    final TemplateDetail templateDetail = await getTemplateById(templateId);
    final WorkoutRow? activeRow = await (_database.select(
      _database.workouts,
    )..where((tbl) => tbl.endedAt.isNull())).getSingleOrNull();

    if (activeRow != null) {
      throw ActiveWorkoutAlreadyExistsException(activeRow.id);
    }

    final DateTime now = _utcNow();
    final Workout workout = Workout(
      id: _uuid.v4(),
      startedAt: now,
      templateId: templateDetail.template.id,
    );

    await _database.transaction(() async {
      await _database
          .into(_database.workouts)
          .insert(
            WorkoutsCompanion.insert(
              id: workout.id,
              startedAt: workout.startedAt,
              endedAt: const Value<DateTime?>(null),
              templateId: Value<String?>(workout.templateId),
              notes: const Value<String?>(null),
            ),
          );

      for (final TemplateExerciseDetail exerciseDetail
          in templateDetail.exercises) {
        final String workoutExerciseId = _uuid.v4();
        await _database
            .into(_database.workoutExercises)
            .insert(
              WorkoutExercisesCompanion.insert(
                id: workoutExerciseId,
                workoutId: workout.id,
                exerciseId: exerciseDetail.exercise.id,
                orderIndex: exerciseDetail.templateExercise.orderIndex,
              ),
            );

        for (
          int setIndex = 0;
          setIndex < exerciseDetail.templateExercise.defaultSets;
          setIndex++
        ) {
          await _database
              .into(_database.sets)
              .insert(
                SetsCompanion.insert(
                  id: _uuid.v4(),
                  workoutExerciseId: workoutExerciseId,
                  setNumber: setIndex + 1,
                  weightKg: const Value<double?>(null),
                  reps: const Value<int?>(null),
                  distanceKm: const Value<double?>(null),
                  durationSeconds: const Value<int?>(null),
                  completed: const Value<bool>(false),
                ),
              );
        }
      }
    });

    return workout;
  }

  Future<void> _replaceTemplateExercises(
    String templateId,
    List<TemplateExerciseDraft> exercises,
  ) async {
    for (final TemplateExerciseDraft exercise in exercises) {
      await _database
          .into(_database.templateExercises)
          .insert(
            TemplateExercisesCompanion.insert(
              id: _uuid.v4(),
              templateId: templateId,
              exerciseId: exercise.exerciseId,
              orderIndex: exercise.orderIndex,
              defaultSets: exercise.defaultSets,
            ),
          );
    }
  }

  Future<Map<String, ExerciseRow>> _loadExerciseMap(List<String> ids) async {
    if (ids.isEmpty) {
      return <String, ExerciseRow>{};
    }

    final List<ExerciseRow> exercises = await (_database.select(
      _database.exercises,
    )..where((tbl) => tbl.id.isIn(ids))).get();
    return <String, ExerciseRow>{
      for (final ExerciseRow exercise in exercises) exercise.id: exercise,
    };
  }

  DateTime _utcNow() => DateTime.now().toUtc();

  String _validatedName(String name) {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw InvalidWorkoutTemplateNameException();
    }
    return trimmedName;
  }
}
