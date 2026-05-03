import 'dart:convert';

import '../db/app_database.dart';
import 'exercise.dart';
import 'exercise_muscle_group.dart';
import 'exercise_pack.dart';
import 'template_exercise.dart';
import 'user_profile.dart';
import 'weight_entry.dart';
import 'workout.dart';
import 'workout_exercise.dart';
import 'workout_set.dart';
import 'workout_set_kind.dart';
import 'workout_template.dart';

extension ExerciseRowMapper on ExerciseRow {
  Exercise toModel() {
    return Exercise(
      id: id,
      name: name,
      type: type,
      muscleGroup: muscleGroup,
      thumbnailPath: thumbnailPath,
      thumbnailBytes: thumbnailBytes,
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
      defaultRestSeconds: defaultRestSeconds,
      equipment: equipment,
      force: force,
      level: level,
      mechanic: mechanic,
      category: category,
      primaryMuscles: decodeStringListJson(primaryMusclesJson),
      secondaryMuscles: decodeStringListJson(secondaryMusclesJson),
      instructions: decodeStringListJson(instructionsJson),
      sourcePackId: sourcePackId,
      sourceExerciseId: sourceExerciseId,
      hidden: hidden,
    );
  }
}

extension ExercisePackRowMapper on ExercisePackRow {
  ExercisePack toModel() {
    return ExercisePack(
      id: id,
      name: name,
      description: description,
      credit: credit,
      license: license,
      assetPath: assetPath,
      isActive: isActive,
      schemaVersion: schemaVersion,
      exerciseCount: exerciseCount,
      installedAt: installedAt,
      updatedAt: updatedAt,
    );
  }
}

extension WorkoutTemplateRowMapper on WorkoutTemplateRow {
  WorkoutTemplate toModel() {
    return WorkoutTemplate(
      id: id,
      name: name,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension TemplateExerciseRowMapper on TemplateExerciseRow {
  TemplateExercise toModel() {
    return TemplateExercise(
      id: id,
      templateId: templateId,
      exerciseId: exerciseId,
      orderIndex: orderIndex,
      defaultSets: defaultSets,
    );
  }
}

extension WorkoutRowMapper on WorkoutRow {
  Workout toModel() {
    return Workout(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      templateId: templateId,
      notes: notes,
      name: name,
      intensityScore: intensityScore,
    );
  }
}

extension WorkoutExerciseRowMapper on WorkoutExerciseRow {
  WorkoutExercise toModel() {
    return WorkoutExercise(
      id: id,
      workoutId: workoutId,
      exerciseId: exerciseId,
      orderIndex: orderIndex,
      createdAt: createdAt,
    );
  }
}

extension WorkoutSetRowMapper on WorkoutSetRow {
  WorkoutSet toModel() {
    return WorkoutSet(
      id: id,
      workoutExerciseId: workoutExerciseId,
      setNumber: setNumber,
      weightKg: weightKg,
      reps: reps,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      completed: completed,
      completedAt: completedAt,
      updatedAt: updatedAt,
      startedAt: startedAt,
      kind: WorkoutSetKind.fromName(kind),
      parentSetId: parentSetId,
      rpe: rpe,
      note: note,
    );
  }
}

extension UserProfileRowMapper on UserProfileRow {
  UserProfile toModel() {
    return UserProfile(
      id: id,
      name: name,
      ageYears: ageYears,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      goalWeightKg: goalWeightKg,
      bodyFatPercent: bodyFatPercent,
      diabetic: diabetic,
      muscleGroupPriority: muscleGroupPriority,
      muscleGoals: decodeMuscleGoalsJson(muscleGoalsJson),
      unitSystem: unitSystem,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension WeightEntryRowMapper on WeightEntryRow {
  WeightEntry toModel() {
    return WeightEntry(
      id: id,
      measuredAt: measuredAt,
      weightKg: weightKg,
      source: WeightEntrySource.fromName(source),
      createdAt: createdAt,
    );
  }
}

/// Decodes the `muscleGoalsJson` text column into a typed map. Unknown
/// muscle keys are skipped so deleting an enum value later doesn't crash
/// reads on existing rows.
Map<ExerciseMuscleGroup, int>? decodeMuscleGoalsJson(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final Object? parsed = jsonDecode(raw);
    if (parsed is! Map<String, dynamic>) return null;
    final Map<ExerciseMuscleGroup, int> out = <ExerciseMuscleGroup, int>{};
    for (final MapEntry<String, dynamic> entry in parsed.entries) {
      final ExerciseMuscleGroup? mg = _muscleGroupByName(entry.key);
      if (mg == null) continue;
      final Object? value = entry.value;
      if (value is int) {
        out[mg] = value;
      } else if (value is num) {
        out[mg] = value.toInt();
      }
    }
    return out.isEmpty ? null : out;
  } catch (_) {
    return null;
  }
}

/// Inverse of [decodeMuscleGoalsJson]. Returns `null` for null/empty maps so
/// the column stays NULL rather than holding `"{}"`.
String? encodeMuscleGoalsJson(Map<ExerciseMuscleGroup, int>? goals) {
  if (goals == null || goals.isEmpty) return null;
  final Map<String, int> out = <String, int>{
    for (final MapEntry<ExerciseMuscleGroup, int> e in goals.entries)
      e.key.name: e.value,
  };
  return jsonEncode(out);
}

ExerciseMuscleGroup? _muscleGroupByName(String name) {
  for (final ExerciseMuscleGroup mg in ExerciseMuscleGroup.values) {
    if (mg.name == name) return mg;
  }
  return null;
}

/// Tolerant decoder for the JSON-encoded `List<String>` columns on
/// exercises (primary muscles, secondary muscles, instructions). Returns
/// an empty list for null/empty input or anything that fails to parse,
/// so a corrupt row never crashes a list query.
List<String> decodeStringListJson(String? raw) {
  if (raw == null || raw.isEmpty) return const <String>[];
  try {
    final Object? parsed = jsonDecode(raw);
    if (parsed is! List<dynamic>) return const <String>[];
    return <String>[
      for (final dynamic item in parsed)
        if (item is String) item,
    ];
  } catch (_) {
    return const <String>[];
  }
}

/// Inverse of [decodeStringListJson]. Returns null for empty input so
/// the column stays NULL rather than holding `"[]"`.
String? encodeStringListJson(List<String>? values) {
  if (values == null || values.isEmpty) return null;
  return jsonEncode(values);
}
