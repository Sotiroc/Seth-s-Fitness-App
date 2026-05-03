// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Raw list of every non-hidden exercise in the catalogue. Includes
/// exercises whose pack the user has currently turned off — pack-aware
/// filtering happens one layer up in [packAwareExerciseList].

@ProviderFor(exerciseList)
const exerciseListProvider = ExerciseListProvider._();

/// Raw list of every non-hidden exercise in the catalogue. Includes
/// exercises whose pack the user has currently turned off — pack-aware
/// filtering happens one layer up in [packAwareExerciseList].

final class ExerciseListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Exercise>>,
          List<Exercise>,
          Stream<List<Exercise>>
        >
    with $FutureModifier<List<Exercise>>, $StreamProvider<List<Exercise>> {
  /// Raw list of every non-hidden exercise in the catalogue. Includes
  /// exercises whose pack the user has currently turned off — pack-aware
  /// filtering happens one layer up in [packAwareExerciseList].
  const ExerciseListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exerciseListHash();

  @$internal
  @override
  $StreamProviderElement<List<Exercise>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Exercise>> create(Ref ref) {
    return exerciseList(ref);
  }
}

String _$exerciseListHash() => r'4e00a76850fd62e83d8e72f86db7e9edd4788126';

@ProviderFor(exerciseById)
const exerciseByIdProvider = ExerciseByIdFamily._();

final class ExerciseByIdProvider
    extends
        $FunctionalProvider<AsyncValue<Exercise?>, Exercise?, Stream<Exercise?>>
    with $FutureModifier<Exercise?>, $StreamProvider<Exercise?> {
  const ExerciseByIdProvider._({
    required ExerciseByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'exerciseByIdProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exerciseByIdHash();

  @override
  String toString() {
    return r'exerciseByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Exercise?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Exercise?> create(Ref ref) {
    final argument = this.argument as String;
    return exerciseById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exerciseByIdHash() => r'bfadbac3fe6c03225a19a43067e3779887f94926';

final class ExerciseByIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Exercise?>, String> {
  const ExerciseByIdFamily._()
    : super(
        retry: null,
        name: r'exerciseByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ExerciseByIdProvider call(String exerciseId) =>
      ExerciseByIdProvider._(argument: exerciseId, from: this);

  @override
  String toString() => r'exerciseByIdProvider';
}

/// Exercises filtered by the currently active packs. User-created
/// exercises (those without a [Exercise.sourcePackId]) always pass
/// through regardless of pack toggles.

@ProviderFor(packAwareExerciseList)
const packAwareExerciseListProvider = PackAwareExerciseListProvider._();

/// Exercises filtered by the currently active packs. User-created
/// exercises (those without a [Exercise.sourcePackId]) always pass
/// through regardless of pack toggles.

final class PackAwareExerciseListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Exercise>>,
          AsyncValue<List<Exercise>>,
          AsyncValue<List<Exercise>>
        >
    with $Provider<AsyncValue<List<Exercise>>> {
  /// Exercises filtered by the currently active packs. User-created
  /// exercises (those without a [Exercise.sourcePackId]) always pass
  /// through regardless of pack toggles.
  const PackAwareExerciseListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packAwareExerciseListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packAwareExerciseListHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Exercise>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Exercise>> create(Ref ref) {
    return packAwareExerciseList(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Exercise>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Exercise>>>(value),
    );
  }
}

String _$packAwareExerciseListHash() =>
    r'186bbe67e146c61cbaecb2508824502f8c7fb9b7';

/// Stream of active pack ids — the picker and library list use this to
/// hide exercises from packs the user has turned off in settings.

@ProviderFor(activeExercisePackIds)
const activeExercisePackIdsProvider = ActiveExercisePackIdsProvider._();

/// Stream of active pack ids — the picker and library list use this to
/// hide exercises from packs the user has turned off in settings.

final class ActiveExercisePackIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          Stream<Set<String>>
        >
    with $FutureModifier<Set<String>>, $StreamProvider<Set<String>> {
  /// Stream of active pack ids — the picker and library list use this to
  /// hide exercises from packs the user has turned off in settings.
  const ActiveExercisePackIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeExercisePackIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeExercisePackIdsHash();

  @$internal
  @override
  $StreamProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<String>> create(Ref ref) {
    return activeExercisePackIds(ref);
  }
}

String _$activeExercisePackIdsHash() =>
    r'41db7a174c66fbe391a90efc24a4cacb9f857447';

/// Stream of every installed pack — used by both the library settings
/// screen and the pack filter chip on the library list.

@ProviderFor(installedExercisePacks)
const installedExercisePacksProvider = InstalledExercisePacksProvider._();

/// Stream of every installed pack — used by both the library settings
/// screen and the pack filter chip on the library list.

final class InstalledExercisePacksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ExercisePack>>,
          List<ExercisePack>,
          Stream<List<ExercisePack>>
        >
    with
        $FutureModifier<List<ExercisePack>>,
        $StreamProvider<List<ExercisePack>> {
  /// Stream of every installed pack — used by both the library settings
  /// screen and the pack filter chip on the library list.
  const InstalledExercisePacksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installedExercisePacksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installedExercisePacksHash();

  @$internal
  @override
  $StreamProviderElement<List<ExercisePack>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ExercisePack>> create(Ref ref) {
    return installedExercisePacks(ref);
  }
}

String _$installedExercisePacksHash() =>
    r'1020bf485a983038c74c73ef8ec3810399e448d2';

@ProviderFor(ExerciseFilter)
const exerciseFilterProvider = ExerciseFilterProvider._();

final class ExerciseFilterProvider
    extends $NotifierProvider<ExerciseFilter, ExerciseListFilter> {
  const ExerciseFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exerciseFilterHash();

  @$internal
  @override
  ExerciseFilter create() => ExerciseFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExerciseListFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExerciseListFilter>(value),
    );
  }
}

String _$exerciseFilterHash() => r'9a1794e20a81b1f4c1f5d775cfd293ee78184442';

abstract class _$ExerciseFilter extends $Notifier<ExerciseListFilter> {
  ExerciseListFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ExerciseListFilter, ExerciseListFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExerciseListFilter, ExerciseListFilter>,
              ExerciseListFilter,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(filteredExercises)
const filteredExercisesProvider = FilteredExercisesProvider._();

final class FilteredExercisesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Exercise>>,
          AsyncValue<List<Exercise>>,
          AsyncValue<List<Exercise>>
        >
    with $Provider<AsyncValue<List<Exercise>>> {
  const FilteredExercisesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredExercisesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredExercisesHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Exercise>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Exercise>> create(Ref ref) {
    return filteredExercises(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Exercise>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Exercise>>>(value),
    );
  }
}

String _$filteredExercisesHash() => r'9c97a630d8bacaf0e3ecf2237fa2bf3e756948bc';
