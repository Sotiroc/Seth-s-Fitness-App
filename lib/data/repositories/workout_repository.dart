import 'dart:async';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/strength_formulas.dart';
import '../db/app_database.dart';
import '../db/database_providers.dart';
import '../models/database_mappers.dart';
import '../models/exercise.dart';
import '../models/exercise_history_day.dart';
import '../models/exercise_muscle_group.dart';
import '../models/exercise_type.dart';
import '../models/pr_event.dart';
import '../models/workout.dart';
import '../models/workout_detail.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../models/workout_set_kind.dart';
import '../models/workout_structure.dart';
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
            name: Value<String?>(workout.name),
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
          _database
              .tableUpdates(TableUpdateQuery.onTable(_database.workouts))
              .listen((_) => scheduleEmit()),
          _database
              .tableUpdates(
                TableUpdateQuery.onTable(_database.workoutExercises),
              )
              .listen((_) => scheduleEmit()),
          _database
              .tableUpdates(TableUpdateQuery.onTable(_database.sets))
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

  /// Updates the workout's optional free-text note. Works on both active
  /// and finished workouts because the summary screen — the natural
  /// reflection moment — is the primary input surface, and that screen
  /// only opens after the workout has ended.
  Future<Workout> updateWorkoutNotes({
    required String workoutId,
    required String? notes,
  }) async {
    final WorkoutRow workoutRow = await _getWorkoutRow(workoutId);
    final String? trimmed = _trimmed(notes);
    final Workout updated = workoutRow.toModel().copyWith(
      notes: trimmed,
      clearNotes: trimmed == null,
    );

    await (_database.update(_database.workouts)
          ..where((tbl) => tbl.id.equals(workoutId)))
        .write(WorkoutsCompanion(notes: Value<String?>(updated.notes)));

    return updated;
  }

  /// Updates the workout's user-assigned name. Works for both active and
  /// finished workouts, since naming can happen on the summary screen.
  Future<Workout> updateWorkoutName({
    required String workoutId,
    required String? name,
  }) async {
    final WorkoutRow workoutRow = await _getWorkoutRow(workoutId);
    final String? trimmed = _trimmed(name);
    final Workout updated = workoutRow.toModel().copyWith(
      name: trimmed,
      clearName: trimmed == null,
    );

    await (_database.update(_database.workouts)
          ..where((tbl) => tbl.id.equals(workoutId)))
        .write(WorkoutsCompanion(name: Value<String?>(updated.name)));

    return updated;
  }

  /// Updates the workout's optional 1–10 session intensity score. Works on
  /// both active and finished workouts (input lives on the summary screen).
  /// Out-of-range values are clamped silently to 1..10; null clears the
  /// score.
  Future<Workout> updateWorkoutIntensityScore({
    required String workoutId,
    required int? score,
  }) async {
    final WorkoutRow workoutRow = await _getWorkoutRow(workoutId);
    final int? clamped = score?.clamp(1, 10);
    final Workout updated = workoutRow.toModel().copyWith(
      intensityScore: clamped,
      clearIntensityScore: clamped == null,
    );

    await (_database.update(_database.workouts)
          ..where((tbl) => tbl.id.equals(workoutId)))
        .write(
          WorkoutsCompanion(
            intensityScore: Value<int?>(updated.intensityScore),
          ),
        );

    return updated;
  }

  /// Updates the free-text note attached to a single exercise within a
  /// workout (the per-workout-exercise instance, not the global exercise
  /// definition). Only allowed while the parent workout is active so the
  /// active-workout invariant matches other exercise mutations.
  Future<WorkoutExercise> updateWorkoutExerciseNotes({
    required String workoutExerciseId,
    required String? notes,
  }) async {
    final _WorkoutExerciseContext context = await _getWorkoutExerciseContext(
      workoutExerciseId,
    );
    _ensureWorkoutIsActive(context.workout);

    final String? trimmed = _trimmed(notes);
    await (_database.update(_database.workoutExercises)
          ..where((tbl) => tbl.id.equals(workoutExerciseId)))
        .write(WorkoutExercisesCompanion(notes: Value<String?>(trimmed)));

    return context.workoutExercise.toModel().copyWith(
      notes: trimmed,
      clearNotes: trimmed == null,
    );
  }

  Future<WorkoutExerciseDetail> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
  }) async {
    await _requireActiveWorkoutRow(workoutId);
    final ExerciseRow exerciseRow = await _getExerciseRow(exerciseId);
    final int orderIndex = await _nextWorkoutExerciseOrderIndex(workoutId);
    final String workoutExerciseId = _uuid.v4();
    final DateTime createdAt = _utcNow();

    await _database
        .into(_database.workoutExercises)
        .insert(
          WorkoutExercisesCompanion.insert(
            id: workoutExerciseId,
            workoutId: workoutId,
            exerciseId: exerciseId,
            orderIndex: orderIndex,
            createdAt: Value<DateTime?>(createdAt),
          ),
        );

    return WorkoutExerciseDetail(
      workoutExercise: WorkoutExercise(
        id: workoutExerciseId,
        workoutId: workoutId,
        exerciseId: exerciseId,
        orderIndex: orderIndex,
        createdAt: createdAt,
      ),
      exercise: exerciseRow.toModel(),
      sets: const <WorkoutSet>[],
    );
  }

  Future<WorkoutSet> addSetToWorkoutExercise(
    String workoutExerciseId, {
    WorkoutSetKind kind = WorkoutSetKind.normal,
    String? parentSetId,
  }) async {
    final _WorkoutExerciseContext context = await _getWorkoutExerciseContext(
      workoutExerciseId,
    );
    _ensureWorkoutIsActive(context.workout);
    if (kind == WorkoutSetKind.drop && parentSetId == null) {
      throw InvalidWorkoutSetException(
        'Drop sets must reference a parent set.',
      );
    }
    if (kind != WorkoutSetKind.drop && parentSetId != null) {
      throw InvalidWorkoutSetException(
        'Only drop sets can have a parent set.',
      );
    }
    final int setNumber = await _nextSetNumber(workoutExerciseId);
    final DateTime now = _utcNow();
    final WorkoutSet workoutSet = WorkoutSet(
      id: _uuid.v4(),
      workoutExerciseId: workoutExerciseId,
      setNumber: setNumber,
      completed: false,
      updatedAt: now,
      kind: kind,
      parentSetId: parentSetId,
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
            completedAt: const Value<DateTime?>(null),
            updatedAt: Value<DateTime?>(now),
            // startedAt left null on insert; the first updateWorkoutSet
            // call captures the user's first-edit timestamp.
            startedAt: const Value<DateTime?>(null),
            kind: Value<String>(kind.name),
            parentSetId: Value<String?>(parentSetId),
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

    final DateTime now = _utcNow();
    // completedAt tracks the timestamp of the most recent false→true
    // transition. Re-saving an already-completed set keeps the original
    // timestamp so the auto-close duration anchors to when the user
    // *actually* finished the set, not when they re-tapped Save.
    final bool wasCompleted = setRow.completed;
    final DateTime? newCompletedAt = completed
        ? (wasCompleted ? setRow.completedAt : now)
        : null;
    // startedAt is first-edit-wins: capture once and never move. Combined
    // with completedAt this gives true per-set timing for analytics.
    final DateTime newStartedAt = setRow.startedAt ?? now;

    final WorkoutSet updated = setRow.toModel().copyWith(
      weightKg: weightKg,
      reps: reps,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      completed: completed,
      completedAt: newCompletedAt,
      updatedAt: now,
      startedAt: newStartedAt,
      clearWeightKg: weightKg == null,
      clearReps: reps == null,
      clearDistanceKm: distanceKm == null,
      clearDurationSeconds: durationSeconds == null,
      clearCompletedAt: newCompletedAt == null,
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
        completedAt: Value<DateTime?>(updated.completedAt),
        updatedAt: Value<DateTime?>(updated.updatedAt),
        startedAt: Value<DateTime?>(updated.startedAt),
      ),
    );

    return updated;
  }

  /// Updates the "extras" attached to a set: its [kind] (warm-up / normal /
  /// drop / failure), optional 1–10 [rpe], and free-text [note]. Doesn't
  /// touch weight/reps/completed — those flow through [updateWorkoutSet].
  ///
  /// Switching a set's kind has structural implications:
  /// - changing kind to/from [WorkoutSetKind.drop] flips parent linkage:
  ///   - drop → other: clears [parentSetId]
  ///   - other → drop: requires [parentSetId] to be passed in [parentSetId]
  /// - changing kind from [WorkoutSetKind.drop] to anything else, when
  ///   the row had children (other drops chained off it), leaves those
  ///   children orphaned — but the previous parent had no link of its
  ///   own to give up, so this is a no-op cleanup-wise. We do, however,
  ///   re-parent any direct children of *this* set when it becomes a
  ///   non-parent (e.g. user demotes a parent working set to a warm-up):
  ///   children are re-pointed at this set's previous parent (or detached
  ///   if there isn't one). Keeps the chain intact instead of dangling.
  Future<WorkoutSet> updateWorkoutSetExtras({
    required String workoutSetId,
    required WorkoutSetKind kind,
    int? rpe,
    String? note,
    String? parentSetId,
    bool clearParentSetId = false,
  }) async {
    final WorkoutSetRow setRow = await _getWorkoutSetRow(workoutSetId);
    final _WorkoutExerciseContext context = await _getWorkoutExerciseContext(
      setRow.workoutExerciseId,
    );
    _ensureWorkoutIsActive(context.workout);

    final int? clampedRpe = rpe?.clamp(1, 10);
    final String? trimmedNote = _trimmed(note);

    String? nextParentSetId;
    if (kind == WorkoutSetKind.drop) {
      // When promoting to drop, caller must supply a parent (or the row
      // already had one we keep).
      nextParentSetId = parentSetId ?? setRow.parentSetId;
      if (nextParentSetId == null) {
        throw InvalidWorkoutSetException(
          'A drop set must reference a parent set.',
        );
      }
    } else {
      // Non-drop kinds never carry a parent reference.
      nextParentSetId = null;
    }
    // `clearParentSetId` is honoured for drop kinds only when caller
    // explicitly asks for it; for non-drop kinds the parent is always
    // cleared regardless.
    if (clearParentSetId && kind == WorkoutSetKind.drop) {
      throw InvalidWorkoutSetException(
        'Cannot clear parent on a drop set.',
      );
    }

    await _database.transaction(() async {
      // If this set is changing away from being a parent (i.e., not a
      // working set anymore), re-parent its direct drop children to its
      // own parent so the chain doesn't dangle.
      final bool wasWorkingSet =
          WorkoutSetKind.fromName(setRow.kind).countsAsWorkingSet &&
          setRow.kind != WorkoutSetKind.drop.name;
      final bool willStillBeWorkingSet =
          kind.countsAsWorkingSet && kind != WorkoutSetKind.drop;
      if (wasWorkingSet && !willStillBeWorkingSet) {
        await (_database.update(_database.sets)
              ..where((tbl) => tbl.parentSetId.equals(workoutSetId)))
            .write(
              SetsCompanion(
                parentSetId: Value<String?>(setRow.parentSetId),
              ),
            );
      }

      await (_database.update(_database.sets)
            ..where((tbl) => tbl.id.equals(workoutSetId)))
          .write(
            SetsCompanion(
              kind: Value<String>(kind.name),
              parentSetId: Value<String?>(nextParentSetId),
              rpe: Value<int?>(clampedRpe),
              note: Value<String?>(trimmedNote),
              updatedAt: Value<DateTime?>(_utcNow()),
            ),
          );
    });

    return setRow.toModel().copyWith(
      kind: kind,
      parentSetId: nextParentSetId,
      clearParentSetId: nextParentSetId == null,
      rpe: clampedRpe,
      clearRpe: clampedRpe == null,
      note: trimmedNote,
      clearNote: trimmedNote == null,
      updatedAt: _utcNow(),
    );
  }

  /// Removes a workout_exercise (and its sets, via cascade) from the workout
  /// and renumbers the remaining exercises so [WorkoutExercise.orderIndex]
  /// stays contiguous (0, 1, 2...). Only allowed while the workout is active.
  Future<void> removeExerciseFromWorkout(String workoutExerciseId) async {
    final _WorkoutExerciseContext context = await _getWorkoutExerciseContext(
      workoutExerciseId,
    );
    _ensureWorkoutIsActive(context.workout);
    final WorkoutExerciseRow target = context.workoutExercise;

    await _database.transaction(() async {
      await (_database.delete(
        _database.workoutExercises,
      )..where((tbl) => tbl.id.equals(workoutExerciseId))).go();

      final List<WorkoutExerciseRow> following =
          await (_database.select(_database.workoutExercises)
                ..where(
                  (tbl) =>
                      tbl.workoutId.equals(target.workoutId) &
                      tbl.orderIndex.isBiggerThanValue(target.orderIndex),
                )
                ..orderBy(<OrderingTerm Function(WorkoutExercises)>[
                  (tbl) => OrderingTerm(expression: tbl.orderIndex),
                ]))
              .get();

      for (final WorkoutExerciseRow row in following) {
        await (_database.update(_database.workoutExercises)
              ..where((tbl) => tbl.id.equals(row.id)))
            .write(
              WorkoutExercisesCompanion(
                orderIndex: Value<int>(row.orderIndex - 1),
              ),
            );
      }
    });
  }

  /// Deletes a single set and renumbers the remaining sets for that exercise
  /// so setNumber stays contiguous (1, 2, 3...). Only allowed while the
  /// workout is active.
  ///
  /// If the deleted set is a parent of any drop sets, those children are
  /// re-pointed at the deleted set's own parent (or detached entirely if
  /// it had none) so the chain doesn't dangle. The children themselves
  /// are kept — the user can re-attach them via the set details sheet.
  Future<void> deleteWorkoutSet(String workoutSetId) async {
    final WorkoutSetRow setRow = await _getWorkoutSetRow(workoutSetId);
    final _WorkoutExerciseContext context = await _getWorkoutExerciseContext(
      setRow.workoutExerciseId,
    );
    _ensureWorkoutIsActive(context.workout);

    await _database.transaction(() async {
      // Re-parent any direct drop children of this set so the chain
      // stays valid after the row is gone.
      await (_database.update(_database.sets)
            ..where((tbl) => tbl.parentSetId.equals(workoutSetId)))
          .write(
            SetsCompanion(
              parentSetId: Value<String?>(setRow.parentSetId),
            ),
          );

      await (_database.delete(
        _database.sets,
      )..where((tbl) => tbl.id.equals(workoutSetId))).go();

      // Renumber any sets with a higher setNumber for this workoutExercise.
      final List<WorkoutSetRow> following =
          await (_database.select(_database.sets)
                ..where(
                  (tbl) =>
                      tbl.workoutExerciseId.equals(setRow.workoutExerciseId) &
                      tbl.setNumber.isBiggerThanValue(setRow.setNumber),
                )
                ..orderBy(<OrderingTerm Function(Sets)>[
                  (tbl) => OrderingTerm(expression: tbl.setNumber),
                ]))
              .get();

      for (final WorkoutSetRow row in following) {
        await (_database.update(_database.sets)
              ..where((tbl) => tbl.id.equals(row.id)))
            .write(SetsCompanion(setNumber: Value<int>(row.setNumber - 1)));
      }
    });
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

  /// Deletes a workout regardless of whether it is active or finished. Used
  /// by the recovery dialog's "Discard" action on a workout that the
  /// auto-close flow already moved into the finished state.
  Future<void> deleteFinishedWorkout(String workoutId) async {
    final int deleted = await (_database.delete(
      _database.workouts,
    )..where((tbl) => tbl.id.equals(workoutId))).go();

    if (deleted == 0) {
      throw WorkoutNotFoundException(workoutId);
    }
  }

  /// Re-activates a finished workout so the user can keep logging sets in
  /// it. Symmetric to [endWorkout] but for the auto-close recovery flow:
  /// when the user picks "Edit / Add" in the recovery dialog we clear
  /// `endedAt` and the existing active-workout UI takes over.
  Future<Workout> reopenWorkout(String workoutId) async {
    final WorkoutRow row = await _getWorkoutRow(workoutId);
    if (row.endedAt == null) {
      throw WorkoutNotEndedException(workoutId);
    }
    // Don't allow reopening if another workout is already active — would
    // violate the "only one active workout" invariant enforced by
    // [startWorkout].
    final WorkoutRow? otherActive = await (_database.select(
      _database.workouts,
    )..where((tbl) => tbl.endedAt.isNull())).getSingleOrNull();
    if (otherActive != null) {
      throw ActiveWorkoutAlreadyExistsException(otherActive.id);
    }

    await (_database.update(_database.workouts)
          ..where((tbl) => tbl.id.equals(workoutId)))
        .write(const WorkoutsCompanion(endedAt: Value<DateTime?>(null)));
    return row.toModel().copyWith(clearEndedAt: true);
  }

  /// Updates `endedAt` on a workout that is already finished. Sibling to
  /// [endWorkout] (which only works on active workouts). Used by the
  /// recovery dialog's "Save" action when the user edits the duration.
  Future<Workout> adjustEndedAt(String workoutId, DateTime endedAt) async {
    final WorkoutRow row = await _getWorkoutRow(workoutId);
    if (row.endedAt == null) {
      throw WorkoutNotEndedException(workoutId);
    }
    await (_database.update(_database.workouts)
          ..where((tbl) => tbl.id.equals(workoutId)))
        .write(WorkoutsCompanion(endedAt: Value<DateTime?>(endedAt)));
    return row.toModel().copyWith(endedAt: endedAt);
  }

  /// Returns the data needed to decide whether [autoCloseIfStale] should
  /// fire on a given workout: the most recent activity timestamp (set
  /// edits, set completions, exercise additions, or — as fallback — the
  /// workout's `startedAt`); the time of the last *completed* set
  /// (used as the auto-closed `endedAt`); and the count of completed sets
  /// (used to decide between auto-close and silent discard).
  Future<({DateTime lastActivityAt, DateTime? lastCompletedSetAt, int completedSetCount})>
  getStalenessSnapshot(String workoutId) async {
    final WorkoutRow workoutRow = await _getWorkoutRow(workoutId);

    final List<WorkoutExerciseRow> exercises =
        await (_database.select(_database.workoutExercises)
              ..where((tbl) => tbl.workoutId.equals(workoutId)))
            .get();

    DateTime lastActivityAt = workoutRow.startedAt;
    for (final WorkoutExerciseRow exercise in exercises) {
      final DateTime? createdAt = exercise.createdAt;
      if (createdAt != null && createdAt.isAfter(lastActivityAt)) {
        lastActivityAt = createdAt;
      }
    }

    if (exercises.isEmpty) {
      return (
        lastActivityAt: lastActivityAt,
        lastCompletedSetAt: null,
        completedSetCount: 0,
      );
    }

    final List<String> exerciseIds =
        exercises.map((e) => e.id).toList(growable: false);
    final List<WorkoutSetRow> sets =
        await (_database.select(_database.sets)
              ..where((tbl) => tbl.workoutExerciseId.isIn(exerciseIds)))
            .get();

    DateTime? lastCompletedSetAt;
    int completedSetCount = 0;
    for (final WorkoutSetRow set in sets) {
      final DateTime? updatedAt = set.updatedAt;
      if (updatedAt != null && updatedAt.isAfter(lastActivityAt)) {
        lastActivityAt = updatedAt;
      }
      if (set.completed) {
        completedSetCount++;
        final DateTime? completedAt = set.completedAt;
        if (completedAt != null &&
            (lastCompletedSetAt == null ||
                completedAt.isAfter(lastCompletedSetAt))) {
          lastCompletedSetAt = completedAt;
        }
      }
    }

    return (
      lastActivityAt: lastActivityAt,
      lastCompletedSetAt: lastCompletedSetAt,
      completedSetCount: completedSetCount,
    );
  }

  /// Auto-closes the active workout if its inactivity exceeds [threshold].
  ///
  /// - Returns `null` if there is no active workout, the workout is still
  ///   within the threshold, or the workout had zero completed sets (in
  ///   which case it is silently deleted — there's nothing meaningful to
  ///   recover).
  /// - Otherwise sets `endedAt` to the timestamp of the last completed
  ///   set so the recorded duration reflects training time rather than
  ///   the wall-clock gap until the next app launch, and returns the
  ///   freshly-closed [Workout].
  ///
  /// Iterates over every active row defensively in case the DB ends up
  /// holding more than one (the schema doesn't enforce uniqueness, only
  /// [startWorkout] does). Re-checks `endedAt` inside the transaction to
  /// guard against the race where the user manually finishes the workout
  /// between snapshot and write.
  Future<Workout?> autoCloseIfStale({
    Duration threshold = const Duration(hours: 1),
    DateTime? now,
  }) async {
    final DateTime resolvedNow = now ?? _utcNow();

    return _database.transaction<Workout?>(() async {
      final List<WorkoutRow> activeRows =
          await (_database.select(_database.workouts)
                ..where((tbl) => tbl.endedAt.isNull()))
              .get();
      if (activeRows.isEmpty) return null;

      Workout? recovered;
      for (final WorkoutRow row in activeRows) {
        // Re-read inside the transaction to detect the user-finished-it race.
        final WorkoutRow? fresh = await (_database.select(
          _database.workouts,
        )..where((tbl) => tbl.id.equals(row.id))).getSingleOrNull();
        if (fresh == null || fresh.endedAt != null) continue;

        final ({
          DateTime lastActivityAt,
          DateTime? lastCompletedSetAt,
          int completedSetCount,
        })
        snapshot = await getStalenessSnapshot(row.id);
        if (snapshot.lastActivityAt.add(threshold).isAfter(resolvedNow)) {
          continue;
        }

        if (snapshot.completedSetCount == 0) {
          // Silent discard. Bypass cancelWorkout's active-only guard —
          // we just verified active above and deletion is the right
          // outcome regardless.
          await (_database.delete(_database.workouts)
                ..where((tbl) => tbl.id.equals(row.id)))
              .go();
          continue;
        }

        final DateTime endedAt = snapshot.lastCompletedSetAt!;
        await (_database.update(_database.workouts)
              ..where((tbl) => tbl.id.equals(row.id)))
            .write(WorkoutsCompanion(endedAt: Value<DateTime?>(endedAt)));
        recovered ??= row.toModel().copyWith(endedAt: endedAt);
      }

      return recovered;
    });
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

  Stream<List<Workout>> watchHistory() {
    final Stream<List<WorkoutRow>> rows =
        (_database.select(_database.workouts)
              ..where((tbl) => tbl.endedAt.isNotNull())
              ..orderBy(<OrderingTerm Function(Workouts)>[
                (tbl) => OrderingTerm(
                  expression: tbl.endedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .watch();

    return rows.map(
      (items) => items.map((row) => row.toModel()).toList(growable: false),
    );
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

  /// For each [exerciseIds], returns the sets from the most recent *completed*
  /// workout that included that exercise — used to populate the "Previous"
  /// column on the active workout screen. Pass [excludeWorkoutId] to skip the
  /// in-progress workout.
  Future<Map<String, List<WorkoutSet>>> getLastCompletedSetsForExercises({
    required List<String> exerciseIds,
    String? excludeWorkoutId,
  }) async {
    if (exerciseIds.isEmpty) return const <String, List<WorkoutSet>>{};

    final SimpleSelectStatement<Workouts, WorkoutRow> query =
        _database.select(_database.workouts)
          ..where((tbl) => tbl.endedAt.isNotNull())
          ..orderBy(<OrderingTerm Function(Workouts)>[
            (tbl) => OrderingTerm(
              expression: tbl.endedAt,
              mode: OrderingMode.desc,
            ),
          ]);
    if (excludeWorkoutId != null) {
      query.where((tbl) => tbl.id.equals(excludeWorkoutId).not());
    }
    final List<WorkoutRow> workouts = await query.get();
    if (workouts.isEmpty) return const <String, List<WorkoutSet>>{};

    final Set<String> remaining = exerciseIds.toSet();
    final Map<String, String> pickedWorkoutExerciseIdByExerciseId =
        <String, String>{};

    // Walk newest → oldest; first hit per exercise wins.
    for (final WorkoutRow workout in workouts) {
      if (remaining.isEmpty) break;
      final List<WorkoutExerciseRow> rows =
          await (_database.select(_database.workoutExercises)..where(
                (tbl) =>
                    tbl.workoutId.equals(workout.id) &
                    tbl.exerciseId.isIn(remaining.toList()),
              ))
              .get();
      for (final WorkoutExerciseRow row in rows) {
        if (remaining.remove(row.exerciseId)) {
          pickedWorkoutExerciseIdByExerciseId[row.exerciseId] = row.id;
        }
      }
    }

    if (pickedWorkoutExerciseIdByExerciseId.isEmpty) {
      return const <String, List<WorkoutSet>>{};
    }

    final Map<String, List<WorkoutSet>> setsByWorkoutExerciseId =
        await _loadWorkoutSetsByWorkoutExercise(
          pickedWorkoutExerciseIdByExerciseId.values.toList(growable: false),
        );

    return <String, List<WorkoutSet>>{
      for (final MapEntry<String, String> entry
          in pickedWorkoutExerciseIdByExerciseId.entries)
        entry.key:
            setsByWorkoutExerciseId[entry.value] ?? const <WorkoutSet>[],
    };
  }

  /// One row per exercise that has at least one PR-qualifying completed
  /// set in a finished workout: maps the exercise id to the start time of
  /// the most recent qualifying session. "Qualifying" matches the strength
  /// chart's filter — `normal` or `failure` kind sets with weight > 0 and
  /// reps > 0.
  ///
  /// Single SQL aggregate; replaces the previous "loop over every weighted
  /// exercise and pull its full history just to find the latest date" path
  /// that the progression tab's trackable-exercises picker used.
  Future<Map<String, DateTime>>
  getLatestQualifyingSessionPerExercise() async {
    final List<QueryRow> rows = await _database.customSelect(
      'SELECT we.exercise_id AS exercise_id, '
      '       MAX(w.started_at) AS latest_started_at '
      'FROM sets s '
      'INNER JOIN workout_exercises we ON s.workout_exercise_id = we.id '
      'INNER JOIN workouts w ON we.workout_id = w.id '
      'WHERE w.ended_at IS NOT NULL '
      '  AND s.completed = 1 '
      "  AND s.kind IN ('normal', 'failure') "
      '  AND s.weight_kg IS NOT NULL AND s.weight_kg > 0 '
      '  AND s.reps IS NOT NULL AND s.reps > 0 '
      'GROUP BY we.exercise_id',
      variables: const <Variable<Object>>[],
      readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
        _database.sets,
        _database.workoutExercises,
        _database.workouts,
      },
    ).get();

    return <String, DateTime>{
      for (final QueryRow row in rows)
        row.read<String>('exercise_id'): row.read<DateTime>(
          'latest_started_at',
        ),
    };
  }

  /// Counts completed *working* sets (i.e. excludes warm-ups) for each of
  /// the given [workoutIds]. Used by the history list to surface a "sets"
  /// tally on each workout tile. Workouts with zero qualifying sets are
  /// omitted from the result map.
  Future<Map<String, int>> getCompletedSetCountsForWorkouts(
    List<String> workoutIds,
  ) async {
    if (workoutIds.isEmpty) return const <String, int>{};

    final String placeholders = List<String>.filled(
      workoutIds.length,
      '?',
    ).join(',');
    final List<QueryRow> rows = await _database.customSelect(
      'SELECT we.workout_id AS workout_id, COUNT(s.id) AS set_count '
      'FROM sets s '
      'INNER JOIN workout_exercises we ON s.workout_exercise_id = we.id '
      "WHERE s.completed = 1 AND s.kind != 'warmUp' "
      'AND we.workout_id IN ($placeholders) '
      'GROUP BY we.workout_id',
      variables: <Variable<Object>>[
        for (final String id in workoutIds) Variable<String>(id),
      ],
    ).get();

    return <String, int>{
      for (final QueryRow row in rows)
        row.read<String>('workout_id'): row.read<int>('set_count'),
    };
  }

  /// Counts completed sets per [ExerciseMuscleGroup] for any workout whose
  /// [Workout.startedAt] falls within the half-open range
  /// [`rangeStart`, `rangeEnd`). Used by the workouts hero card to surface
  /// "this week's volume" at a glance — and counts in-progress workouts so
  /// the number ticks up as the user completes sets in the live session.
  ///
  /// Muscle groups with zero completed sets are omitted from the result.
  Stream<Map<ExerciseMuscleGroup, int>> watchSetCountsByMuscleGroup({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final Selectable<QueryRow> query = _database.customSelect(
      'SELECT e.muscle_group AS muscle_group, COUNT(s.id) AS set_count '
      'FROM sets s '
      'INNER JOIN workout_exercises we ON s.workout_exercise_id = we.id '
      'INNER JOIN exercises e ON we.exercise_id = e.id '
      'INNER JOIN workouts w ON we.workout_id = w.id '
      'WHERE s.completed = 1 '
      // Drop sets are continuations of a working set, not full sets
      // themselves — exclude them from the weekly muscle-group counter
      // so a triple-drop on bench press doesn't inflate chest volume.
      // Warm-ups are excluded for the same reason.
      "  AND s.kind NOT IN ('warmUp', 'drop') "
      '  AND w.started_at >= ? '
      '  AND w.started_at < ? '
      'GROUP BY e.muscle_group',
      variables: <Variable<Object>>[
        Variable<DateTime>(rangeStart),
        Variable<DateTime>(rangeEnd),
      ],
      readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
        _database.sets,
        _database.workoutExercises,
        _database.exercises,
        _database.workouts,
      },
    );

    return query.watch().map((List<QueryRow> rows) {
      final Map<ExerciseMuscleGroup, int> result =
          <ExerciseMuscleGroup, int>{};
      for (final QueryRow row in rows) {
        final String name = row.read<String>('muscle_group');
        final ExerciseMuscleGroup? mg = _muscleGroupByName(name);
        if (mg == null) continue;
        result[mg] = row.read<int>('set_count');
      }
      return result;
    });
  }

  /// Sum of `duration_seconds` across every completed cardio set whose
  /// parent workout started within `[rangeStart, rangeEnd)`. Streams from
  /// Drift so the in-workout strip updates in real time as the user logs
  /// cardio minutes.
  ///
  /// Cardio exercises are identified via `e.muscle_group = 'cardio'` —
  /// the same convention used by [watchSetCountsByMuscleGroup].
  Stream<int> watchCardioDurationSecondsForRange({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final Selectable<QueryRow> query = _database.customSelect(
      'SELECT COALESCE(SUM(s.duration_seconds), 0) AS total_seconds '
      'FROM sets s '
      'INNER JOIN workout_exercises we ON s.workout_exercise_id = we.id '
      'INNER JOIN exercises e ON we.exercise_id = e.id '
      'INNER JOIN workouts w ON we.workout_id = w.id '
      'WHERE s.completed = 1 '
      "  AND s.kind != 'warmUp' "
      "  AND e.muscle_group = 'cardio' "
      '  AND s.duration_seconds IS NOT NULL '
      '  AND w.started_at >= ? '
      '  AND w.started_at < ?',
      variables: <Variable<Object>>[
        Variable<DateTime>(rangeStart),
        Variable<DateTime>(rangeEnd),
      ],
      readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
        _database.sets,
        _database.workoutExercises,
        _database.exercises,
        _database.workouts,
      },
    );

    return query.watch().map((List<QueryRow> rows) {
      if (rows.isEmpty) return 0;
      return rows.first.read<int>('total_seconds');
    });
  }

  /// Sum of `weight_kg × reps` across every completed set whose parent
  /// workout started within `[rangeStart, rangeEnd)`. Streams from Drift;
  /// updates the moment a set is marked complete during a live workout.
  ///
  /// Returns total kilograms moved (a.k.a. "tonnage"), in canonical kg
  /// regardless of the user's display unit system. Cardio sets are
  /// excluded automatically — they have no `weight_kg`/`reps`.
  Stream<double> watchTotalVolumeKgForRange({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final Selectable<QueryRow> query = _database.customSelect(
      'SELECT COALESCE(SUM(s.weight_kg * s.reps), 0.0) AS total_volume '
      'FROM sets s '
      'INNER JOIN workout_exercises we ON s.workout_exercise_id = we.id '
      'INNER JOIN workouts w ON we.workout_id = w.id '
      'WHERE s.completed = 1 '
      "  AND s.kind != 'warmUp' "
      '  AND s.weight_kg IS NOT NULL '
      '  AND s.reps IS NOT NULL '
      '  AND w.started_at >= ? '
      '  AND w.started_at < ?',
      variables: <Variable<Object>>[
        Variable<DateTime>(rangeStart),
        Variable<DateTime>(rangeEnd),
      ],
      readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
        _database.sets,
        _database.workoutExercises,
        _database.workouts,
      },
    );

    return query.watch().map((List<QueryRow> rows) {
      if (rows.isEmpty) return 0.0;
      // SUM with REAL operands returns REAL; COALESCE keeps it non-null.
      return rows.first.read<double>('total_volume');
    });
  }

  /// Per-day completed set counts within `[rangeStart, rangeEnd)`, keyed
  /// by local-time midnight DateTime so the calendar heatmap can index
  /// directly. Streams from Drift; ticks up live as sets complete.
  ///
  /// Days with zero training are absent from the map (consumers default
  /// to 0). Grouping uses the parent workout's `started_at` so a session
  /// that crosses midnight stays on its starting day, matching how the
  /// rest of the app reasons about training days.
  Stream<Map<DateTime, int>> watchDailySetCountsForRange({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final Selectable<QueryRow> query = _database.customSelect(
      'SELECT w.id AS workout_id, w.started_at AS started_at, '
      '       COUNT(s.id) AS set_count '
      'FROM sets s '
      'INNER JOIN workout_exercises we ON s.workout_exercise_id = we.id '
      'INNER JOIN workouts w ON we.workout_id = w.id '
      'WHERE s.completed = 1 '
      "  AND s.kind != 'warmUp' "
      '  AND w.started_at >= ? '
      '  AND w.started_at < ? '
      'GROUP BY w.id',
      variables: <Variable<Object>>[
        Variable<DateTime>(rangeStart),
        Variable<DateTime>(rangeEnd),
      ],
      readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
        _database.sets,
        _database.workoutExercises,
        _database.workouts,
      },
    );

    return query.watch().map((List<QueryRow> rows) {
      final Map<DateTime, int> result = <DateTime, int>{};
      for (final QueryRow row in rows) {
        final DateTime startedAt = row.read<DateTime>('started_at');
        final int count = row.read<int>('set_count');
        final DateTime local = startedAt.toLocal();
        final DateTime day = DateTime(local.year, local.month, local.day);
        result[day] = (result[day] ?? 0) + count;
      }
      return result;
    });
  }

  /// Every PR moment across every exercise, newest-first. Walks every
  /// completed PR-eligible set in chronological order, tracks per-
  /// exercise running maxes for each [PrType] that applies to that
  /// exercise's [ExerciseType], and emits a [PrEvent] each time a set
  /// (or per-workout aggregate) strictly exceeds all prior records.
  ///
  /// First-workout suppression: an exercise's first-ever completed
  /// workout only seeds the running maxes — no PRs emit. From the
  /// second workout onwards, sets that beat the running max can fire
  /// PRs. This avoids the "first leg day fires 30 PRs" problem.
  ///
  /// Streams from Drift so the feed re-emits the moment a new PR lands —
  /// no manual invalidation. Single SQL query + linear scan; cheap enough
  /// for tens of thousands of sets.
  Stream<List<PrEvent>> watchAllPrEvents() {
    final Selectable<QueryRow> query = _database.customSelect(
      'SELECT s.id AS set_id, s.weight_kg AS weight_kg, s.reps AS reps, '
      '       s.distance_km AS distance_km, '
      '       s.duration_seconds AS duration_seconds, '
      '       s.set_number AS set_number, '
      '       w.id AS workout_id, w.started_at AS started_at, '
      '       e.id AS exercise_id, e.name AS exercise_name, '
      '       e.type AS exercise_type '
      'FROM sets s '
      'INNER JOIN workout_exercises we ON s.workout_exercise_id = we.id '
      'INNER JOIN workouts w ON we.workout_id = w.id '
      'INNER JOIN exercises e ON we.exercise_id = e.id '
      'WHERE s.completed = 1 '
      "  AND s.kind IN ('normal', 'failure') "
      'ORDER BY w.started_at ASC, s.set_number ASC',
      variables: <Variable<Object>>[],
      readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
        _database.sets,
        _database.workoutExercises,
        _database.workouts,
        _database.exercises,
      },
    );

    return query
        .watch()
        .map(_buildPrEventsFromRows)
        // Each set keystroke / mutation wakes this stream, but the PR set
        // is unchanged unless a new lift actually beat a running max.
        // Dedupe so the PR feed and counters don't churn during typing.
        .distinct(prEventListsStructurallyEqual);
  }

  /// Walks the chronologically-ordered query rows, grouping by workout
  /// and emitting PR events per exercise type. Pure function — pulled
  /// out of [watchAllPrEvents] so it can be tested without Drift.
  List<PrEvent> _buildPrEventsFromRows(List<QueryRow> rows) {
    if (rows.isEmpty) return const <PrEvent>[];

    // Per-exercise running maxes for every PR type. Each map is keyed
    // by exerciseId so all exercises share one walk through the data.
    final Map<String, _BestSet> bestSetByExercise = <String, _BestSet>{};
    final Map<String, double> e1rmByExercise = <String, double>{};
    final Map<String, Map<int, double>> repMaxByExercise =
        <String, Map<int, double>>{};
    final Map<String, int> mostRepsInSetByExercise = <String, int>{};
    final Map<String, int> mostRepsInWorkoutByExercise = <String, int>{};
    final Map<String, double> longestDistanceByExercise = <String, double>{};
    final Map<String, int> longestDurationByExercise = <String, int>{};

    // Tracks which exercises have appeared in at least one earlier
    // *completed* workout. Sets in a workout only emit PRs when their
    // exercise is in this set — i.e. has prior history.
    final Set<String> exercisesWithPriorWorkout = <String>{};

    final List<PrEvent> events = <PrEvent>[];

    int i = 0;
    while (i < rows.length) {
      final String workoutId = rows[i].read<String>('workout_id');
      // Slurp every row that belongs to this workout into one chunk.
      final int workoutStart = i;
      while (i < rows.length &&
          rows[i].read<String>('workout_id') == workoutId) {
        i++;
      }
      final List<QueryRow> workoutRows = rows.sublist(workoutStart, i);

      // Group this workout's rows by exercise.
      final Map<String, List<QueryRow>> byExercise =
          <String, List<QueryRow>>{};
      for (final QueryRow row in workoutRows) {
        final String exId = row.read<String>('exercise_id');
        byExercise.putIfAbsent(exId, () => <QueryRow>[]).add(row);
      }

      for (final MapEntry<String, List<QueryRow>> entry in byExercise.entries) {
        final String exerciseId = entry.key;
        final List<QueryRow> exRows = entry.value;
        final QueryRow first = exRows.first;
        final ExerciseType exerciseType = ExerciseType.values.firstWhere(
          (ExerciseType t) => t.name == first.read<String>('exercise_type'),
          orElse: () => ExerciseType.weighted,
        );
        final String exerciseName = first.read<String>('exercise_name');
        final DateTime achievedAt = first.read<DateTime>('started_at');
        final bool canEmit = exercisesWithPriorWorkout.contains(exerciseId);

        switch (exerciseType) {
          case ExerciseType.weighted:
            _processWeightedExercise(
              rows: exRows,
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              workoutId: workoutId,
              achievedAt: achievedAt,
              canEmit: canEmit,
              bestSetByExercise: bestSetByExercise,
              e1rmByExercise: e1rmByExercise,
              repMaxByExercise: repMaxByExercise,
              events: events,
            );
          case ExerciseType.bodyweight:
            _processBodyweightExercise(
              rows: exRows,
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              workoutId: workoutId,
              achievedAt: achievedAt,
              canEmit: canEmit,
              mostRepsInSetByExercise: mostRepsInSetByExercise,
              mostRepsInWorkoutByExercise: mostRepsInWorkoutByExercise,
              events: events,
            );
          case ExerciseType.cardio:
            _processCardioExercise(
              rows: exRows,
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              workoutId: workoutId,
              achievedAt: achievedAt,
              canEmit: canEmit,
              longestDistanceByExercise: longestDistanceByExercise,
              longestDurationByExercise: longestDurationByExercise,
              events: events,
            );
        }
      }

      // After processing this workout, mark every exercise that
      // appeared as having prior history for the next iteration.
      exercisesWithPriorWorkout.addAll(byExercise.keys);
    }

    return events.reversed.toList(growable: false);
  }

  void _processWeightedExercise({
    required List<QueryRow> rows,
    required String exerciseId,
    required String exerciseName,
    required String workoutId,
    required DateTime achievedAt,
    required bool canEmit,
    required Map<String, _BestSet> bestSetByExercise,
    required Map<String, double> e1rmByExercise,
    required Map<String, Map<int, double>> repMaxByExercise,
    required List<PrEvent> events,
  }) {
    // Find this workout's best-of for each PR type, then compare to
    // running maxes once per type so we never emit two best-set PRs
    // for the same workout.
    QueryRow? bestSetRow;
    QueryRow? bestE1rmRow;
    double bestE1rmValue = 0;
    final Map<int, ({QueryRow row, double weight})> bestPerRepCount =
        <int, ({QueryRow row, double weight})>{};

    for (final QueryRow row in rows) {
      final double? weightKg = row.read<double?>('weight_kg');
      final int? reps = row.read<int?>('reps');
      if (weightKg == null || weightKg <= 0) continue;
      if (reps == null || reps <= 0) continue;

      // Best set: heavier weight wins, then more reps as tiebreak.
      if (bestSetRow == null) {
        bestSetRow = row;
      } else {
        final double bw = bestSetRow.read<double>('weight_kg');
        final int br = bestSetRow.read<int>('reps');
        if (weightKg > bw || (weightKg == bw && reps > br)) {
          bestSetRow = row;
        }
      }

      // Epley e1RM.
      final double? oneRm = StrengthFormulas.epley1RMKg(
        weightKg: weightKg,
        reps: reps,
      );
      if (oneRm != null && oneRm > bestE1rmValue) {
        bestE1rmValue = oneRm;
        bestE1rmRow = row;
      }

      // Heaviest weight at this exact rep count.
      final ({QueryRow row, double weight})? prev = bestPerRepCount[reps];
      if (prev == null || weightKg > prev.weight) {
        bestPerRepCount[reps] = (row: row, weight: weightKg);
      }
    }

    // Compare against running maxes; emit only when strictly better.
    if (bestSetRow != null) {
      final double w = bestSetRow.read<double>('weight_kg');
      final int r = bestSetRow.read<int>('reps');
      final _BestSet? prev = bestSetByExercise[exerciseId];
      final bool beats = prev == null ||
          w > prev.weightKg ||
          (w == prev.weightKg && r > prev.reps);
      if (beats) {
        bestSetByExercise[exerciseId] = _BestSet(weightKg: w, reps: r);
        if (canEmit) {
          events.add(
            PrEvent(
              type: PrType.bestSet,
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              exerciseType: ExerciseType.weighted,
              workoutId: workoutId,
              achievedAt: achievedAt,
              setId: bestSetRow.read<String>('set_id'),
              weightKg: w,
              reps: r,
              oneRepMaxKg: StrengthFormulas.epley1RMKg(
                weightKg: w,
                reps: r,
              ),
            ),
          );
        }
      }
    }

    if (bestE1rmRow != null) {
      final double prevMax = e1rmByExercise[exerciseId] ?? 0;
      if (bestE1rmValue > prevMax) {
        e1rmByExercise[exerciseId] = bestE1rmValue;
        if (canEmit) {
          events.add(
            PrEvent(
              type: PrType.e1rm,
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              exerciseType: ExerciseType.weighted,
              workoutId: workoutId,
              achievedAt: achievedAt,
              setId: bestE1rmRow.read<String>('set_id'),
              weightKg: bestE1rmRow.read<double>('weight_kg'),
              reps: bestE1rmRow.read<int>('reps'),
              oneRepMaxKg: bestE1rmValue,
            ),
          );
        }
      }
    }

    final Map<int, double> repMaxes =
        repMaxByExercise.putIfAbsent(exerciseId, () => <int, double>{});
    for (final MapEntry<int, ({QueryRow row, double weight})> e
        in bestPerRepCount.entries) {
      final int reps = e.key;
      final double weight = e.value.weight;
      final double prev = repMaxes[reps] ?? 0;
      if (weight > prev) {
        repMaxes[reps] = weight;
        if (canEmit) {
          events.add(
            PrEvent(
              type: PrType.repMax,
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              exerciseType: ExerciseType.weighted,
              workoutId: workoutId,
              achievedAt: achievedAt,
              setId: e.value.row.read<String>('set_id'),
              weightKg: weight,
              reps: reps,
              oneRepMaxKg: StrengthFormulas.epley1RMKg(
                weightKg: weight,
                reps: reps,
              ),
              repCountForRepMax: reps,
            ),
          );
        }
      }
    }
  }

  void _processBodyweightExercise({
    required List<QueryRow> rows,
    required String exerciseId,
    required String exerciseName,
    required String workoutId,
    required DateTime achievedAt,
    required bool canEmit,
    required Map<String, int> mostRepsInSetByExercise,
    required Map<String, int> mostRepsInWorkoutByExercise,
    required List<PrEvent> events,
  }) {
    QueryRow? bestSetRow;
    int totalReps = 0;
    for (final QueryRow row in rows) {
      final int? reps = row.read<int?>('reps');
      if (reps == null || reps <= 0) continue;
      totalReps += reps;
      if (bestSetRow == null || reps > bestSetRow.read<int>('reps')) {
        bestSetRow = row;
      }
    }

    if (bestSetRow != null) {
      final int reps = bestSetRow.read<int>('reps');
      final int prev = mostRepsInSetByExercise[exerciseId] ?? 0;
      if (reps > prev) {
        mostRepsInSetByExercise[exerciseId] = reps;
        if (canEmit) {
          events.add(
            PrEvent(
              type: PrType.mostRepsInSet,
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              exerciseType: ExerciseType.bodyweight,
              workoutId: workoutId,
              achievedAt: achievedAt,
              setId: bestSetRow.read<String>('set_id'),
              reps: reps,
            ),
          );
        }
      }
    }

    if (totalReps > 0) {
      final int prev = mostRepsInWorkoutByExercise[exerciseId] ?? 0;
      if (totalReps > prev) {
        mostRepsInWorkoutByExercise[exerciseId] = totalReps;
        if (canEmit) {
          events.add(
            PrEvent(
              type: PrType.mostRepsInWorkout,
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              exerciseType: ExerciseType.bodyweight,
              workoutId: workoutId,
              achievedAt: achievedAt,
              reps: totalReps,
            ),
          );
        }
      }
    }
  }

  void _processCardioExercise({
    required List<QueryRow> rows,
    required String exerciseId,
    required String exerciseName,
    required String workoutId,
    required DateTime achievedAt,
    required bool canEmit,
    required Map<String, double> longestDistanceByExercise,
    required Map<String, int> longestDurationByExercise,
    required List<PrEvent> events,
  }) {
    QueryRow? bestDistanceRow;
    double bestDistanceValue = 0;
    QueryRow? bestDurationRow;
    int bestDurationValue = 0;

    for (final QueryRow row in rows) {
      final double? km = row.read<double?>('distance_km');
      if (km != null && km > bestDistanceValue) {
        bestDistanceValue = km;
        bestDistanceRow = row;
      }
      final int? secs = row.read<int?>('duration_seconds');
      if (secs != null && secs > bestDurationValue) {
        bestDurationValue = secs;
        bestDurationRow = row;
      }
    }

    if (bestDistanceRow != null) {
      final double prev = longestDistanceByExercise[exerciseId] ?? 0;
      if (bestDistanceValue > prev) {
        longestDistanceByExercise[exerciseId] = bestDistanceValue;
        if (canEmit) {
          events.add(
            PrEvent(
              type: PrType.longestDistance,
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              exerciseType: ExerciseType.cardio,
              workoutId: workoutId,
              achievedAt: achievedAt,
              setId: bestDistanceRow.read<String>('set_id'),
              distanceKm: bestDistanceValue,
            ),
          );
        }
      }
    }

    if (bestDurationRow != null) {
      final int prev = longestDurationByExercise[exerciseId] ?? 0;
      if (bestDurationValue > prev) {
        longestDurationByExercise[exerciseId] = bestDurationValue;
        if (canEmit) {
          events.add(
            PrEvent(
              type: PrType.longestDuration,
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              exerciseType: ExerciseType.cardio,
              workoutId: workoutId,
              achievedAt: achievedAt,
              setId: bestDurationRow.read<String>('set_id'),
              durationSeconds: bestDurationValue,
            ),
          );
        }
      }
    }
  }

  /// Set of finished workout ids that have at least one non-empty note —
  /// at the workout, workout-exercise, or set level. Backs the History
  /// "Notes" filter chip ("show me sessions where I wrote something
  /// down"). Streams from Drift across all three tables so the set
  /// updates the moment the user types into a notes sheet.
  Stream<Set<String>> watchWorkoutsWithAnyNote() {
    final Selectable<QueryRow> query = _database.customSelect(
      'SELECT DISTINCT w.id AS workout_id '
      'FROM workouts w '
      'WHERE w.ended_at IS NOT NULL '
      "  AND (w.notes IS NOT NULL AND TRIM(w.notes) != '' "
      '       OR EXISTS ( '
      '         SELECT 1 FROM workout_exercises we '
      '         WHERE we.workout_id = w.id '
      "           AND we.notes IS NOT NULL AND TRIM(we.notes) != '' "
      '       ) '
      '       OR EXISTS ( '
      '         SELECT 1 FROM workout_exercises we '
      '         INNER JOIN sets s ON s.workout_exercise_id = we.id '
      '         WHERE we.workout_id = w.id '
      "           AND s.note IS NOT NULL AND TRIM(s.note) != '' "
      '       ) '
      '  )',
      variables: <Variable<Object>>[],
      readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
        _database.workouts,
        _database.workoutExercises,
        _database.sets,
      },
    );

    return query.watch().map((List<QueryRow> rows) {
      return Set<String>.unmodifiable(<String>{
        for (final QueryRow row in rows) row.read<String>('workout_id'),
      });
    });
  }

  /// Per-workout view of which exercises were performed: each finished
  /// workout maps to the ordered list of (exerciseId, exerciseName) entries
  /// for every exercise added to it. Powers the History search/filter — the
  /// Exercise filter ANDs against the id set, and the search text ANDs
  /// against names.
  ///
  /// Streams from Drift across workouts, workout_exercises, and exercises
  /// so the result map updates immediately when an exercise is added,
  /// removed, or renamed during the active workout (which then gets
  /// finished and shows up here).
  Stream<Map<String, List<({String id, String name})>>>
  watchExercisesByFinishedWorkout() {
    final Selectable<QueryRow> query = _database.customSelect(
      'SELECT we.workout_id AS workout_id, '
      '       we.order_index AS order_index, '
      '       e.id AS exercise_id, e.name AS exercise_name '
      'FROM workout_exercises we '
      'INNER JOIN workouts w ON we.workout_id = w.id '
      'INNER JOIN exercises e ON we.exercise_id = e.id '
      'WHERE w.ended_at IS NOT NULL '
      'ORDER BY we.workout_id ASC, we.order_index ASC',
      variables: <Variable<Object>>[],
      readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
        _database.workouts,
        _database.workoutExercises,
        _database.exercises,
      },
    );

    return query.watch().map((List<QueryRow> rows) {
      final Map<String, List<({String id, String name})>> byWorkout =
          <String, List<({String id, String name})>>{};
      for (final QueryRow row in rows) {
        final String workoutId = row.read<String>('workout_id');
        byWorkout
            .putIfAbsent(workoutId, () => <({String id, String name})>[])
            .add((
              id: row.read<String>('exercise_id'),
              name: row.read<String>('exercise_name'),
            ));
      }
      return Map<String, List<({String id, String name})>>.unmodifiable(
        byWorkout.map(
          (String key, List<({String id, String name})> value) =>
              MapEntry<String, List<({String id, String name})>>(
                key,
                List<({String id, String name})>.unmodifiable(value),
              ),
        ),
      );
    });
  }

  static ExerciseMuscleGroup? _muscleGroupByName(String name) {
    for (final ExerciseMuscleGroup mg in ExerciseMuscleGroup.values) {
      if (mg.name == name) return mg;
    }
    return null;
  }

  /// Returns one entry per (workout, exercise) occurrence — i.e. every
  /// historical session that contained [exerciseId], ordered newest first
  /// by workout start time. Includes only completed sets; entries whose
  /// parent workout has been finished AND that contributed at least one
  /// completed set are returned. The active in-progress workout is excluded.
  ///
  /// Powers the per-exercise history screen reachable by tapping an
  /// exercise's name on the active workout card.
  Future<List<ExerciseHistoryDay>> getExerciseHistoryByDay(
    String exerciseId,
  ) async {
    // 1. Find every workout_exercise row pointing at this exercise.
    final List<WorkoutExerciseRow> workoutExerciseRows =
        await (_database.select(_database.workoutExercises)
              ..where((tbl) => tbl.exerciseId.equals(exerciseId)))
            .get();
    if (workoutExerciseRows.isEmpty) return const <ExerciseHistoryDay>[];

    // 2. Pull the parent workouts; keep only finished ones.
    final List<String> workoutIds = workoutExerciseRows
        .map((row) => row.workoutId)
        .toSet()
        .toList(growable: false);
    final List<WorkoutRow> workoutRows =
        await (_database.select(_database.workouts)
              ..where(
                (tbl) => tbl.id.isIn(workoutIds) & tbl.endedAt.isNotNull(),
              ))
            .get();
    if (workoutRows.isEmpty) return const <ExerciseHistoryDay>[];

    final Map<String, WorkoutRow> workoutById = <String, WorkoutRow>{
      for (final WorkoutRow row in workoutRows) row.id: row,
    };

    // 3. Load every completed set for those workout_exercise rows.
    final List<String> finishedWorkoutExerciseIds = workoutExerciseRows
        .where((row) => workoutById.containsKey(row.workoutId))
        .map((row) => row.id)
        .toList(growable: false);
    if (finishedWorkoutExerciseIds.isEmpty) {
      return const <ExerciseHistoryDay>[];
    }

    final List<WorkoutSetRow> setRows =
        await (_database.select(_database.sets)
              ..where(
                (tbl) =>
                    tbl.workoutExerciseId.isIn(finishedWorkoutExerciseIds) &
                    tbl.completed.equals(true),
              )
              ..orderBy(<OrderingTerm Function(Sets)>[
                (tbl) => OrderingTerm(expression: tbl.setNumber),
              ]))
            .get();
    if (setRows.isEmpty) return const <ExerciseHistoryDay>[];

    // 4. Group sets by workout_exercise_id, then map into per-day entries.
    final Map<String, List<WorkoutSet>> setsByWorkoutExerciseId =
        <String, List<WorkoutSet>>{};
    for (final WorkoutSetRow row in setRows) {
      setsByWorkoutExerciseId
          .putIfAbsent(row.workoutExerciseId, () => <WorkoutSet>[])
          .add(row.toModel());
    }

    final List<ExerciseHistoryDay> entries = <ExerciseHistoryDay>[];
    for (final WorkoutExerciseRow weRow in workoutExerciseRows) {
      final WorkoutRow? workout = workoutById[weRow.workoutId];
      if (workout == null) continue;
      final List<WorkoutSet>? sets = setsByWorkoutExerciseId[weRow.id];
      if (sets == null || sets.isEmpty) continue;

      final DateTime localStarted = workout.startedAt.toLocal();
      final DateTime dayKey = DateTime(
        localStarted.year,
        localStarted.month,
        localStarted.day,
      );

      entries.add(
        ExerciseHistoryDay(
          date: dayKey,
          workoutId: workout.id,
          workoutName: workout.name,
          workoutStartedAt: workout.startedAt,
          sets: List<WorkoutSet>.unmodifiable(sets),
        ),
      );
    }

    // 5. Newest first.
    entries.sort(
      (a, b) => b.workoutStartedAt.compareTo(a.workoutStartedAt),
    );
    return List<ExerciseHistoryDay>.unmodifiable(entries);
  }

  Stream<List<ExerciseHistoryDay>> watchExerciseHistoryByDay(
    String exerciseId,
  ) {
    // Dedupe: every keystroke on any set wakes this stream, but
    // unfinished workouts are excluded from the result, so during an
    // active workout the per-exercise history list is unchanged across
    // emissions. Structural equality drops those redundant emissions
    // before they reach the strength chart, history sheet, etc.
    return _watchExerciseHistoryByDayRaw(
      exerciseId,
    ).distinct(exerciseHistoryDayListsStructurallyEqual);
  }

  Stream<List<ExerciseHistoryDay>> _watchExerciseHistoryByDayRaw(
    String exerciseId,
  ) {
    late final StreamController<List<ExerciseHistoryDay>> controller;
    final List<StreamSubscription<Object?>> subscriptions =
        <StreamSubscription<Object?>>[];
    bool closed = false;
    bool loading = false;
    bool queued = false;

    Future<void> emit() async {
      if (closed) return;
      if (loading) {
        queued = true;
        return;
      }
      loading = true;
      try {
        controller.add(await getExerciseHistoryByDay(exerciseId));
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      } finally {
        loading = false;
      }
      if (queued && !closed) {
        queued = false;
        unawaited(emit());
      }
    }

    void schedule() => unawaited(emit());

    controller = StreamController<List<ExerciseHistoryDay>>.broadcast(
      onListen: () {
        subscriptions.addAll(<StreamSubscription<Object?>>[
          _database
              .tableUpdates(TableUpdateQuery.onTable(_database.workouts))
              .listen((_) => schedule()),
          _database
              .tableUpdates(
                TableUpdateQuery.onTable(_database.workoutExercises),
              )
              .listen((_) => schedule()),
          _database
              .tableUpdates(TableUpdateQuery.onTable(_database.sets))
              .listen((_) => schedule()),
        ]);
        schedule();
      },
      onCancel: () async {
        closed = true;
        for (final StreamSubscription<Object?> sub in subscriptions) {
          await sub.cancel();
        }
      },
    );

    return controller.stream;
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

  /// Structural shell of a workout — the workout row plus its ordered
  /// exercises (workout-exercise rows + exercise definitions) without
  /// any per-set data. Used by the history detail screen so per-set
  /// edits don't rebuild the surrounding hero, exercise titles, and
  /// section labels.
  Future<WorkoutStructure> getWorkoutStructure(String workoutId) async {
    final WorkoutRow? workoutRow = await (_database.select(
      _database.workouts,
    )..where((tbl) => tbl.id.equals(workoutId))).getSingleOrNull();
    if (workoutRow == null) {
      throw WorkoutNotFoundException(workoutId);
    }
    final List<WorkoutExerciseRow> workoutExerciseRows =
        await _loadWorkoutExerciseRows(workoutId);
    final Map<String, ExerciseRow> exerciseMap = await _loadExerciseMap(
      workoutExerciseRows.map((row) => row.exerciseId).toList(growable: false),
    );
    return WorkoutStructure(
      workout: workoutRow.toModel(),
      exercises: List<WorkoutExerciseStructure>.unmodifiable(
        workoutExerciseRows.map(
          (WorkoutExerciseRow row) => WorkoutExerciseStructure(
            workoutExercise: row.toModel(),
            exercise: exerciseMap[row.exerciseId]!.toModel(),
          ),
        ),
      ),
    );
  }

  /// Streams the structural shell — listens only to the workouts,
  /// workout_exercises, and exercises tables. Set edits never wake this
  /// stream, so the screen's hero/section frames stay stable while the
  /// user tweaks RPE, set kind, or notes on individual sets.
  Stream<WorkoutStructure> watchWorkoutStructure(String workoutId) {
    late final StreamController<WorkoutStructure> controller;
    final List<StreamSubscription<Object?>> subscriptions =
        <StreamSubscription<Object?>>[];
    bool closed = false;
    bool loading = false;
    bool queued = false;

    Future<void> emit() async {
      if (closed) return;
      if (loading) {
        queued = true;
        return;
      }
      loading = true;
      try {
        controller.add(await getWorkoutStructure(workoutId));
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      } finally {
        loading = false;
      }
      if (queued && !closed) {
        queued = false;
        unawaited(emit());
      }
    }

    void scheduleEmit() => unawaited(emit());

    controller = StreamController<WorkoutStructure>.broadcast(
      onListen: () {
        subscriptions.addAll(<StreamSubscription<Object?>>[
          _database
              .tableUpdates(TableUpdateQuery.onTable(_database.workouts))
              .listen((_) => scheduleEmit()),
          _database
              .tableUpdates(
                TableUpdateQuery.onTable(_database.workoutExercises),
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
        for (final StreamSubscription<Object?> sub in subscriptions) {
          await sub.cancel();
        }
      },
    );

    return controller.stream.distinct(workoutStructuresStructurallyEqual);
  }

  /// Streams the completed-or-otherwise sets for a single workout-
  /// exercise, ordered by set number. Filtered Drift query — only emits
  /// when this exercise's sets actually change. Composed with the
  /// structure stream by the detail screen so a kind/RPE/note change on
  /// one exercise rebuilds only that card.
  Stream<List<WorkoutSet>> watchSetsForWorkoutExercise(
    String workoutExerciseId,
  ) {
    final Stream<List<WorkoutSet>> source =
        (_database.select(_database.sets)
              ..where(
                (tbl) => tbl.workoutExerciseId.equals(workoutExerciseId),
              )
              ..orderBy(<OrderingTerm Function(Sets)>[
                (tbl) => OrderingTerm(expression: tbl.setNumber),
              ]))
            .watch()
            .map(
              (List<WorkoutSetRow> rows) => List<WorkoutSet>.unmodifiable(
                rows.map((WorkoutSetRow row) => row.toModel()),
              ),
            );
    return source.distinct(
      (List<WorkoutSet> a, List<WorkoutSet> b) =>
          workoutSetListsStructurallyEqual(a, b),
    );
  }

  Stream<WorkoutDetail> watchWorkoutDetail(String workoutId) {
    // Dedupe: this stream listens to all four workout/exercise/set tables,
    // so a keystroke in any unrelated set wakes it up. Drop emissions where
    // the rebuilt detail is structurally identical to the previous one so
    // history-detail screens don't repaint while another workout is being
    // edited.
    return _watchWorkoutDetailRaw(
      workoutId,
    ).distinct(workoutDetailsStructurallyEqual);
  }

  Stream<WorkoutDetail> _watchWorkoutDetailRaw(String workoutId) {
    late final StreamController<WorkoutDetail> controller;
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
        controller.add(await getWorkoutById(workoutId));
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

    controller = StreamController<WorkoutDetail>.broadcast(
      onListen: () {
        subscriptions.addAll(<StreamSubscription<Object?>>[
          _database
              .tableUpdates(TableUpdateQuery.onTable(_database.workouts))
              .listen((_) => scheduleEmit()),
          _database
              .tableUpdates(
                TableUpdateQuery.onTable(_database.workoutExercises),
              )
              .listen((_) => scheduleEmit()),
          _database
              .tableUpdates(TableUpdateQuery.onTable(_database.sets))
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

    final List<WorkoutExerciseDetail> exercises = workoutExerciseRows
        .map((row) {
          return WorkoutExerciseDetail(
            workoutExercise: row.toModel(),
            exercise: exerciseMap[row.exerciseId]!.toModel(),
            sets: setsByWorkoutExerciseId[row.id] ?? const <WorkoutSet>[],
          );
        })
        .toList(growable: false);

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

    final List<WorkoutSetRow> setRows =
        await (_database.select(_database.sets)
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

/// Structural equality for `List<ExerciseHistoryDay>`. Models in this app
/// don't override `==`, so we compare the fields that actually drive
/// downstream rendering. Used as the predicate for `Stream.distinct` so
/// unrelated table updates don't wake history-driven UI on every keystroke.
bool exerciseHistoryDayListsStructurallyEqual(
  List<ExerciseHistoryDay> a,
  List<ExerciseHistoryDay> b,
) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    final ExerciseHistoryDay x = a[i];
    final ExerciseHistoryDay y = b[i];
    if (x.workoutId != y.workoutId) return false;
    if (x.workoutName != y.workoutName) return false;
    if (x.workoutStartedAt != y.workoutStartedAt) return false;
    if (x.date != y.date) return false;
    if (!_workoutSetListsEqual(x.sets, y.sets)) return false;
  }
  return true;
}

/// Structural equality for `List<PrEvent>`.
bool prEventListsStructurallyEqual(List<PrEvent> a, List<PrEvent> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    final PrEvent x = a[i];
    final PrEvent y = b[i];
    if (x.type != y.type) return false;
    if (x.exerciseId != y.exerciseId) return false;
    if (x.exerciseName != y.exerciseName) return false;
    if (x.exerciseType != y.exerciseType) return false;
    if (x.setId != y.setId) return false;
    if (x.workoutId != y.workoutId) return false;
    if (x.weightKg != y.weightKg) return false;
    if (x.reps != y.reps) return false;
    if (x.distanceKm != y.distanceKm) return false;
    if (x.durationSeconds != y.durationSeconds) return false;
    if (x.oneRepMaxKg != y.oneRepMaxKg) return false;
    if (x.repCountForRepMax != y.repCountForRepMax) return false;
    if (x.achievedAt != y.achievedAt) return false;
  }
  return true;
}

/// Internal: tracks the per-exercise running best set (heaviest weight,
/// tiebreak more reps) for [WorkoutRepository._buildPrEventsFromRows].
class _BestSet {
  const _BestSet({required this.weightKg, required this.reps});
  final double weightKg;
  final int reps;
}

/// Structural equality for `WorkoutStructure` — workout fields plus the
/// per-exercise pair (workout-exercise + exercise definition). Ignores
/// per-set data; the sets stream is responsible for its own dedupe.
bool workoutStructuresStructurallyEqual(
  WorkoutStructure a,
  WorkoutStructure b,
) {
  if (identical(a, b)) return true;
  if (!_workoutsEqual(a.workout, b.workout)) return false;
  if (a.exercises.length != b.exercises.length) return false;
  for (int i = 0; i < a.exercises.length; i++) {
    final WorkoutExerciseStructure x = a.exercises[i];
    final WorkoutExerciseStructure y = b.exercises[i];
    if (!_workoutExercisesEqual(x.workoutExercise, y.workoutExercise)) {
      return false;
    }
    if (!_exercisesEqual(x.exercise, y.exercise)) return false;
  }
  return true;
}

/// Structural equality for `List<WorkoutSet>` — public wrapper around
/// the private list helper so callers (and `Stream.distinct` predicates)
/// can use it without reaching for internals.
bool workoutSetListsStructurallyEqual(List<WorkoutSet> a, List<WorkoutSet> b) {
  return _workoutSetListsEqual(a, b);
}

/// Structural equality for `WorkoutDetail`.
bool workoutDetailsStructurallyEqual(WorkoutDetail a, WorkoutDetail b) {
  if (identical(a, b)) return true;
  if (!_workoutsEqual(a.workout, b.workout)) return false;
  if (a.exercises.length != b.exercises.length) return false;
  for (int i = 0; i < a.exercises.length; i++) {
    final WorkoutExerciseDetail x = a.exercises[i];
    final WorkoutExerciseDetail y = b.exercises[i];
    if (!_workoutExercisesEqual(x.workoutExercise, y.workoutExercise)) {
      return false;
    }
    if (!_exercisesEqual(x.exercise, y.exercise)) return false;
    if (!_workoutSetListsEqual(x.sets, y.sets)) return false;
  }
  return true;
}

bool _workoutSetListsEqual(List<WorkoutSet> a, List<WorkoutSet> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (!_workoutSetsEqual(a[i], b[i])) return false;
  }
  return true;
}

bool _workoutSetsEqual(WorkoutSet a, WorkoutSet b) {
  return a.id == b.id &&
      a.workoutExerciseId == b.workoutExerciseId &&
      a.setNumber == b.setNumber &&
      a.weightKg == b.weightKg &&
      a.reps == b.reps &&
      a.distanceKm == b.distanceKm &&
      a.durationSeconds == b.durationSeconds &&
      a.completed == b.completed &&
      a.completedAt == b.completedAt &&
      a.updatedAt == b.updatedAt &&
      a.startedAt == b.startedAt &&
      a.kind == b.kind &&
      a.parentSetId == b.parentSetId &&
      a.rpe == b.rpe &&
      a.note == b.note;
}

bool _workoutsEqual(Workout a, Workout b) {
  return a.id == b.id &&
      a.startedAt == b.startedAt &&
      a.endedAt == b.endedAt &&
      a.templateId == b.templateId &&
      a.notes == b.notes &&
      a.name == b.name &&
      a.intensityScore == b.intensityScore;
}

bool _workoutExercisesEqual(WorkoutExercise a, WorkoutExercise b) {
  return a.id == b.id &&
      a.workoutId == b.workoutId &&
      a.exerciseId == b.exerciseId &&
      a.orderIndex == b.orderIndex &&
      a.createdAt == b.createdAt &&
      a.notes == b.notes;
}

bool _exercisesEqual(Exercise a, Exercise b) {
  // Skip thumbnailBytes — bytes equality is expensive and a thumbnail
  // change always produces a fresh row that bumps updatedAt anyway.
  return a.id == b.id &&
      a.name == b.name &&
      a.type == b.type &&
      a.muscleGroup == b.muscleGroup &&
      a.thumbnailPath == b.thumbnailPath &&
      a.isDefault == b.isDefault &&
      a.createdAt == b.createdAt &&
      a.updatedAt == b.updatedAt &&
      a.defaultRestSeconds == b.defaultRestSeconds;
}
