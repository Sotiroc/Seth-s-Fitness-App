import '../../data/models/unit_system.dart';

/// Conversion helpers between metric (the canonical storage units in the
/// database) and imperial display values used by the Profile UI.
abstract final class UnitConversions {
  static const double _kgPerLb = 0.45359237;
  static const double _cmPerInch = 2.54;
  static const double _inchesPerFoot = 12;

  // ---- Weight ----

  static double kgToLb(double kg) => kg / _kgPerLb;
  static double lbToKg(double lb) => lb * _kgPerLb;

  /// Formats a stored kilogram value for display in the active unit system.
  /// Returns null when the input is null so the UI can render "Not set".
  static String? formatWeight(double? kg, UnitSystem system) {
    if (kg == null) return null;
    switch (system) {
      case UnitSystem.metric:
        return '${_trimZero(kg, 1)} kg';
      case UnitSystem.imperial:
        return '${_trimZero(kgToLb(kg), 1)} lb';
    }
  }

  /// Returns the editable value to seed a weight TextFormField in the active
  /// unit system. Empty string when the underlying value is null.
  static String weightInputValue(double? kg, UnitSystem system) {
    if (kg == null) return '';
    switch (system) {
      case UnitSystem.metric:
        return _trimZero(kg, 1);
      case UnitSystem.imperial:
        return _trimZero(kgToLb(kg), 1);
    }
  }

  /// Parses raw form text in the given unit system and returns the canonical
  /// kilogram value. Returns null when the input is empty or unparseable.
  static double? parseWeightToKg(String input, UnitSystem system) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final double? value = _tryParseDecimal(trimmed);
    if (value == null) return null;
    switch (system) {
      case UnitSystem.metric:
        return value;
      case UnitSystem.imperial:
        return lbToKg(value);
    }
  }

  // ---- Height ----

  /// Splits a centimeter measurement into integer feet + remaining inches.
  static ({int feet, double inches}) cmToFeetInches(double cm) {
    final double totalInches = cm / _cmPerInch;
    final int feet = totalInches ~/ _inchesPerFoot;
    final double inches = totalInches - feet * _inchesPerFoot;
    return (feet: feet, inches: inches);
  }

  static double feetInchesToCm(int feet, double inches) {
    final double totalInches = feet * _inchesPerFoot + inches;
    return totalInches * _cmPerInch;
  }

  /// Formats a stored centimeter value for display in the active unit system.
  static String? formatHeight(double? cm, UnitSystem system) {
    if (cm == null) return null;
    switch (system) {
      case UnitSystem.metric:
        return '${_trimZero(cm, 0)} cm';
      case UnitSystem.imperial:
        final ({int feet, double inches}) parts = cmToFeetInches(cm);
        return '${parts.feet}\'${_trimZero(parts.inches, 0)}"';
    }
  }

  /// Seed value for a metric height TextFormField (cm).
  static String heightCmInputValue(double? cm) {
    if (cm == null) return '';
    return _trimZero(cm, 0);
  }

  /// Seed values for an imperial height entry — feet and inches as separate
  /// fields. Returns empty strings when the underlying value is null.
  static ({String feet, String inches}) heightFeetInchesInputValue(double? cm) {
    if (cm == null) return (feet: '', inches: '');
    final ({int feet, double inches}) parts = cmToFeetInches(cm);
    return (feet: parts.feet.toString(), inches: _trimZero(parts.inches, 0));
  }

  /// Parses metric height input (cm) to the canonical centimeter value.
  static double? parseHeightCm(String input) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    return _tryParseDecimal(trimmed);
  }

  /// Parses imperial height inputs (feet + inches) to the canonical centimeter
  /// value. Returns null only when both inputs are empty; treats either field
  /// being non-empty as an explicit value (the other defaults to 0).
  static double? parseHeightFeetInchesToCm(
    String feetInput,
    String inchesInput,
  ) {
    final String feetTrim = feetInput.trim();
    final String inchesTrim = inchesInput.trim();
    if (feetTrim.isEmpty && inchesTrim.isEmpty) return null;
    final int? feet = feetTrim.isEmpty ? 0 : int.tryParse(feetTrim);
    final double? inches = inchesTrim.isEmpty
        ? 0.0
        : _tryParseDecimal(inchesTrim);
    if (feet == null || inches == null) return null;
    return feetInchesToCm(feet, inches);
  }

  // ---- Internal ----

  /// Parses a decimal number, accepting both `.` and `,` as the decimal
  /// separator so users in comma-locale regions can type "78,5".
  static double? _tryParseDecimal(String trimmed) =>
      double.tryParse(trimmed.replaceAll(',', '.'));

  static String _trimZero(double value, int maxFractionDigits) {
    if (maxFractionDigits <= 0) {
      return value.round().toString();
    }
    final String formatted = value.toStringAsFixed(maxFractionDigits);
    if (!formatted.contains('.')) return formatted;
    final String trimmed = formatted
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
    return trimmed.isEmpty ? '0' : trimmed;
  }
}
