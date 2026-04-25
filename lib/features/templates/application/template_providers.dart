import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/template_detail.dart';
import '../../../data/models/workout_template.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/repositories/template_repository.dart';

part 'template_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<List<WorkoutTemplate>> templateList(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(templateRepositoryProvider).watchAllTemplates();
}

@Riverpod(keepAlive: true)
Stream<TemplateDetail> templateDetail(Ref ref, String templateId) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(templateRepositoryProvider).watchTemplateById(templateId);
}

@Riverpod(keepAlive: true)
Future<List<Exercise>> templateExerciseOptions(Ref ref) async {
  await ref.watch(databaseBootstrapProvider.future);
  return ref.watch(exerciseRepositoryProvider).getAllExercises();
}
