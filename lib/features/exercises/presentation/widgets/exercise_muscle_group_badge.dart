import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/exercise_muscle_group.dart';

class ExerciseMuscleGroupBadge extends StatelessWidget {
  const ExerciseMuscleGroupBadge({super.key, required this.muscleGroup});

  final ExerciseMuscleGroup muscleGroup;

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final (Color background, Color foreground, IconData icon) style = _styleFor(
      muscleGroup,
      palette,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(style.$3, size: 12, color: style.$2),
          const SizedBox(width: 4),
          Text(
            muscleGroup.label.toUpperCase(),
            style: TextStyle(
              color: style.$2,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, IconData) _styleFor(
    ExerciseMuscleGroup value,
    JellyBeanPalette p,
  ) {
    switch (value) {
      case ExerciseMuscleGroup.legs:
        return (p.shade100, p.shade800, Icons.directions_walk_rounded);
      case ExerciseMuscleGroup.biceps:
        return (p.shade50, p.shade700, Icons.sports_gymnastics_rounded);
      case ExerciseMuscleGroup.triceps:
        return (p.shade200, p.shade900, Icons.straighten_rounded);
      case ExerciseMuscleGroup.chest:
        return (p.shade100, p.shade900, Icons.favorite_outline_rounded);
      case ExerciseMuscleGroup.back:
        return (p.shade50, p.shade800, Icons.accessibility_new_rounded);
      case ExerciseMuscleGroup.shoulders:
        return (p.shade200, p.shade800, Icons.pan_tool_outlined);
      case ExerciseMuscleGroup.abs:
        return (p.shade100, p.shade700, Icons.crop_7_5_rounded);
      case ExerciseMuscleGroup.cardio:
        return (p.shade200, p.shade900, Icons.monitor_heart_outlined);
    }
  }
}
