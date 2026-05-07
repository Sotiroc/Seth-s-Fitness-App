/// What kind of equipment an exercise uses. Drives the equipment chip
/// filter on the library screen and is shown as a small dropdown in the
/// exercise editor. Nullable on the model — pre-feature rows don't have
/// an assignment until the user edits them or the seed is upgraded.
enum ExerciseEquipment {
  barbell,
  dumbbell,
  machine,
  cable,
  bodyweight,
  kettlebell,
  band,
  cardioMachine,
  other;

  /// Display label for chips and dropdowns.
  String get label {
    switch (this) {
      case ExerciseEquipment.barbell:
        return 'Barbell';
      case ExerciseEquipment.dumbbell:
        return 'Dumbbell';
      case ExerciseEquipment.machine:
        return 'Machine';
      case ExerciseEquipment.cable:
        return 'Cable';
      case ExerciseEquipment.bodyweight:
        return 'Bodyweight';
      case ExerciseEquipment.kettlebell:
        return 'Kettlebell';
      case ExerciseEquipment.band:
        return 'Band';
      case ExerciseEquipment.cardioMachine:
        return 'Cardio machine';
      case ExerciseEquipment.other:
        return 'Other';
    }
  }
}

ExerciseEquipment? decodeExerciseEquipment(String? raw) {
  if (raw == null) return null;
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  for (final ExerciseEquipment e in ExerciseEquipment.values) {
    if (e.name == trimmed) return e;
  }
  return null;
}
