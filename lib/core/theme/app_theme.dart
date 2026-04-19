import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const Color seedColor = Color(0xFF289CB2);
  static const List<String> _fontFamilyFallback = <String>['Manrope'];

  static ThemeData light() {
    return _buildTheme(Brightness.light);
  }

  static ThemeData dark() {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final TextTheme textTheme = _withFallback(
      GoogleFonts.interTextTheme(
        ThemeData(
          colorScheme: colorScheme,
          brightness: brightness,
          useMaterial3: true,
        ).textTheme,
      ).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        brightness == Brightness.light
            ? JellyBeanPalette.light
            : JellyBeanPalette.dark,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          final FontWeight weight = states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500;
          return textTheme.labelMedium?.copyWith(fontWeight: weight);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        disabledColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        secondarySelectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.labelMedium!.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: textTheme.labelMedium!.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  static TextTheme _withFallback(TextTheme textTheme) {
    return TextTheme(
      displayLarge: _withFontFallback(textTheme.displayLarge),
      displayMedium: _withFontFallback(textTheme.displayMedium),
      displaySmall: _withFontFallback(textTheme.displaySmall),
      headlineLarge: _withFontFallback(textTheme.headlineLarge),
      headlineMedium: _withFontFallback(textTheme.headlineMedium),
      headlineSmall: _withFontFallback(textTheme.headlineSmall),
      titleLarge: _withFontFallback(textTheme.titleLarge),
      titleMedium: _withFontFallback(textTheme.titleMedium),
      titleSmall: _withFontFallback(textTheme.titleSmall),
      bodyLarge: _withFontFallback(textTheme.bodyLarge),
      bodyMedium: _withFontFallback(textTheme.bodyMedium),
      bodySmall: _withFontFallback(textTheme.bodySmall),
      labelLarge: _withFontFallback(textTheme.labelLarge),
      labelMedium: _withFontFallback(textTheme.labelMedium),
      labelSmall: _withFontFallback(textTheme.labelSmall),
    );
  }

  static TextStyle? _withFontFallback(TextStyle? style) {
    return style?.copyWith(fontFamilyFallback: _fontFamilyFallback);
  }
}
