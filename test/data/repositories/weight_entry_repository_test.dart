import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessapp/data/db/app_database.dart';
import 'package:fitnessapp/data/models/weight_entry.dart';
import 'package:fitnessapp/data/repositories/weight_entry_repository.dart';

void main() {
  late AppDatabase database;
  late WeightEntryRepository repo;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WeightEntryRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  group('WeightEntryRepository.getLatestEntry', () {
    test('returns null when the log is empty', () async {
      final WeightEntry? latest = await repo.getLatestEntry();
      expect(latest, isNull);
    });

    test('returns the only entry when there is exactly one', () async {
      final WeightEntry inserted = await repo.logEntry(
        weightKg: 78.0,
        measuredAt: DateTime.utc(2026, 1, 10),
      );

      final WeightEntry? latest = await repo.getLatestEntry();

      expect(latest, isNotNull);
      expect(latest!.id, inserted.id);
      expect(latest.weightKg, 78.0);
    });

    test('returns the entry with the most recent measuredAt', () async {
      await repo.logEntry(weightKg: 80.0, measuredAt: DateTime.utc(2026, 1, 1));
      final WeightEntry latest = await repo.logEntry(
        weightKg: 78.0,
        measuredAt: DateTime.utc(2026, 1, 15),
      );
      await repo.logEntry(weightKg: 79.0, measuredAt: DateTime.utc(2026, 1, 8));

      final WeightEntry? result = await repo.getLatestEntry();

      expect(result, isNotNull);
      expect(result!.id, latest.id);
      expect(result.weightKg, 78.0);
    });

    test('breaks measuredAt ties by createdAt (later insert wins)', () async {
      // Both entries share the same measuredAt; the second insert is
      // chronologically later by virtue of being inserted second, so its
      // createdAt is greater. The wait crosses a second boundary because
      // Drift's default `dateTime()` serializer stores Unix seconds — sub-
      // second waits don't yield distinct stored timestamps.
      final DateTime sameInstant = DateTime.utc(2026, 1, 10);

      await repo.logEntry(weightKg: 80.0, measuredAt: sameInstant);
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      final WeightEntry second = await repo.logEntry(
        weightKg: 81.0,
        measuredAt: sameInstant,
      );

      final WeightEntry? latest = await repo.getLatestEntry();

      expect(latest, isNotNull);
      expect(latest!.id, second.id);
      expect(latest.weightKg, 81.0);
    });

    test('a backdated insert does not become the latest', () async {
      final WeightEntry recent = await repo.logEntry(
        weightKg: 78.0,
        measuredAt: DateTime.utc(2026, 1, 15),
      );
      await repo.logEntry(weightKg: 75.0, measuredAt: DateTime.utc(2026, 1, 1));

      final WeightEntry? latest = await repo.getLatestEntry();

      expect(latest, isNotNull);
      expect(latest!.id, recent.id);
    });
  });
}
