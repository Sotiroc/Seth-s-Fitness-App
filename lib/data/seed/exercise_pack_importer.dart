import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../db/app_database.dart';
import '../db/database_providers.dart';
import '../models/exercise_muscle_group.dart';
import '../models/exercise_type.dart';
import '../repositories/exercise_pack_repository.dart';
import '../repositories/exercise_repository.dart';
import 'exercise_pack_loader.dart';
import 'starter_remap.dart';

part 'exercise_pack_importer.g.dart';

const String _starterRemapDoneKey = 'starter_remap_v12_done';

@Riverpod(keepAlive: true)
ExercisePackImporter exercisePackImporter(Ref ref) {
  return ExercisePackImporter(
    database: ref.watch(appDatabaseProvider),
    loader: const ExercisePackLoader(),
    exerciseRepository: ref.watch(exerciseRepositoryProvider),
    packRepository: ref.watch(exercisePackRepositoryProvider),
  );
}

/// Bootstraps the bundled exercise library packs:
///
///   1. Loads every pack in [bundledPackManifest] from app assets.
///   2. Upserts the pack registry row (preserving the user's on/off
///      toggle on subsequent runs).
///   3. Bulk upserts every exercise in the pack into the exercises table.
///   4. On first run after upgrade, rewrites past workout/template
///      references from the legacy 18 starter ids onto their library
///      matches and marks the starters hidden so they leave the pickers.
///
/// Idempotent — safe to run on every app boot.
class ExercisePackImporter {
  ExercisePackImporter({
    required AppDatabase database,
    required ExercisePackLoader loader,
    required ExerciseRepository exerciseRepository,
    required ExercisePackRepository packRepository,
  })  : _database = database,
        _loader = loader,
        _exerciseRepository = exerciseRepository,
        _packRepository = packRepository;

  final AppDatabase _database;
  final ExercisePackLoader _loader;
  final ExerciseRepository _exerciseRepository;
  final ExercisePackRepository _packRepository;

  Future<void> run() async {
    final List<BundledPack> packs = await _loader.loadAll();

    for (final BundledPack pack in packs) {
      await _packRepository.upsertPack(
        id: pack.packId,
        name: pack.name,
        description: pack.description,
        credit: pack.credit,
        license: pack.license,
        assetPath: pack.assetPath,
        schemaVersion: pack.schemaVersion,
        exerciseCount: pack.exercises.length,
      );

      final List<LibraryExerciseInput> inputs = <LibraryExerciseInput>[
        for (final BundledExercise ex in pack.exercises)
          LibraryExerciseInput(
            id: '${pack.packId}/${ex.sourceId}',
            sourceExerciseId: ex.sourceId,
            name: ex.name,
            type: _resolveType(category: ex.category, equipment: ex.equipment),
            muscleGroup: _resolveMuscleGroup(
              category: ex.category,
              primaryMuscles: ex.primaryMuscles,
            ),
            primaryMuscles: ex.primaryMuscles,
            secondaryMuscles: ex.secondaryMuscles,
            instructions: ex.instructions,
            equipment: ex.equipment,
            force: ex.force,
            level: ex.level,
            mechanic: ex.mechanic,
            category: ex.category,
          ),
      ];

      await _exerciseRepository.upsertLibraryExercises(
        packId: pack.packId,
        exercises: inputs,
      );
    }

    await _maybeRunStarterRemap();
  }

  /// One-shot remap of legacy starter exercises to library entries.
  /// Guarded by an app-settings flag so it only runs once even across
  /// reinstalls of the same major version.
  Future<void> _maybeRunStarterRemap() async {
    final AppSettingRow? flag = await (_database.select(
      _database.appSettings,
    )..where((tbl) => tbl.key.equals(_starterRemapDoneKey)))
        .getSingleOrNull();
    if (flag?.value == 'true') return;

    for (final MapEntry<String, String> entry
        in starterToLibraryRemap.entries) {
      final String oldId = entry.key;
      final String newId = entry.value;

      final ExerciseRow? oldRow = await (_database.select(
        _database.exercises,
      )..where((tbl) => tbl.id.equals(oldId))).getSingleOrNull();
      if (oldRow == null) continue;

      final ExerciseRow? newRow = await (_database.select(
        _database.exercises,
      )..where((tbl) => tbl.id.equals(newId))).getSingleOrNull();
      if (newRow == null) continue; // pack import didn't land it; skip safely.

      await _exerciseRepository.rewriteExerciseReferences(
        fromExerciseId: oldId,
        toExerciseId: newId,
      );
      await _exerciseRepository.setExerciseHidden(
        exerciseId: oldId,
        hidden: true,
      );
    }

    await _database.into(_database.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _starterRemapDoneKey,
            value: const Value<String>('true'),
          ),
        );
  }

  /// Type rule:
  ///   - source `category == 'cardio'` → cardio
  ///   - `equipment == 'body only'`    → bodyweight
  ///   - everything else              → weighted
  ExerciseType _resolveType({
    required String category,
    required String? equipment,
  }) {
    if (category == 'cardio') return ExerciseType.cardio;
    if (equipment == 'body only') return ExerciseType.bodyweight;
    return ExerciseType.weighted;
  }

  /// Maps the source library's free-form muscle labels onto the app's
  /// 8-bucket [ExerciseMuscleGroup] enum. Only the first primary muscle
  /// is consulted — multi-muscle exercises bucket by their headline mover.
  ExerciseMuscleGroup _resolveMuscleGroup({
    required String category,
    required List<String> primaryMuscles,
  }) {
    if (category == 'cardio') return ExerciseMuscleGroup.cardio;
    if (primaryMuscles.isEmpty) return ExerciseMuscleGroup.cardio;
    final String key = primaryMuscles.first.toLowerCase();
    switch (key) {
      case 'abdominals':
        return ExerciseMuscleGroup.abs;
      case 'biceps':
      case 'forearms':
        return ExerciseMuscleGroup.biceps;
      case 'triceps':
        return ExerciseMuscleGroup.triceps;
      case 'chest':
        return ExerciseMuscleGroup.chest;
      case 'lats':
      case 'middle back':
      case 'lower back':
      case 'traps':
        return ExerciseMuscleGroup.back;
      case 'shoulders':
      case 'neck':
        return ExerciseMuscleGroup.shoulders;
      case 'quadriceps':
      case 'hamstrings':
      case 'glutes':
      case 'calves':
      case 'adductors':
      case 'abductors':
        return ExerciseMuscleGroup.legs;
      default:
        return ExerciseMuscleGroup.cardio;
    }
  }
}
