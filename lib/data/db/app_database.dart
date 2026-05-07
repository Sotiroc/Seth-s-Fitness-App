import 'package:drift/drift.dart';

import '../models/exercise_muscle_group.dart';
import '../models/exercise_type.dart';
import '../models/gender.dart';
import '../models/unit_system.dart';
import '../seed/default_exercises.dart';
import 'database_connection.dart';

part 'app_database.g.dart';

class ExerciseTypeConverter extends TypeConverter<ExerciseType, String> {
  const ExerciseTypeConverter();

  @override
  ExerciseType fromSql(String fromDb) {
    return ExerciseType.values.firstWhere((value) => value.name == fromDb);
  }

  @override
  String toSql(ExerciseType value) => value.name;
}

class ExerciseMuscleGroupConverter
    extends TypeConverter<ExerciseMuscleGroup, String> {
  const ExerciseMuscleGroupConverter();

  @override
  ExerciseMuscleGroup fromSql(String fromDb) {
    return ExerciseMuscleGroup.values.firstWhere(
      (value) => value.name == fromDb,
    );
  }

  @override
  String toSql(ExerciseMuscleGroup value) => value.name;
}

class GenderConverter extends TypeConverter<Gender, String> {
  const GenderConverter();

  @override
  Gender fromSql(String fromDb) {
    return Gender.values.firstWhere((value) => value.name == fromDb);
  }

  @override
  String toSql(Gender value) => value.name;
}

class UnitSystemConverter extends TypeConverter<UnitSystem, String> {
  const UnitSystemConverter();

  @override
  UnitSystem fromSql(String fromDb) {
    return UnitSystem.values.firstWhere((value) => value.name == fromDb);
  }

  @override
  String toSql(UnitSystem value) => value.name;
}

@DataClassName('ExerciseRow')
class Exercises extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  TextColumn get type => text().map(const ExerciseTypeConverter())();

  TextColumn get muscleGroup => text()
      .map(const ExerciseMuscleGroupConverter())
      .withDefault(const Constant('cardio'))();

  TextColumn get thumbnailPath => text().nullable()();

  BlobColumn get thumbnailBytes => blob().nullable()();

  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// Optional per-exercise rest-timer override in whole seconds. Null falls
  /// back to type-based defaults (weighted=120, bodyweight=60, cardio=0/
  /// disabled). 0 explicitly disables the rest timer for this exercise.
  IntColumn get defaultRestSeconds => integer().nullable()();

  /// Comma-separated list of `CardioMetric` enum names. Only meaningful
  /// for cardio exercises — drives which input fields the set row
  /// renders (e.g. `duration` for boxing, `laps,duration` for swimming).
  /// Null on cardio rows means "use the legacy default" (distance +
  /// duration). Always null for non-cardio rows.
  TextColumn get trackedMetrics => text().nullable()();

  /// Equipment classification (`barbell`, `dumbbell`, `machine`, …). Used
  /// by the equipment filter chip on the library screen and shown in the
  /// editor as a small dropdown. Null on legacy rows until the user
  /// edits the exercise.
  TextColumn get equipment => text().nullable()();

  /// Optional one-line form cue (~80 chars, e.g. "Drive feet, retract
  /// shoulders, bar to lower chest"). Renders as quiet text under the
  /// exercise name on the library card and inside the active-workout
  /// exercise picker.
  TextColumn get formCue => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('WorkoutTemplateRow')
class WorkoutTemplates extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('TemplateExerciseRow')
class TemplateExercises extends Table {
  TextColumn get id => text()();

  TextColumn get templateId =>
      text().references(WorkoutTemplates, #id, onDelete: KeyAction.cascade)();

  TextColumn get exerciseId => text().references(Exercises, #id)();

  IntColumn get orderIndex => integer()();

  IntColumn get defaultSets => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('WorkoutRow')
class Workouts extends Table {
  TextColumn get id => text()();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get endedAt => dateTime().nullable()();

  TextColumn get templateId => text().nullable().references(
    WorkoutTemplates,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get notes => text().nullable()();

  /// User-assigned display name for the session (e.g. "Leg day – light").
  /// Nullable — falls back to a date/template label in the UI.
  TextColumn get name => text().nullable()();

  /// Optional 1–10 session RPE captured on the summary screen. Null means
  /// the user skipped it. Stored unrestricted; the repository clamps inputs
  /// to the 1..10 range.
  IntColumn get intensityScore => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('WorkoutExerciseRow')
class WorkoutExercises extends Table {
  TextColumn get id => text()();

  TextColumn get workoutId =>
      text().references(Workouts, #id, onDelete: KeyAction.cascade)();

  TextColumn get exerciseId => text().references(Exercises, #id)();

  IntColumn get orderIndex => integer()();

  /// Wall-clock time the exercise was added to the workout. Used (alongside
  /// `Sets.updatedAt`) to derive when the user was last active in this
  /// workout for the auto-close-stale-workout flow. Nullable because
  /// pre-v9 rows are backfilled to the parent workout's `startedAt`.
  DateTimeColumn get createdAt => dateTime().nullable()();

  /// Optional free-text note attached to this exercise *within this workout*
  /// (e.g. "left shoulder felt tight on bench"). Distinct from the global
  /// exercise definition — lives on the workout-exercise instance so it
  /// only surfaces alongside the session it was written in. Trimmed at
  /// write time; null/empty means "no note".
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('WorkoutSetRow')
class Sets extends Table {
  TextColumn get id => text()();

  TextColumn get workoutExerciseId =>
      text().references(WorkoutExercises, #id, onDelete: KeyAction.cascade)();

  IntColumn get setNumber => integer()();

  RealColumn get weightKg => real().nullable()();

  IntColumn get reps => integer().nullable()();

  RealColumn get distanceKm => real().nullable()();

  IntColumn get durationSeconds => integer().nullable()();

  /// Pool laps for swimming sets. Cardio-only; populated when the
  /// parent exercise's `trackedMetrics` includes `laps`.
  IntColumn get laps => integer().nullable()();

  /// Floors / flights climbed for stair-master sets. Cardio-only;
  /// populated when the parent exercise's `trackedMetrics` includes
  /// `floors`.
  IntColumn get floors => integer().nullable()();

  /// Manually-entered calorie count. Optional add-on for any cardio
  /// exercise that opts into the `calories` metric.
  IntColumn get calories => integer().nullable()();

  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  /// Wall-clock time the set was marked completed. Set when `completed`
  /// transitions false→true; cleared when transitions back to false. Used
  /// as the `endedAt` timestamp when the workout is auto-closed for
  /// inactivity, so the recorded duration reflects actual training time
  /// rather than the wall-clock gap until the next app launch.
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Wall-clock time of the most recent insert/update on this set. Bumped
  /// on every mutation regardless of completion state, so even editing an
  /// uncompleted set's weight counts as activity for the inactivity timer.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// Wall-clock time the user first interacted with this set (first edit
  /// of any field, or first completion). Recorded regardless of the rest-
  /// timer toggle so set-by-set timing metadata is always available for
  /// future analytics. Once captured, it sticks: re-saves never move it.
  DateTimeColumn get startedAt => dateTime().nullable()();

  /// Set classification: 'normal' | 'warmUp' | 'drop' | 'failure'. Stored
  /// as a string for forward-compatibility with future kinds; the model
  /// decodes tolerantly so unknown values fall back to normal. Volume,
  /// completion counters, and PR detection branch on this.
  TextColumn get kind =>
      text().withDefault(const Constant('normal'))();

  /// Only populated when [kind] = 'drop'. Points at the parent working
  /// set this drop belongs to so the UI can indent and the PREVIOUS
  /// reference can render the drop chain. Stored without an FK reference
  /// because the parent lives in the same table; cascade is handled by
  /// the parent's workoutExercise cascade and an explicit cleanup in the
  /// repository's deleteWorkoutSet.
  TextColumn get parentSetId => text().nullable()();

  /// Optional 1–10 per-set RPE. Independent of the per-workout
  /// intensityScore on Workouts. Repository clamps inputs to 1..10.
  IntColumn get rpe => integer().nullable()();

  /// Optional free-text per-set note. Trimmed at write time; null/empty
  /// means "no note".
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();

  TextColumn get value => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

/// History of body-weight measurements, written either by the explicit
/// "Log weight" sheet on the Progression page (`source = 'manual'`), by
/// the profile editor when the user changes their weight there
/// (`source = 'profile'`, deduped per-day via deterministic id), or by
/// the v8 migration that seeds the user's existing profile weight as a
/// single starting point (`source = 'backfill'`).
@DataClassName('WeightEntryRow')
class WeightEntries extends Table {
  TextColumn get id => text()();

  /// UTC timestamp the user is logging the measurement *for*. Defaults to
  /// "now" but the quick-log sheet lets the user pick a past date.
  DateTimeColumn get measuredAt => dateTime()();

  RealColumn get weightKg => real()();

  /// `'manual'` | `'profile'` | `'backfill'`. Stored as a string for
  /// forward-compatibility; the model decodes tolerantly.
  TextColumn get source =>
      text().withDefault(const Constant('manual'))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  TextColumn get id => text().withDefault(const Constant('me'))();

  TextColumn get name => text().withLength(min: 1, max: 60).nullable()();

  IntColumn get ageYears => integer().nullable()();

  TextColumn get gender => text().map(const GenderConverter()).nullable()();

  RealColumn get heightCm => real().nullable()();

  RealColumn get weightKg => real().nullable()();

  RealColumn get goalWeightKg => real().nullable()();

  RealColumn get bodyFatPercent => real().nullable()();

  BoolColumn get diabetic => boolean().nullable()();

  TextColumn get muscleGroupPriority =>
      text().map(const ExerciseMuscleGroupConverter()).nullable()();

  /// JSON-encoded `Map<ExerciseMuscleGroup, int>` of weekly set goals.
  /// Null means the user has not configured goals — the UI falls back to
  /// the default per-muscle targets in `muscle_goals_provider.dart`.
  TextColumn get muscleGoalsJson => text().nullable()();

  TextColumn get unitSystem => text()
      .map(const UnitSystemConverter())
      .withDefault(const Constant('metric'))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// One persisted weekly summary. Generated automatically once per week
/// (app-open check) for any completed week the user logged at least one
/// workout in. Past recaps are immutable snapshots — later edits to the
/// underlying workouts do NOT mutate already-generated recaps so the
/// shareable card stays consistent over time.
@DataClassName('WeeklyRecapRow')
class WeeklyRecaps extends Table {
  TextColumn get id => text()();

  /// UTC timestamp of the start of the local week the recap covers
  /// (Monday 00:00 local, converted to UTC at write time). Unique with
  /// `weekEnd` — both stored so reads don't have to recompute the range.
  DateTimeColumn get weekStart => dateTime()();

  /// UTC timestamp marking the exclusive end of the recap window (the
  /// following Monday 00:00 local, in UTC).
  DateTimeColumn get weekEnd => dateTime()();

  /// Number of workouts whose `startedAt` fell inside the window.
  IntColumn get workoutCount => integer()();

  /// Total kg moved across every completed, non-warmup, weighted set in
  /// the window. Stored canonical (kg) — UI converts to user units.
  RealColumn get totalVolumeKg => real()();

  /// Sum of (endedAt − startedAt) across the workouts in the window, in
  /// seconds. Active or unfinished workouts contribute 0.
  IntColumn get totalDurationSeconds => integer()();

  /// Mean of the 1–10 session intensity scores recorded on the workouts
  /// in this window. Null when no workout had an intensityScore set.
  RealColumn get averageRpe => real().nullable()();

  /// Quick scalar so the home card can show "1 PR" without decoding json.
  IntColumn get prCount => integer()();

  /// JSON-encoded list of `{exerciseName, type, weightKg?, reps?,
  /// distanceKm?, durationSeconds?, oneRepMaxKg?, repCountForRepMax?}`.
  /// Captured at generation time so later set/exercise edits don't
  /// silently mutate the recap card.
  TextColumn get prsJson => text().nullable()();

  /// JSON-encoded `List<double>` of length 7 — daily kg volume Mon→Sun
  /// for the small line chart. Stored to keep historic recaps reproducible.
  TextColumn get dailyVolumeKgJson => text()();

  /// Workout count for the immediately-preceding week. Null means the
  /// previous week was outside the user's logged history (no comparison
  /// shown). Stored at generation time so the comparison stays stable.
  IntColumn get prevWorkoutCount => integer().nullable()();

  /// Total kg volume for the immediately-preceding week. Null when no
  /// previous-week data was available.
  RealColumn get prevTotalVolumeKg => real().nullable()();

  DateTimeColumn get generatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DriftDatabase(
  tables: <Type>[
    Exercises,
    WorkoutTemplates,
    TemplateExercises,
    Workouts,
    WorkoutExercises,
    Sets,
    AppSettings,
    UserProfiles,
    WeightEntries,
    WeeklyRecaps,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createHotPathIndexes();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Web (Drift + IndexedDbFileSystem) can end up with a database whose
      // user_version PRAGMA is behind the actual schema — e.g. a partially
      // applied migration or a deploy where the table definition added a
      // column before the matching migration step landed. Re-running the
      // raw addColumn / createTable would then throw "duplicate column" /
      // "table already exists" and brick boot. Guarding every step with
      // a pragma check makes onUpgrade safely re-runnable.
      Future<void> addColumnIfMissing(
        String tableName,
        String columnName,
        TableInfo<Table, dynamic> table,
        GeneratedColumn<Object> column,
      ) async {
        if (await _columnExists(tableName, columnName)) return;
        await m.addColumn(table, column);
      }

      Future<void> createTableIfMissing(
        String tableName,
        TableInfo<Table, dynamic> table,
      ) async {
        if (await _tableExists(tableName)) return;
        await m.createTable(table);
      }

      if (from < 2) {
        await addColumnIfMissing('workouts', 'name', workouts, workouts.name);
      }
      if (from < 3) {
        final bool addedMuscleGroup =
            !await _columnExists('exercises', 'muscle_group');
        await addColumnIfMissing(
          'exercises',
          'muscle_group',
          exercises,
          exercises.muscleGroup,
        );
        if (addedMuscleGroup) {
          await customStatement('''
            UPDATE exercises
            SET muscle_group = CASE
              WHEN type = 'cardio' THEN 'cardio'
              ELSE 'chest'
            END
            ''');
          for (final DefaultExerciseSeed seed in defaultExerciseSeeds) {
            await (update(
              exercises,
            )..where((tbl) => tbl.id.equals(seed.id))).write(
              ExercisesCompanion(
                muscleGroup: Value<ExerciseMuscleGroup>(seed.muscleGroup),
              ),
            );
          }
        }
      }
      if (from < 4) {
        await addColumnIfMissing(
          'exercises',
          'thumbnail_bytes',
          exercises,
          exercises.thumbnailBytes,
        );
      }
      if (from < 5) {
        await createTableIfMissing('user_profiles', userProfiles);
      }
      if (from < 6) {
        await addColumnIfMissing(
          'workouts',
          'intensity_score',
          workouts,
          workouts.intensityScore,
        );
      }
      if (from < 7) {
        await addColumnIfMissing(
          'user_profiles',
          'muscle_goals_json',
          userProfiles,
          userProfiles.muscleGoalsJson,
        );
      }
      if (from < 8) {
        await createTableIfMissing('weight_entries', weightEntries);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_weight_entries_measured_at '
          'ON weight_entries (measured_at)',
        );
        // Backfill: seed an existing profile weight as a single starting
        // point so the chart isn't empty on first launch after upgrade.
        // Deterministic id keeps this idempotent if the migration is
        // ever re-run on a clean schema.
        final List<UserProfileRow> profileRows =
            await select(userProfiles).get();
        if (profileRows.isNotEmpty) {
          final UserProfileRow row = profileRows.first;
          if (row.weightKg != null) {
            await into(weightEntries).insertOnConflictUpdate(
              WeightEntriesCompanion.insert(
                id: 'backfill-${row.id}',
                measuredAt: row.createdAt,
                weightKg: row.weightKg!,
                source: const Value<String>('backfill'),
                createdAt: DateTime.now().toUtc(),
              ),
            );
          }
        }
      }
      if (from < 9) {
        await addColumnIfMissing(
          'sets',
          'completed_at',
          sets,
          sets.completedAt,
        );
        await addColumnIfMissing(
          'sets',
          'updated_at',
          sets,
          sets.updatedAt,
        );
        await addColumnIfMissing(
          'workout_exercises',
          'created_at',
          workoutExercises,
          workoutExercises.createdAt,
        );
        // Backfill so the auto-close-stale-workout flow has sensible
        // "last activity" timestamps for pre-upgrade rows. Completed sets
        // get the parent workout's endedAt as their completion time
        // (best available proxy). updatedAt falls back to completedAt or
        // the workout's startedAt. Exercises get the workout's startedAt.
        await customStatement('''
          UPDATE sets
          SET completed_at = (
            SELECT w.ended_at
            FROM workouts w
            INNER JOIN workout_exercises we ON we.workout_id = w.id
            WHERE we.id = sets.workout_exercise_id
          )
          WHERE completed = 1
        ''');
        await customStatement('''
          UPDATE sets
          SET updated_at = COALESCE(completed_at, (
            SELECT w.started_at
            FROM workouts w
            INNER JOIN workout_exercises we ON we.workout_id = w.id
            WHERE we.id = sets.workout_exercise_id
          ))
        ''');
        await customStatement('''
          UPDATE workout_exercises
          SET created_at = (
            SELECT w.started_at
            FROM workouts w
            WHERE w.id = workout_exercises.workout_id
          )
        ''');
      }
      if (from < 10) {
        await addColumnIfMissing(
          'exercises',
          'default_rest_seconds',
          exercises,
          exercises.defaultRestSeconds,
        );
        await addColumnIfMissing(
          'sets',
          'started_at',
          sets,
          sets.startedAt,
        );
        // Best-proxy backfill for existing rows: prefer completedAt (a clear
        // interaction signal) and fall back to updatedAt (most recent edit).
        // defaultRestSeconds is intentionally left null on existing exercises
        // so the type-based fallback applies until users opt in per exercise.
        await customStatement('''
          UPDATE sets
          SET started_at = COALESCE(completed_at, updated_at)
          WHERE started_at IS NULL
        ''');
      }
      if (from < 11) {
        // Per-set kind (warm-up / drop / failure / normal), parent link
        // for drop sets, optional 1–10 RPE, and optional note. All
        // existing rows inherit kind = 'normal' via the column default.
        await addColumnIfMissing('sets', 'kind', sets, sets.kind);
        await addColumnIfMissing(
          'sets',
          'parent_set_id',
          sets,
          sets.parentSetId,
        );
        await addColumnIfMissing('sets', 'rpe', sets, sets.rpe);
        await addColumnIfMissing('sets', 'note', sets, sets.note);
      }
      if (from < 12) {
        // Per-exercise (per workout-exercise instance) free-text note.
        // Existing rows leave notes NULL; users add them via the active
        // workout screen "+ Note" affordance.
        await addColumnIfMissing(
          'workout_exercises',
          'notes',
          workoutExercises,
          workoutExercises.notes,
        );
      }
      if (from < 13) {
        // Indexes on hot-path foreign-key and date columns. Without these
        // SQLite full-scans on every history/progression/active-workout
        // lookup. CREATE INDEX IF NOT EXISTS keeps this idempotent for
        // databases that already have idx_weight_entries_measured_at.
        await _createHotPathIndexes();
      }
      if (from < 14) {
        // Persisted weekly recap snapshots. Generation runs on app open;
        // existing users get an empty table and the first generation pass
        // backfills any complete week they have workouts in.
        await createTableIfMissing('weekly_recaps', weeklyRecaps);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_weekly_recaps_week_start '
          'ON weekly_recaps (week_start)',
        );
      }
      if (from < 15) {
        // Per-exercise cardio metrics + equipment + form cue on Exercises;
        // laps / floors / calories on Sets to back the new metrics. Every
        // existing exercise leaves the new columns null — the resolver in
        // Exercise.resolveCardioMetrics() falls back to distance+duration
        // for cardio rows so the legacy behaviour is unchanged.
        await addColumnIfMissing(
          'exercises',
          'tracked_metrics',
          exercises,
          exercises.trackedMetrics,
        );
        await addColumnIfMissing(
          'exercises',
          'equipment',
          exercises,
          exercises.equipment,
        );
        await addColumnIfMissing(
          'exercises',
          'form_cue',
          exercises,
          exercises.formCue,
        );
        await addColumnIfMissing('sets', 'laps', sets, sets.laps);
        await addColumnIfMissing('sets', 'floors', sets, sets.floors);
        await addColumnIfMissing('sets', 'calories', sets, sets.calories);
      }
    },
  );

  Future<bool> _columnExists(String tableName, String columnName) async {
    final List<QueryRow> rows = await customSelect(
      'PRAGMA table_info(${_quoteIdent(tableName)})',
    ).get();
    for (final QueryRow row in rows) {
      if (row.read<String>('name') == columnName) return true;
    }
    return false;
  }

  Future<bool> _tableExists(String tableName) async {
    final List<QueryRow> rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: <Variable<Object>>[Variable<String>(tableName)],
    ).get();
    return rows.isNotEmpty;
  }

  String _quoteIdent(String identifier) =>
      '"${identifier.replaceAll('"', '""')}"';

  Future<void> _createHotPathIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sets_workout_exercise_id '
      'ON sets (workout_exercise_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_workout_exercises_workout_id '
      'ON workout_exercises (workout_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_workout_exercises_exercise_id '
      'ON workout_exercises (exercise_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_workouts_started_at '
      'ON workouts (started_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_workouts_ended_at '
      'ON workouts (ended_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_weight_entries_measured_at '
      'ON weight_entries (measured_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_weekly_recaps_week_start '
      'ON weekly_recaps (week_start)',
    );
  }
}

QueryExecutor _openConnection() => openAppDatabaseConnection();
