enum ExerciseMuscleGroup {
  legs,
  biceps,
  triceps,
  chest,
  back,
  shoulders,
  abs,
  cardio;

  String get label {
    switch (this) {
      case ExerciseMuscleGroup.legs:
        return 'Legs';
      case ExerciseMuscleGroup.biceps:
        return 'Biceps';
      case ExerciseMuscleGroup.triceps:
        return 'Triceps';
      case ExerciseMuscleGroup.chest:
        return 'Chest';
      case ExerciseMuscleGroup.back:
        return 'Back';
      case ExerciseMuscleGroup.shoulders:
        return 'Shoulders';
      case ExerciseMuscleGroup.abs:
        return 'Abs';
      case ExerciseMuscleGroup.cardio:
        return 'Cardio';
    }
  }
}
