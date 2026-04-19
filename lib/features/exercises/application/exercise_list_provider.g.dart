// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(exerciseList)
const exerciseListProvider = ExerciseListProvider._();

final class ExerciseListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Exercise>>,
          List<Exercise>,
          Stream<List<Exercise>>
        >
    with $FutureModifier<List<Exercise>>, $StreamProvider<List<Exercise>> {
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

String _$exerciseFilterHash() => r'42eb81bcd0001403ea3258e38736c64d991ef372';

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

String _$filteredExercisesHash() => r'a95890e0969be03993815fd76dd2624d4a2766ce';
