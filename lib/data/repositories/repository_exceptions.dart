class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExerciseNotFoundException extends RepositoryException {
  ExerciseNotFoundException(String exerciseId)
    : super('Exercise not found: $exerciseId');
}

class WorkoutNotFoundException extends RepositoryException {
  WorkoutNotFoundException(String workoutId)
    : super('Workout not found: $workoutId');
}

class WorkoutTemplateNotFoundException extends RepositoryException {
  WorkoutTemplateNotFoundException(String templateId)
    : super('Workout template not found: $templateId');
}

class ActiveWorkoutAlreadyExistsException extends RepositoryException {
  ActiveWorkoutAlreadyExistsException(String workoutId)
    : super('An active workout already exists: $workoutId');
}

class ExerciseDeleteBlockedException extends RepositoryException {
  ExerciseDeleteBlockedException(String exerciseId)
    : super('Exercise cannot be deleted because it is referenced: $exerciseId');
}
