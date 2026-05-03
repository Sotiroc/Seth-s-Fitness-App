import 'exercise_muscle_group.dart';
import 'gender.dart';
import 'unit_system.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.unitSystem,
    required this.createdAt,
    required this.updatedAt,
    this.name,
    this.ageYears,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.goalWeightKg,
    this.bodyFatPercent,
    this.diabetic,
    this.muscleGroupPriority,
    this.muscleGoals,
  });

  final String id;
  final String? name;
  final int? ageYears;
  final Gender? gender;
  final double? heightCm;
  final double? weightKg;
  final double? goalWeightKg;
  final double? bodyFatPercent;
  final bool? diabetic;
  final ExerciseMuscleGroup? muscleGroupPriority;

  /// User-configured weekly set targets per muscle group. `null` means the
  /// user has not customised goals — UIs should fall back to defaults.
  final Map<ExerciseMuscleGroup, int>? muscleGoals;

  final UnitSystem unitSystem;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isEmpty =>
      name == null &&
      ageYears == null &&
      gender == null &&
      heightCm == null &&
      weightKg == null &&
      goalWeightKg == null &&
      bodyFatPercent == null &&
      diabetic == null &&
      muscleGroupPriority == null &&
      muscleGoals == null;

  UserProfile copyWith({
    String? id,
    String? name,
    int? ageYears,
    Gender? gender,
    double? heightCm,
    double? weightKg,
    double? goalWeightKg,
    double? bodyFatPercent,
    bool? diabetic,
    ExerciseMuscleGroup? muscleGroupPriority,
    Map<ExerciseMuscleGroup, int>? muscleGoals,
    UnitSystem? unitSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearName = false,
    bool clearAgeYears = false,
    bool clearGender = false,
    bool clearHeightCm = false,
    bool clearWeightKg = false,
    bool clearGoalWeightKg = false,
    bool clearBodyFatPercent = false,
    bool clearDiabetic = false,
    bool clearMuscleGroupPriority = false,
    bool clearMuscleGoals = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: clearName ? null : name ?? this.name,
      ageYears: clearAgeYears ? null : ageYears ?? this.ageYears,
      gender: clearGender ? null : gender ?? this.gender,
      heightCm: clearHeightCm ? null : heightCm ?? this.heightCm,
      weightKg: clearWeightKg ? null : weightKg ?? this.weightKg,
      goalWeightKg: clearGoalWeightKg
          ? null
          : goalWeightKg ?? this.goalWeightKg,
      bodyFatPercent: clearBodyFatPercent
          ? null
          : bodyFatPercent ?? this.bodyFatPercent,
      diabetic: clearDiabetic ? null : diabetic ?? this.diabetic,
      muscleGroupPriority: clearMuscleGroupPriority
          ? null
          : muscleGroupPriority ?? this.muscleGroupPriority,
      muscleGoals: clearMuscleGoals ? null : muscleGoals ?? this.muscleGoals,
      unitSystem: unitSystem ?? this.unitSystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
