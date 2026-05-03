import '../../../../data/models/workout_set.dart';
import '../../../../data/models/workout_set_kind.dart';

/// Returns [sets] re-ordered for display:
/// - All warm-ups float to the top, in their original setNumber order.
/// - Working sets (normal / failure) follow, in setNumber order.
/// - Each working set is immediately followed by its drop children
///   (matched via [WorkoutSet.parentSetId]), in setNumber order.
/// - Drop sets without a resolvable parent (orphaned by deletes) are
///   slotted at the end — visible but clearly unattached.
///
/// Pure function — does not mutate the input list. Stable enough for the
/// active workout screen's per-build call.
List<WorkoutSet> orderedSetsForDisplay(List<WorkoutSet> sets) {
  if (sets.isEmpty) return const <WorkoutSet>[];

  final List<WorkoutSet> warmUps = <WorkoutSet>[];
  final List<WorkoutSet> working = <WorkoutSet>[];
  final List<WorkoutSet> drops = <WorkoutSet>[];

  for (final WorkoutSet s in sets) {
    switch (s.kind) {
      case WorkoutSetKind.warmUp:
        warmUps.add(s);
      case WorkoutSetKind.drop:
        drops.add(s);
      case WorkoutSetKind.normal:
      case WorkoutSetKind.failure:
        working.add(s);
    }
  }

  // Stable secondary sort by setNumber so the user's original row order is
  // preserved within each bucket.
  warmUps.sort((WorkoutSet a, WorkoutSet b) => a.setNumber.compareTo(b.setNumber));
  working.sort((WorkoutSet a, WorkoutSet b) => a.setNumber.compareTo(b.setNumber));
  drops.sort((WorkoutSet a, WorkoutSet b) => a.setNumber.compareTo(b.setNumber));

  final Map<String, List<WorkoutSet>> dropsByParent = <String, List<WorkoutSet>>{};
  final List<WorkoutSet> orphanDrops = <WorkoutSet>[];
  final Set<String> workingIds = <String>{
    for (final WorkoutSet s in working) s.id,
  };
  for (final WorkoutSet drop in drops) {
    final String? parentId = drop.parentSetId;
    if (parentId != null && workingIds.contains(parentId)) {
      dropsByParent
          .putIfAbsent(parentId, () => <WorkoutSet>[])
          .add(drop);
    } else {
      orphanDrops.add(drop);
    }
  }

  final List<WorkoutSet> result = <WorkoutSet>[];
  result.addAll(warmUps);
  for (final WorkoutSet w in working) {
    result.add(w);
    final List<WorkoutSet>? children = dropsByParent[w.id];
    if (children != null) result.addAll(children);
  }
  result.addAll(orphanDrops);
  return result;
}

/// Renders the drop chain that follows [parent], formatted like
/// `100×8 → 80×6 → 60×4`. Used by the PREVIOUS column so the user can
/// see the full prior chain at a glance instead of just the parent's
/// numbers.
///
/// Returns null when the parent has no completed drop children.
String? formatDropChainSuffix({
  required WorkoutSet parent,
  required List<WorkoutSet> allPreviousSets,
}) {
  final List<WorkoutSet> children = allPreviousSets
      .where((WorkoutSet s) =>
          s.kind == WorkoutSetKind.drop &&
          s.parentSetId == parent.id &&
          s.completed)
      .toList()
    ..sort((WorkoutSet a, WorkoutSet b) => a.setNumber.compareTo(b.setNumber));
  if (children.isEmpty) return null;

  final List<String> parts = <String>[];
  for (final WorkoutSet child in children) {
    final double weight = child.weightKg ?? 0;
    final int reps = child.reps ?? 0;
    parts.add('${_formatNum(weight)}×$reps');
  }
  return parts.join(' → ');
}

String _formatNum(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}
