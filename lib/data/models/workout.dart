class Workout {
  const Workout({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.templateId,
    this.notes,
    this.name,
    this.intensityScore,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? templateId;
  final String? notes;

  /// Optional user-assigned display name (e.g. "Leg day — light"). Null means
  /// the UI should fall back to a date/template-derived label.
  final String? name;

  /// Optional 1–10 session RPE captured on the summary screen. Null means
  /// the user skipped it.
  final int? intensityScore;

  bool get isActive => endedAt == null;

  Workout copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? endedAt,
    String? templateId,
    String? notes,
    String? name,
    int? intensityScore,
    bool clearTemplateId = false,
    bool clearNotes = false,
    bool clearName = false,
    bool clearIntensityScore = false,
    bool clearEndedAt = false,
  }) {
    return Workout(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : endedAt ?? this.endedAt,
      templateId: clearTemplateId ? null : templateId ?? this.templateId,
      notes: clearNotes ? null : notes ?? this.notes,
      name: clearName ? null : name ?? this.name,
      intensityScore: clearIntensityScore
          ? null
          : intensityScore ?? this.intensityScore,
    );
  }
}
