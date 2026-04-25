import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/exercise_muscle_group.dart';

class ExerciseMuscleGroupBadge extends StatelessWidget {
  const ExerciseMuscleGroupBadge({super.key, required this.muscleGroup});

  final ExerciseMuscleGroup muscleGroup;

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final (Color background, Color foreground) style = _styleFor(
      muscleGroup,
      palette,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        muscleGroup.label.toUpperCase(),
        style: TextStyle(
          color: style.$2,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  (Color, Color) _styleFor(ExerciseMuscleGroup value, JellyBeanPalette p) {
    switch (value) {
      case ExerciseMuscleGroup.legs:
        return (p.shade100, p.shade800);
      case ExerciseMuscleGroup.biceps:
        return (p.shade50, p.shade700);
      case ExerciseMuscleGroup.triceps:
        return (p.shade200, p.shade900);
      case ExerciseMuscleGroup.chest:
        return (p.shade100, p.shade900);
      case ExerciseMuscleGroup.back:
        return (p.shade50, p.shade800);
      case ExerciseMuscleGroup.shoulders:
        return (p.shade200, p.shade800);
      case ExerciseMuscleGroup.abs:
        return (p.shade100, p.shade700);
      case ExerciseMuscleGroup.cardio:
        return (p.shade200, p.shade900);
    }
  }
}
