import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/exercise_type.dart';
import '../../../data/repositories/exercise_repository.dart';

part 'exercise_list_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<List<Exercise>> exerciseList(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  final ExerciseRepository repository = ref.watch(exerciseRepositoryProvider);
  yield* repository.watchAllExercises();
}

@Riverpod(keepAlive: true)
Stream<Exercise?> exerciseById(Ref ref, String exerciseId) async* {
  await ref.watch(databaseBootstrapProvider.future);
  final ExerciseRepository repository = ref.watch(exerciseRepositoryProvider);
  yield* repository.watchExerciseById(exerciseId);
}

class ExerciseListFilter {
  const ExerciseListFilter({this.query = '', this.type});

  final String query;
  final ExerciseType? type;

  ExerciseListFilter copyWith({
    String? query,
    ExerciseType? type,
    bool clearType = false,
  }) {
    return ExerciseListFilter(
      query: query ?? this.query,
      type: clearType ? null : type ?? this.type,
    );
  }

  bool matches(Exercise exercise) {
    if (type != null && exercise.type != type) {
      return false;
    }
    if (query.trim().isEmpty) {
      return true;
    }
    return exercise.name.toLowerCase().contains(query.trim().toLowerCase());
  }
}

@Riverpod(keepAlive: true)
class ExerciseFilter extends _$ExerciseFilter {
  @override
  ExerciseListFilter build() => const ExerciseListFilter();

  void setQuery(String value) {
    state = state.copyWith(query: value);
  }

  void setType(ExerciseType? value) {
    state = value == null
        ? state.copyWith(clearType: true)
        : state.copyWith(type: value);
  }

  void clear() {
    state = const ExerciseListFilter();
  }
}

@Riverpod(keepAlive: true)
AsyncValue<List<Exercise>> filteredExercises(Ref ref) {
  final AsyncValue<List<Exercise>> list = ref.watch(exerciseListProvider);
  final ExerciseListFilter filter = ref.watch(exerciseFilterProvider);
  return list.whenData(
    (items) => items.where(filter.matches).toList(growable: false),
  );
}
