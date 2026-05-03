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
  final AsyncValue<UserProfile?> profile = ref.watch(userProfileProvider);
  final Map<ExerciseMuscleGroup, int>? overrides = profile.maybeWhen(
    data: (UserProfile? p) => p?.muscleGoals,
    orElse: () => null,
  );
  if (overrides == null || overrides.isEmpty) {
    return defaultMuscleGoals;
  }
  return <ExerciseMuscleGroup, int>{
    for (final ExerciseMuscleGroup mg in ExerciseMuscleGroup.values)
      mg: overrides[mg] ?? defaultMuscleGoals[mg] ?? 0,
  };
}
