import 'dart:typed_data';

import 'exercise_muscle_group.dart';
import 'exercise_type.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.type,
    required this.muscleGroup,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
    this.thumbnailBytes,
    this.defaultRestSeconds,
    this.equipment,
    this.force,
    this.level,
    this.mechanic,
    this.category,
    this.primaryMuscles = const <String>[],
    this.secondaryMuscles = const <String>[],
    this.instructions = const <String>[],
    this.sourcePackId,
    this.sourceExerciseId,
    this.hidden = false,
  });

  final String id;
  final String name;
  final ExerciseType type;
  final ExerciseMuscleGroup muscleGroup;
  final String? thumbnailPath;
  final Uint8List? thumbnailBytes;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Per-exercise rest-timer override in whole seconds. Null means "use
  /// the type-based default" (see [effectiveRestSeconds]). 0 explicitly
  /// disables the rest timer for this exercise.
  final int? defaultRestSeconds;

  /// Equipment label as supplied by the source library (e.g. 'barbell',
  /// 'body only'). Null for user-created exercises.
  final String? equipment;

  /// 'push' | 'pull' | 'static'.
  final String? force;

  /// 'beginner' | 'intermediate' | 'expert'.
  final String? level;

  /// 'compound' | 'isolation'.
  final String? mechanic;

  /// Source category — matches the pack id for library entries.
  final String? category;

  /// Source library's full primary muscle list. Always non-null; may be
  /// empty for user-created exercises.
  final List<String> primaryMuscles;

  /// Source library's secondary muscle list. Always non-null.
  final List<String> secondaryMuscles;

  /// Multi-step form instructions from the source library. Empty for
  /// user-created exercises.
  final List<String> instructions;

  /// Pack id this exercise was imported from. Null means user-created or
  /// legacy starter.
  final String? sourcePackId;

  /// Stable id within the source pack (e.g. 'Barbell_Bench_Press_-_Medium_Grip').
  final String? sourceExerciseId;

  /// Hidden from pickers and the main library list. Hidden exercises
  /// still resolve in workout history and individual lookups so past
  /// references keep working.
  final bool hidden;

  /// True when this exercise originated from a bundled library pack.
  bool get isLibraryExercise => sourcePackId != null;

  /// Effective rest-timer length using only the per-exercise override
  /// and per-type fallbacks. Provided for places that don't have a user
  /// default at hand; most callers want [resolveRestSeconds].
  int get effectiveRestSeconds => resolveRestSeconds();

  /// Effective rest-timer length. The chain is:
  ///   1. per-exercise override ([defaultRestSeconds]) — if set, wins.
  ///   2. user-level default (Timer settings) — if set.
  ///   3. per-type fallback — weighted=120, bodyweight=60, cardio=0.
  ///
  /// 0 at any layer means "off" (no timer fires for this exercise).
  int resolveRestSeconds({int? userDefault}) {
    final int? override = defaultRestSeconds;
    if (override != null) return override;
    if (userDefault != null) return userDefault;
    switch (type) {
      case ExerciseType.weighted:
        return 120;
      case ExerciseType.bodyweight:
        return 60;
      case ExerciseType.cardio:
        return 0;
    }
  }

  Exercise copyWith({
    String? id,
    String? name,
    ExerciseType? type,
    ExerciseMuscleGroup? muscleGroup,
    String? thumbnailPath,
    Uint8List? thumbnailBytes,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? defaultRestSeconds,
    String? equipment,
    String? force,
    String? level,
    String? mechanic,
    String? category,
    List<String>? primaryMuscles,
    List<String>? secondaryMuscles,
    List<String>? instructions,
    String? sourcePackId,
    String? sourceExerciseId,
    bool? hidden,
    bool clearThumbnailPath = false,
    bool clearThumbnailBytes = false,
    bool clearDefaultRestSeconds = false,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      thumbnailPath: clearThumbnailPath
          ? null
          : thumbnailPath ?? this.thumbnailPath,
      thumbnailBytes: clearThumbnailBytes
          ? null
          : thumbnailBytes ?? this.thumbnailBytes,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      defaultRestSeconds: clearDefaultRestSeconds
          ? null
          : defaultRestSeconds ?? this.defaultRestSeconds,
      equipment: equipment ?? this.equipment,
      force: force ?? this.force,
      level: level ?? this.level,
      mechanic: mechanic ?? this.mechanic,
      category: category ?? this.category,
      primaryMuscles: primaryMuscles ?? this.primaryMuscles,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      instructions: instructions ?? this.instructions,
      sourcePackId: sourcePackId ?? this.sourcePackId,
      sourceExerciseId: sourceExerciseId ?? this.sourceExerciseId,
      hidden: hidden ?? this.hidden,
    );
  }
}
