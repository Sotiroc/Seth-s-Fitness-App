import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/exercise_equipment.dart';
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
  const ExerciseListFilter({
    this.query = '',
    this.type,
    this.equipment,
  });

  final String query;
  final ExerciseType? type;
  final ExerciseEquipment? equipment;

  ExerciseListFilter copyWith({
    String? query,
    ExerciseType? type,
    bool clearType = false,
    ExerciseEquipment? equipment,
    bool clearEquipment = false,
  }) {
    return ExerciseListFilter(
      query: query ?? this.query,
      type: clearType ? null : type ?? this.type,
      equipment: clearEquipment ? null : equipment ?? this.equipment,
    );
  }

  bool matches(Exercise exercise) {
    if (type != null && exercise.type != type) {
      return false;
    }
    if (equipment != null && exercise.equipment != equipment) {
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
  static const Duration _queryDebounce = Duration(milliseconds: 300);

  Timer? _queryDebounceTimer;

  @override
  ExerciseListFilter build() {
    ref.onDispose(() {
      _queryDebounceTimer?.cancel();
      _queryDebounceTimer = null;
    });
    return const ExerciseListFilter();
  }

  /// Debounced — the filter state (and therefore [filteredExercises])
  /// only updates after the user stops typing for ~300ms. The search
  /// field's TextField holds the typed value locally so the input still
  /// echoes every keystroke instantly; only the list filter pass is
  /// throttled.
  void setQuery(String value) {
    _queryDebounceTimer?.cancel();
    _queryDebounceTimer = Timer(_queryDebounce, () {
      _queryDebounceTimer = null;
      if (state.query == value) return;
      state = state.copyWith(query: value);
    });
  }

  void setType(ExerciseType? value) {
    state = value == null
        ? state.copyWith(clearType: true)
        : state.copyWith(type: value);
  }

  void setEquipment(ExerciseEquipment? value) {
    state = value == null
        ? state.copyWith(clearEquipment: true)
        : state.copyWith(equipment: value);
  }

  void clear() {
    _queryDebounceTimer?.cancel();
    _queryDebounceTimer = null;
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
