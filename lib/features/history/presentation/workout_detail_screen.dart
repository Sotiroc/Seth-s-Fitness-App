import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/exercise_type.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/workout_detail.dart';
import '../../../data/models/workout_exercise.dart';
import '../../../data/models/workout_set.dart';
import '../../../data/models/workout_set_kind.dart';
import '../../../data/models/workout_structure.dart';
import '../../exercises/presentation/widgets/exercise_avatar.dart';
import '../../exercises/presentation/widgets/exercise_muscle_group_badge.dart';
import '../../exercises/presentation/widgets/exercise_type_badge.dart';
import '../application/history_providers.dart';

/// Read-only detail view of a completed (or in-progress) workout.
///
/// The data is split into two streams:
///  - [workoutStructureProvider] for the layout shell (workout, ordered
///    exercises) — re-emits only when the workout / exercise list itself
///    changes, so per-set edits don't flicker the hero or section labels.
///  - [workoutExerciseSetsProvider] (one per exercise card) for the sets
///    inside each card — set-kind / RPE / note tweaks only rebuild the
///    card whose sets actually changed.
class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final AsyncValue<WorkoutStructure> structureAsync = ref.watch(
      workoutStructureProvider(workoutId),
    );

    return Scaffold(
      backgroundColor: palette.shade50,
      body: structureAsync.when(
        data: (WorkoutStructure structure) => _DetailBody(
          workoutId: workoutId,
          structure: structure,
          palette: palette,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(palette: palette, error: err),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.palette, required this.error});

  final JellyBeanPalette palette;
  final Object error;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: palette.shade600,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Could not load workout',
                style: TextStyle(
                  color: palette.shade950,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.shade800),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => context.go('/history'),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.shade900,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to History'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.workoutId,
    required this.structure,
    required this.palette,
  });

  final String workoutId;
  final WorkoutStructure structure;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    final Workout workout = structure.workout;
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: _HeroSection(
            workoutId: workoutId,
            workout: workout,
            palette: palette,
          ),
        ),
        if (workout.notes != null && workout.notes!.trim().isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _NotesCard(palette: palette, notes: workout.notes!),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          sliver: SliverToBoxAdapter(
            child: _SectionLabel(text: 'Exercises', palette: palette),
          ),
        ),
        if (structure.exercises.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                'No exercises were logged.',
                style: TextStyle(
                  color: palette.shade800.withValues(alpha: 0.8),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverList.separated(
              itemCount: structure.exercises.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final WorkoutExerciseStructure entry =
                    structure.exercises[index];
                return _DetailExerciseCard(
                  key: ValueKey<String>(
                    'detail-card-${entry.workoutExercise.id}',
                  ),
                  workoutExercise: entry.workoutExercise,
                  exercise: entry.exercise,
                  palette: palette,
                );
              },
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: _BackButton(
              palette: palette,
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/history');
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Hero header — its own Consumer so set-table aggregates re-render here
/// without forcing the rest of the screen to rebuild. Watches the full
/// `workoutDetailProvider` to compute totals/volume/distance; the
/// surrounding shell only listens to structural changes.
class _HeroSection extends ConsumerWidget {
  const _HeroSection({
    required this.workoutId,
    required this.workout,
    required this.palette,
  });

  final String workoutId;
  final Workout workout;
  final JellyBeanPalette palette;

  static String? _cleanedName(String? value) {
    if (value == null) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<WorkoutDetail> detailAsync = ref.watch(
      workoutDetailProvider(workoutId),
    );
    final WorkoutDetail? detail = detailAsync.asData?.value;
    // Aggregates are recomputed only on actual content change because
    // `workoutDetailProvider`'s stream dedupes by structural equality.
    final _DetailAggregates aggregates = detail == null
        ? _DetailAggregates.placeholder(workout)
        : _DetailAggregates.from(detail);
    return _Hero(
      palette: palette,
      workoutName: _cleanedName(workout.name),
      workoutDateLabel: aggregates.dateLabel,
      isActive: workout.isActive,
      duration: aggregates.duration,
      completedSets: aggregates.completedSets,
      totalSets: aggregates.totalSets,
      volumeLabel: aggregates.volumeLabel,
      distanceLabel: aggregates.distanceLabel,
      hasCardio: aggregates.hasCardio,
      intensityScore: workout.intensityScore,
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.palette,
    required this.workoutName,
    required this.workoutDateLabel,
    required this.isActive,
    required this.duration,
    required this.completedSets,
    required this.totalSets,
    required this.volumeLabel,
    required this.distanceLabel,
    required this.hasCardio,
    required this.intensityScore,
  });

  final JellyBeanPalette palette;
  final String? workoutName;

  /// Pre-formatted weekday + date string ("Monday, 5 May 2026").
  final String workoutDateLabel;
  final bool isActive;
  final Duration duration;
  final int completedSets;
  final int totalSets;

  /// Pre-formatted total volume label (e.g. "1.2k" or "750"). Empty when
  /// the workout has no qualifying weighted sets.
  final String volumeLabel;

  /// Pre-formatted total distance label. Empty when the workout has no
  /// cardio entries.
  final String distanceLabel;

  /// True when there is at least one completed cardio set.
  final bool hasCardio;
  final int? intensityScore;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.shade950, palette.shade800, palette.shade500],
          stops: const <double>[0.0, 0.55, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topPadding + AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              InkWell(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/history');
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: palette.shade100,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      isActive
                          ? Icons.bolt_rounded
                          : Icons.check_circle_rounded,
                      size: 14,
                      color: palette.shade100,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'IN PROGRESS' : 'COMPLETED',
                      style: TextStyle(
                        color: palette.shade100,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (workoutName != null) ...<Widget>[
            Text(
              workoutName!,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
          ],
          Text(
            workoutDateLabel,
            style:
                (workoutName != null
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.titleLarge)
                    ?.copyWith(
                      color: workoutName != null
                          ? palette.shade100.withValues(alpha: 0.85)
                          : Colors.white,
                      fontWeight: workoutName != null
                          ? FontWeight.w600
                          : FontWeight.w800,
                      letterSpacing: workoutName != null ? 0.0 : -0.6,
                    ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: _HeroStat(
                  palette: palette,
                  value: DurationFormatter.elapsed(duration),
                  label: 'Duration',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeroStat(
                  palette: palette,
                  value: '$completedSets / $totalSets',
                  label: 'Sets',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: _HeroStat(
                  palette: palette,
                  value: '$volumeLabel kg',
                  label: 'Volume',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeroStat(
                  palette: palette,
                  value: hasCardio ? '$distanceLabel km' : '—',
                  label: 'Distance',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: _HeroStat(
                  palette: palette,
                  value: intensityScore != null ? '$intensityScore/10' : '—',
                  label: 'Intensity',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.palette,
    required this.value,
    required this.label,
  });

  final JellyBeanPalette palette;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: palette.shade200.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.palette, required this.notes});

  final JellyBeanPalette palette;
  final String notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.shade100.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.sticky_note_2_outlined, color: palette.shade700, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              notes,
              style: TextStyle(
                color: palette.shade900,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.palette});

  final String text;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(width: 24, height: 2, color: palette.shade500),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            color: palette.shade700,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

class _DetailExerciseCard extends ConsumerWidget {
  const _DetailExerciseCard({
    super.key,
    required this.workoutExercise,
    required this.exercise,
    required this.palette,
  });

  final WorkoutExercise workoutExercise;
  final Exercise exercise;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    // Per-card sets stream — only this card rebuilds when its sets
    // change (kind / RPE / note / values). Sibling cards stay still.
    final List<WorkoutSet> sets = ref
            .watch(workoutExerciseSetsProvider(workoutExercise.id))
            .asData
            ?.value ??
        const <WorkoutSet>[];
    final int completed = sets.where((s) => s.completed).length;
    final String? exerciseNote = workoutExercise.notes;
    final bool hasExerciseNote =
        exerciseNote != null && exerciseNote.trim().isNotEmpty;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                ExerciseAvatar(exercise: exercise, size: 40),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        exercise.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: palette.shade950,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: <Widget>[
                          ExerciseTypeBadge(type: exercise.type),
                          ExerciseMuscleGroupBadge(
                            muscleGroup: exercise.muscleGroup,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '$completed / ${sets.length}',
                  style: TextStyle(
                    color: palette.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (hasExerciseNote)
              Padding(
                padding: const EdgeInsets.only(
                  top: 6,
                  left: 50,
                  right: 4,
                ),
                child: Text(
                  exerciseNote.trim(),
                  style: TextStyle(
                    color: palette.shade800.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
                ),
              ),
            if (sets.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'No sets recorded.',
                  style: TextStyle(
                    color: palette.shade700.withValues(alpha: 0.7),
                    fontSize: 12.5,
                  ),
                ),
              )
            else ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              for (final WorkoutSet set in sets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _SetLine(
                    set: set,
                    type: exercise.type,
                    palette: palette,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SetLine extends StatelessWidget {
  const _SetLine({
    required this.set,
    required this.type,
    required this.palette,
  });

  final WorkoutSet set;
  final ExerciseType type;
  final JellyBeanPalette palette;

  String _formatSet() {
    switch (type) {
      case ExerciseType.weighted:
        final String kg = _formatNumber(set.weightKg ?? 0);
        return '$kg kg  ·  ${set.reps ?? 0} reps';
      case ExerciseType.bodyweight:
        return '${set.reps ?? 0} reps';
      case ExerciseType.cardio:
        final String km = _formatNumber(set.distanceKm ?? 0);
        final String time = DurationFormatter.formatSeconds(
          set.durationSeconds ?? 0,
        );
        return '$km km  ·  $time';
    }
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bool completed = set.completed;
    final String? note = set.note;
    final bool hasNote = note != null && note.trim().isNotEmpty;
    final int? rpe = set.rpe;

    return Opacity(
      opacity: completed ? 1.0 : 0.55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: completed ? palette.shade100 : palette.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: completed
                      ? null
                      : Border.all(color: palette.shade200),
                ),
                child: Text(
                  '${set.setNumber}',
                  style: TextStyle(
                    color: palette.shade800,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _formatSet(),
                  style: TextStyle(
                    color: palette.shade950,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              if (rpe != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: Text(
                    'RPE $rpe',
                    style: TextStyle(
                      color: palette.shade700.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              if (hasNote)
                Padding(
                  padding: EdgeInsets.only(
                    left: rpe != null ? 6 : AppSpacing.xs,
                  ),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.shade700.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              if (!completed)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: Text(
                    'skipped',
                    style: TextStyle(
                      color: palette.shade700.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
          if (hasNote)
            Padding(
              padding: const EdgeInsets.only(
                top: 2,
                left: 26 + AppSpacing.sm,
                right: 4,
                bottom: 2,
              ),
              child: Text(
                note.trim(),
                style: TextStyle(
                  color: palette.shade800.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Single-pass aggregates + pre-formatted labels for the workout-detail
/// hero. Built once per `WorkoutDetail` instance so the hero's stats row
/// doesn't re-walk the exercise/set list or reformat strings on every
/// rebuild.
class _DetailAggregates {
  const _DetailAggregates({
    required this.duration,
    required this.completedSets,
    required this.totalSets,
    required this.volumeLabel,
    required this.distanceLabel,
    required this.hasCardio,
    required this.dateLabel,
  });

  final Duration duration;
  final int completedSets;
  final int totalSets;
  final String volumeLabel;
  final String distanceLabel;
  final bool hasCardio;
  final String dateLabel;

  /// Cheap fallback used while the full detail (with sets) hasn't
  /// arrived yet — populates structural fields (date/duration) and
  /// leaves the set-derived totals at zero. Renders the hero
  /// immediately while the detail stream catches up rather than gating
  /// the whole screen on a spinner.
  factory _DetailAggregates.placeholder(Workout workout) {
    final DateTime end = workout.endedAt ?? DateTime.now();
    return _DetailAggregates(
      duration: end.difference(workout.startedAt),
      completedSets: 0,
      totalSets: 0,
      volumeLabel: _formatKg(0),
      distanceLabel: _formatKm(0),
      hasCardio: false,
      dateLabel: _formatDate(workout.startedAt.toLocal()),
    );
  }

  factory _DetailAggregates.from(WorkoutDetail detail) {
    int completedSets = 0;
    int totalSets = 0;
    double totalVolumeKg = 0;
    double totalDistanceKm = 0;

    for (final WorkoutExerciseDetail e in detail.exercises) {
      final ExerciseType type = e.exercise.type;
      for (final WorkoutSet s in e.sets) {
        if (s.kind.countsAsWorkingSet) {
          totalSets++;
          if (s.completed) completedSets++;
        }
        if (!s.completed || s.kind == WorkoutSetKind.warmUp) continue;
        if (type == ExerciseType.weighted) {
          totalVolumeKg += (s.weightKg ?? 0) * (s.reps ?? 0);
        } else if (type == ExerciseType.cardio) {
          totalDistanceKm += s.distanceKm ?? 0;
        }
      }
    }

    final DateTime end = detail.workout.endedAt ?? DateTime.now();
    return _DetailAggregates(
      duration: end.difference(detail.workout.startedAt),
      completedSets: completedSets,
      totalSets: totalSets,
      volumeLabel: _formatKg(totalVolumeKg),
      distanceLabel: _formatKm(totalDistanceKm),
      hasCardio: totalDistanceKm > 0,
      dateLabel: _formatDate(detail.workout.startedAt.toLocal()),
    );
  }

  static String _formatKg(double value) {
    if (value <= 0) return '0';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  static String _formatKm(double value) {
    if (value <= 0) return '0';
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
  }

  static const List<String> _weekdayNames = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _formatDate(DateTime d) {
    return '${_weekdayNames[d.weekday - 1]}, ${d.day} '
        '${_monthNames[d.month - 1]} ${d.year}';
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.palette, required this.onTap});

  final JellyBeanPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: palette.shade900,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Back',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
