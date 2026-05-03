import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../db/app_database.dart';
import '../db/database_providers.dart';

part 'app_settings_repository.g.dart';

const String _restTimerEnabledKey = 'rest_timer_enabled';
const String _defaultRestSecondsKey = 'default_rest_seconds';

@Riverpod(keepAlive: true)
AppSettingsRepository appSettingsRepository(Ref ref) {
  return AppSettingsRepository(database: ref.watch(appDatabaseProvider));
}

/// Reactive bool stream for the "show rest timer" toggle in the active
/// workout header. Defaults to `true` when no row exists so first-time
/// users see the timer; flipping the toggle persists immediately.
@Riverpod(keepAlive: true)
Stream<bool> restTimerEnabled(Ref ref) {
  return ref.watch(appSettingsRepositoryProvider).watchRestTimerEnabled();
}

/// Reactive `int?` stream for the user-level default rest period that
/// applies when an exercise has no per-exercise override. `null` means
/// "fall back to per-type defaults" (weighted=120, bodyweight=60,
/// cardio=0). Set from the Timer settings screen.
@Riverpod(keepAlive: true)
Stream<int?> defaultRestSeconds(Ref ref) {
  return ref.watch(appSettingsRepositoryProvider).watchDefaultRestSeconds();
}

/// Type-safe accessor over the `app_settings` key/value table for app-level
/// preferences. Mirrors the existing `'default_exercises_seeded'` pattern in
/// [ExerciseRepository] but exposes typed helpers per setting.
class AppSettingsRepository {
  AppSettingsRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  Future<bool> getRestTimerEnabled() async {
    final AppSettingRow? row =
        await (_database.select(_database.appSettings)
              ..where((tbl) => tbl.key.equals(_restTimerEnabledKey)))
            .getSingleOrNull();
    return _decodeEnabled(row?.value);
  }

  Stream<bool> watchRestTimerEnabled() {
    return (_database.select(_database.appSettings)
          ..where((tbl) => tbl.key.equals(_restTimerEnabledKey)))
        .watchSingleOrNull()
        .map((row) => _decodeEnabled(row?.value));
  }

  Future<void> setRestTimerEnabled(bool enabled) async {
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _restTimerEnabledKey,
            value: Value<String>(enabled ? 'true' : 'false'),
          ),
        );
  }

  Future<int?> getDefaultRestSeconds() async {
    final AppSettingRow? row =
        await (_database.select(_database.appSettings)
              ..where((tbl) => tbl.key.equals(_defaultRestSecondsKey)))
            .getSingleOrNull();
    return _decodeRestSeconds(row?.value);
  }

  Stream<int?> watchDefaultRestSeconds() {
    return (_database.select(_database.appSettings)
          ..where((tbl) => tbl.key.equals(_defaultRestSecondsKey)))
        .watchSingleOrNull()
        .map((row) => _decodeRestSeconds(row?.value));
  }

  /// Persists the user-level default rest period. Pass `null` to clear it
  /// and fall back to per-type defaults. Validates the same 0..3600 range
  /// as [ExerciseRepository.updateExerciseRestSeconds].
  Future<void> setDefaultRestSeconds(int? seconds) async {
    if (seconds != null && (seconds < 0 || seconds > 3600)) {
      throw ArgumentError.value(
        seconds,
        'seconds',
        'Default rest must be null or between 0 and 3600 seconds.',
      );
    }
    if (seconds == null) {
      await (_database.delete(_database.appSettings)
            ..where((tbl) => tbl.key.equals(_defaultRestSecondsKey)))
          .go();
      return;
    }
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _defaultRestSecondsKey,
            value: Value<String>(seconds.toString()),
          ),
        );
  }

  // Default ON: a missing row means the user hasn't toggled — show the timer.
  bool _decodeEnabled(String? raw) => raw != 'false';

  // Tolerant decode: malformed values fall back to "no default set" rather
  // than crashing the timer flow on a corrupt settings row.
  int? _decodeRestSeconds(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final int? parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0 || parsed > 3600) return null;
    return parsed;
  }
}
