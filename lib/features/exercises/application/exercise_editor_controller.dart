import 'dart:async';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/exercise.dart';
import '../../../data/models/exercise_muscle_group.dart';
import '../../../data/models/exercise_type.dart';
import '../../../data/repositories/exercise_repository.dart';

part 'exercise_editor_controller.g.dart';

@Riverpod(keepAlive: true)
class ExerciseEditorController extends _$ExerciseEditorController {
  @override
  FutureOr<void> build() {}

  Future<Exercise> createExercise({
    required String name,
    required ExerciseType type,
    required ExerciseMuscleGroup muscleGroup,
    Uint8List? thumbnailBytes,
  }) {
    return _runMutation(() async {
      final ExerciseRepository repository = ref.read(
        exerciseRepositoryProvider,
      );
      return repository.createExercise(
        name: name,
        type: type,
        muscleGroup: muscleGroup,
        thumbnailBytes: thumbnailBytes,
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
  }) {
    return _runMutation(() async {
      final ExerciseRepository repository = ref.read(
        exerciseRepositoryProvider,
      );
      return repository.updateExercise(
        exercise.copyWith(
          name: name,
          type: type,
          muscleGroup: muscleGroup,
          thumbnailBytes: thumbnailBytes,
          clearThumbnailBytes: clearThumbnail,
        ),
      );
    });
  }

  Future<void> deleteExercise(Exercise exercise) {
    return _runMutation(() async {
      final ExerciseRepository repository = ref.read(
        exerciseRepositoryProvider,
      );
      await repository.deleteExercise(exercise.id);
    });
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
