import 'dart:async';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/database_providers.dart';
import '../models/database_mappers.dart';
import '../models/pr_event.dart';
import '../models/weekly_recap.dart';
import 'workout_repository.dart';

part 'weekly_recap_repository.g.dart';

@Riverpod(keepAlive: true)
WeeklyRecapRepository weeklyRecapRepository(Ref ref) {
  return WeeklyRecapRepository(
    database: ref.watch(appDatabaseProvider),
    workouts: ref.watch(workoutRepositoryProvider),
    uuid: ref.watch(uuidProvider),
  );
}

/// Persists and serves the weekly summary cards. Generation is driven by
/// [generateRecapsIfNeeded], called once at app open: it walks forward
/// from the most-recent stored recap (or "the week before now" on a
/// cold install) and writes a row for every completed week the user
/// logged at least one workout in. Empty weeks are skipped — there is
/// deliberately no "rest week" placeholder card.
class WeeklyRecapRepository {
  WeeklyRecapRepository({
    required AppDatabase database,
    required WorkoutRepository workouts,
    required Uuid uuid,
  }) : _database = database,
       _workouts = workouts,
       _uuid = uuid;

  final AppDatabase _database;
  final WorkoutRepository _workouts;
  final Uuid _uuid;

  /// Streams every persisted recap, newest first.
  Stream<List<WeeklyRecap>> watchAll() {
    final Stream<List<WeeklyRecapRow>> rows =
        (_database.select(_database.weeklyRecaps)
              ..orderBy(<OrderingTerm Function(WeeklyRecaps)>[
                (tbl) => OrderingTerm(
                  expression: tbl.weekStart,
                  mode: OrderingMode.desc,
                ),
              ]))
            .watch();
    return rows.map(
      (List<WeeklyRecapRow> items) =>
          items.map((WeeklyRecapRow r) => r.toModel()).toList(growable: false),
    );
  }

  /// Streams the recap that should be shown on the home for the current
  /// week. Returns the most-recent recap, but only while it's still
  /// "fresh" — older than 7 days from `now` and the home shows nothing
  /// until the next generation pass writes a new one.
  Stream<WeeklyRecap?> watchCurrent() async* {
    await for (final List<WeeklyRecap> items in watchAll()) {
      if (items.isEmpty) {
        yield null;
        continue;
      }
      final WeeklyRecap latest = items.first;
      final DateTime now = DateTime.now().toUtc();
      // weekEnd is exclusive (Mon 00:00 of the following week, UTC).
      // A recap stays current for the 7 days immediately after weekEnd.
      final DateTime expiresAt = latest.weekEnd.add(const Duration(days: 7));
      yield now.isBefore(expiresAt) ? latest : null;
    }
  }

  Future<WeeklyRecap?> getById(String id) async {
    final WeeklyRecapRow? row = await (_database.select(
      _database.weeklyRecaps,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  /// Walks forward from the most recent persisted recap (or the most
  /// recent fully-completed week on a cold install), generating one
  /// recap per week the user trained in. Idempotent: each week is keyed
  /// by its `weekStart` and skipped if already stored. Safe to call on
  /// every app open.
  Future<void> generateRecapsIfNeeded({DateTime? now}) async {
    final DateTime nowLocal = (now ?? DateTime.now()).toLocal();
    final DateTime currentWeekStart = _localWeekStart(nowLocal);

    // Find the latest recap we've already written.
    final WeeklyRecapRow? latestRow =
        await (_database.select(_database.weeklyRecaps)
              ..orderBy(<OrderingTerm Function(WeeklyRecaps)>[
                (tbl) => OrderingTerm(
                  expression: tbl.weekStart,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    // Resolve the next week we should consider generating for.
    DateTime cursorWeekStart;
    if (latestRow != null) {
      final DateTime latestStartLocal = latestRow.weekStart.toLocal();
      cursorWeekStart = latestStartLocal.add(const Duration(days: 7));
    } else {
      // Cold install: only attempt the most recently-completed week so
      // we don't backfill the user's entire workout history.
      cursorWeekStart = currentWeekStart.subtract(const Duration(days: 7));
    }

    // PR events list (newest first); filtered per-week below. Pulled
    // once and cached so we don't wake the stream per week.
    final List<PrEvent> allPrEvents = await _workouts
        .watchAllPrEvents()
        .first;

    // Generate one recap per fully-completed week up to (not including)
    // the current in-progress week. The week ending at currentWeekStart
    // is the most recent eligible candidate.
    while (cursorWeekStart.isBefore(currentWeekStart)) {
      await _generateForWeek(
        weekStartLocal: cursorWeekStart,
        allPrEvents: allPrEvents,
      );
      cursorWeekStart = cursorWeekStart.add(const Duration(days: 7));
    }
  }

  Future<void> _generateForWeek({
    required DateTime weekStartLocal,
    required List<PrEvent> allPrEvents,
  }) async {
    final DateTime weekEndLocal = weekStartLocal.add(const Duration(days: 7));
    final DateTime weekStartUtc = weekStartLocal.toUtc();
    final DateTime weekEndUtc = weekEndLocal.toUtc();

    // Skip if we've already written this week (defensive — caller should
    // be walking forward from the last stored start, but guards against
    // clock changes / tz shifts).
    final WeeklyRecapRow? existing = await (_database.select(
      _database.weeklyRecaps,
    )..where((tbl) => tbl.weekStart.equals(weekStartUtc))).getSingleOrNull();
    if (existing != null) return;

    final _WeekAggregate agg = await _aggregateWeek(
      rangeStartUtc: weekStartUtc,
      rangeEndUtc: weekEndUtc,
    );
    if (agg.workoutCount == 0) {
      // Empty week — by spec, no recap card and no placeholder row.
      return;
    }

    // Previous-week comparison (workout count + volume only). Null when
    // the previous week itself had no logged workouts so the UI can
    // hide the comparison line on the very first generated recap.
    final DateTime prevStartUtc = weekStartUtc.subtract(
      const Duration(days: 7),
    );
    final _WeekAggregate? prev = await _aggregateWeekIfNonEmpty(
      rangeStartUtc: prevStartUtc,
      rangeEndUtc: weekStartUtc,
    );

    // Filter PR events down to the recap window. allPrEvents is sorted
    // newest-first; achievedAt is the parent workout's startedAt (UTC).
    final List<WeeklyRecapPr> prsThisWeek = <WeeklyRecapPr>[
      for (final PrEvent e in allPrEvents)
        if (!e.achievedAt.isBefore(weekStartUtc) &&
            e.achievedAt.isBefore(weekEndUtc))
          WeeklyRecapPr(
            exerciseName: e.exerciseName,
            exerciseType: e.exerciseType,
            type: e.type.name,
            weightKg: e.weightKg,
            reps: e.reps,
            distanceKm: e.distanceKm,
            durationSeconds: e.durationSeconds,
            laps: e.laps,
            floors: e.floors,
            calories: e.calories,
            oneRepMaxKg: e.oneRepMaxKg,
            repCountForRepMax: e.repCountForRepMax,
          ),
    ];

    await _database
        .into(_database.weeklyRecaps)
        .insert(
          WeeklyRecapsCompanion.insert(
            id: _uuid.v4(),
            weekStart: weekStartUtc,
            weekEnd: weekEndUtc,
            workoutCount: agg.workoutCount,
            totalVolumeKg: agg.totalVolumeKg,
            totalDurationSeconds: agg.totalDurationSeconds,
            averageRpe: Value<double?>(agg.averageRpe),
            prCount: prsThisWeek.length,
            prsJson: Value<String?>(
              prsThisWeek.isEmpty
                  ? null
                  : encodeWeeklyRecapPrsJson(prsThisWeek),
            ),
            dailyVolumeKgJson: encodeDailyVolumeKgJson(agg.dailyVolumeKg),
            prevWorkoutCount: Value<int?>(prev?.workoutCount),
            prevTotalVolumeKg: Value<double?>(prev?.totalVolumeKg),
            generatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<_WeekAggregate?> _aggregateWeekIfNonEmpty({
    required DateTime rangeStartUtc,
    required DateTime rangeEndUtc,
  }) async {
    final _WeekAggregate agg = await _aggregateWeek(
      rangeStartUtc: rangeStartUtc,
      rangeEndUtc: rangeEndUtc,
    );
    if (agg.workoutCount == 0) return null;
    return agg;
  }

  Future<_WeekAggregate> _aggregateWeek({
    required DateTime rangeStartUtc,
    required DateTime rangeEndUtc,
  }) async {
    // Workouts in the window: row-per-workout so we can compute count,
    // duration, and average RPE in one pass.
    final List<WorkoutRow> workouts = await (_database.select(
      _database.workouts,
    )..where(
          (tbl) =>
              tbl.startedAt.isBiggerOrEqualValue(rangeStartUtc) &
              tbl.startedAt.isSmallerThanValue(rangeEndUtc),
        ))
        .get();

    int workoutCount = workouts.length;
    int totalDurationSeconds = 0;
    int rpeCount = 0;
    int rpeSum = 0;
    for (final WorkoutRow w in workouts) {
      if (w.endedAt != null) {
        final int seconds = w.endedAt!.difference(w.startedAt).inSeconds;
        if (seconds > 0) totalDurationSeconds += seconds;
      }
      if (w.intensityScore != null) {
        rpeCount += 1;
        rpeSum += w.intensityScore!;
      }
    }
    final double? averageRpe = rpeCount == 0 ? null : rpeSum / rpeCount;

    // Total volume + per-day volume in one query, grouped by day key.
    final Selectable<QueryRow> volumeQuery = _database.customSelect(
      'SELECT w.started_at AS started_at, '
      '       COALESCE(SUM(s.weight_kg * s.reps), 0.0) AS volume '
      'FROM workouts w '
      'INNER JOIN workout_exercises we ON we.workout_id = w.id '
      'INNER JOIN sets s ON s.workout_exercise_id = we.id '
      'WHERE s.completed = 1 '
      "  AND s.kind != 'warmUp' "
      '  AND s.weight_kg IS NOT NULL '
      '  AND s.reps IS NOT NULL '
      '  AND w.started_at >= ? '
      '  AND w.started_at < ? '
      'GROUP BY w.id',
      variables: <Variable<Object>>[
        Variable<DateTime>(rangeStartUtc),
        Variable<DateTime>(rangeEndUtc),
      ],
      readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
        _database.sets,
        _database.workoutExercises,
        _database.workouts,
      },
    );
    final List<QueryRow> rows = await volumeQuery.get();

    double totalVolumeKg = 0;
    final List<double> dailyVolumeKg = List<double>.filled(7, 0);
    final DateTime weekStartLocal = rangeStartUtc.toLocal();
    final DateTime weekStartLocalDay = DateTime(
      weekStartLocal.year,
      weekStartLocal.month,
      weekStartLocal.day,
    );
    for (final QueryRow row in rows) {
      final double volume = row.read<double>('volume');
      totalVolumeKg += volume;
      final DateTime startedLocal = row.read<DateTime>('started_at').toLocal();
      final DateTime startedDay = DateTime(
        startedLocal.year,
        startedLocal.month,
        startedLocal.day,
      );
      final int dayIndex = startedDay.difference(weekStartLocalDay).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        dailyVolumeKg[dayIndex] += volume;
      }
    }

    return _WeekAggregate(
      workoutCount: workoutCount,
      totalVolumeKg: totalVolumeKg,
      totalDurationSeconds: totalDurationSeconds,
      averageRpe: averageRpe,
      dailyVolumeKg: dailyVolumeKg,
    );
  }

  /// Debug-only: force-regenerate a recap for an arbitrary anchor week
  /// regardless of generation cadence, the empty-week skip, or whether
  /// the week has finished. Picks the most-recently-completed week if
  /// it has any workouts, otherwise falls back to the in-progress week
  /// so testers always see a card. Replaces any existing recap for the
  /// chosen week so repeated taps stay idempotent.
  Future<WeeklyRecap?> debugForceGenerateLatest({DateTime? now}) async {
    final DateTime nowLocal = (now ?? DateTime.now()).toLocal();
    final DateTime currentWeekStart = _localWeekStart(nowLocal);
    final DateTime lastCompleteWeekStart = currentWeekStart.subtract(
      const Duration(days: 7),
    );
    final List<PrEvent> allPrEvents = await _workouts
        .watchAllPrEvents()
        .first;

    Future<WeeklyRecap?> tryGenerate(DateTime weekStartLocal) async {
      final DateTime weekEndLocal = weekStartLocal.add(
        const Duration(days: 7),
      );
      final DateTime weekStartUtc = weekStartLocal.toUtc();
      final DateTime weekEndUtc = weekEndLocal.toUtc();
      final _WeekAggregate agg = await _aggregateWeek(
        rangeStartUtc: weekStartUtc,
        rangeEndUtc: weekEndUtc,
      );
      if (agg.workoutCount == 0) return null;

      // Wipe any prior recap for this week so the new one is the latest.
      await (_database.delete(
        _database.weeklyRecaps,
      )..where((tbl) => tbl.weekStart.equals(weekStartUtc))).go();

      final _WeekAggregate? prev = await _aggregateWeekIfNonEmpty(
        rangeStartUtc: weekStartUtc.subtract(const Duration(days: 7)),
        rangeEndUtc: weekStartUtc,
      );
      final List<WeeklyRecapPr> prsThisWeek = <WeeklyRecapPr>[
        for (final PrEvent e in allPrEvents)
          if (!e.achievedAt.isBefore(weekStartUtc) &&
              e.achievedAt.isBefore(weekEndUtc))
            WeeklyRecapPr(
              exerciseName: e.exerciseName,
              exerciseType: e.exerciseType,
              type: e.type.name,
              weightKg: e.weightKg,
              reps: e.reps,
              distanceKm: e.distanceKm,
              durationSeconds: e.durationSeconds,
              oneRepMaxKg: e.oneRepMaxKg,
              repCountForRepMax: e.repCountForRepMax,
            ),
      ];
      final String id = _uuid.v4();
      await _database
          .into(_database.weeklyRecaps)
          .insert(
            WeeklyRecapsCompanion.insert(
              id: id,
              weekStart: weekStartUtc,
              weekEnd: weekEndUtc,
              workoutCount: agg.workoutCount,
              totalVolumeKg: agg.totalVolumeKg,
              totalDurationSeconds: agg.totalDurationSeconds,
              averageRpe: Value<double?>(agg.averageRpe),
              prCount: prsThisWeek.length,
              prsJson: Value<String?>(
                prsThisWeek.isEmpty
                    ? null
                    : encodeWeeklyRecapPrsJson(prsThisWeek),
              ),
              dailyVolumeKgJson: encodeDailyVolumeKgJson(agg.dailyVolumeKg),
              prevWorkoutCount: Value<int?>(prev?.workoutCount),
              prevTotalVolumeKg: Value<double?>(prev?.totalVolumeKg),
              generatedAt: DateTime.now().toUtc(),
            ),
          );
      return getById(id);
    }

    // Prefer the most-recently-completed week so the surfaced recap is a
    // realistic "ready to share" snapshot. Fall back to the in-progress
    // week if last week is empty so testers always see something.
    final WeeklyRecap? lastWeek = await tryGenerate(lastCompleteWeekStart);
    if (lastWeek != null) return lastWeek;
    return tryGenerate(currentWeekStart);
  }

  /// Local Monday 00:00 for the week containing [reference]. Dart's
  /// `weekday` is 1 (Mon) … 7 (Sun) so subtracting `weekday - 1` always
  /// lands on Monday regardless of locale. We rebuild the DateTime via
  /// the local-time constructor to drop hours / handle DST.
  static DateTime _localWeekStart(DateTime reference) {
    final DateTime midnight = DateTime(
      reference.year,
      reference.month,
      reference.day,
    );
    final int daysSinceMonday = midnight.weekday - DateTime.monday;
    return midnight.subtract(Duration(days: daysSinceMonday));
  }
}

class _WeekAggregate {
  const _WeekAggregate({
    required this.workoutCount,
    required this.totalVolumeKg,
    required this.totalDurationSeconds,
    required this.averageRpe,
    required this.dailyVolumeKg,
  });

  final int workoutCount;
  final double totalVolumeKg;
  final int totalDurationSeconds;
  final double? averageRpe;
  final List<double> dailyVolumeKg;
}
