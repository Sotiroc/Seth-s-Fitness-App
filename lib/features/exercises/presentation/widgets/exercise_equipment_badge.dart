import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Compact equipment chip rendered next to the type and muscle-group
/// badges on exercise tiles. Source equipment values from the bundled
/// library packs are short labels like 'barbell', 'body only', 'cable',
/// 'kettlebells'. Unknown / null is rendered as nothing — the caller
/// should null-check before adding the badge.
class ExerciseEquipmentBadge extends StatelessWidget {
  const ExerciseEquipmentBadge({super.key, required this.equipment});

  final String equipment;

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.shade50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.shade200, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.fitness_center, size: 10, color: palette.shade700),
          const SizedBox(width: 4),
          Text(
            _label(equipment).toUpperCase(),
            style: TextStyle(
              color: palette.shade800,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  String _label(String raw) {
    switch (raw) {
      case 'body only':
        return 'Bodyweight';
      case 'kettlebells':
        return 'Kettlebell';
      case 'foam roll':
        return 'Foam roller';
      case 'exercise ball':
        return 'Stability ball';
      case 'medicine ball':
        return 'Med ball';
      case 'bands':
        return 'Bands';
      case 'cable':
        return 'Cable';
      case 'machine':
        return 'Machine';
      case 'barbell':
        return 'Barbell';
      case 'dumbbell':
        return 'Dumbbell';
      case 'other':
        return 'Other';
      default:
        return raw[0].toUpperCase() + raw.substring(1);
    }
  }
}
