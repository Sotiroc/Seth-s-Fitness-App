import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessapp/data/models/unit_system.dart';
import 'package:fitnessapp/data/models/user_profile.dart';
import 'package:fitnessapp/features/profile/application/profile_stats_provider.dart';

UserProfile _profile({
  double? heightCm,
  double? weightKg,
  double? goalWeightKg,
}) {
  final DateTime now = DateTime.utc(2024, 1, 1);
  return UserProfile(
    id: 'me',
    unitSystem: UnitSystem.metric,
    createdAt: now,
    updatedAt: now,
    heightCm: heightCm,
    weightKg: weightKg,
    goalWeightKg: goalWeightKg,
  );
}

void main() {
  group('computeProfileStats — BMI', () {
    test('returns null fields when no profile is provided', () {
      final ProfileStats stats = computeProfileStats(null);
      expect(stats.bmi, isNull);
      expect(stats.bmiCategory, isNull);
      expect(stats.weightToGoalKg, isNull);
      expect(stats.weightToGoalDirection, isNull);
      expect(stats.score, isNull);
    });

    test('returns null BMI when height is missing', () {
      final ProfileStats stats = computeProfileStats(_profile(weightKg: 80));
      expect(stats.bmi, isNull);
      expect(stats.bmiCategory, isNull);
    });

    test('returns null BMI when weight is missing', () {
      final ProfileStats stats = computeProfileStats(_profile(heightCm: 175));
      expect(stats.bmi, isNull);
      expect(stats.bmiCategory, isNull);
    });

    test('returns null BMI when height is zero', () {
      final ProfileStats stats = computeProfileStats(
        _profile(heightCm: 0, weightKg: 80),
      );
      expect(stats.bmi, isNull);
    });

    test('classifies underweight correctly (<18.5)', () {
      final ProfileStats stats = computeProfileStats(
        _profile(heightCm: 180, weightKg: 55),
      );
      expect(stats.bmi, closeTo(16.97, 0.01));
      expect(stats.bmiCategory, BmiCategory.underweight);
    });

    test('classifies normal correctly (18.5–25)', () {
      final ProfileStats stats = computeProfileStats(
        _profile(heightCm: 180, weightKg: 70),
      );
      expect(stats.bmi, closeTo(21.6, 0.05));
      expect(stats.bmiCategory, BmiCategory.normal);
    });

    test('treats exactly 18.5 as normal (boundary)', () {
      // 18.5 BMI at 1.80 m -> 59.94 kg
      final ProfileStats stats = computeProfileStats(
        _profile(heightCm: 180, weightKg: 18.5 * 1.80 * 1.80),
      );
      expect(stats.bmi, closeTo(18.5, 0.001));
      expect(stats.bmiCategory, BmiCategory.normal);
    });

    test('classifies overweight correctly (25–30)', () {
      final ProfileStats stats = computeProfileStats(
        _profile(heightCm: 175, weightKg: 80),
      );
      expect(stats.bmi, closeTo(26.12, 0.05));
      expect(stats.bmiCategory, BmiCategory.overweight);
    });

    test('treats exactly 25 as overweight (boundary)', () {
      final ProfileStats stats = computeProfileStats(
        _profile(heightCm: 175, weightKg: 25 * 1.75 * 1.75),
      );
      expect(stats.bmi, closeTo(25, 0.001));
      expect(stats.bmiCategory, BmiCategory.overweight);
    });

    test('classifies obese correctly (>=30)', () {
      final ProfileStats stats = computeProfileStats(
        _profile(heightCm: 170, weightKg: 95),
      );
      expect(stats.bmi, closeTo(32.87, 0.05));
      expect(stats.bmiCategory, BmiCategory.obese);
    });

    test('treats exactly 30 as obese (boundary)', () {
      final ProfileStats stats = computeProfileStats(
        _profile(heightCm: 170, weightKg: 30 * 1.70 * 1.70),
      );
      expect(stats.bmi, closeTo(30, 0.001));
      expect(stats.bmiCategory, BmiCategory.obese);
    });
  });

  group('computeProfileStats — weight-to-goal', () {
    test('returns null delta when goal weight is missing', () {
      final ProfileStats stats = computeProfileStats(_profile(weightKg: 80));
      expect(stats.weightToGoalKg, isNull);
      expect(stats.weightToGoalDirection, isNull);
    });

    test('returns null delta when current weight is missing', () {
      final ProfileStats stats = computeProfileStats(
        _profile(goalWeightKg: 75),
      );
      expect(stats.weightToGoalKg, isNull);
      expect(stats.weightToGoalDirection, isNull);
    });

    test('reports lose direction when current > goal', () {
      final ProfileStats stats = computeProfileStats(
        _profile(weightKg: 80, goalWeightKg: 75),
      );
      expect(stats.weightToGoalKg, closeTo(5.0, 0.001));
      expect(stats.weightToGoalDirection, WeightGoalDirection.lose);
    });

    test('reports gain direction when current < goal', () {
      final ProfileStats stats = computeProfileStats(
        _profile(weightKg: 70, goalWeightKg: 75),
      );
      expect(stats.weightToGoalKg, closeTo(5.0, 0.001));
      expect(stats.weightToGoalDirection, WeightGoalDirection.gain);
    });

    test('reports atGoal when within tolerance', () {
      final ProfileStats stats = computeProfileStats(
        _profile(weightKg: 75.2, goalWeightKg: 75.0),
      );
      expect(stats.weightToGoalDirection, WeightGoalDirection.atGoal);
    });

    test('reports atGoal when exactly equal', () {
      final ProfileStats stats = computeProfileStats(
        _profile(weightKg: 75, goalWeightKg: 75),
      );
      expect(stats.weightToGoalKg, 0);
      expect(stats.weightToGoalDirection, WeightGoalDirection.atGoal);
    });
  });

  test('score is null until a future iteration populates it', () {
    final ProfileStats stats = computeProfileStats(
      _profile(heightCm: 180, weightKg: 75, goalWeightKg: 75),
    );
    expect(stats.score, isNull);
  });
}
