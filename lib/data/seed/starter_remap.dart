/// One-time mapping from the legacy 18 starter exercise UUIDs to their
/// closest match in the bundled library packs. The pack importer uses
/// this to rewrite past workout/template references onto library entries
/// and then hide the starter rows. The starter rows themselves stay in
/// the database so any reference we couldn't catch still resolves by id.
///
/// New library exercise ids follow the convention `<packId>/<sourceId>`.
const Map<String, String> starterToLibraryRemap = <String, String>{
  // Bench Press
  '6f7c82cf-6f43-4e0b-ae08-d9e5f5a2d101':
      'strength/Barbell_Bench_Press_-_Medium_Grip',
  // Incline Dumbbell Press
  '17c4d0e0-6ae7-4e8f-8b5f-6a6c3d6d2102':
      'strength/Incline_Dumbbell_Press',
  // Overhead Press
  '0f3e8cf0-c3ad-4a46-a8f5-0d0a8d8b3103':
      'strength/Standing_Military_Press',
  // Pull-Up
  'b710d151-5591-4ac6-b13e-f7c1b5b04104': 'strength/Pullups',
  // Barbell Row
  '5b24d3c9-1b61-4ff8-8f5a-77f7a0f65105':
      'strength/Bent_Over_Barbell_Row',
  // Lat Pulldown
  '0c3af544-113e-4e52-873a-42790f9b8106':
      'strength/Wide-Grip_Lat_Pulldown',
  // Seated Cable Row
  'd83a9d2e-2785-4d88-a3a9-e12f1f065107':
      'strength/Seated_Cable_Rows',
  // Squat
  '7fe2f8f4-b5b8-456a-93ff-b8f0b8cf7108': 'strength/Barbell_Squat',
  // Deadlift
  '2fd3b643-905b-4d12-b1e9-2d978bd99109': 'strength/Barbell_Deadlift',
  // Romanian Deadlift
  '8dd7fdb2-79a2-482a-a64d-8edab0ce310a':
      'strength/Romanian_Deadlift',
  // Leg Press
  '0f8f1943-7679-4602-b75a-0e8c19a0410b': 'strength/Leg_Press',
  // Bicep Curl
  'ff0b2209-c470-46bb-80e8-5171ea6d610c': 'strength/Barbell_Curl',
  // Tricep Pushdown
  'ea79f0f7-a32f-4f8d-a90a-9cd2864d910d': 'strength/Triceps_Pushdown',
  // Plank
  'd2e0ab93-cb1d-4c14-9a9a-a7307d2bb10e': 'strength/Plank',
  // Push-Up
  'd5b74e62-cf52-4fdd-b933-278baab5e10f': 'strength/Pushups',
  // Sit-Up
  '9a7f6c81-e94d-43ea-8a53-d79ec66d6110': 'strength/3_4_Sit-Up',
  // Treadmill
  '278738fe-7c99-4761-a6c6-9a09be2a5111': 'cardio/Running_Treadmill',
  // Stationary Bike
  'e40fc26a-9c4d-4aa0-9201-c99fb7d9d112': 'cardio/Bicycling_Stationary',
};
