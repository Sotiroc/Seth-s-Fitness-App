import 'dart:convert';

import '../db/app_database.dart';
import 'cardio_metric.dart';
import 'exercise.dart';
import 'exercise_equipment.dart';
import 'exercise_muscle_group.dart';
import 'exercise_type.dart';
import 'template_exercise.dart';
import 'user_profile.dart';
import 'weekly_recap.dart';
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
      trackedMetrics: decodeCardioMetrics(trackedMetrics),
      equipment: decodeExerciseEquipment(equipment),
      formCue: formCue,
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
      notes: notes,
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
      laps: laps,
      floors: floors,
      calories: calories,
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

extension WeeklyRecapRowMapper on WeeklyRecapRow {
  WeeklyRecap toModel() {
    return WeeklyRecap(
      id: id,
      weekStart: weekStart,
      weekEnd: weekEnd,
      workoutCount: workoutCount,
      totalVolumeKg: totalVolumeKg,
      totalDurationSeconds: totalDurationSeconds,
      averageRpe: averageRpe,
      prs: decodeWeeklyRecapPrsJson(prsJson),
      dailyVolumeKg: decodeDailyVolumeKgJson(dailyVolumeKgJson),
      prevWorkoutCount: prevWorkoutCount,
      prevTotalVolumeKg: prevTotalVolumeKg,
      generatedAt: generatedAt,
    );
  }
}

/// Decodes the prsJson column. Returns an empty list on null/empty/parse
/// failure so the recap card stays renderable for malformed snapshots.
List<WeeklyRecapPr> decodeWeeklyRecapPrsJson(String? raw) {
  if (raw == null || raw.isEmpty) return const <WeeklyRecapPr>[];
  try {
    final Object? parsed = jsonDecode(raw);
    if (parsed is! List) return const <WeeklyRecapPr>[];
    final List<WeeklyRecapPr> out = <WeeklyRecapPr>[];
    for (final Object? entry in parsed) {
      if (entry is! Map) continue;
      final Map<String, dynamic> map = Map<String, dynamic>.from(entry);
      final String? exerciseName = map['exerciseName'] as String?;
      final String? exerciseTypeName = map['exerciseType'] as String?;
      final String? type = map['type'] as String?;
      if (exerciseName == null || exerciseTypeName == null || type == null) {
        continue;
      }
      final ExerciseType exerciseType = ExerciseType.values.firstWhere(
        (ExerciseType t) => t.name == exerciseTypeName,
        orElse: () => ExerciseType.weighted,
      );
      out.add(
        WeeklyRecapPr(
          exerciseName: exerciseName,
          exerciseType: exerciseType,
          type: type,
          weightKg: (map['weightKg'] as num?)?.toDouble(),
          reps: (map['reps'] as num?)?.toInt(),
          distanceKm: (map['distanceKm'] as num?)?.toDouble(),
          durationSeconds: (map['durationSeconds'] as num?)?.toInt(),
          laps: (map['laps'] as num?)?.toInt(),
          floors: (map['floors'] as num?)?.toInt(),
          calories: (map['calories'] as num?)?.toInt(),
          oneRepMaxKg: (map['oneRepMaxKg'] as num?)?.toDouble(),
          repCountForRepMax: (map['repCountForRepMax'] as num?)?.toInt(),
        ),
      );
    }
    return out;
  } catch (_) {
    return const <WeeklyRecapPr>[];
  }
}

String encodeWeeklyRecapPrsJson(List<WeeklyRecapPr> prs) {
  return jsonEncode(<Map<String, Object?>>[
    for (final WeeklyRecapPr p in prs)
      <String, Object?>{
        'exerciseName': p.exerciseName,
        'exerciseType': p.exerciseType.name,
        'type': p.type,
        if (p.weightKg != null) 'weightKg': p.weightKg,
        if (p.reps != null) 'reps': p.reps,
        if (p.distanceKm != null) 'distanceKm': p.distanceKm,
        if (p.durationSeconds != null) 'durationSeconds': p.durationSeconds,
        if (p.laps != null) 'laps': p.laps,
        if (p.floors != null) 'floors': p.floors,
        if (p.calories != null) 'calories': p.calories,
        if (p.oneRepMaxKg != null) 'oneRepMaxKg': p.oneRepMaxKg,
        if (p.repCountForRepMax != null)
          'repCountForRepMax': p.repCountForRepMax,
      },
  ]);
}

/// Decodes the 7-element daily-volume list. Pads / truncates to length 7
/// so consumers can index unconditionally.
List<double> decodeDailyVolumeKgJson(String raw) {
  try {
    final Object? parsed = jsonDecode(raw);
    if (parsed is! List) return List<double>.filled(7, 0);
    final List<double> out = <double>[
      for (final Object? value in parsed)
        if (value is num) value.toDouble() else 0.0,
    ];
    if (out.length == 7) return out;
    if (out.length > 7) return out.sublist(0, 7);
    return <double>[...out, ...List<double>.filled(7 - out.length, 0)];
  } catch (_) {
    return List<double>.filled(7, 0);
  }
}

String encodeDailyVolumeKgJson(List<double> daily) {
  return jsonEncode(daily);
}
