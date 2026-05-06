import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/exercise_muscle_group.dart';
import '../../../data/models/user_profile.dart';
import '../../profile/application/user_profile_provider.dart';

part 'muscle_goals_provider.g.dart';

/// Default weekly set targets per muscle group. Picked to match common
/// hypertrophy-block starting points (RP / PPL conventions). The user can
/// override any of these via the goals sheet.
const Map<ExerciseMuscleGroup, int> defaultMuscleGoals =
    <ExerciseMuscleGroup, int>{
      ExerciseMuscleGroup.legs: 14,
      ExerciseMuscleGroup.back: 14,
      ExerciseMuscleGroup.chest: 12,
      ExerciseMuscleGroup.shoulders: 10,
      ExerciseMuscleGroup.biceps: 8,
      ExerciseMuscleGroup.triceps: 8,
      ExerciseMuscleGroup.abs: 6,
      // Cardio is measured in minutes per week (not sets) — 90 minutes is
      // a moderate fitness baseline (mid-point of public-health guidance:
      // 150 min/wk moderate or 75 min/wk vigorous).
      ExerciseMuscleGroup.cardio: 90,
    };

/// Effective per-muscle weekly set goals, merging the user's saved overrides
/// (from `UserProfile.muscleGoals`) over [defaultMuscleGoals]. Always returns
/// a value for every muscle group so consumers don't need null checks.
@Riverpod(keepAlive: true)
Map<ExerciseMuscleGroup, int> muscleGoals(Ref ref) {
  // Subscribe only to the muscle-goals slice of the profile. Riverpod's
  // `select` re-fires when the selected value `!=` the previous one, but
  // Dart Map equality is identity-based, so we collapse the override map
  // into a stable signature string. Edits to unrelated profile fields
  // (name, height, weight, etc.) keep the same signature and therefore
  // don't trigger a recompute here.
  ref.watch(
    userProfileProvider.select(
      (AsyncValue<UserProfile?> async) =>
          _muscleGoalsSignature(async.asData?.value?.muscleGoals),
    ),
  );

  // Pull the live override map non-reactively now that we know it changed
  // in a meaningful way.
  final Map<ExerciseMuscleGroup, int>? overrides =
      ref.read(userProfileProvider).asData?.value?.muscleGoals;

  if (overrides == null || overrides.isEmpty) {
    return defaultMuscleGoals;
  }
  return <ExerciseMuscleGroup, int>{
    for (final ExerciseMuscleGroup mg in ExerciseMuscleGroup.values)
      mg: overrides[mg] ?? defaultMuscleGoals[mg] ?? 0,
  };
}

/// Stable string signature for an optional muscle-goals override map. Used
/// by [muscleGoals]'s `select` so unrelated profile-field edits don't
/// recompute the merged goal map.
String _muscleGoalsSignature(Map<ExerciseMuscleGroup, int>? overrides) {
  if (overrides == null || overrides.isEmpty) return '';
  final List<MapEntry<ExerciseMuscleGroup, int>> entries =
      overrides.entries.toList()
        ..sort(
          (
            MapEntry<ExerciseMuscleGroup, int> a,
            MapEntry<ExerciseMuscleGroup, int> b,
          ) =>
              a.key.index.compareTo(b.key.index),
        );
  return entries
      .map(
        (MapEntry<ExerciseMuscleGroup, int> e) => '${e.key.index}:${e.value}',
      )
      .join(',');
}
