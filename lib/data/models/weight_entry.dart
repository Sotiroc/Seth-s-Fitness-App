/// Provenance of a [WeightEntry]. The string column stores the enum name;
/// the mapper decodes tolerantly so adding values later is non-breaking.
enum WeightEntrySource {
  /// Logged from the "Log weight" sheet on the Progression page.
  manual,

  /// Auto-logged when the user changed their weight in the profile form.
  /// Deduped per local day via deterministic id `profile-yyyyMMdd`.
  profile,

  /// Seeded once by the v8 migration from the user's existing
  /// `UserProfile.weightKg` so the chart isn't empty on first launch.
  backfill;

  static WeightEntrySource fromName(String? raw) {
    if (raw == null) return WeightEntrySource.manual;
    for (final WeightEntrySource s in WeightEntrySource.values) {
      if (s.name == raw) return s;
    }
    return WeightEntrySource.manual;
  }
}

/// One body-weight measurement on the user's timeline. All weights are
/// stored canonically in kilograms; the UI converts to lb based on the
/// active [UnitSystem].
class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.measuredAt,
    required this.weightKg,
    required this.source,
    required this.createdAt,
  });

  final String id;

  /// When the measurement was taken. UTC.
  final DateTime measuredAt;

  final double weightKg;

  final WeightEntrySource source;

  /// When the row was inserted. Different from [measuredAt] when the user
  /// back-dates an entry from the log sheet, or when the migration
  /// backfills a profile weight at upgrade time.
  final DateTime createdAt;

  WeightEntry copyWith({
    String? id,
    DateTime? measuredAt,
    double? weightKg,
    WeightEntrySource? source,
    DateTime? createdAt,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      measuredAt: measuredAt ?? this.measuredAt,
      weightKg: weightKg ?? this.weightKg,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
