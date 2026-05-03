import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessapp/data/db/app_database.dart';
import 'package:fitnessapp/data/models/user_profile.dart';
import 'package:fitnessapp/data/models/weight_entry.dart';
import 'package:fitnessapp/data/repositories/user_profile_repository.dart';
import 'package:fitnessapp/data/repositories/weight_entry_repository.dart';
import 'package:fitnessapp/features/progression/presentation/widgets/log_weight_sheet.dart';

/// Direct tests of the reverse-sync logic extracted from `_LogWeightForm._save`
/// — exercising the contract that a chronologically-latest manual entry
/// updates `profile.weightKg`, and a backdated one doesn't.
void main() {
  late AppDatabase database;
  late WeightEntryRepository weightRepo;
  late UserProfileRepository profileRepo;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    weightRepo = WeightEntryRepository(database: database);
    profileRepo = UserProfileRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  group('syncProfileWeightFromLog', () {
    test('updates profile.weightKg when the new entry is the latest', () async {
      // Existing log: an entry from a week ago at 80 kg.
      await weightRepo.logEntry(
        weightKg: 80.0,
        measuredAt: DateTime.utc(2026, 5, 1),
      );
      // Profile currently anchored to that older value.
      await profileRepo.upsertProfile(name: 'Sam', weightKg: 80.0);

      // User logs a fresh "today" entry at 78.5 kg.
      final WeightEntry inserted = await syncProfileWeightFromLog(
        weightRepo: weightRepo,
        profileRepo: profileRepo,
        weightKg: 78.5,
        measuredAt: DateTime.utc(2026, 5, 8),
      );

      expect(inserted.weightKg, 78.5);

      // Profile should now reflect the new latest weight.
      final UserProfile? profile = await profileRepo.getProfile();
      expect(profile, isNotNull);
      expect(profile!.weightKg, 78.5);
      // Other fields preserved.
      expect(profile.name, 'Sam');
    });

    test('creates the profile row when none exists', () async {
      // Empty database — no profile, no log.
      expect(await profileRepo.getProfile(), isNull);

      await syncProfileWeightFromLog(
        weightRepo: weightRepo,
        profileRepo: profileRepo,
        weightKg: 75.0,
        measuredAt: DateTime.utc(2026, 5, 8),
      );

      final UserProfile? profile = await profileRepo.getProfile();
      expect(profile, isNotNull);
      expect(profile!.weightKg, 75.0);
    });

    test(
      'leaves profile.weightKg untouched when the new entry is backdated',
      () async {
        // Existing log: a recent entry at 78 kg.
        await weightRepo.logEntry(
          weightKg: 78.0,
          measuredAt: DateTime.utc(2026, 5, 8),
        );
        // Profile already synced to that value.
        await profileRepo.upsertProfile(name: 'Sam', weightKg: 78.0);

        // User logs a backdated historical entry from a week earlier.
        await syncProfileWeightFromLog(
          weightRepo: weightRepo,
          profileRepo: profileRepo,
          weightKg: 82.0,
          measuredAt: DateTime.utc(2026, 5, 1),
        );

        // Profile weight should NOT change — the backdated entry isn't the
        // user's "current weight".
        final UserProfile? profile = await profileRepo.getProfile();
        expect(profile, isNotNull);
        expect(profile!.weightKg, 78.0);
      },
    );

    test(
      'returns the inserted entry whether or not the profile is touched',
      () async {
        await weightRepo.logEntry(
          weightKg: 78.0,
          measuredAt: DateTime.utc(2026, 5, 8),
        );

        final WeightEntry returned = await syncProfileWeightFromLog(
          weightRepo: weightRepo,
          profileRepo: profileRepo,
          weightKg: 82.0,
          measuredAt: DateTime.utc(2026, 5, 1), // backdated
        );

        // The inserted entry is returned even when no profile sync happened,
        // so the caller can dismiss its UI based on the successful insert.
        expect(returned.weightKg, 82.0);
        expect(returned.measuredAt, DateTime.utc(2026, 5, 1));
      },
    );
  });
}
