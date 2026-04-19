import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout_detail.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/repositories/workout_repository.dart';

final FutureProvider<WorkoutDetail?> activeWorkoutDetailProvider =
    FutureProvider<WorkoutDetail?>((Ref ref) async {
      await ref.watch(databaseBootstrapProvider.future);
      return ref.watch(workoutRepositoryProvider).getActiveWorkoutDetail();
    });

final FutureProvider<List<Exercise>> workoutExerciseOptionsProvider =
    FutureProvider<List<Exercise>>((Ref ref) async {
      await ref.watch(databaseBootstrapProvider.future);
      return ref.watch(exerciseRepositoryProvider).getAllExercises();
    });
