import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/exercise_type.dart';
import '../../../data/models/workout_detail.dart';
import '../../../data/models/workout_set.dart';
import '../../exercises/presentation/widgets/exercise_avatar.dart';
import '../../exercises/presentation/widgets/exercise_type_badge.dart';
import '../application/history_providers.dart';

/// Read-only detail view of a completed (or in-progress) workout. Reuses the
/// streaming [workoutDetailProvider] so edits from the active workout flow
/// appear immediately.
class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final AsyncValue<WorkoutDetail> detailAsync = ref.watch(
      workoutDetailProvider(workoutId),
    );

    return Scaffold(
      backgroundColor: palette.shade50,
      body: detailAsync.when(
        data: (detail) => _DetailBody(detail: detail, palette: palette),
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
  const _DetailBody({required this.detail, required this.palette});

  final WorkoutDetail detail;
  final JellyBeanPalette palette;

  Duration get _duration {
    final DateTime end = detail.workout.endedAt ?? DateTime.now();
    return end.difference(detail.workout.startedAt);
  }

  int get _completedSets =>
      detail.exercises.expand((e) => e.sets).where((s) => s.completed).length;

  int get _totalSets =>
      detail.exercises.fold<int>(0, (sum, e) => sum + e.sets.length);

  double get _totalVolumeKg {
    double total = 0;
    for (final WorkoutExerciseDetail e in detail.exercises) {
      if (e.exercise.type != ExerciseType.weighted) continue;
      for (final WorkoutSet s in e.sets) {
        if (!s.completed) continue;
        total += (s.weightKg ?? 0) * (s.reps ?? 0);
      }
    }
    return total;
  }

  double get _totalDistanceKm {
    double total = 0;
    for (final WorkoutExerciseDetail e in detail.exercises) {
      if (e.exercise.type != ExerciseType.cardio) continue;
      for (final WorkoutSet s in e.sets) {
        if (!s.completed) continue;
        total += s.distanceKm ?? 0;
      }
    }
    return total;
  }

  static String? _cleanedName(String? value) {
    if (value == null) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: _Hero(
            palette: palette,
            workoutName: _cleanedName(detail.workout.name),
            workoutDate: detail.workout.startedAt.toLocal(),
            isActive: detail.workout.isActive,
            duration: _duration,
            completedSets: _completedSets,
            totalSets: _totalSets,
            totalVolumeKg: _totalVolumeKg,
            totalDistanceKm: _totalDistanceKm,
          ),
        ),
        if (detail.workout.notes != null &&
            detail.workout.notes!.trim().isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _NotesCard(
                palette: palette,
                notes: detail.workout.notes!,
              ),
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
        if (detail.exercises.isEmpty)
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
              itemCount: detail.exercises.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _DetailExerciseCard(
                detail: detail.exercises[index],
                palette: palette,
              ),
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

class _Hero extends StatelessWidget {
  const _Hero({
    required this.palette,
    required this.workoutName,
    required this.workoutDate,
    required this.isActive,
    required this.duration,
    required this.completedSets,
    required this.totalSets,
    required this.totalVolumeKg,
    required this.totalDistanceKm,
  });

  final JellyBeanPalette palette;
  final String? workoutName;
  final DateTime workoutDate;
  final bool isActive;
  final Duration duration;
  final int completedSets;
  final int totalSets;
  final double totalVolumeKg;
  final double totalDistanceKm;

  String _formatKg(double value) {
    if (value <= 0) return '0';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  String _formatKm(double value) {
    if (value <= 0) return '0';
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
  }

  String _formatDate(DateTime d) {
    const List<String> weekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const List<String> months = <String>[
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
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double topPadding = MediaQuery.paddingOf(context).top;
    final bool hasCardio = totalDistanceKm > 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.shade950, palette.shade800, palette.shade500],
          stops: const <double>[0.0, 0.55, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
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
            _formatDate(workoutDate),
            style: (workoutName != null
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
                  value: '${_formatKg(totalVolumeKg)} kg',
                  label: 'Volume',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeroStat(
                  palette: palette,
                  value:
                      hasCardio ? '${_formatKm(totalDistanceKm)} km' : '—',
                  label: 'Distance',
                ),
              ),
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

class _DetailExerciseCard extends StatelessWidget {
  const _DetailExerciseCard({required this.detail, required this.palette});

  final WorkoutExerciseDetail detail;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int completed = detail.sets.where((s) => s.completed).length;

    return Container(
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
              ExerciseAvatar(exercise: detail.exercise, size: 40),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      detail.exercise.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: palette.shade950,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    ExerciseTypeBadge(type: detail.exercise.type),
                  ],
                ),
              ),
              Text(
                '$completed / ${detail.sets.length}',
                style: TextStyle(
                  color: palette.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (detail.sets.isEmpty)
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
            for (final WorkoutSet set in detail.sets)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _SetLine(
                  set: set,
                  type: detail.exercise.type,
                  palette: palette,
                ),
              ),
          ],
        ],
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
    return Opacity(
      opacity: completed ? 1.0 : 0.55,
      child: Row(
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
          if (!completed)
            Text(
              'skipped',
              style: TextStyle(
                color: palette.shade700.withValues(alpha: 0.6),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
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
