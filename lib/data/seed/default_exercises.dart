import '../models/exercise_muscle_group.dart';
import '../models/exercise_type.dart';

class DefaultExerciseSeed {
  const DefaultExerciseSeed({
    required this.id,
    required this.name,
    required this.type,
    required this.muscleGroup,
  });

  final String id;
  final String name;
  final ExerciseType type;
  final ExerciseMuscleGroup muscleGroup;
}

const List<DefaultExerciseSeed> defaultExerciseSeeds = <DefaultExerciseSeed>[
  DefaultExerciseSeed(
    id: '6f7c82cf-6f43-4e0b-ae08-d9e5f5a2d101',
    name: 'Bench Press',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.chest,
  ),
  DefaultExerciseSeed(
    id: '17c4d0e0-6ae7-4e8f-8b5f-6a6c3d6d2102',
    name: 'Incline Dumbbell Press',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.chest,
  ),
  DefaultExerciseSeed(
    id: '0f3e8cf0-c3ad-4a46-a8f5-0d0a8d8b3103',
    name: 'Overhead Press',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.shoulders,
  ),
  DefaultExerciseSeed(
    id: 'b710d151-5591-4ac6-b13e-f7c1b5b04104',
    name: 'Pull-Up',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.back,
  ),
  DefaultExerciseSeed(
    id: '5b24d3c9-1b61-4ff8-8f5a-77f7a0f65105',
    name: 'Barbell Row',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.back,
  ),
  DefaultExerciseSeed(
    id: '0c3af544-113e-4e52-873a-42790f9b8106',
    name: 'Lat Pulldown',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.back,
  ),
  DefaultExerciseSeed(
    id: 'd83a9d2e-2785-4d88-a3a9-e12f1f065107',
    name: 'Seated Cable Row',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.back,
  ),
  DefaultExerciseSeed(
    id: '7fe2f8f4-b5b8-456a-93ff-b8f0b8cf7108',
    name: 'Squat',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
  ),
  DefaultExerciseSeed(
    id: '2fd3b643-905b-4d12-b1e9-2d978bd99109',
    name: 'Deadlift',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
  ),
  DefaultExerciseSeed(
    id: '8dd7fdb2-79a2-482a-a64d-8edab0ce310a',
    name: 'Romanian Deadlift',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
  ),
  DefaultExerciseSeed(
    id: '0f8f1943-7679-4602-b75a-0e8c19a0410b',
    name: 'Leg Press',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
  ),
  DefaultExerciseSeed(
    id: 'ff0b2209-c470-46bb-80e8-5171ea6d610c',
    name: 'Bicep Curl',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.biceps,
  ),
  DefaultExerciseSeed(
    id: 'ea79f0f7-a32f-4f8d-a90a-9cd2864d910d',
    name: 'Tricep Pushdown',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.triceps,
  ),
  DefaultExerciseSeed(
    id: 'd2e0ab93-cb1d-4c14-9a9a-a7307d2bb10e',
    name: 'Plank',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.abs,
  ),
  DefaultExerciseSeed(
    id: 'd5b74e62-cf52-4fdd-b933-278baab5e10f',
    name: 'Push-Up',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.chest,
  ),
  DefaultExerciseSeed(
    id: '9a7f6c81-e94d-43ea-8a53-d79ec66d6110',
    name: 'Sit-Up',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.abs,
  ),
  DefaultExerciseSeed(
    id: '278738fe-7c99-4761-a6c6-9a09be2a5111',
    name: 'Treadmill',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
  ),
  DefaultExerciseSeed(
    id: 'e40fc26a-9c4d-4aa0-9201-c99fb7d9d112',
    name: 'Stationary Bike',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
  ),
];
