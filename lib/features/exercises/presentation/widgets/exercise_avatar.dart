import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/exercise.dart';

class ExerciseAvatar extends StatelessWidget {
  const ExerciseAvatar({super.key, required this.exercise, this.size = 48});

  final Exercise exercise;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = exercise.thumbnailBytes;
    final BorderRadius radius = BorderRadius.circular(size / 4);

    if (bytes != null && bytes.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }

    final JellyBeanPalette palette = context.jellyBeanPalette;
    final Color background = _backgroundColorFor(exercise.name, palette);
    final Color foreground = _foregroundColorFor(background);
    final String letter = _firstLetter(exercise.name);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  static String _firstLetter(String name) {
    for (final int rune in name.runes) {
      final String ch = String.fromCharCode(rune);
      if (ch.trim().isNotEmpty) {
        return ch.toUpperCase();
      }
    }
    return '?';
  }

  static Color _backgroundColorFor(String name, JellyBeanPalette palette) {
    final List<Color> options = <Color>[
      palette.shade300,
      palette.shade400,
      palette.shade500,
      palette.shade600,
      palette.shade700,
      palette.shade800,
    ];
    int hash = 0;
    for (final int unit in name.toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return options[hash % options.length];
  }

  static Color _foregroundColorFor(Color background) {
    final double luminance = background.computeLuminance();
    return luminance > 0.55 ? const Color(0xFF0F2630) : Colors.white;
  }
}
