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

/// Exercises offered in the add-exercise picker. Tracks the same active-
/// pack filter used by the library list so toggling a pack off in
/// settings instantly removes those exercises from the picker too.
/// User-created exercises always appear regardless of pack toggles.

@ProviderFor(workoutExerciseOptions)
const workoutExerciseOptionsProvider = WorkoutExerciseOptionsProvider._();

/// Exercises offered in the add-exercise picker. Tracks the same active-
/// pack filter used by the library list so toggling a pack off in
/// settings instantly removes those exercises from the picker too.
/// User-created exercises always appear regardless of pack toggles.

final class WorkoutExerciseOptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Exercise>>,
          AsyncValue<List<Exercise>>,
          AsyncValue<List<Exercise>>
        >
    with $Provider<AsyncValue<List<Exercise>>> {
  /// Exercises offered in the add-exercise picker. Tracks the same active-
  /// pack filter used by the library list so toggling a pack off in
  /// settings instantly removes those exercises from the picker too.
  /// User-created exercises always appear regardless of pack toggles.
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
  $ProviderElement<AsyncValue<List<Exercise>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Exercise>> create(Ref ref) {
    return workoutExerciseOptions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Exercise>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Exercise>>>(value),
    );
  }
}

String _$workoutExerciseOptionsHash() =>
    r'd7d4a8660ab1619eebb5e7150f72e7e31eee8810';

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
/// Depends on [activeWorkoutSignatureProvider] (a stable string), not on the
/// full workout detail, so per-set edits — which emit a new detail on every
/// keystroke — do not trigger a refetch. The query only re-runs when the
/// active workout itself changes, or when an exercise is added / removed.

@ProviderFor(activeWorkoutPreviousSets)
const activeWorkoutPreviousSetsProvider = ActiveWorkoutPreviousSetsProvider._();

/// Most recent completed-workout sets for each exercise in the active
/// workout, keyed by exerciseId. Powers the "Previous" column on the
/// active workout screen.
///
/// Depends on [activeWorkoutSignatureProvider] (a stable string), not on the
/// full workout detail, so per-set edits — which emit a new detail on every
/// keystroke — do not trigger a refetch. The query only re-runs when the
/// active workout itself changes, or when an exercise is added / removed.

final class ActiveWorkoutPreviousSetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, List<WorkoutSet>>>,
          Map<String, List<WorkoutSet>>,
          FutureOr<Map<String, List<WorkoutSet>>>
        >
    with
        $FutureModifier<Map<String, List<WorkoutSet>>>,
        $FutureProvider<Map<String, List<WorkoutSet>>> {
  /// Most recent completed-workout sets for each exercise in the active
  /// workout, keyed by exerciseId. Powers the "Previous" column on the
  /// active workout screen.
  ///
  /// Depends on [activeWorkoutSignatureProvider] (a stable string), not on the
  /// full workout detail, so per-set edits — which emit a new detail on every
  /// keystroke — do not trigger a refetch. The query only re-runs when the
  /// active workout itself changes, or when an exercise is added / removed.
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
  $FutureProviderElement<Map<String, List<WorkoutSet>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, List<WorkoutSet>>> create(Ref ref) {
    return activeWorkoutPreviousSets(ref);
  }
}

String _$activeWorkoutPreviousSetsHash() =>
    r'cfd3722a08e3006ce079fad3e7760046ecc1317d';

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
