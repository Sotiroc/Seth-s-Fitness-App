class TemplateExercise {
  const TemplateExercise({
    required this.id,
    required this.templateId,
    required this.exerciseId,
    required this.orderIndex,
    required this.defaultSets,
  });

  final String id;
  final String templateId;
  final String exerciseId;
  final int orderIndex;
  final int defaultSets;
}

class TemplateExerciseDraft {
  const TemplateExerciseDraft({
    required this.exerciseId,
    required this.orderIndex,
    required this.defaultSets,
  });

  final String exerciseId;
  final int orderIndex;
  final int defaultSets;
}
