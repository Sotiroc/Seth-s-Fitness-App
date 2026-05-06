import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/exercise.dart';

/// Letter/thumbnail badge for an exercise. The fallback letter background
/// can be passed in via [letterBackgroundColor] so list callers compute
/// the colour once at the list level and every row in the list shares
/// the same primitive — that way an unrelated theme change doesn't
/// invalidate every avatar's build via `Theme.of` / `JellyBeanPalette`
/// reads. When the colour is omitted the widget falls back to reading
/// the palette out of `context` (kept for one-off / non-list usages).
class ExerciseAvatar extends StatelessWidget {
  const ExerciseAvatar({
    super.key,
    required this.exercise,
    this.size = 48,
    this.letterBackgroundColor,
  });

  final Exercise exercise;
  final double size;
  final Color? letterBackgroundColor;

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

    final Color background =
        letterBackgroundColor ?? context.jellyBeanPalette.shade500;
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
