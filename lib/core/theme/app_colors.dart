import 'package:flutter/material.dart';

@immutable
class JellyBeanPalette extends ThemeExtension<JellyBeanPalette> {
  const JellyBeanPalette({
    required this.shade50,
    required this.shade100,
    required this.shade200,
    required this.shade300,
    required this.shade400,
    required this.shade500,
    required this.shade600,
    required this.shade700,
    required this.shade800,
    required this.shade900,
    required this.shade950,
  });

  const JellyBeanPalette.base()
    : shade50 = const Color(0xFFEFFBFC),
      shade100 = const Color(0xFFD7F3F6),
      shade200 = const Color(0xFFB3E7EE),
      shade300 = const Color(0xFF7FD4E1),
      shade400 = const Color(0xFF44B8CC),
      shade500 = const Color(0xFF289CB2),
      shade600 = const Color(0xFF26849D),
      shade700 = const Color(0xFF24667A),
      shade800 = const Color(0xFF255565),
      shade900 = const Color(0xFF234756),
      shade950 = const Color(0xFF122E3A);

  static const JellyBeanPalette light = JellyBeanPalette.base();
  static const JellyBeanPalette dark = JellyBeanPalette.base();

  final Color shade50;
  final Color shade100;
  final Color shade200;
  final Color shade300;
  final Color shade400;
  final Color shade500;
  final Color shade600;
  final Color shade700;
  final Color shade800;
  final Color shade900;
  final Color shade950;

  @override
  JellyBeanPalette copyWith({
    Color? shade50,
    Color? shade100,
    Color? shade200,
    Color? shade300,
    Color? shade400,
    Color? shade500,
    Color? shade600,
    Color? shade700,
    Color? shade800,
    Color? shade900,
    Color? shade950,
  }) {
    return JellyBeanPalette(
      shade50: shade50 ?? this.shade50,
      shade100: shade100 ?? this.shade100,
      shade200: shade200 ?? this.shade200,
      shade300: shade300 ?? this.shade300,
      shade400: shade400 ?? this.shade400,
      shade500: shade500 ?? this.shade500,
      shade600: shade600 ?? this.shade600,
      shade700: shade700 ?? this.shade700,
      shade800: shade800 ?? this.shade800,
      shade900: shade900 ?? this.shade900,
      shade950: shade950 ?? this.shade950,
    );
  }

  @override
  JellyBeanPalette lerp(ThemeExtension<JellyBeanPalette>? other, double t) {
    if (other is! JellyBeanPalette) {
      return this;
    }

    return JellyBeanPalette(
      shade50: Color.lerp(shade50, other.shade50, t) ?? shade50,
      shade100: Color.lerp(shade100, other.shade100, t) ?? shade100,
      shade200: Color.lerp(shade200, other.shade200, t) ?? shade200,
      shade300: Color.lerp(shade300, other.shade300, t) ?? shade300,
      shade400: Color.lerp(shade400, other.shade400, t) ?? shade400,
      shade500: Color.lerp(shade500, other.shade500, t) ?? shade500,
      shade600: Color.lerp(shade600, other.shade600, t) ?? shade600,
      shade700: Color.lerp(shade700, other.shade700, t) ?? shade700,
      shade800: Color.lerp(shade800, other.shade800, t) ?? shade800,
      shade900: Color.lerp(shade900, other.shade900, t) ?? shade900,
      shade950: Color.lerp(shade950, other.shade950, t) ?? shade950,
    );
  }
}

extension JellyBeanPaletteContext on BuildContext {
  JellyBeanPalette get jellyBeanPalette {
    return Theme.of(this).extension<JellyBeanPalette>()!;
  }
}
