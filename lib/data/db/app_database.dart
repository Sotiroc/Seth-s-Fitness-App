import 'package:drift/drift.dart';

import '../models/exercise_type.dart';
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

@DataClassName('ExerciseRow')
class Exercises extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  TextColumn get type => text().map(const ExerciseTypeConverter())();

  TextColumn get thumbnailPath => text().nullable()();

  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

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

@DriftDatabase(
  tables: <Type>[
    Exercises,
    WorkoutTemplates,
    TemplateExercises,
    Workouts,
    WorkoutExercises,
    Sets,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() => openAppDatabaseConnection();
