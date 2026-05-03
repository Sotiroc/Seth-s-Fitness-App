import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/exercise_pack.dart';
import '../../../data/models/exercise_type.dart';
import '../../../data/repositories/exercise_pack_repository.dart';
import '../../../data/repositories/exercise_repository.dart';

part 'exercise_list_provider.g.dart';

/// Raw list of every non-hidden exercise in the catalogue. Includes
/// exercises whose pack the user has currently turned off — pack-aware
/// filtering happens one layer up in [packAwareExerciseList].
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

/// Exercises filtered by the currently active packs. User-created
/// exercises (those without a [Exercise.sourcePackId]) always pass
/// through regardless of pack toggles.
@Riverpod(keepAlive: true)
AsyncValue<List<Exercise>> packAwareExerciseList(Ref ref) {
  final AsyncValue<List<Exercise>> all = ref.watch(exerciseListProvider);
  final AsyncValue<Set<String>> activePacks = ref.watch(
    activeExercisePackIdsProvider,
  );

  return all.whenData((items) {
    final Set<String>? active = activePacks.asData?.value;
    if (active == null) return items;
    return items
        .where(
          (e) => e.sourcePackId == null || active.contains(e.sourcePackId),
        )
        .toList(growable: false);
  });
}

/// Stream of active pack ids — the picker and library list use this to
/// hide exercises from packs the user has turned off in settings.
@Riverpod(keepAlive: true)
Stream<Set<String>> activeExercisePackIds(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  final ExercisePackRepository repository = ref.watch(
    exercisePackRepositoryProvider,
  );
  yield* repository.watchActivePackIds();
}

/// Stream of every installed pack — used by both the library settings
/// screen and the pack filter chip on the library list.
@Riverpod(keepAlive: true)
Stream<List<ExercisePack>> installedExercisePacks(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(exercisePackRepositoryProvider).watchAllPacks();
}

class ExerciseListFilter {
  const ExerciseListFilter({
    this.query = '',
    this.type,
    this.packId,
  });

  final String query;
  final ExerciseType? type;

  /// User-selected pack chip. Null = no pack filter applied. Distinct
  /// from the active-pack toggles in settings — this is a quick filter
  /// the user can flip on the library list itself.
  final String? packId;

  ExerciseListFilter copyWith({
    String? query,
    ExerciseType? type,
    String? packId,
    bool clearType = false,
    bool clearPack = false,
  }) {
    return ExerciseListFilter(
      query: query ?? this.query,
      type: clearType ? null : type ?? this.type,
      packId: clearPack ? null : packId ?? this.packId,
    );
  }

  bool matches(Exercise exercise) {
    if (type != null && exercise.type != type) {
      return false;
    }
    if (packId != null && exercise.sourcePackId != packId) {
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

  void setPackId(String? value) {
    state = value == null
        ? state.copyWith(clearPack: true)
        : state.copyWith(packId: value);
  }

  void clear() {
    state = const ExerciseListFilter();
  }
}

@Riverpod(keepAlive: true)
AsyncValue<List<Exercise>> filteredExercises(Ref ref) {
  final AsyncValue<List<Exercise>> list = ref.watch(
    packAwareExerciseListProvider,
  );
  final ExerciseListFilter filter = ref.watch(exerciseFilterProvider);
  return list.whenData(
    (items) => items.where(filter.matches).toList(growable: false),
  );
}
