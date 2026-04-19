class Workout {
  const Workout({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.templateId,
    this.notes,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? templateId;
  final String? notes;

  bool get isActive => endedAt == null;

  Workout copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? endedAt,
    String? templateId,
    String? notes,
    bool clearTemplateId = false,
    bool clearNotes = false,
  }) {
    return Workout(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      templateId: clearTemplateId ? null : templateId ?? this.templateId,
      notes: clearNotes ? null : notes ?? this.notes,
    );
  }
}
