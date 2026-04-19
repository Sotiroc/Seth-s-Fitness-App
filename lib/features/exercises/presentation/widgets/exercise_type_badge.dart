import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/exercise_type.dart';

class ExerciseTypeBadge extends StatelessWidget {
  const ExerciseTypeBadge({super.key, required this.type});

  final ExerciseType type;

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final (Color background, Color foreground, IconData icon) style = _styleFor(
      type,
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
            type.label.toUpperCase(),
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

  (Color, Color, IconData) _styleFor(ExerciseType type, JellyBeanPalette p) {
    switch (type) {
      case ExerciseType.weighted:
        return (p.shade100, p.shade800, Icons.fitness_center_rounded);
      case ExerciseType.bodyweight:
        return (p.shade50, p.shade700, Icons.self_improvement_rounded);
      case ExerciseType.cardio:
        return (p.shade200, p.shade900, Icons.directions_run_rounded);
    }
  }
}
