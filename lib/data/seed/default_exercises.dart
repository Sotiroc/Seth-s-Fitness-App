import '../models/cardio_metric.dart';
import '../models/exercise_equipment.dart';
import '../models/exercise_muscle_group.dart';
import '../models/exercise_type.dart';

/// One row in the built-in exercise library. Each seed has a stable UUID
/// so the seeder can identify which defaults a given install has already
/// been offered (see `ExerciseRepository.seedDefaultsIfNeeded`). Once an
/// id is in the seen set, future boots leave the row alone — even if the
/// user has renamed or deleted it. New seeds appearing in future versions
/// of this list get inserted on the next boot.
class DefaultExerciseSeed {
  const DefaultExerciseSeed({
    required this.id,
    required this.name,
    required this.type,
    required this.muscleGroup,
    required this.equipment,
    required this.formCue,
    this.trackedMetrics,
  });

  final String id;
  final String name;
  final ExerciseType type;
  final ExerciseMuscleGroup muscleGroup;
  final ExerciseEquipment equipment;
  final String formCue;

  /// Only meaningful for cardio. Null falls back to the legacy default
  /// (distance + duration) at the resolver — but every seeded cardio
  /// row sets this explicitly so the metric story is never accidental.
  final List<CardioMetric>? trackedMetrics;
}

const List<DefaultExerciseSeed> defaultExerciseSeeds = <DefaultExerciseSeed>[
  // ────────────────────────────────────────────────────────────────────
  // CHEST
  // ────────────────────────────────────────────────────────────────────
  DefaultExerciseSeed(
    id: '6f7c82cf-6f43-4e0b-ae08-d9e5f5a2d101',
    name: 'Bench Press',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.chest,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Drive feet down, retract shoulders, bar to lower chest, press through chest.',
  ),
  DefaultExerciseSeed(
    id: '17c4d0e0-6ae7-4e8f-8b5f-6a6c3d6d2102',
    name: 'Incline Dumbbell Press',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.chest,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Bench at 30°. Wrists stacked over elbows, press straight up, slow descent.',
  ),
  DefaultExerciseSeed(
    id: 'd5b74e62-cf52-4fdd-b933-278baab5e10f',
    name: 'Push-Up',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.chest,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Hands under shoulders, body straight, lower until chest taps the floor.',
  ),
  DefaultExerciseSeed(
    id: 'c1e57d02-4001-4abc-9def-c1e500000201',
    name: 'Incline Bench Press',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.chest,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Bench at 30°. Bar to upper chest, drive up and slightly back over face.',
  ),
  DefaultExerciseSeed(
    id: 'c1e57d02-4002-4abc-9def-c1e500000202',
    name: 'Decline Bench Press',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.chest,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Bench at -15°. Bar to lower chest, control descent, full lockout up top.',
  ),
  DefaultExerciseSeed(
    id: 'c1e57d02-4003-4abc-9def-c1e500000203',
    name: 'Dumbbell Bench Press',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.chest,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Wrists stacked over elbows, press straight up, full stretch at bottom.',
  ),
  DefaultExerciseSeed(
    id: 'c1e57d02-4004-4abc-9def-c1e500000204',
    name: 'Decline Dumbbell Press',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.chest,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Bench at -15°. Press dumbbells up to meet over lower chest.',
  ),
  DefaultExerciseSeed(
    id: 'c1e57d02-4005-4abc-9def-c1e500000205',
    name: 'Dumbbell Fly',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.chest,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Slight bend in elbows, lower in a wide arc until chest stretches.',
  ),
  DefaultExerciseSeed(
    id: 'c1e57d02-4006-4abc-9def-c1e500000206',
    name: 'Cable Fly',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.chest,
    equipment: ExerciseEquipment.cable,
    formCue:
        'Slight forward lean. Sweep handles together in front of chest, squeeze.',
  ),
  DefaultExerciseSeed(
    id: 'c1e57d02-4007-4abc-9def-c1e500000207',
    name: 'Pec Deck Machine',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.chest,
    equipment: ExerciseEquipment.machine,
    formCue:
        'Press handles together with chest, elbows slightly bent, slow return.',
  ),
  DefaultExerciseSeed(
    id: 'c1e57d02-4008-4abc-9def-c1e500000208',
    name: 'Incline Push-Up',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.chest,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Hands on bench. Body straight, lower chest to bench, drive back up.',
  ),
  DefaultExerciseSeed(
    id: 'c1e57d02-4009-4abc-9def-c1e500000209',
    name: 'Decline Push-Up',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.chest,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Feet elevated. Hands under shoulders, lower with control, press up.',
  ),
  DefaultExerciseSeed(
    id: 'c1e57d02-400a-4abc-9def-c1e50000020a',
    name: 'Diamond Push-Up',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.chest,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Hands form a triangle under chest. Elbows tight to body as you lower.',
  ),
  DefaultExerciseSeed(
    id: 'c1e57d02-400b-4abc-9def-c1e50000020b',
    name: 'Chest Dip',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.chest,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Lean forward. Lower until shoulders break parallel, press through chest.',
  ),
  DefaultExerciseSeed(
    id: 'c1e57d02-400c-4abc-9def-c1e50000020c',
    name: 'Chest Press Machine',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.chest,
    equipment: ExerciseEquipment.machine,
    formCue:
        'Adjust seat so handles align with mid-chest. Press out, control return.',
  ),

  // ────────────────────────────────────────────────────────────────────
  // BACK
  // ────────────────────────────────────────────────────────────────────
  DefaultExerciseSeed(
    id: 'b710d151-5591-4ac6-b13e-f7c1b5b04104',
    name: 'Pull-Up',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.back,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Dead hang start. Squeeze shoulder blades, pull chin over the bar.',
  ),
  DefaultExerciseSeed(
    id: '5b24d3c9-1b61-4ff8-8f5a-77f7a0f65105',
    name: 'Barbell Row',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.back,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Hinge at hips, flat back, bar to lower ribs, control the negative.',
  ),
  DefaultExerciseSeed(
    id: '0c3af544-113e-4e52-873a-42790f9b8106',
    name: 'Lat Pulldown',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.back,
    equipment: ExerciseEquipment.cable,
    formCue:
        'Lean back slightly, bar to upper chest, drive elbows down and back.',
  ),
  DefaultExerciseSeed(
    id: 'd83a9d2e-2785-4d88-a3a9-e12f1f065107',
    name: 'Seated Cable Row',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.back,
    equipment: ExerciseEquipment.cable,
    formCue:
        'Tall chest, pull handle to belly button, squeeze shoulder blades.',
  ),
  DefaultExerciseSeed(
    id: 'ba6cd401-4001-4abc-9def-ba6cd0000301',
    name: 'Chin-Up',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.back,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Underhand grip, shoulder-width. Pull chin over bar, slow descent.',
  ),
  DefaultExerciseSeed(
    id: 'ba6cd401-4002-4abc-9def-ba6cd0000302',
    name: 'Pendlay Row',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.back,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Bar dead-stops on the floor each rep. Explosive pull to lower chest.',
  ),
  DefaultExerciseSeed(
    id: 'ba6cd401-4003-4abc-9def-ba6cd0000303',
    name: 'T-Bar Row',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.back,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Hinge over the bar. Pull handles to chest, drive elbows back.',
  ),
  DefaultExerciseSeed(
    id: 'ba6cd401-4004-4abc-9def-ba6cd0000304',
    name: 'Single-Arm Dumbbell Row',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.back,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Brace on bench. Pull dumbbell to hip, elbow tight to side.',
  ),
  DefaultExerciseSeed(
    id: 'ba6cd401-4005-4abc-9def-ba6cd0000305',
    name: 'Inverted Row',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.back,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Bar at hip height. Body rigid, pull chest to bar, full lockout down.',
  ),
  DefaultExerciseSeed(
    id: 'ba6cd401-4006-4abc-9def-ba6cd0000306',
    name: 'Face Pull',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.back,
    equipment: ExerciseEquipment.cable,
    formCue:
        'Cable at face height. Pull rope to forehead, elbows high, shoulders back.',
  ),
  DefaultExerciseSeed(
    id: 'ba6cd401-4007-4abc-9def-ba6cd0000307',
    name: 'Hyperextension',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.back,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Hinge at hips on the pad. Lower under control, squeeze glutes up top.',
  ),
  DefaultExerciseSeed(
    id: 'ba6cd401-4008-4abc-9def-ba6cd0000308',
    name: 'Shrug',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.back,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Lift shoulders straight up toward ears. Hold a beat, lower with control.',
  ),
  DefaultExerciseSeed(
    id: 'ba6cd401-4009-4abc-9def-ba6cd0000309',
    name: 'Straight-Arm Pulldown',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.back,
    equipment: ExerciseEquipment.cable,
    formCue:
        'Tall posture. Pull cable to thighs with straight arms, feel the lats.',
  ),
  DefaultExerciseSeed(
    id: 'ba6cd401-400a-4abc-9def-ba6cd000030a',
    name: 'Reverse Fly',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.back,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Hinge forward. Sweep dumbbells out to sides, squeeze rear delts.',
  ),
  DefaultExerciseSeed(
    id: 'ba6cd401-400b-4abc-9def-ba6cd000030b',
    name: 'Single-Arm Lat Pulldown',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.back,
    equipment: ExerciseEquipment.cable,
    formCue:
        'Sit sideways to cable. Pull handle to ribs, full stretch at top.',
  ),
  DefaultExerciseSeed(
    id: 'ba6cd401-400c-4abc-9def-ba6cd000030c',
    name: 'Renegade Row',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.back,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Plank on dumbbells. Row one to hip, hips stay square, controlled.',
  ),

  // ────────────────────────────────────────────────────────────────────
  // LEGS
  // ────────────────────────────────────────────────────────────────────
  DefaultExerciseSeed(
    id: '7fe2f8f4-b5b8-456a-93ff-b8f0b8cf7108',
    name: 'Squat',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Feet shoulder-width, knees track over toes, drop until thighs parallel.',
  ),
  DefaultExerciseSeed(
    id: '2fd3b643-905b-4d12-b1e9-2d978bd99109',
    name: 'Deadlift',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Bar over mid-foot, flat back, push the floor away as you stand up.',
  ),
  DefaultExerciseSeed(
    id: '8dd7fdb2-79a2-482a-a64d-8edab0ce310a',
    name: 'Romanian Deadlift',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Hinge at hips, soft knees, bar slides down thighs, feel the stretch.',
  ),
  DefaultExerciseSeed(
    id: '0f8f1943-7679-4602-b75a-0e8c19a0410b',
    name: 'Leg Press',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.machine,
    formCue:
        'Feet flat, shoulder-width. Lower until knees ~90°, drive through heels.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-4001-4abc-9def-1e6700000401',
    name: 'Front Squat',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Bar racked on front delts, elbows up high. Stay tall, drop straight down.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-4002-4abc-9def-1e6700000402',
    name: 'Goblet Squat',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Hold dumbbell at chest. Drop between heels, knees track out over toes.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-4003-4abc-9def-1e6700000403',
    name: 'Bulgarian Split Squat',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Rear foot on bench. Drop straight down, drive through front heel.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-4004-4abc-9def-1e6700000404',
    name: 'Lunge',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Step forward, drop back knee toward floor, drive off front heel to stand.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-4005-4abc-9def-1e6700000405',
    name: 'Walking Lunge',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Long stride, drop back knee, push through front heel into next step.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-4006-4abc-9def-1e6700000406',
    name: 'Step-Up',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Drive off the heel of the lead foot, full lockout up top, control down.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-4007-4abc-9def-1e6700000407',
    name: 'Sumo Deadlift',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Wide stance, toes turned out. Hips low, drive feet through the floor.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-4008-4abc-9def-1e6700000408',
    name: 'Hack Squat',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.machine,
    formCue:
        'Feet a bit higher on the platform. Drop deep, drive heels through pad.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-4009-4abc-9def-1e6700000409',
    name: 'Leg Extension',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.machine,
    formCue:
        'Sit tall, pad on shins. Extend to lockout, hold a beat, control back.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-400a-4abc-9def-1e670000040a',
    name: 'Leg Curl',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.machine,
    formCue:
        'Pad on lower calves. Pull heels to glutes, slow eccentric.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-400b-4abc-9def-1e670000040b',
    name: 'Standing Calf Raise',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.machine,
    formCue:
        'Press up onto toes, pause at top stretch, lower below platform.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-400c-4abc-9def-1e670000040c',
    name: 'Seated Calf Raise',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.machine,
    formCue:
        'Knees pinned under pad. Press up onto toes, deep stretch at bottom.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-400d-4abc-9def-1e670000040d',
    name: 'Hip Thrust',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Shoulders on bench, bar over hips. Drive hips up, squeeze glutes hard.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-400e-4abc-9def-1e670000040e',
    name: 'Glute Bridge',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Lay on floor, knees bent. Press hips up, squeeze, slow descent.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-400f-4abc-9def-1e670000040f',
    name: 'Box Jump',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Drop into a quarter squat, jump up, land soft on box. Step down each rep.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-4010-4abc-9def-1e6700000410',
    name: 'Adductor Machine',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.machine,
    formCue:
        'Pads on inner thighs. Squeeze legs together, slow controlled return.',
  ),
  DefaultExerciseSeed(
    id: '1e670102-4011-4abc-9def-1e6700000411',
    name: 'Abductor Machine',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.legs,
    equipment: ExerciseEquipment.machine,
    formCue:
        'Pads on outer thighs. Press legs apart, hold, controlled return.',
  ),

  // ────────────────────────────────────────────────────────────────────
  // SHOULDERS
  // ────────────────────────────────────────────────────────────────────
  DefaultExerciseSeed(
    id: '0f3e8cf0-c3ad-4a46-a8f5-0d0a8d8b3103',
    name: 'Overhead Press',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.shoulders,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Stand tall, brace core, bar moves in a straight line past your nose.',
  ),
  DefaultExerciseSeed(
    id: '5b07db40-4001-4abc-9def-5b07d0000501',
    name: 'Dumbbell Shoulder Press',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.shoulders,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Wrists stacked over elbows. Press straight up overhead, full stretch.',
  ),
  DefaultExerciseSeed(
    id: '5b07db40-4002-4abc-9def-5b07d0000502',
    name: 'Arnold Press',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.shoulders,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Start palms facing you. Rotate as you press up, palms forward at top.',
  ),
  DefaultExerciseSeed(
    id: '5b07db40-4003-4abc-9def-5b07d0000503',
    name: 'Lateral Raise',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.shoulders,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Slight bend in elbows. Raise out to shoulder height, soft pause, lower.',
  ),
  DefaultExerciseSeed(
    id: '5b07db40-4004-4abc-9def-5b07d0000504',
    name: 'Front Raise',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.shoulders,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Raise dumbbells in front to shoulder height. No swinging, controlled tempo.',
  ),
  DefaultExerciseSeed(
    id: '5b07db40-4005-4abc-9def-5b07d0000505',
    name: 'Rear Delt Fly',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.shoulders,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Hinge forward. Sweep dumbbells out wide, squeeze rear delts hard.',
  ),
  DefaultExerciseSeed(
    id: '5b07db40-4006-4abc-9def-5b07d0000506',
    name: 'Cable Lateral Raise',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.shoulders,
    equipment: ExerciseEquipment.cable,
    formCue:
        'Cable behind body. Sweep arm out to shoulder height, slow control.',
  ),
  DefaultExerciseSeed(
    id: '5b07db40-4007-4abc-9def-5b07d0000507',
    name: 'Upright Row',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.shoulders,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Pull bar straight up to upper chest, elbows leading, pause at top.',
  ),
  DefaultExerciseSeed(
    id: '5b07db40-4008-4abc-9def-5b07d0000508',
    name: 'Push Press',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.shoulders,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Quarter dip with legs, drive bar up overhead in one motion. Lock out.',
  ),

  // ────────────────────────────────────────────────────────────────────
  // BICEPS
  // ────────────────────────────────────────────────────────────────────
  DefaultExerciseSeed(
    id: 'ff0b2209-c470-46bb-80e8-5171ea6d610c',
    name: 'Bicep Curl',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.biceps,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Elbows pinned to sides, curl up controlled, full stretch at the bottom.',
  ),
  DefaultExerciseSeed(
    id: 'b1cef540-4001-4abc-9def-b1cef0000601',
    name: 'Hammer Curl',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.biceps,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Palms face each other. Curl with no rotation, elbows pinned to sides.',
  ),
  DefaultExerciseSeed(
    id: 'b1cef540-4002-4abc-9def-b1cef0000602',
    name: 'Preacher Curl',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.biceps,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Arms over the pad. Lower to nearly-straight, curl with full control.',
  ),
  DefaultExerciseSeed(
    id: 'b1cef540-4003-4abc-9def-b1cef0000603',
    name: 'Concentration Curl',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.biceps,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Elbow braced on inner thigh. Curl across body, peak contraction up top.',
  ),
  DefaultExerciseSeed(
    id: 'b1cef540-4004-4abc-9def-b1cef0000604',
    name: 'Cable Curl',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.biceps,
    equipment: ExerciseEquipment.cable,
    formCue:
        'Stand tall, elbows at sides. Curl handle up, slow eccentric down.',
  ),
  DefaultExerciseSeed(
    id: 'b1cef540-4005-4abc-9def-b1cef0000605',
    name: 'EZ Bar Curl',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.biceps,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Use the angled grip for wrist comfort. Elbows pinned, full range.',
  ),
  DefaultExerciseSeed(
    id: 'b1cef540-4006-4abc-9def-b1cef0000606',
    name: 'Incline Dumbbell Curl',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.biceps,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Bench at 60°. Long stretch at the bottom, curl up controlled.',
  ),
  DefaultExerciseSeed(
    id: 'b1cef540-4007-4abc-9def-b1cef0000607',
    name: 'Barbell Curl',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.biceps,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Stand tall, shoulder-width grip. Elbows pinned, no swinging body.',
  ),
  DefaultExerciseSeed(
    id: 'b1cef540-4008-4abc-9def-b1cef0000608',
    name: 'Spider Curl',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.biceps,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Chest on incline bench. Curl with elbows hanging, no momentum.',
  ),

  // ────────────────────────────────────────────────────────────────────
  // TRICEPS
  // ────────────────────────────────────────────────────────────────────
  DefaultExerciseSeed(
    id: 'ea79f0f7-a32f-4f8d-a90a-9cd2864d910d',
    name: 'Tricep Pushdown',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.triceps,
    equipment: ExerciseEquipment.cable,
    formCue:
        'Elbows tight to ribs, push down to full lockout, slow eccentric.',
  ),
  DefaultExerciseSeed(
    id: '727cef50-4001-4abc-9def-727cf0000701',
    name: 'Rope Pushdown',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.triceps,
    equipment: ExerciseEquipment.cable,
    formCue:
        'Elbows tight to sides. Spread the rope at the bottom, full lockout.',
  ),
  DefaultExerciseSeed(
    id: '727cef50-4002-4abc-9def-727cf0000702',
    name: 'Skull Crusher',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.triceps,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Elbows pointed at the ceiling. Lower bar to forehead, extend up.',
  ),
  DefaultExerciseSeed(
    id: '727cef50-4003-4abc-9def-727cf0000703',
    name: 'Overhead Tricep Extension',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.triceps,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Dumbbell overhead, elbows by ears. Lower behind head, extend up.',
  ),
  DefaultExerciseSeed(
    id: '727cef50-4004-4abc-9def-727cf0000704',
    name: 'Close-Grip Bench Press',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.triceps,
    equipment: ExerciseEquipment.barbell,
    formCue:
        'Hands shoulder-width on bar. Elbows tight, press to lockout.',
  ),
  DefaultExerciseSeed(
    id: '727cef50-4005-4abc-9def-727cf0000705',
    name: 'Tricep Dip',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.triceps,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Bench dip or bars. Stay upright, lower until ~90°, press up.',
  ),
  DefaultExerciseSeed(
    id: '727cef50-4006-4abc-9def-727cf0000706',
    name: 'Tricep Kickback',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.triceps,
    equipment: ExerciseEquipment.dumbbell,
    formCue:
        'Hinged over, elbow up. Extend dumbbell back to lockout, slow return.',
  ),

  // ────────────────────────────────────────────────────────────────────
  // ABS / CORE
  // ────────────────────────────────────────────────────────────────────
  DefaultExerciseSeed(
    id: 'd2e0ab93-cb1d-4c14-9a9a-a7307d2bb10e',
    name: 'Plank',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.abs,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Forearms down, body straight head to heels, brace core, breathe.',
  ),
  DefaultExerciseSeed(
    id: '9a7f6c81-e94d-43ea-8a53-d79ec66d6110',
    name: 'Sit-Up',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.abs,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        "Knees bent, feet flat. Curl up smoothly, don't yank with your neck.",
  ),
  DefaultExerciseSeed(
    id: 'ab500a01-4001-4abc-9def-ab50a0000801',
    name: 'Side Plank',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.abs,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Stack feet, hips high, body in one line. Hold, breathe, swap sides.',
  ),
  DefaultExerciseSeed(
    id: 'ab500a01-4002-4abc-9def-ab50a0000802',
    name: 'Crunch',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.abs,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Lay flat, knees bent. Curl shoulders off floor, ribs to hips, slow return.',
  ),
  DefaultExerciseSeed(
    id: 'ab500a01-4003-4abc-9def-ab50a0000803',
    name: 'Bicycle Crunch',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.abs,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Opposite elbow to opposite knee. Slow rotation, full leg extension.',
  ),
  DefaultExerciseSeed(
    id: 'ab500a01-4004-4abc-9def-ab50a0000804',
    name: 'Russian Twist',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.abs,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Sit at angle, feet up. Rotate weight side to side, brace through middle.',
  ),
  DefaultExerciseSeed(
    id: 'ab500a01-4005-4abc-9def-ab50a0000805',
    name: 'Hanging Leg Raise',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.abs,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Hang from bar. Raise legs to 90° (or feet to bar), slow descent.',
  ),
  DefaultExerciseSeed(
    id: 'ab500a01-4006-4abc-9def-ab50a0000806',
    name: 'Mountain Climbers',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.abs,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Plank position. Drive knees toward chest in alternating sprint.',
  ),
  DefaultExerciseSeed(
    id: 'ab500a01-4007-4abc-9def-ab50a0000807',
    name: 'Dead Bug',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.abs,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Lay on back, arms up, knees over hips. Lower opposite arm and leg, return.',
  ),
  DefaultExerciseSeed(
    id: 'ab500a01-4008-4abc-9def-ab50a0000808',
    name: 'Bird Dog',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.abs,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Quadruped. Extend opposite arm and leg, hold, return with control.',
  ),
  DefaultExerciseSeed(
    id: 'ab500a01-4009-4abc-9def-ab50a0000809',
    name: 'Cable Woodchopper',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.abs,
    equipment: ExerciseEquipment.cable,
    formCue:
        'Cable high. Pull and rotate diagonally across to opposite hip.',
  ),
  DefaultExerciseSeed(
    id: 'ab500a01-400a-4abc-9def-ab50a000080a',
    name: 'Ab Wheel Rollout',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.abs,
    equipment: ExerciseEquipment.other,
    formCue:
        'Knees on pad. Roll forward as far as you can hold, pull back in.',
  ),
  DefaultExerciseSeed(
    id: 'ab500a01-400b-4abc-9def-ab50a000080b',
    name: 'Toe Touch',
    type: ExerciseType.bodyweight,
    muscleGroup: ExerciseMuscleGroup.abs,
    equipment: ExerciseEquipment.bodyweight,
    formCue:
        'Lay flat, legs up. Reach hands to feet, curling shoulders off the floor.',
  ),
  DefaultExerciseSeed(
    id: 'ab500a01-400c-4abc-9def-ab50a000080c',
    name: 'Cable Crunch',
    type: ExerciseType.weighted,
    muscleGroup: ExerciseMuscleGroup.abs,
    equipment: ExerciseEquipment.cable,
    formCue:
        'Kneel under cable. Crunch ribs to hips, hold the contraction.',
  ),

  // ────────────────────────────────────────────────────────────────────
  // CARDIO
  // ────────────────────────────────────────────────────────────────────
  DefaultExerciseSeed(
    id: '278738fe-7c99-4761-a6c6-9a09be2a5111',
    name: 'Treadmill',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.cardioMachine,
    formCue:
        'Steady pace. Keep posture upright, land mid-foot, breathe rhythmically.',
    trackedMetrics: <CardioMetric>[CardioMetric.distance, CardioMetric.duration],
  ),
  DefaultExerciseSeed(
    id: 'e40fc26a-9c4d-4aa0-9201-c99fb7d9d112',
    name: 'Stationary Bike',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.cardioMachine,
    formCue:
        'Adjust seat to nearly-straight leg at bottom. Stay relaxed up top.',
    trackedMetrics: <CardioMetric>[CardioMetric.distance, CardioMetric.duration],
  ),
  DefaultExerciseSeed(
    id: 'cad10cad-4001-4abc-9def-cad100000901',
    name: 'Running (Outdoor)',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.other,
    formCue:
        'Steady cadence. Land mid-foot, relax shoulders, breathe rhythmically.',
    trackedMetrics: <CardioMetric>[CardioMetric.distance, CardioMetric.duration],
  ),
  DefaultExerciseSeed(
    id: 'cad10cad-4002-4abc-9def-cad100000902',
    name: 'Cycling (Outdoor)',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.other,
    formCue:
        'Smooth cadence ~80 rpm. Stay relaxed up top, push and pull through.',
    trackedMetrics: <CardioMetric>[CardioMetric.distance, CardioMetric.duration],
  ),
  DefaultExerciseSeed(
    id: 'cad10cad-4003-4abc-9def-cad100000903',
    name: 'Rowing Machine',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.cardioMachine,
    formCue:
        'Drive with legs, then back, then arms. Reverse on the recovery.',
    trackedMetrics: <CardioMetric>[CardioMetric.distance, CardioMetric.duration],
  ),
  DefaultExerciseSeed(
    id: 'cad10cad-4004-4abc-9def-cad100000904',
    name: 'Walking',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.other,
    formCue:
        'Brisk pace. Tall posture, swing arms naturally, breathe through nose.',
    trackedMetrics: <CardioMetric>[CardioMetric.distance, CardioMetric.duration],
  ),
  DefaultExerciseSeed(
    id: 'cad10cad-4005-4abc-9def-cad100000905',
    name: 'Hiking',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.other,
    formCue:
        'Pace yourself on grades. Short steps uphill, controlled descent.',
    trackedMetrics: <CardioMetric>[CardioMetric.distance, CardioMetric.duration],
  ),
  DefaultExerciseSeed(
    id: 'cad10cad-4006-4abc-9def-cad100000906',
    name: 'Elliptical',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.cardioMachine,
    formCue:
        'Stand tall. Drive through heels, push and pull handles, steady cadence.',
    trackedMetrics: <CardioMetric>[CardioMetric.duration, CardioMetric.calories],
  ),
  DefaultExerciseSeed(
    id: 'cad10cad-4007-4abc-9def-cad100000907',
    name: 'Stair Master',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.cardioMachine,
    formCue:
        'Stand tall, no leaning on rails. Full step each time, drive through heel.',
    trackedMetrics: <CardioMetric>[CardioMetric.duration, CardioMetric.floors],
  ),
  DefaultExerciseSeed(
    id: 'cad10cad-4008-4abc-9def-cad100000908',
    name: 'Stair Climber',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.cardioMachine,
    formCue:
        'Pace yourself early. Steady cadence, full extension on each step.',
    trackedMetrics: <CardioMetric>[CardioMetric.duration],
  ),
  DefaultExerciseSeed(
    id: 'cad10cad-4009-4abc-9def-cad100000909',
    name: 'Swimming',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.other,
    formCue:
        'Long strokes, breathe to the side. Streamline body, kick from the hip.',
    trackedMetrics: <CardioMetric>[CardioMetric.laps, CardioMetric.duration],
  ),
  DefaultExerciseSeed(
    id: 'cad10cad-400a-4abc-9def-cad10000090a',
    name: 'Boxing',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.other,
    formCue:
        'Stay light, hands up, exhale on each punch. Round structure with breaks.',
    trackedMetrics: <CardioMetric>[CardioMetric.duration],
  ),
  DefaultExerciseSeed(
    id: 'cad10cad-400b-4abc-9def-cad10000090b',
    name: 'Kickboxing',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.other,
    formCue:
        'Mix punches and kicks. Stay light on feet, breathe rhythmically.',
    trackedMetrics: <CardioMetric>[CardioMetric.duration],
  ),
  DefaultExerciseSeed(
    id: 'cad10cad-400c-4abc-9def-cad10000090c',
    name: 'Jump Rope',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.other,
    formCue:
        'Light bounce on balls of feet, wrists do the work, not the arms.',
    trackedMetrics: <CardioMetric>[CardioMetric.duration],
  ),
  DefaultExerciseSeed(
    id: 'cad10cad-400d-4abc-9def-cad10000090d',
    name: 'Battle Ropes',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.other,
    formCue:
        'Soft knees, hips back. Drive waves with full body, brace your core.',
    trackedMetrics: <CardioMetric>[CardioMetric.duration],
  ),
  DefaultExerciseSeed(
    id: 'cad10cad-400e-4abc-9def-cad10000090e',
    name: 'HIIT',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.other,
    formCue:
        'Hard intervals, full recovery. Quality reps over volume.',
    trackedMetrics: <CardioMetric>[CardioMetric.duration],
  ),
  DefaultExerciseSeed(
    id: 'cad10cad-400f-4abc-9def-cad10000090f',
    name: 'Yoga',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.other,
    formCue:
        'Match breath to movement. Hold poses with intention, never force a stretch.',
    trackedMetrics: <CardioMetric>[CardioMetric.duration],
  ),
  DefaultExerciseSeed(
    id: 'cad10cad-4010-4abc-9def-cad100000910',
    name: 'Pilates',
    type: ExerciseType.cardio,
    muscleGroup: ExerciseMuscleGroup.cardio,
    equipment: ExerciseEquipment.other,
    formCue:
        'Breathe steadily, pull navel to spine. Slow controlled tempo throughout.',
    trackedMetrics: <CardioMetric>[CardioMetric.duration],
  ),
];
