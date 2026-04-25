import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/template_exercise.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/workout_template.dart';
import '../../../data/repositories/template_repository.dart';
import 'template_providers.dart';

part 'template_editor_controller.g.dart';

@Riverpod(keepAlive: true)
class TemplateEditorController extends _$TemplateEditorController {
  @override
  FutureOr<void> build() {}

  Future<WorkoutTemplate> createTemplate({
    required String name,
    required List<TemplateExerciseDraft> exercises,
  }) {
    return _runMutation(() async {
      final WorkoutTemplate template = await ref
          .read(templateRepositoryProvider)
          .createTemplate(name: name, exercises: exercises);
      _invalidateTemplateState(templateId: template.id);
      return template;
    });
  }

  Future<WorkoutTemplate> updateTemplate({
    required WorkoutTemplate template,
    required List<TemplateExerciseDraft> exercises,
  }) {
    return _runMutation(() async {
      final WorkoutTemplate updated = await ref
          .read(templateRepositoryProvider)
          .updateTemplate(template: template, exercises: exercises);
      _invalidateTemplateState(templateId: updated.id);
      return updated;
    });
  }

  Future<void> deleteTemplate(String templateId) {
    return _runMutation(() async {
      await ref.read(templateRepositoryProvider).deleteTemplate(templateId);
      _invalidateTemplateState(templateId: templateId);
    });
  }

  Future<Workout> startWorkoutFromTemplate(String templateId) {
    return _runMutation(() async {
      final Workout workout = await ref
          .read(templateRepositoryProvider)
          .createWorkoutFromTemplate(templateId);
      _invalidateTemplateState(templateId: templateId);
      return workout;
    });
  }

  void _invalidateTemplateState({required String templateId}) {
    ref.invalidate(templateListProvider);
    ref.invalidate(templateDetailProvider(templateId));
  }

  Future<T> _runMutation<T>(Future<T> Function() action) async {
    state = const AsyncLoading();
    try {
      final T result = await action();
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
