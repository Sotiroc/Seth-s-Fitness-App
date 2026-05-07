import 'dart:async';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/cardio_metric.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/exercise_equipment.dart';
import '../../../data/models/exercise_muscle_group.dart';
import '../../../data/models/exercise_type.dart';
import '../../../data/repositories/exercise_repository.dart';

part 'exercise_editor_controller.g.dart';

/// Page-local — only the exercise form mounts this. Auto-dispose so the
/// busy/error AsyncValue resets cleanly when the editor closes.
@riverpod
class ExerciseEditorController extends _$ExerciseEditorController {
  @override
  FutureOr<void> build() {}

  Future<Exercise> createExercise({
    required String name,
    required ExerciseType type,
    required ExerciseMuscleGroup muscleGroup,
    Uint8List? thumbnailBytes,
    int? defaultRestSeconds,
    List<CardioMetric>? trackedMetrics,
    ExerciseEquipment? equipment,
    String? formCue,
  }) {
    // Resolve the repository synchronously before any async gap. This
    // controller is auto-disposed by Riverpod, and reading `ref` inside
    // the async closure can race with disposal — surfaces as
    // "Cannot use the Ref of … after it has been disposed".
    final ExerciseRepository repository = ref.read(exerciseRepositoryProvider);
    return _runMutation(() {
      return repository.createExercise(
        name: name,
        type: type,
        muscleGroup: muscleGroup,
        thumbnailBytes: thumbnailBytes,
        defaultRestSeconds: defaultRestSeconds,
        trackedMetrics: trackedMetrics,
        equipment: equipment,
        formCue: formCue,
      );
    });
  }

  Future<Exercise> updateExercise({
    required Exercise exercise,
    required String name,
    required ExerciseType type,
    required ExerciseMuscleGroup muscleGroup,
    Uint8List? thumbnailBytes,
    bool clearThumbnail = false,
    int? defaultRestSeconds,
    bool clearDefaultRestSeconds = false,
    List<CardioMetric>? trackedMetrics,
    bool clearTrackedMetrics = false,
    ExerciseEquipment? equipment,
    bool clearEquipment = false,
    String? formCue,
    bool clearFormCue = false,
  }) {
    final ExerciseRepository repository = ref.read(exerciseRepositoryProvider);
    return _runMutation(() {
      return repository.updateExercise(
        exercise.copyWith(
          name: name,
          type: type,
          muscleGroup: muscleGroup,
          thumbnailBytes: thumbnailBytes,
          clearThumbnailBytes: clearThumbnail,
          defaultRestSeconds: defaultRestSeconds,
          clearDefaultRestSeconds: clearDefaultRestSeconds,
          trackedMetrics: trackedMetrics,
          clearTrackedMetrics: clearTrackedMetrics,
          equipment: equipment,
          clearEquipment: clearEquipment,
          formCue: formCue,
          clearFormCue: clearFormCue,
        ),
      );
    });
  }

  Future<void> deleteExercise(Exercise exercise) {
    final ExerciseRepository repository = ref.read(exerciseRepositoryProvider);
    return _runMutation(() async {
      await repository.deleteExercise(exercise.id);
    });
  }

  Future<T> _runMutation<T>(Future<T> Function() action) async {
    state = const AsyncLoading();
    try {
      final T result = await action();
      // Guard against disposal during the async gap — the controller is
      // auto-disposed and a navigation pop in the caller's `then` chain
      // can race ahead of this assignment.
      if (ref.mounted) {
        state = const AsyncData(null);
      }
      return result;
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    }
  }
}
