import 'dart:async';

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
import '../../../data/models/workout_set.dart';
import '../../../data/models/workout_template.dart';
import '../../../data/repositories/repository_exceptions.dart';
import '../../exercises/presentation/widgets/exercise_avatar.dart';
import '../../exercises/presentation/widgets/exercise_muscle_group_badge.dart';
import '../../exercises/presentation/widgets/exercise_type_badge.dart';
import '../../templates/application/template_editor_controller.dart';
import '../../templates/application/template_providers.dart';
import '../application/active_workout_provider.dart';
import '../application/workout_session_controller.dart';
import '../application/workout_stats_provider.dart';
import 'widgets/add_exercise_sheet.dart';
import 'widgets/set_row.dart';

/// Centerpiece of Phase W4 — the live workout screen. Watches
/// [activeWorkoutDetailProvider] and exposes mutation flows (add exercise,
/// add/update set, finish, cancel) through
/// [workoutSessionControllerProvider].
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  bool _starting = false;

  Future<void> _handleAddExercise(String workoutId) async {
    final Exercise? picked = await showAddExerciseSheet(context);
    if (picked == null || !mounted) return;
    try {
      await ref
          .read(workoutSessionControllerProvider.notifier)
          .addExercise(workoutId: workoutId, exerciseId: picked.id);
    } catch (error) {
      if (!mounted) return;
      _showError('Could not add exercise: $error');
    }
  }

  Future<void> _handleStart() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final WorkoutDetail? existing = await ref.read(
        activeWorkoutDetailProvider.future,
      );
      if (existing != null) {
        return;
      }
      await ref
          .read(workoutSessionControllerProvider.notifier)
          .startEmptyWorkout();
    } catch (error) {
      if (!mounted) return;
      _showError('Could not start workout: $error');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _handleStartFromTemplate() async {
    if (_starting) return;
    final WorkoutTemplate? picked = await showModalBottomSheet<WorkoutTemplate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TemplatePickerSheet(),
    );
    if (picked == null || !mounted) return;

    setState(() => _starting = true);
    try {
      await ref
          .read(templateEditorControllerProvider.notifier)
          .startWorkoutFromTemplate(picked.id);
    } on ActiveWorkoutAlreadyExistsException {
      if (!mounted) return;
      _showError(
        'You already have an active workout — finish or cancel it first.',
      );
    } catch (error) {
      if (!mounted) return;
      _showError('Could not start: ${_humanError(error)}');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _handleAddSet(String workoutExerciseId) async {
    try {
      await ref
          .read(workoutSessionControllerProvider.notifier)
          .addSet(workoutExerciseId);
    } catch (error) {
      if (!mounted) return;
      _showError('Could not add set: $error');
    }
  }

  Future<void> _handleRemoveSet(String workoutSetId) async {
    try {
      await ref
          .read(workoutSessionControllerProvider.notifier)
          .removeSet(workoutSetId);
    } catch (error) {
      if (!mounted) return;
      _showError(_humanError(error));
    }
  }

  Future<void> _handleUpdateSet({
    required String workoutSetId,
    required double? weightKg,
    required int? reps,
    required double? distanceKm,
    required int? durationSeconds,
    required bool completed,
  }) async {
    try {
      await ref
          .read(workoutSessionControllerProvider.notifier)
          .updateSet(
            workoutSetId: workoutSetId,
            weightKg: weightKg,
            reps: reps,
            distanceKm: distanceKm,
            durationSeconds: durationSeconds,
            completed: completed,
          );
    } catch (error) {
      if (!mounted) return;
      _showError(_humanError(error));
    }
  }

  Future<void> _handleFinish(WorkoutDetail detail) async {
    final bool confirmed = await _confirmFinish(detail);
    if (!confirmed || !mounted) return;
    try {
      final Workout finished = await ref
          .read(workoutSessionControllerProvider.notifier)
          .finishWorkout(detail.workout.id);
      if (!mounted) return;
      context.go('/workouts/summary/${finished.id}');
    } catch (error) {
      if (!mounted) return;
      _showError(_humanError(error));
    }
  }

  Future<void> _handleCancel(WorkoutDetail detail) async {
    final bool confirmed = await _confirmCancel();
    if (!confirmed || !mounted) return;
    try {
      await ref
          .read(workoutSessionControllerProvider.notifier)
          .cancelWorkout(detail.workout.id);
      if (!mounted) return;
      context.go('/workouts');
    } catch (error) {
      if (!mounted) return;
      _showError(_humanError(error));
    }
  }

  Future<bool> _confirmFinish(WorkoutDetail detail) async {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final int completedSets = detail.exercises
        .expand((e) => e.sets)
        .where((s) => s.completed)
        .length;
    final int totalSets = detail.exercises.fold<int>(
      0,
      (sum, e) => sum + e.sets.length,
    );
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Finish workout?',
          style: TextStyle(
            color: palette.shade950,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          totalSets == 0
              ? 'You have not logged any sets yet.'
              : '$completedSets of $totalSets sets are marked complete. '
                    'Incomplete sets will not be saved.',
          style: TextStyle(color: palette.shade800, height: 1.45),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.shade900,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _confirmCancel() async {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel workout?',
          style: TextStyle(
            color: palette.shade950,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'This discards the session and every set you logged. This cannot '
          'be undone.',
          style: TextStyle(color: palette.shade800, height: 1.45),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep workout'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent.shade200,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  String _humanError(Object error) {
    final String raw = error.toString();
    return raw.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final AsyncValue<WorkoutDetail?> detailAsync = ref.watch(
      activeWorkoutDetailProvider,
    );
    final Map<String, List<WorkoutSet>> previousSetsByExerciseId = ref
            .watch(activeWorkoutPreviousSetsProvider)
            .asData
            ?.value ??
        const <String, List<WorkoutSet>>{};

    return Scaffold(
      backgroundColor: palette.shade50,
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return _NoActiveWorkout(
              palette: palette,
              busy: _starting,
              onQuickStart: _handleStart,
              onStartFromTemplate: _handleStartFromTemplate,
            );
          }
          return _WorkoutBody(
            detail: detail,
            palette: palette,
            previousSetsByExerciseId: previousSetsByExerciseId,
            onAddExercise: () => _handleAddExercise(detail.workout.id),
            onAddSet: _handleAddSet,
            onUpdateSet: _handleUpdateSet,
            onRemoveSet: _handleRemoveSet,
            onFinish: () => _handleFinish(detail),
            onCancel: () => _handleCancel(detail),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Could not load workout: $err'),
          ),
        ),
      ),
    );
  }
}

class _NoActiveWorkout extends ConsumerWidget {
  const _NoActiveWorkout({
    required this.palette,
    required this.busy,
    required this.onQuickStart,
    required this.onStartFromTemplate,
  });

  final JellyBeanPalette palette;
  final bool busy;
  final VoidCallback onQuickStart;
  final VoidCallback onStartFromTemplate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<WorkoutPeriodStats> monthlyStats = ref.watch(
      monthlyWorkoutStatsProvider,
    );

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(child: _ReadyToMoveHeader(palette: palette)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _PrimaryStartButton(
                  palette: palette,
                  busy: busy,
                  onTap: onQuickStart,
                ),
                const SizedBox(height: AppSpacing.sm),
                _SecondaryStartButton(
                  palette: palette,
                  busy: busy,
                  onTap: onStartFromTemplate,
                ),
              ],
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
            child: _MonthlyKpiSection(
              palette: palette,
              stats: monthlyStats.asData?.value ?? WorkoutPeriodStats.empty,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadyToMoveHeader extends StatelessWidget {
  const _ReadyToMoveHeader({required this.palette});

  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.shade950, palette.shade800, palette.shade600],
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
              Container(width: 2, height: 14, color: palette.shade300),
              const SizedBox(width: 8),
              Text(
                'READY TO MOVE',
                style: TextStyle(
                  color: palette.shade200,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Workouts',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fire up a quick session or pull up one of your saved templates.',
            style: TextStyle(
              color: palette.shade100.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryStartButton extends StatelessWidget {
  const _PrimaryStartButton({
    required this.palette,
    required this.busy,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: FilledButton(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: palette.shade900,
          disabledBackgroundColor: palette.shade300,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  Icon(Icons.bolt_rounded, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Quick start',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SecondaryStartButton extends StatelessWidget {
  const _SecondaryStartButton({
    required this.palette,
    required this.busy,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.shade950,
          side: BorderSide(color: palette.shade200, width: 1.2),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.auto_awesome_rounded, color: palette.shade800, size: 20),
            const SizedBox(width: 8),
            Text(
              'Start from template',
              style: TextStyle(
                color: palette.shade950,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyKpiSection extends StatelessWidget {
  const _MonthlyKpiSection({required this.palette, required this.stats});

  final JellyBeanPalette palette;
  final WorkoutPeriodStats stats;

  static const List<String> _monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _formatDuration(Duration d) {
    final int totalMinutes = d.inMinutes;
    if (totalMinutes <= 0) return '0m';
    final int h = totalMinutes ~/ 60;
    final int m = totalMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final String monthLabel = _monthNames[DateTime.now().month - 1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            'This Month · $monthLabel',
            style: TextStyle(
              color: palette.shade950,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: _KpiCard(
                palette: palette,
                label: 'WORKOUTS',
                value: '${stats.count}',
                icon: Icons.calendar_today_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _KpiCard(
                palette: palette,
                label: 'DURATION',
                value: _formatDuration(stats.totalDuration),
                icon: Icons.access_time_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.palette,
    required this.label,
    required this.value,
    required this.icon,
  });

  final JellyBeanPalette palette;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(22);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: palette.shade100.withValues(alpha: 0.55),
          borderRadius: radius,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Decorative icon that bleeds into the bottom-right rounded
            // corner. The outer ClipRRect trims the overflow so the glyph
            // looks flush with the container's edge.
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 80,
                color: palette.shade300.withValues(alpha: 0.55),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: TextStyle(
                      color: palette.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      color: palette.shade950,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
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

/// Bottom-sheet list of saved templates for the "Start from template" action.
class _TemplatePickerSheet extends ConsumerWidget {
  const _TemplatePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final AsyncValue<List<WorkoutTemplate>> templates = ref.watch(
      templateListProvider,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: palette.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Pick a template',
                style: TextStyle(
                  color: palette.shade950,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Starts a new workout pre-loaded with that template\'s exercises.',
                style: TextStyle(
                  color: palette.shade700.withValues(alpha: 0.8),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: templates.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return _EmptyTemplates(palette: palette);
                    }
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final WorkoutTemplate t = items[index];
                        return _TemplatePickerTile(
                          palette: palette,
                          template: t,
                          onTap: () => Navigator.of(context).pop(t),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text(
                      'Could not load templates: $err',
                      style: TextStyle(color: palette.shade800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TemplatePickerTile extends StatelessWidget {
  const _TemplatePickerTile({
    required this.palette,
    required this.template,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final WorkoutTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.shade100),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: palette.shade800,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  template.name,
                  style: TextStyle(
                    color: palette.shade950,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.shade600,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTemplates extends StatelessWidget {
  const _EmptyTemplates({required this.palette});

  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.auto_awesome_outlined, size: 40, color: palette.shade400),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No templates yet',
            style: TextStyle(
              color: palette.shade950,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create one from the Templates tab to start here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.shade800.withValues(alpha: 0.75),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutBody extends StatelessWidget {
  const _WorkoutBody({
    required this.detail,
    required this.palette,
    required this.previousSetsByExerciseId,
    required this.onAddExercise,
    required this.onAddSet,
    required this.onUpdateSet,
    required this.onRemoveSet,
    required this.onFinish,
    required this.onCancel,
  });

  final WorkoutDetail detail;
  final JellyBeanPalette palette;
  final Map<String, List<WorkoutSet>> previousSetsByExerciseId;
  final VoidCallback onAddExercise;
  final Future<void> Function(String workoutExerciseId) onAddSet;
  final Future<void> Function({
    required String workoutSetId,
    required double? weightKg,
    required int? reps,
    required double? distanceKm,
    required int? durationSeconds,
    required bool completed,
  })
  onUpdateSet;
  final Future<void> Function(String workoutSetId) onRemoveSet;
  final VoidCallback onFinish;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final int totalSets = detail.exercises.fold<int>(
      0,
      (sum, e) => sum + e.sets.length,
    );
    final int completedSets = detail.exercises
        .expand((e) => e.sets)
        .where((s) => s.completed)
        .length;

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: _Header(
            palette: palette,
            startedAt: detail.workout.startedAt,
            totalSets: totalSets,
            completedSets: completedSets,
            exerciseCount: detail.exercises.length,
            onCancel: onCancel,
          ),
        ),
        if (detail.exercises.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyExercises(
              palette: palette,
              onAddExercise: onAddExercise,
            ),
          )
        else ...<Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverList.separated(
              itemCount: detail.exercises.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final WorkoutExerciseDetail exerciseDetail =
                    detail.exercises[index];
                return _ExerciseCard(
                  detail: exerciseDetail,
                  palette: palette,
                  previousSets:
                      previousSetsByExerciseId[exerciseDetail.exercise.id] ??
                      const <WorkoutSet>[],
                  onAddSet: () => onAddSet(exerciseDetail.workoutExercise.id),
                  onUpdateSet: onUpdateSet,
                  onRemoveSet: onRemoveSet,
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: _AddExerciseButton(palette: palette, onTap: onAddExercise),
            ),
          ),
        ],
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: _FinishButton(
              palette: palette,
              enabled: completedSets > 0,
              onTap: onFinish,
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.palette,
    required this.startedAt,
    required this.totalSets,
    required this.completedSets,
    required this.exerciseCount,
    required this.onCancel,
  });

  final JellyBeanPalette palette;
  final DateTime startedAt;
  final int totalSets;
  final int completedSets;
  final int exerciseCount;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.shade950, palette.shade800, palette.shade600],
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
              _GlassPill(
                palette: palette,
                icon: Icons.bolt_rounded,
                label: 'WORKOUT IN PROGRESS',
              ),
              const Spacer(),
              InkWell(
                onTap: onCancel,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: palette.shade100,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Cancel',
                        style: TextStyle(
                          color: palette.shade100,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _ElapsedTimeText(
            startedAt: startedAt,
            textStyle: theme.textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.8,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Elapsed time',
            style: theme.textTheme.displayMedium?.copyWith(
              color: palette.shade200.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: _Stat(
                  palette: palette,
                  value: '$exerciseCount',
                  label: exerciseCount == 1 ? 'Exercise' : 'Exercises',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Stat(
                  palette: palette,
                  value: '$completedSets / $totalSets',
                  label: 'Sets done',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ElapsedTimeText extends StatefulWidget {
  const _ElapsedTimeText({required this.startedAt, required this.textStyle});

  final DateTime startedAt;
  final TextStyle? textStyle;

  @override
  State<_ElapsedTimeText> createState() => _ElapsedTimeTextState();
}

class _ElapsedTimeTextState extends State<_ElapsedTimeText> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker(TickerMode.of(context));
  }

  @override
  void didUpdateWidget(covariant _ElapsedTimeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startedAt != widget.startedAt && mounted) {
      setState(() => _now = DateTime.now());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker(bool enabled) {
    if (!enabled) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    if (_ticker != null) {
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Duration elapsed = _now.difference(widget.startedAt);
    return Text(DurationFormatter.elapsed(elapsed), style: widget.textStyle);
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.palette,
    required this.icon,
    required this.label,
  });

  final JellyBeanPalette palette;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: palette.shade200),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: palette.shade100,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
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
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: palette.shade200.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExercises extends StatelessWidget {
  const _EmptyExercises({required this.palette, required this.onAddExercise});

  final JellyBeanPalette palette;
  final VoidCallback onAddExercise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: AppSpacing.xl),
          Icon(Icons.fitness_center_rounded, size: 40, color: palette.shade400),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No exercises yet',
            style: TextStyle(
              color: palette.shade950,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add one to start logging sets.',
            style: TextStyle(
              color: palette.shade800.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _AddExerciseButton(palette: palette, onTap: onAddExercise),
        ],
      ),
    );
  }
}

String _formatPreviousSetSummary(WorkoutSet? set, ExerciseType type) {
  // Only completed sets contribute to "previous"; in-progress / abandoned
  // sets shouldn't surface as a target the user is trying to match.
  if (set == null || !set.completed) return '-';
  switch (type) {
    case ExerciseType.weighted:
      return '${_formatNum(set.weightKg ?? 0)} kg · ${set.reps ?? 0} reps';
    case ExerciseType.bodyweight:
      return '${set.reps ?? 0} reps';
    case ExerciseType.cardio:
      final String time = DurationFormatter.formatSeconds(
        set.durationSeconds ?? 0,
      );
      return '${_formatNum(set.distanceKm ?? 0)} km · $time';
  }
}

String _formatNum(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.detail,
    required this.palette,
    required this.previousSets,
    required this.onAddSet,
    required this.onUpdateSet,
    required this.onRemoveSet,
  });

  final WorkoutExerciseDetail detail;
  final JellyBeanPalette palette;
  final List<WorkoutSet> previousSets;
  final VoidCallback onAddSet;
  final Future<void> Function({
    required String workoutSetId,
    required double? weightKg,
    required int? reps,
    required double? distanceKm,
    required int? durationSeconds,
    required bool completed,
  })
  onUpdateSet;
  final Future<void> Function(String workoutSetId) onRemoveSet;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.shade100),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ExerciseAvatar(exercise: detail.exercise, size: 42),
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
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _SetTableHeader(type: detail.exercise.type, palette: palette),
          const SizedBox(height: 2),
          if (detail.sets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No sets yet — add your first below.',
                style: TextStyle(
                  color: palette.shade700.withValues(alpha: 0.7),
                  fontSize: 12.5,
                ),
              ),
            )
          else
            for (int i = 0; i < detail.sets.length; i++)
              Builder(
                key: ValueKey<String>('dismiss-${detail.sets[i].id}'),
                builder: (BuildContext context) {
                  final WorkoutSet set = detail.sets[i];
                  final bool prevCompleted =
                      i > 0 && detail.sets[i - 1].completed;
                  final bool nextCompleted =
                      i < detail.sets.length - 1 &&
                      detail.sets[i + 1].completed;
                  final WorkoutSet? previousSet = previousSets
                      .where((s) => s.setNumber == set.setNumber)
                      .firstOrNull;
                  return Dismissible(
                    key: ValueKey<String>('dismiss-${set.id}'),
                    direction: DismissDirection.startToEnd,
                    dismissThresholds: const <DismissDirection, double>{
                      DismissDirection.startToEnd: 0.35,
                    },
                    background: const _SwipeDeleteBackground(),
                    onDismissed: (_) => onRemoveSet(set.id),
                    child: SetRow(
                      key: ValueKey<String>(set.id),
                      set: set,
                      exerciseType: detail.exercise.type,
                      previousSummary: _formatPreviousSetSummary(
                        previousSet,
                        detail.exercise.type,
                      ),
                      roundTop: !prevCompleted,
                      roundBottom: !nextCompleted,
                      onCommit:
                          ({
                            required bool completed,
                            double? distanceKm,
                            int? durationSeconds,
                            int? reps,
                            double? weightKg,
                          }) {
                            return onUpdateSet(
                              workoutSetId: set.id,
                              weightKg: weightKg,
                              reps: reps,
                              distanceKm: distanceKm,
                              durationSeconds: durationSeconds,
                              completed: completed,
                            );
                          },
                    ),
                  );
                },
              ),
          const SizedBox(height: AppSpacing.xs),
          _AddSetButton(palette: palette, onTap: onAddSet),
        ],
      ),
    );
  }
}

class _SetTableHeader extends StatelessWidget {
  const _SetTableHeader({required this.type, required this.palette});

  final ExerciseType type;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    final TextStyle headerStyle = TextStyle(
      color: palette.shade700,
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.0,
    );

    final List<Widget> valueHeaders = switch (type) {
      ExerciseType.weighted => <Widget>[
        Expanded(
          flex: 2,
          child: Text('KG', textAlign: TextAlign.center, style: headerStyle),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: Text('REPS', textAlign: TextAlign.center, style: headerStyle),
        ),
      ],
      ExerciseType.bodyweight => <Widget>[
        Expanded(
          flex: 4,
          child: Text('REPS', textAlign: TextAlign.center, style: headerStyle),
        ),
      ],
      ExerciseType.cardio => <Widget>[
        Expanded(
          flex: 2,
          child: Text('KM', textAlign: TextAlign.center, style: headerStyle),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: Text('TIME', textAlign: TextAlign.center, style: headerStyle),
        ),
      ],
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 30,
            child: Text('#', textAlign: TextAlign.center, style: headerStyle),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              'PREVIOUS',
              textAlign: TextAlign.center,
              style: headerStyle,
            ),
          ),
          const SizedBox(width: 8),
          ...valueHeaders,
          const SizedBox(width: 8),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

class _AddSetButton extends StatelessWidget {
  const _AddSetButton({required this.palette, required this.onTap});

  final JellyBeanPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: palette.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.add_rounded, size: 18, color: palette.shade800),
            const SizedBox(width: 6),
            Text(
              'Add set',
              style: TextStyle(
                color: palette.shade800,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddExerciseButton extends StatelessWidget {
  const _AddExerciseButton({required this.palette, required this.onTap});

  final JellyBeanPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.shade200, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.add_circle_outline_rounded, color: palette.shade900),
            const SizedBox(width: 8),
            Text(
              'Add exercise',
              style: TextStyle(
                color: palette.shade950,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.redAccent.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const <Widget>[
          Icon(Icons.delete_rounded, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Text(
            'Delete set',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishButton extends StatelessWidget {
  const _FinishButton({
    required this.palette,
    required this.enabled,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: palette.shade900,
          // Cool-tinted neutral grey when disabled — keeps the surface clearly
          // inactive instead of reading as a muted "active" blue.
          disabledBackgroundColor: const Color(0xFFE2E6E8),
          disabledForegroundColor: const Color(0xFF8A969C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.check_rounded, size: 22),
            const SizedBox(width: 8),
            Text(
              enabled ? 'Finish workout' : 'Complete a set to finish',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
