// One-shot generator that converts the Free Exercise DB source JSON into
// the per-category pack files the app loads at runtime.
//
// Run from the repo root:
//   dart run tools/build_exercise_packs.dart
//
// Inputs:  tools/exercises_source.json (committed snapshot of upstream)
// Outputs: assets/exercise_packs/<pack_id>.json (one per category)
//
// The source data is the Free Exercise DB by yuhonas:
//   https://github.com/yuhonas/free-exercise-db
//   License: Unlicense (public domain)

import 'dart:convert';
import 'dart:io';

const String _sourcePath = 'tools/exercises_source.json';
const String _outputDir = 'assets/exercise_packs';
const int _packSchemaVersion = 1;

const String _credit =
    'Free Exercise DB by yuhonas — https://github.com/yuhonas/free-exercise-db';
const String _license = 'Unlicense (public domain)';

class _PackSpec {
  const _PackSpec({
    required this.packId,
    required this.sourceCategory,
    required this.name,
    required this.description,
  });

  final String packId;
  final String sourceCategory;
  final String name;
  final String description;
}

const List<_PackSpec> _packs = <_PackSpec>[
  _PackSpec(
    packId: 'strength',
    sourceCategory: 'strength',
    name: 'Strength',
    description:
        'Compound and isolation lifts across all major muscle groups.',
  ),
  _PackSpec(
    packId: 'cardio',
    sourceCategory: 'cardio',
    name: 'Cardio',
    description: 'Steady-state and interval cardio for conditioning.',
  ),
  _PackSpec(
    packId: 'stretching',
    sourceCategory: 'stretching',
    name: 'Stretching',
    description: 'Mobility and flexibility work for warm-ups and recovery.',
  ),
  _PackSpec(
    packId: 'plyometrics',
    sourceCategory: 'plyometrics',
    name: 'Plyometrics',
    description: 'Explosive jumping and bounding drills for power.',
  ),
  _PackSpec(
    packId: 'powerlifting',
    sourceCategory: 'powerlifting',
    name: 'Powerlifting',
    description: 'Squat, bench, and deadlift variations with accessory lifts.',
  ),
  _PackSpec(
    packId: 'strongman',
    sourceCategory: 'strongman',
    name: 'Strongman',
    description: 'Loaded carries, pulls, and event-style strength work.',
  ),
  _PackSpec(
    packId: 'olympic_weightlifting',
    sourceCategory: 'olympic weightlifting',
    name: 'Olympic Weightlifting',
    description: 'Snatch and clean & jerk plus their core variations.',
  ),
];

Map<String, dynamic> _slimExercise(Map<String, dynamic> raw) {
  return <String, dynamic>{
    'sourceId': raw['id'] as String,
    'name': raw['name'] as String,
    if (raw['force'] != null) 'force': raw['force'],
    if (raw['level'] != null) 'level': raw['level'],
    if (raw['mechanic'] != null) 'mechanic': raw['mechanic'],
    if (raw['equipment'] != null) 'equipment': raw['equipment'],
    'primaryMuscles': List<String>.from(raw['primaryMuscles'] as List<dynamic>),
    'secondaryMuscles': List<String>.from(
      raw['secondaryMuscles'] as List<dynamic>,
    ),
    'instructions': List<String>.from(raw['instructions'] as List<dynamic>),
    'category': raw['category'] as String,
  };
}

void main() {
  final File sourceFile = File(_sourcePath);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Source not found: $_sourcePath');
    exit(1);
  }

  final List<dynamic> all = jsonDecode(sourceFile.readAsStringSync()) as List<dynamic>;
  stdout.writeln('Loaded ${all.length} exercises from source.');

  final Directory outDir = Directory(_outputDir);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final Set<String> coveredCategories = _packs
      .map((p) => p.sourceCategory)
      .toSet();
  final Set<String> uncovered = <String>{};

  final JsonEncoder encoder = const JsonEncoder.withIndent('  ');
  int totalWritten = 0;

  for (final _PackSpec pack in _packs) {
    final List<Map<String, dynamic>> exercises = <Map<String, dynamic>>[];
    for (final dynamic raw in all) {
      final Map<String, dynamic> ex = raw as Map<String, dynamic>;
      final String? cat = ex['category'] as String?;
      if (cat == null) continue;
      if (cat == pack.sourceCategory) {
        exercises.add(_slimExercise(ex));
      }
    }
    exercises.sort(
      (a, b) =>
          (a['name'] as String).toLowerCase().compareTo(
            (b['name'] as String).toLowerCase(),
          ),
    );

    final Map<String, dynamic> output = <String, dynamic>{
      'schemaVersion': _packSchemaVersion,
      'packId': pack.packId,
      'name': pack.name,
      'description': pack.description,
      'credit': _credit,
      'license': _license,
      'exerciseCount': exercises.length,
      'exercises': exercises,
    };

    final File outFile = File('$_outputDir/${pack.packId}.json');
    outFile.writeAsStringSync('${encoder.convert(output)}\n');
    stdout.writeln(
      '  wrote ${pack.packId.padRight(22)} '
      '${exercises.length.toString().padLeft(3)} exercises',
    );
    totalWritten += exercises.length;
  }

  for (final dynamic raw in all) {
    final Map<String, dynamic> ex = raw as Map<String, dynamic>;
    final String? cat = ex['category'] as String?;
    if (cat != null && !coveredCategories.contains(cat)) {
      uncovered.add(cat);
    }
  }

  stdout.writeln('Total written: $totalWritten of ${all.length}');
  if (uncovered.isNotEmpty) {
    stderr.writeln('WARN: uncovered categories in source: $uncovered');
    exit(2);
  }
}
