import 'exercise.dart';
import 'template_exercise.dart';
import 'workout_template.dart';

class TemplateDetail {
  const TemplateDetail({required this.template, required this.exercises});

  final WorkoutTemplate template;
  final List<TemplateExerciseDetail> exercises;
}

class TemplateExerciseDetail {
  const TemplateExerciseDetail({
    required this.templateExercise,
    required this.exercise,
  });

  final TemplateExercise templateExercise;
  final Exercise exercise;
}
