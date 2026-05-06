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

/// Stable identity of the active workout: workout id plus an ordered list of
/// exercise ids. Recomputes whenever [activeWorkoutDetailProvider] emits, but
/// only changes value when the workout itself or its exercise list changes —
/// so dependents that key off this don't rebuild on every set edit.

@ProviderFor(activeWorkoutSignature)
const activeWorkoutSignatureProvider = ActiveWorkoutSignatureProvider._();

/// Stable identity of the active workout: workout id plus an ordered list of
/// exercise ids. Recomputes whenever [activeWorkoutDetailProvider] emits, but
/// only changes value when the workout itself or its exercise list changes —
/// so dependents that key off this don't rebuild on every set edit.

final class ActiveWorkoutSignatureProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Stable identity of the active workout: workout id plus an ordered list of
  /// exercise ids. Recomputes whenever [activeWorkoutDetailProvider] emits, but
  /// only changes value when the workout itself or its exercise list changes —
  /// so dependents that key off this don't rebuild on every set edit.
  const ActiveWorkoutSignatureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeWorkoutSignatureProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeWorkoutSignatureHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return activeWorkoutSignature(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$activeWorkoutSignatureHash() =>
    r'00d18afff4ce90bfafda36db660accc1dfac059b';

/// Most recent completed-workout sets for each exercise in the active
/// workout, keyed by exerciseId. Powers the "Previous" column on the
/// active workout screen.
///
/// Watches [activeWorkoutSignatureProvider] (a stable string), not the full
/// workout detail, so per-set edits — which emit a new detail on every
/// keystroke — do not trigger a refetch. When the signature changes (an
/// exercise added or removed), only the *new* exercise ids are fetched
/// from the repository; previously-fetched exercises are served from a
/// per-workout cache held on the notifier instance, so a 6-exercise
/// workout where one exercise was just added does one lookup instead of
/// six.

@ProviderFor(ActiveWorkoutPreviousSets)
const activeWorkoutPreviousSetsProvider = ActiveWorkoutPreviousSetsProvider._();

/// Most recent completed-workout sets for each exercise in the active
/// workout, keyed by exerciseId. Powers the "Previous" column on the
/// active workout screen.
///
/// Watches [activeWorkoutSignatureProvider] (a stable string), not the full
/// workout detail, so per-set edits — which emit a new detail on every
/// keystroke — do not trigger a refetch. When the signature changes (an
/// exercise added or removed), only the *new* exercise ids are fetched
/// from the repository; previously-fetched exercises are served from a
/// per-workout cache held on the notifier instance, so a 6-exercise
/// workout where one exercise was just added does one lookup instead of
/// six.
final class ActiveWorkoutPreviousSetsProvider
    extends
        $AsyncNotifierProvider<
          ActiveWorkoutPreviousSets,
          Map<String, List<WorkoutSet>>
        > {
  /// Most recent completed-workout sets for each exercise in the active
  /// workout, keyed by exerciseId. Powers the "Previous" column on the
  /// active workout screen.
  ///
  /// Watches [activeWorkoutSignatureProvider] (a stable string), not the full
  /// workout detail, so per-set edits — which emit a new detail on every
  /// keystroke — do not trigger a refetch. When the signature changes (an
  /// exercise added or removed), only the *new* exercise ids are fetched
  /// from the repository; previously-fetched exercises are served from a
  /// per-workout cache held on the notifier instance, so a 6-exercise
  /// workout where one exercise was just added does one lookup instead of
  /// six.
  const ActiveWorkoutPreviousSetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeWorkoutPreviousSetsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeWorkoutPreviousSetsHash();

  @$internal
  @override
  ActiveWorkoutPreviousSets create() => ActiveWorkoutPreviousSets();
}

String _$activeWorkoutPreviousSetsHash() =>
    r'19bbe9c5a521acd2a2bb8ced99801fb08f90119d';

/// Most recent completed-workout sets for each exercise in the active
/// workout, keyed by exerciseId. Powers the "Previous" column on the
/// active workout screen.
///
/// Watches [activeWorkoutSignatureProvider] (a stable string), not the full
/// workout detail, so per-set edits — which emit a new detail on every
/// keystroke — do not trigger a refetch. When the signature changes (an
/// exercise added or removed), only the *new* exercise ids are fetched
/// from the repository; previously-fetched exercises are served from a
/// per-workout cache held on the notifier instance, so a 6-exercise
/// workout where one exercise was just added does one lookup instead of
/// six.

abstract class _$ActiveWorkoutPreviousSets
    extends $AsyncNotifier<Map<String, List<WorkoutSet>>> {
  FutureOr<Map<String, List<WorkoutSet>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<String, List<WorkoutSet>>>,
              Map<String, List<WorkoutSet>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, List<WorkoutSet>>>,
                Map<String, List<WorkoutSet>>
              >,
              AsyncValue<Map<String, List<WorkoutSet>>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

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
