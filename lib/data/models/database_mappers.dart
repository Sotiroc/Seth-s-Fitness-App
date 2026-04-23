import '../db/app_database.dart';
import 'exercise.dart';
import 'template_exercise.dart';
import 'workout.dart';
import 'workout_exercise.dart';
import 'workout_set.dart';
import 'workout_template.dart';

extension ExerciseRowMapper on ExerciseRow {
  Exercise toModel() {
    return Exercise(
      id: id,
      name: name,
      type: type,
      muscleGroup: muscleGroup,
      thumbnailPath: thumbnailPath,
      isDefault: isDefault,
      createdAt: createdAt,
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
    );
  }
}
