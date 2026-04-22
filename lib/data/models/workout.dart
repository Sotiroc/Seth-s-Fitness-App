class Workout {
  const Workout({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.templateId,
    this.notes,
    this.name,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? templateId;
  final String? notes;

  /// Optional user-assigned display name (e.g. "Leg day — light"). Null means
  /// the UI should fall back to a date/template-derived label.
  final String? name;

  bool get isActive => endedAt == null;

  Workout copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? endedAt,
    String? templateId,
    String? notes,
    String? name,
    bool clearTemplateId = false,
    bool clearNotes = false,
    bool clearName = false,
  }) {
    return Workout(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      templateId: clearTemplateId ? null : templateId ?? this.templateId,
      notes: clearNotes ? null : notes ?? this.notes,
      name: clearName ? null : name ?? this.name,
    );
  }
}
