import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/template_detail.dart';
import '../../../data/models/workout_template.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/repositories/template_repository.dart';

final StreamProvider<List<WorkoutTemplate>> templateListProvider =
    StreamProvider<List<WorkoutTemplate>>((Ref ref) async* {
      await ref.watch(databaseBootstrapProvider.future);
      yield* ref.watch(templateRepositoryProvider).watchAllTemplates();
    });

final templateDetailProvider = StreamProvider.family<TemplateDetail, String>((
  Ref ref,
  String templateId,
) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(templateRepositoryProvider).watchTemplateById(templateId);
});

final FutureProvider<List<Exercise>> templateExerciseOptionsProvider =
    FutureProvider<List<Exercise>>((Ref ref) async {
      await ref.watch(databaseBootstrapProvider.future);
      return ref.watch(exerciseRepositoryProvider).getAllExercises();
    });
