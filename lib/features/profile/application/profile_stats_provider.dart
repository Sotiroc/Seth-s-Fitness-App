import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/user_profile.dart';
import 'user_profile_provider.dart';

part 'profile_stats_provider.g.dart';

/// WHO BMI cut-offs.
enum BmiCategory {
  underweight('Underweight'),
  normal('Normal'),
  overweight('Overweight'),
  obese('Obese');

  const BmiCategory(this.label);

  final String label;
}

enum WeightGoalDirection {
  lose('Lose'),
  gain('Gain'),
  atGoal('At goal');

  const WeightGoalDirection(this.label);

  final String label;
}

/// Derived metrics from a [UserProfile]. Every field is nullable so the UI can
/// degrade gracefully when source inputs are missing.
class ProfileStats {
  const ProfileStats({
    this.bmi,
    this.bmiCategory,
    this.weightToGoalKg,
    this.weightToGoalDirection,
    this.score,
  });

  /// Body Mass Index. Null until both height and weight are recorded.
  final double? bmi;

  /// WHO category for the current BMI. Null when [bmi] is null.
  final BmiCategory? bmiCategory;

  /// Absolute kilogram delta between current weight and goal weight. Null when
  /// either input is missing.
  final double? weightToGoalKg;

  /// Direction of the goal delta. Null when either input is missing.
  final WeightGoalDirection? weightToGoalDirection;

  /// Composite fitness score (placeholder — populated in a later iteration).
  final int? score;

  bool get hasBmi => bmi != null;
  bool get hasGoalDelta => weightToGoalKg != null;
}

/// Threshold used to consider the user "at goal" rather than reporting a tiny
/// surplus or deficit.
const double _atGoalToleranceKg = 0.5;

ProfileStats computeProfileStats(UserProfile? profile) {
  if (profile == null) return const ProfileStats();

  double? bmi;
  BmiCategory? category;
  if (profile.heightCm != null &&
      profile.weightKg != null &&
      profile.heightCm! > 0) {
    final double meters = profile.heightCm! / 100;
    bmi = profile.weightKg! / (meters * meters);
    if (bmi < 18.5) {
      category = BmiCategory.underweight;
    } else if (bmi < 25) {
      category = BmiCategory.normal;
    } else if (bmi < 30) {
      category = BmiCategory.overweight;
    } else {
      category = BmiCategory.obese;
    }
  }

  double? weightToGoalKg;
  WeightGoalDirection? direction;
  if (profile.weightKg != null && profile.goalWeightKg != null) {
    final double delta = profile.weightKg! - profile.goalWeightKg!;
    weightToGoalKg = delta.abs();
    if (delta.abs() < _atGoalToleranceKg) {
      direction = WeightGoalDirection.atGoal;
    } else if (delta > 0) {
      direction = WeightGoalDirection.lose;
    } else {
      direction = WeightGoalDirection.gain;
    }
  }

  return ProfileStats(
    bmi: bmi,
    bmiCategory: category,
    weightToGoalKg: weightToGoalKg,
    weightToGoalDirection: direction,
  );
}

@Riverpod(keepAlive: true)
ProfileStats profileStats(Ref ref) {
  final UserProfile? profile = ref.watch(userProfileProvider).asData?.value;
  return computeProfileStats(profile);
}
