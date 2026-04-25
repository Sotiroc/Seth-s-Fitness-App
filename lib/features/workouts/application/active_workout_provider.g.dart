// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_workout_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeWorkoutDetail)
const activeWorkoutDetailProvider = ActiveWorkoutDetailProvider._();

final class ActiveWorkoutDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkoutDetail?>,
          WorkoutDetail?,
          Stream<WorkoutDetail?>
        >
    with $FutureModifier<WorkoutDetail?>, $StreamProvider<WorkoutDetail?> {
  const ActiveWorkoutDetailProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeWorkoutDetailProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeWorkoutDetailHash();

  @$internal
  @override
  $StreamProviderElement<WorkoutDetail?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<WorkoutDetail?> create(Ref ref) {
    return activeWorkoutDetail(ref);
  }
}

String _$activeWorkoutDetailHash() =>
    r'2502f42472530d72375ed784aac1830655ee76cc';

@ProviderFor(workoutExerciseOptions)
const workoutExerciseOptionsProvider = WorkoutExerciseOptionsProvider._();

final class WorkoutExerciseOptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Exercise>>,
          List<Exercise>,
          FutureOr<List<Exercise>>
        >
    with $FutureModifier<List<Exercise>>, $FutureProvider<List<Exercise>> {
  const WorkoutExerciseOptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutExerciseOptionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutExerciseOptionsHash();

  @$internal
  @override
  $FutureProviderElement<List<Exercise>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Exercise>> create(Ref ref) {
    return workoutExerciseOptions(ref);
  }
}

String _$workoutExerciseOptionsHash() =>
    r'62671c3ca16e554a2e2f949117bca93c85c4aaf2';

/// One-shot loader for a finished workout (summary screen).

@ProviderFor(workoutDetailById)
const workoutDetailByIdProvider = WorkoutDetailByIdFamily._();

/// One-shot loader for a finished workout (summary screen).

final class WorkoutDetailByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkoutDetail>,
          WorkoutDetail,
          FutureOr<WorkoutDetail>
        >
    with $FutureModifier<WorkoutDetail>, $FutureProvider<WorkoutDetail> {
  /// One-shot loader for a finished workout (summary screen).
  const WorkoutDetailByIdProvider._({
    required WorkoutDetailByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workoutDetailByIdProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workoutDetailByIdHash();

  @override
  String toString() {
    return r'workoutDetailByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkoutDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkoutDetail> create(Ref ref) {
    final argument = this.argument as String;
    return workoutDetailById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkoutDetailByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workoutDetailByIdHash() => r'1967474702652e2759aeb1f64ce6e0fc074d2a8b';

/// One-shot loader for a finished workout (summary screen).

final class WorkoutDetailByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WorkoutDetail>, String> {
  const WorkoutDetailByIdFamily._()
    : super(
        retry: null,
        name: r'workoutDetailByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// One-shot loader for a finished workout (summary screen).

  WorkoutDetailByIdProvider call(String id) =>
      WorkoutDetailByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'workoutDetailByIdProvider';
}
