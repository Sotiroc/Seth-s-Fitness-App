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
    final String letter = _firstLetter(exercise.name);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.shade500,
        borderRadius: radius,
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ).copyWith(fontSize: size * 0.42),
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
}
