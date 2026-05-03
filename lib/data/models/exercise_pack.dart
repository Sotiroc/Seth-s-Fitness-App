/// Installed exercise library pack.
class ExercisePack {
  const ExercisePack({
    required this.id,
    required this.name,
    required this.description,
    required this.credit,
    required this.license,
    required this.assetPath,
    required this.isActive,
    required this.schemaVersion,
    required this.exerciseCount,
    required this.installedAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String credit;
  final String license;

  /// Bundled-asset path the importer reads from
  /// (e.g. `assets/exercise_packs/strength.json`).
  final String assetPath;

  /// Toggle that hides the pack's exercises from pickers and the main
  /// library list. Past workout history is unaffected by this flag.
  final bool isActive;

  /// `schemaVersion` recorded in the pack file when it was last imported.
  final int schemaVersion;

  /// Number of exercises imported from this pack on its most recent run.
  final int exerciseCount;

  final DateTime installedAt;
  final DateTime updatedAt;

  ExercisePack copyWith({
    String? id,
    String? name,
    String? description,
    String? credit,
    String? license,
    String? assetPath,
    bool? isActive,
    int? schemaVersion,
    int? exerciseCount,
    DateTime? installedAt,
    DateTime? updatedAt,
  }) {
    return ExercisePack(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      credit: credit ?? this.credit,
      license: license ?? this.license,
      assetPath: assetPath ?? this.assetPath,
      isActive: isActive ?? this.isActive,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      exerciseCount: exerciseCount ?? this.exerciseCount,
      installedAt: installedAt ?? this.installedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
