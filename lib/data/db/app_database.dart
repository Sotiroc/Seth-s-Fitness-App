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

  /// Equipment label as supplied by the source pack
  /// (e.g. 'barbell', 'body only'). Null for user-created exercises and
  /// rows imported before this column existed.
  TextColumn get equipment => text().nullable()();

  /// Movement force from the source pack: 'push' | 'pull' | 'static'.
  TextColumn get force => text().nullable()();

  /// Difficulty from the source pack: 'beginner' | 'intermediate' | 'expert'.
  TextColumn get level => text().nullable()();

  /// Mechanic from the source pack: 'compound' | 'isolation'.
  TextColumn get mechanic => text().nullable()();

  /// Source category (matches the pack id for library entries:
  /// 'strength', 'cardio', 'stretching', 'plyometrics', 'powerlifting',
  /// 'strongman', 'olympic weightlifting').
  TextColumn get category => text().nullable()();

  /// JSON-encoded `List<String>` of source primary muscle labels.
  TextColumn get primaryMusclesJson => text().nullable()();

  /// JSON-encoded `List<String>` of source secondary muscle labels.
  TextColumn get secondaryMusclesJson => text().nullable()();

  /// JSON-encoded `List<String>` of multi-step form instructions.
  TextColumn get instructionsJson => text().nullable()();

  /// Pack id this exercise was imported from (e.g. 'strength'). Null for
  /// user-created exercises and the legacy starter set.
  TextColumn get sourcePackId => text().nullable()();

  /// Stable id within the source pack (e.g. 'Barbell_Bench_Press_-_Medium_Grip').
  /// Null for user-created exercises and the legacy starter set.
  TextColumn get sourceExerciseId => text().nullable()();

  /// True when the exercise should be hidden from pickers and the library
  /// list. Used to retire the legacy 18 starters once their references
  /// have been remapped to library entries — the rows stay so any
  /// remaining history references continue to resolve.
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Registry of installed exercise packs. One row per pack — populated by
/// the pack importer on first launch and on every pack file update.
@DataClassName('ExercisePackRow')
class ExercisePacks extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get description => text()();

  TextColumn get credit => text()();

  TextColumn get license => text()();

  TextColumn get assetPath => text()();

  /// On/off toggle. Inactive packs hide their exercises from the library
  /// list and the add-exercise picker. Past workout history is unaffected.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Pack file's `schemaVersion` at import time. Lets future versions
  /// detect upgrade scenarios without scanning every row.
  IntColumn get schemaVersion => integer()();

  IntColumn get exerciseCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get installedAt => dateTime()();

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
    ExercisePacks,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_weight_entries_measured_at '
        'ON weight_entries (measured_at)',
      );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(workouts, workouts.name);
      }
      if (from < 3) {
        await m.addColumn(exercises, exercises.muscleGroup);
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
      if (from < 4) {
        await m.addColumn(exercises, exercises.thumbnailBytes);
      }
      if (from < 5) {
        await m.createTable(userProfiles);
      }
      if (from < 6) {
        await m.addColumn(workouts, workouts.intensityScore);
      }
      if (from < 7) {
        await m.addColumn(userProfiles, userProfiles.muscleGoalsJson);
      }
      if (from < 8) {
        await m.createTable(weightEntries);
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
        await m.addColumn(sets, sets.completedAt);
        await m.addColumn(sets, sets.updatedAt);
        await m.addColumn(workoutExercises, workoutExercises.createdAt);
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
        await m.addColumn(exercises, exercises.defaultRestSeconds);
        await m.addColumn(sets, sets.startedAt);
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
        await m.addColumn(sets, sets.kind);
        await m.addColumn(sets, sets.parentSetId);
        await m.addColumn(sets, sets.rpe);
        await m.addColumn(sets, sets.note);
      }
      if (from < 12) {
        // Richer fields imported from public-domain library packs, plus
        // the pack registry table. Existing 18 starter rows keep
        // sourcePackId = null and hidden = false until the pack importer
        // remaps their references and flips them hidden.
        await m.addColumn(exercises, exercises.equipment);
        await m.addColumn(exercises, exercises.force);
        await m.addColumn(exercises, exercises.level);
        await m.addColumn(exercises, exercises.mechanic);
        await m.addColumn(exercises, exercises.category);
        await m.addColumn(exercises, exercises.primaryMusclesJson);
        await m.addColumn(exercises, exercises.secondaryMusclesJson);
        await m.addColumn(exercises, exercises.instructionsJson);
        await m.addColumn(exercises, exercises.sourcePackId);
        await m.addColumn(exercises, exercises.sourceExerciseId);
        await m.addColumn(exercises, exercises.hidden);
        await m.createTable(exercisePacks);
      }
    },
  );
}

QueryExecutor _openConnection() => openAppDatabaseConnection();
