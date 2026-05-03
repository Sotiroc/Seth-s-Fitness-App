import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/exercise_history_day.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/repositories/workout_repository.dart';

/// Streams the live `Exercise` row for a given id. Used by the per-exercise
/// history screen so the title and avatar refresh if the exercise is renamed
/// or its photo is updated while the screen is open.
final exerciseByIdStreamProvider = StreamProvider.autoDispose
    .family<Exercise?, String>((ref, exerciseId) async* {
      await ref.watch(databaseBootstrapProvider.future);
      yield* ref
          .watch(exerciseRepositoryProvider)
          .watchExerciseById(exerciseId);
    });

/// Streams every completed session that ever included the given exercise,
/// newest first. Powers the per-exercise history screen reachable from the
/// active workout card.
final exerciseHistoryByDayProvider = StreamProvider.autoDispose
    .family<List<ExerciseHistoryDay>, String>((ref, exerciseId) async* {
      await ref.watch(databaseBootstrapProvider.future);
      yield* ref
          .watch(workoutRepositoryProvider)
          .watchExerciseHistoryByDay(exerciseId);
    });
