import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/workout_set_kind.dart';

/// Centralised lookup for the colors and short labels each [WorkoutSetKind]
/// renders with. Keeping this in one place stops the row, the bottom sheet,
/// and the badge cluster from drifting apart visually.
///
/// Color choices are intentionally subtle so the set list reads as a single
/// surface and the brand teal still wins. Per design direction:
/// - warm-up uses a very light amber tint with a darker amber accent
/// - drop uses a soft purple tint with a darker purple accent
/// - failure uses a soft red tint with a darker red accent
/// - normal has neither tint nor accent — the row keeps the brand palette
class SetKindVisuals {
  const SetKindVisuals({
    required this.shortLabel,
    required this.longLabel,
    this.tint,
    this.accent,
  });

  /// Single-letter (or 2-letter) marker shown on the row badge and the
  /// chip's left icon-square (e.g. `W`, `D`, `F`, `N`).
  final String shortLabel;

  /// Full word for the chip in the bottom sheet (e.g. "Warm-up").
  final String longLabel;

  /// Background tint for the row stripe / chip background. Null for
  /// [WorkoutSetKind.normal] — that case keeps the brand palette.
  final Color? tint;

  /// Foreground / border accent. Null for [WorkoutSetKind.normal].
  final Color? accent;

  static SetKindVisuals forKind(WorkoutSetKind kind, JellyBeanPalette palette) {
    switch (kind) {
      case WorkoutSetKind.normal:
        return const SetKindVisuals(shortLabel: 'N', longLabel: 'Normal');
      case WorkoutSetKind.warmUp:
        // Very light amber tint, darker amber accent. Subtle by design so
        // it doesn't fight the teal brand on the surrounding surface.
        return const SetKindVisuals(
          shortLabel: 'W',
          longLabel: 'Warm-up',
          tint: Color(0xFFFFF7E0),
          accent: Color(0xFFB7791F),
        );
      case WorkoutSetKind.drop:
        // Soft purple tint, darker purple accent. Distinct from warm-up so
        // a row of indented drops reads as a chain at a glance.
        return const SetKindVisuals(
          shortLabel: 'D',
          longLabel: 'Drop',
          tint: Color(0xFFF1E9FA),
          accent: Color(0xFF6B46C1),
        );
      case WorkoutSetKind.failure:
        // Soft red tint, deeper red accent. Reserved for true failure —
        // visually loud enough that it pulls the eye but doesn't scream.
        return const SetKindVisuals(
          shortLabel: 'F',
          longLabel: 'Failure',
          tint: Color(0xFFFCE9E9),
          accent: Color(0xFFC53030),
        );
    }
  }
}
