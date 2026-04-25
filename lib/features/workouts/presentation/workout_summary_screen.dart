import 'dart:async';

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
import '../../exercises/presentation/widgets/exercise_muscle_group_badge.dart';
import '../../exercises/presentation/widgets/exercise_type_badge.dart';
import '../../history/application/history_providers.dart';
import '../application/workout_session_controller.dart';

/// Shown after a workout is finished. Streams the workout via
/// [workoutDetailProvider] so name edits reflect immediately, and lets the
/// user give the session a custom name that surfaces in history.
class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  const WorkoutSummaryScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  Timer? _saveDebounce;
  String? _lastSavedName;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _nameFocus.removeListener(_onFocusChange);
    _nameFocus.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_nameFocus.hasFocus) {
      _flushSave();
    }
  }

  void _seedIfNeeded(String? serverName) {
    if (_seeded) return;
    _seeded = true;
    _nameController.text = serverName ?? '';
    _lastSavedName = serverName;
  }

  void _onNameChanged(String _) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), _flushSave);
  }

  Future<void> _flushSave() async {
    _saveDebounce?.cancel();
    final String trimmed = _nameController.text.trim();
    final String? normalized = trimmed.isEmpty ? null : trimmed;
    if (normalized == _lastSavedName) return;
    _lastSavedName = normalized;
    try {
      await ref
          .read(workoutSessionControllerProvider.notifier)
          .updateWorkoutName(workoutId: widget.workoutId, name: normalized);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save name: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final AsyncValue<WorkoutDetail> detailAsync = ref.watch(
      workoutDetailProvider(widget.workoutId),
    );

    return Scaffold(
      backgroundColor: palette.shade50,
      body: detailAsync.when(
        data: (detail) {
          _seedIfNeeded(detail.workout.name);
          return _SummaryBody(
            detail: detail,
            palette: palette,
            nameController: _nameController,
            nameFocus: _nameFocus,
            onNameChanged: _onNameChanged,
            onSubmitted: _flushSave,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Could not load summary: $err'),
          ),
        ),
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({
    required this.detail,
    required this.palette,
    required this.nameController,
    required this.nameFocus,
    required this.onNameChanged,
    required this.onSubmitted,
  });

  final WorkoutDetail detail;
  final JellyBeanPalette palette;
  final TextEditingController nameController;
  final FocusNode nameFocus;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onSubmitted;

  Duration get _duration {
    final DateTime end = detail.workout.endedAt ?? DateTime.now();
    return end.difference(detail.workout.startedAt);
  }

  int get _completedSets {
    return detail.exercises
        .expand<WorkoutSet>((e) => e.sets)
        .where((s) => s.completed)
        .length;
  }

  int get _totalSets {
    return detail.exercises.fold<int>(0, (sum, e) => sum + e.sets.length);
  }

  double get _totalVolumeKg {
    double total = 0;
    for (final WorkoutExerciseDetail e in detail.exercises) {
      if (e.exercise.type != ExerciseType.weighted) continue;
      for (final WorkoutSet s in e.sets) {
        if (!s.completed) continue;
        final double w = s.weightKg ?? 0;
        final int r = s.reps ?? 0;
        total += w * r;
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

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: _Hero(
            palette: palette,
            duration: _duration,
            completedSets: _completedSets,
            totalSets: _totalSets,
            totalVolumeKg: _totalVolumeKg,
            totalDistanceKm: _totalDistanceKm,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: _NameInputCard(
              palette: palette,
              controller: nameController,
              focusNode: nameFocus,
              onChanged: onNameChanged,
              onSubmitted: onSubmitted,
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
              AppSpacing.lg,
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
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _SummaryExerciseCard(
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
            child: _DoneButton(
              palette: palette,
              onTap: () {
                onSubmitted();
                context.go('/workouts');
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
    required this.duration,
    required this.completedSets,
    required this.totalSets,
    required this.totalVolumeKg,
    required this.totalDistanceKm,
  });

  final JellyBeanPalette palette;
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
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
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
                      Icons.check_circle_rounded,
                      size: 14,
                      color: palette.shade100,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'WORKOUT COMPLETE',
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
          Text(
            'Nice work.',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Here is how the session shook out.',
            style: TextStyle(
              color: palette.shade100.withValues(alpha: 0.85),
              fontSize: 13.5,
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
                  value: hasCardio ? '${_formatKm(totalDistanceKm)} km' : '—',
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

class _SummaryExerciseCard extends StatelessWidget {
  const _SummaryExerciseCard({required this.detail, required this.palette});

  final WorkoutExerciseDetail detail;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<WorkoutSet> completed = detail.sets
        .where((s) => s.completed)
        .toList(growable: false);

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
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        ExerciseTypeBadge(type: detail.exercise.type),
                        ExerciseMuscleGroupBadge(
                          muscleGroup: detail.exercise.muscleGroup,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${completed.length} / ${detail.sets.length}',
                style: TextStyle(
                  color: palette.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (completed.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'No completed sets.',
                style: TextStyle(
                  color: palette.shade700.withValues(alpha: 0.7),
                  fontSize: 12.5,
                ),
              ),
            )
          else ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            for (final WorkoutSet set in completed)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _SummarySetLine(
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

class _SummarySetLine extends StatelessWidget {
  const _SummarySetLine({
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
    return Row(
      children: <Widget>[
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.shade100,
            borderRadius: BorderRadius.circular(8),
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
      ],
    );
  }
}

class _NameInputCard extends StatelessWidget {
  const _NameInputCard({
    required this.palette,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  final JellyBeanPalette palette;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => focusNode.requestFocus(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.shade100),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.label_outline_rounded,
                color: palette.shade800,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'NAME THIS WORKOUT',
                    style: TextStyle(
                      color: palette.shade700,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    maxLength: 60,
                    textInputAction: TextInputAction.done,
                    onChanged: onChanged,
                    onSubmitted: (_) => onSubmitted(),
                    style: TextStyle(
                      color: palette.shade950,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      counterText: '',
                      hintText: 'e.g. Leg day — light',
                      hintStyle: TextStyle(
                        color: palette.shade700.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.palette, required this.onTap});

  final JellyBeanPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: palette.shade900,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          'Done',
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
