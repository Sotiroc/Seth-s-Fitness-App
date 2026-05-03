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

class InvalidExerciseNameException extends RepositoryException {
  InvalidExerciseNameException() : super('Exercise name cannot be empty.');
}

class WorkoutNotFoundException extends RepositoryException {
  WorkoutNotFoundException(String workoutId)
    : super('Workout not found: $workoutId');
}

class WorkoutTemplateNotFoundException extends RepositoryException {
  WorkoutTemplateNotFoundException(String templateId)
    : super('Workout template not found: $templateId');
}

class InvalidWorkoutTemplateNameException extends RepositoryException {
  InvalidWorkoutTemplateNameException()
    : super('Workout template name cannot be empty.');
}

class ActiveWorkoutAlreadyExistsException extends RepositoryException {
  ActiveWorkoutAlreadyExistsException(String workoutId)
    : super('An active workout already exists: $workoutId');
}

class ExerciseDeleteBlockedException extends RepositoryException {
  ExerciseDeleteBlockedException(String exerciseId)
    : super('Exercise cannot be deleted because it is referenced: $exerciseId');
}

class WorkoutNotActiveException extends RepositoryException {
  WorkoutNotActiveException(String workoutId)
    : super('Workout is not active: $workoutId');
}

class WorkoutNotEndedException extends RepositoryException {
  WorkoutNotEndedException(String workoutId)
    : super('Workout has not ended: $workoutId');
}

class WorkoutExerciseNotFoundException extends RepositoryException {
  WorkoutExerciseNotFoundException(String workoutExerciseId)
    : super('Workout exercise not found: $workoutExerciseId');
}

class WorkoutSetNotFoundException extends RepositoryException {
  WorkoutSetNotFoundException(String workoutSetId)
    : super('Workout set not found: $workoutSetId');
}

class InvalidWorkoutSetException extends RepositoryException {
  InvalidWorkoutSetException(super.message);
}

class InvalidExerciseRestException extends RepositoryException {
  InvalidExerciseRestException()
    : super('Exercise rest must be null or between 0 and 3600 seconds.');
}
