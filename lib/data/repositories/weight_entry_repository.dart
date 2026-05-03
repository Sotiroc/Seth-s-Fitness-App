import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/database_providers.dart';
import '../models/database_mappers.dart';
import '../models/weight_entry.dart';

part 'weight_entry_repository.g.dart';

@Riverpod(keepAlive: true)
WeightEntryRepository weightEntryRepository(Ref ref) {
  return WeightEntryRepository(database: ref.watch(appDatabaseProvider));
}

/// Drift-backed CRUD for the body-weight history powering the Progression
/// chart. Inserts come from three sources — the explicit "Log weight" sheet
/// ([logEntry]), the profile editor ([upsertProfileEntry], deduped per
/// local day so repeated edits in one day overwrite the same point), and
/// the v8 migration backfill (handled directly in the migration).
class WeightEntryRepository {
  WeightEntryRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  /// Insert a new manual or profile-sourced entry. [measuredAt] defaults
  /// to "now" (UTC) so callers without a date picker don't have to think
  /// about it.
  Future<WeightEntry> logEntry({
    required double weightKg,
    DateTime? measuredAt,
    WeightEntrySource source = WeightEntrySource.manual,
  }) async {
    final DateTime now = _utcNow();
    final DateTime measured = (measuredAt ?? now).toUtc();
    final String id = _uuid.v4();

    await _database
        .into(_database.weightEntries)
        .insert(
          WeightEntriesCompanion.insert(
            id: id,
            measuredAt: measured,
            weightKg: weightKg,
            source: Value<String>(source.name),
            createdAt: now,
          ),
        );

    return WeightEntry(
      id: id,
      measuredAt: measured,
      weightKg: weightKg,
      source: source,
      createdAt: now,
    );
  }

  /// Auto-logged entry from the profile form. Uses a deterministic id
  /// keyed on the LOCAL day of [measuredAt] so multiple edits in the same
  /// user-day collapse to a single point on the chart instead of stacking.
  Future<WeightEntry> upsertProfileEntry({
    required double weightKg,
    required DateTime measuredAt,
  }) async {
    final DateTime now = _utcNow();
    final DateTime measuredUtc = measuredAt.toUtc();
    final String id = _profileEntryIdForDay(measuredUtc);

    await _database
        .into(_database.weightEntries)
        .insertOnConflictUpdate(
          WeightEntriesCompanion.insert(
            id: id,
            measuredAt: measuredUtc,
            weightKg: weightKg,
            source: Value<String>(WeightEntrySource.profile.name),
            createdAt: now,
          ),
        );

    return WeightEntry(
      id: id,
      measuredAt: measuredUtc,
      weightKg: weightKg,
      source: WeightEntrySource.profile,
      createdAt: now,
    );
  }

  /// All entries ordered by [WeightEntry.measuredAt] ascending — chart-
  /// ready, oldest first.
  Stream<List<WeightEntry>> watchAll() {
    return (_database.select(_database.weightEntries)
          ..orderBy(<OrderClauseGenerator<$WeightEntriesTable>>[
            (tbl) => OrderingTerm(expression: tbl.measuredAt),
          ]))
        .watch()
        .map((List<WeightEntryRow> rows) {
          return rows.map((WeightEntryRow row) => row.toModel()).toList();
        });
  }

  /// The single most recent entry by [WeightEntry.measuredAt], or null when
  /// the log is empty. Ties on `measuredAt` are broken by `createdAt` so two
  /// entries on the same instant order deterministically (the later insert
  /// wins). Used by the reverse-sync path after [logEntry] to decide whether
  /// the new entry should bump `profile.weightKg`.
  Future<WeightEntry?> getLatestEntry() async {
    final WeightEntryRow? row =
        await (_database.select(_database.weightEntries)
              ..orderBy(<OrderClauseGenerator<$WeightEntriesTable>>[
                (tbl) => OrderingTerm(
                  expression: tbl.measuredAt,
                  mode: OrderingMode.desc,
                ),
                (tbl) => OrderingTerm(
                  expression: tbl.createdAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.toModel();
  }

  /// Deletes a single entry. Not wired into the v1 UI, but exposed so a
  /// future "edit history" affordance can use it without changes here.
  Future<void> deleteEntry(String id) {
    return (_database.delete(
      _database.weightEntries,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  /// `profile-yyyyMMdd` keyed on the user's local-time day. Storing UTC in
  /// the column but deduping on local day matches user expectations: an
  /// 11pm edit and an 8am-next-morning edit are different days for them.
  static String _profileEntryIdForDay(DateTime instant) {
    final DateTime local = instant.toLocal();
    final String yyyy = local.year.toString().padLeft(4, '0');
    final String mm = local.month.toString().padLeft(2, '0');
    final String dd = local.day.toString().padLeft(2, '0');
    return 'profile-$yyyy$mm$dd';
  }

  static DateTime _utcNow() => DateTime.now().toUtc();
}
