import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Parsed in-memory representation of a bundled exercise-library pack
/// (e.g. `assets/exercise_packs/strength.json`). Mirrors the shape
/// produced by `tools/build_exercise_packs.dart`.
class BundledPack {
  const BundledPack({
    required this.schemaVersion,
    required this.packId,
    required this.name,
    required this.description,
    required this.credit,
    required this.license,
    required this.assetPath,
    required this.exercises,
  });

  final int schemaVersion;
  final String packId;
  final String name;
  final String description;
  final String credit;
  final String license;
  final String assetPath;
  final List<BundledExercise> exercises;
}

/// One exercise row out of a bundled pack file.
class BundledExercise {
  const BundledExercise({
    required this.sourceId,
    required this.name,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.instructions,
    required this.category,
    this.equipment,
    this.force,
    this.level,
    this.mechanic,
  });

  final String sourceId;
  final String name;
  final String? equipment;
  final String? force;
  final String? level;
  final String? mechanic;
  final String category;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> instructions;
}

/// Pack definitions shipped inside the app bundle. Adding a new pack is
/// a matter of appending to this list and dropping the matching JSON file
/// into `assets/exercise_packs/` (and registering the asset in pubspec).
const List<({String id, String assetPath})> bundledPackManifest =
    <({String id, String assetPath})>[
  (id: 'strength', assetPath: 'assets/exercise_packs/strength.json'),
  (id: 'cardio', assetPath: 'assets/exercise_packs/cardio.json'),
  (id: 'stretching', assetPath: 'assets/exercise_packs/stretching.json'),
  (id: 'plyometrics', assetPath: 'assets/exercise_packs/plyometrics.json'),
  (id: 'powerlifting', assetPath: 'assets/exercise_packs/powerlifting.json'),
  (id: 'strongman', assetPath: 'assets/exercise_packs/strongman.json'),
  (
    id: 'olympic_weightlifting',
    assetPath: 'assets/exercise_packs/olympic_weightlifting.json',
  ),
];

class ExercisePackLoader {
  const ExercisePackLoader();

  /// Loads every bundled pack listed in [bundledPackManifest]. Order
  /// matches the manifest, which is the order users will see in settings.
  Future<List<BundledPack>> loadAll() async {
    final List<BundledPack> packs = <BundledPack>[];
    for (final ({String id, String assetPath}) entry in bundledPackManifest) {
      packs.add(await _load(entry.assetPath));
    }
    return packs;
  }

  Future<BundledPack> _load(String assetPath) async {
    final String raw = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
    final List<dynamic> rawExercises = json['exercises'] as List<dynamic>;
    return BundledPack(
      schemaVersion: json['schemaVersion'] as int,
      packId: json['packId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      credit: json['credit'] as String,
      license: json['license'] as String,
      assetPath: assetPath,
      exercises: <BundledExercise>[
        for (final dynamic raw in rawExercises)
          _parseExercise(raw as Map<String, dynamic>),
      ],
    );
  }

  BundledExercise _parseExercise(Map<String, dynamic> raw) {
    return BundledExercise(
      sourceId: raw['sourceId'] as String,
      name: raw['name'] as String,
      equipment: raw['equipment'] as String?,
      force: raw['force'] as String?,
      level: raw['level'] as String?,
      mechanic: raw['mechanic'] as String?,
      category: raw['category'] as String,
      primaryMuscles: <String>[
        for (final dynamic m in (raw['primaryMuscles'] as List<dynamic>? ?? <dynamic>[]))
          if (m is String) m,
      ],
      secondaryMuscles: <String>[
        for (final dynamic m in (raw['secondaryMuscles'] as List<dynamic>? ?? <dynamic>[]))
          if (m is String) m,
      ],
      instructions: <String>[
        for (final dynamic s in (raw['instructions'] as List<dynamic>? ?? <dynamic>[]))
          if (s is String) s,
      ],
    );
  }
}
