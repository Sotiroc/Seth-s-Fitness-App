import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../db/app_database.dart';
import '../db/database_providers.dart';
import '../models/database_mappers.dart';
import '../models/exercise_pack.dart';

part 'exercise_pack_repository.g.dart';

@Riverpod(keepAlive: true)
ExercisePackRepository exercisePackRepository(Ref ref) {
  return ExercisePackRepository(database: ref.watch(appDatabaseProvider));
}

class ExercisePackRepository {
  ExercisePackRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  /// All installed packs in manifest order (asc by name as a stable
  /// secondary sort — caller can reorder if needed).
  Future<List<ExercisePack>> getAllPacks() async {
    final List<ExercisePackRow> rows =
        await (_database.select(_database.exercisePacks)
              ..orderBy(<OrderingTerm Function(ExercisePacks)>[
                (tbl) => OrderingTerm(expression: tbl.name),
              ]))
            .get();
    return rows.map((row) => row.toModel()).toList(growable: false);
  }

  Stream<List<ExercisePack>> watchAllPacks() {
    return (_database.select(_database.exercisePacks)
          ..orderBy(<OrderingTerm Function(ExercisePacks)>[
            (tbl) => OrderingTerm(expression: tbl.name),
          ]))
        .watch()
        .map((items) =>
            items.map((row) => row.toModel()).toList(growable: false));
  }

  Future<ExercisePack?> getPackById(String packId) async {
    final ExercisePackRow? row = await (_database.select(
      _database.exercisePacks,
    )..where((tbl) => tbl.id.equals(packId))).getSingleOrNull();
    return row?.toModel();
  }

  /// Returns the ids of every active pack. The picker and library list
  /// use this to filter out exercises whose pack the user has turned off.
  Future<Set<String>> getActivePackIds() async {
    final List<ExercisePackRow> rows = await (_database.select(
      _database.exercisePacks,
    )..where((tbl) => tbl.isActive.equals(true))).get();
    return rows.map((row) => row.id).toSet();
  }

  Stream<Set<String>> watchActivePackIds() {
    return (_database.select(_database.exercisePacks)
          ..where((tbl) => tbl.isActive.equals(true)))
        .watch()
        .map((items) => items.map((row) => row.id).toSet());
  }

  /// Inserts the pack row if missing, refreshes its metadata otherwise.
  /// Preserves the [isActive] flag — once a user toggles a pack off, a
  /// re-import on the next launch must not silently turn it back on.
  Future<void> upsertPack({
    required String id,
    required String name,
    required String description,
    required String credit,
    required String license,
    required String assetPath,
    required int schemaVersion,
    required int exerciseCount,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final ExercisePackRow? existing = await (_database.select(
      _database.exercisePacks,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    if (existing == null) {
      await _database.into(_database.exercisePacks).insert(
            ExercisePacksCompanion.insert(
              id: id,
              name: name,
              description: description,
              credit: credit,
              license: license,
              assetPath: assetPath,
              schemaVersion: schemaVersion,
              exerciseCount: Value<int>(exerciseCount),
              installedAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (_database.update(_database.exercisePacks)
            ..where((tbl) => tbl.id.equals(id)))
          .write(
        ExercisePacksCompanion(
          name: Value<String>(name),
          description: Value<String>(description),
          credit: Value<String>(credit),
          license: Value<String>(license),
          assetPath: Value<String>(assetPath),
          schemaVersion: Value<int>(schemaVersion),
          exerciseCount: Value<int>(exerciseCount),
          updatedAt: Value<DateTime>(now),
        ),
      );
    }
  }

  Future<void> setPackActive({
    required String packId,
    required bool isActive,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    await (_database.update(_database.exercisePacks)
          ..where((tbl) => tbl.id.equals(packId)))
        .write(
      ExercisePacksCompanion(
        isActive: Value<bool>(isActive),
        updatedAt: Value<DateTime>(now),
      ),
    );
  }
}
