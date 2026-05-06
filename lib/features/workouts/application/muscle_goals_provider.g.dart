// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'muscle_goals_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Effective per-muscle weekly set goals, merging the user's saved overrides
/// (from `UserProfile.muscleGoals`) over [defaultMuscleGoals]. Always returns
/// a value for every muscle group so consumers don't need null checks.

@ProviderFor(muscleGoals)
const muscleGoalsProvider = MuscleGoalsProvider._();

/// Effective per-muscle weekly set goals, merging the user's saved overrides
/// (from `UserProfile.muscleGoals`) over [defaultMuscleGoals]. Always returns
/// a value for every muscle group so consumers don't need null checks.

final class MuscleGoalsProvider
    extends
        $FunctionalProvider<
          Map<ExerciseMuscleGroup, int>,
          Map<ExerciseMuscleGroup, int>,
          Map<ExerciseMuscleGroup, int>
        >
    with $Provider<Map<ExerciseMuscleGroup, int>> {
  /// Effective per-muscle weekly set goals, merging the user's saved overrides
  /// (from `UserProfile.muscleGoals`) over [defaultMuscleGoals]. Always returns
  /// a value for every muscle group so consumers don't need null checks.
  const MuscleGoalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'muscleGoalsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$muscleGoalsHash();

  @$internal
  @override
  $ProviderElement<Map<ExerciseMuscleGroup, int>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<ExerciseMuscleGroup, int> create(Ref ref) {
    return muscleGoals(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<ExerciseMuscleGroup, int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<ExerciseMuscleGroup, int>>(
        value,
      ),
    );
  }
}

String _$muscleGoalsHash() => r'2cad87827d8d5c11a68963800d2cbdad7ca6f403';
