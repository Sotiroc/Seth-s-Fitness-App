import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_formatter.dart';
import 'widgets/weekly_volume_strip_bar.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/exercise_type.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/workout_detail.dart';
import '../../../data/models/workout_set.dart';
import '../../../data/models/workout_set_kind.dart';
import '../../../data/models/workout_template.dart';
import '../../../data/repositories/app_settings_repository.dart';
import '../../../data/repositories/repository_exceptions.dart';
import '../../exercises/presentation/widgets/exercise_avatar.dart';
import '../../exercises/presentation/widgets/exercise_history_sheet.dart';
import '../../exercises/presentation/widgets/exercise_thumbnail_editor.dart';
import '../../home/presentation/widgets/menu_icon_button.dart';
import '../../templates/application/template_editor_controller.dart';
import '../../templates/application/template_providers.dart';
import '../application/active_workout_provider.dart';
import '../application/rest_timer_controller.dart';
import '../application/workout_session_controller.dart';
import '../application/workout_stats_provider.dart';
import 'widgets/add_exercise_sheet.dart';
import 'widgets/rest_timer_sheet.dart';
import 'widgets/set_details_sheet.dart';
import 'widgets/set_kind_visuals.dart';
import 'widgets/set_ordering.dart';
import 'widgets/set_row.dart';
import 'widgets/set_type_menu.dart';
import 'widgets/workout_recovery_banner.dart';

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

  Future<void> _handleRemoveExercise({
    required String workoutExerciseId,
    required String exerciseName,
  }) async {
    final bool confirmed = await _confirmRemoveExercise(exerciseName);
    if (!confirmed || !mounted) return;
    try {
      await ref
          .read(workoutSessionControllerProvider.notifier)
          .removeExercise(workoutExerciseId);
    } catch (error) {
      if (!mounted) return;
      _showError(_humanError(error));
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

  Future<void> _handleAddDropSet({
    required String workoutExerciseId,
    required String parentSetId,
  }) async {
    try {
      await ref
          .read(workoutSessionControllerProvider.notifier)
          .addSet(
            workoutExerciseId,
            kind: WorkoutSetKind.drop,
            parentSetId: parentSetId,
          );
    } catch (error) {
      if (!mounted) return;
      _showError('Could not add drop set: ${_humanError(error)}');
    }
  }

  /// Routed from the set-number badge. The exact UI depends on whether
  /// the set is already completed:
  ///
  /// - **Incomplete set** → quick popup menu anchored to the badge for
  ///   labelling the set as Normal / Warm-up / Drop / Failure before the
  ///   work is done. Cheap, fast, no full sheet.
  /// - **Completed set** → richer bottom sheet for capturing post-set
  ///   context (1–10 RPE and a free-text note). Type isn't editable
  ///   here — that's a pre-completion concern.
  ///
  /// Switching to Drop requires a working set above to attach to; the
  /// menu disables that entry when no parent candidate exists, but we
  /// still defend with [_suggestDropParent] in case the menu was tapped
  /// during a stale frame.
  Future<void> _handleTapSetNumber({
    required WorkoutSet set,
    required bool canBeDrop,
    required BuildContext anchorContext,
  }) async {
    if (set.completed) {
      await _openSetDetailsSheet(set);
    } else {
      await _openSetTypeMenu(
        set: set,
        canBeDrop: canBeDrop,
        anchorContext: anchorContext,
      );
    }
  }

  Future<void> _openSetTypeMenu({
    required WorkoutSet set,
    required bool canBeDrop,
    required BuildContext anchorContext,
  }) async {
    final WorkoutSetKind? picked = await showSetTypeMenu(
      anchorContext: anchorContext,
      set: set,
      canBeDrop: canBeDrop,
    );
    if (picked == null || picked == set.kind || !mounted) return;

    String? parentSetId;
    if (picked == WorkoutSetKind.drop) {
      parentSetId = set.parentSetId ?? _suggestDropParent(set);
      if (parentSetId == null) {
        _showError('No working set above this one to drop from.');
        return;
      }
    }
    try {
      await ref
          .read(workoutSessionControllerProvider.notifier)
          .updateSetExtras(
            workoutSetId: set.id,
            kind: picked,
            // Preserve the existing RPE/note — the menu only changes kind.
            rpe: set.rpe,
            note: set.note,
            parentSetId: parentSetId,
          );
    } catch (error) {
      if (!mounted) return;
      _showError(_humanError(error));
    }
  }

  Future<void> _openSetDetailsSheet(WorkoutSet set) async {
    final SetDetailsSheetResult? result =
        await showSetDetailsSheet(context, set: set);
    if (result == null || !mounted) return;
    try {
      await ref
          .read(workoutSessionControllerProvider.notifier)
          .updateSetExtras(
            workoutSetId: set.id,
            // Preserve the existing kind/parent — the sheet only edits
            // post-set context (RPE + note).
            kind: set.kind,
            rpe: result.rpe,
            note: result.note,
            parentSetId: set.parentSetId,
          );
    } catch (error) {
      if (!mounted) return;
      _showError(_humanError(error));
    }
  }

  /// Walks the active workout, finds the set's exercise, and returns the id
  /// of the most-recent working set that precedes it (by setNumber). Used
  /// when promoting a row to "drop" without an existing parent link.
  String? _suggestDropParent(WorkoutSet set) {
    final WorkoutDetail? detail =
        ref.read(activeWorkoutDetailProvider).asData?.value;
    if (detail == null) return null;
    WorkoutExerciseDetail? owner;
    for (final WorkoutExerciseDetail e in detail.exercises) {
      if (e.workoutExercise.id == set.workoutExerciseId) {
        owner = e;
        break;
      }
    }
    if (owner == null) return null;
    WorkoutSet? best;
    for (final WorkoutSet s in owner.sets) {
      if (s.id == set.id) continue;
      if (s.kind != WorkoutSetKind.normal &&
          s.kind != WorkoutSetKind.failure) {
        continue;
      }
      if (s.setNumber >= set.setNumber) continue;
      if (best == null || s.setNumber > best.setNumber) {
        best = s;
      }
    }
    return best?.id;
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

  Future<bool> _confirmRemoveExercise(String exerciseName) async {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove exercise?',
          style: TextStyle(
            color: palette.shade950,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'This removes "$exerciseName" and any sets you logged for it from '
          'this workout.',
          style: TextStyle(color: palette.shade800, height: 1.45),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
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
    final Map<String, List<WorkoutSet>> previousSetsByExerciseId =
        ref.watch(activeWorkoutPreviousSetsProvider).asData?.value ??
        const <String, List<WorkoutSet>>{};

    // Drop the rest-timer overlay when the active workout disappears
    // (finished, cancelled, or auto-closed) or when the workoutExercise
    // the timer belongs to is removed mid-rest.
    ref.listen<AsyncValue<WorkoutDetail?>>(activeWorkoutDetailProvider, (
      _,
      next,
    ) {
      final WorkoutDetail? data = next.asData?.value;
      final RestTimerState rt = ref.read(restTimerControllerProvider);
      if (!rt.isActive) return;
      if (data == null) {
        ref.read(restTimerControllerProvider.notifier).clear();
        return;
      }
      final bool stillThere = data.exercises.any(
        (e) => e.workoutExercise.id == rt.workoutExerciseId,
      );
      if (!stillThere) {
        ref.read(restTimerControllerProvider.notifier).clear();
      }
    });

    return Scaffold(
      backgroundColor: palette.shade50,
      drawerEnableOpenDragGesture: false,
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
            onAddDropSet: _handleAddDropSet,
            onUpdateSet: _handleUpdateSet,
            onRemoveSet: _handleRemoveSet,
            onRemoveExercise: _handleRemoveExercise,
            onTapSetNumber: _handleTapSetNumber,
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
        // Compact weekly-progress strip — same widget the active workout
        // uses, sitting on the light body background just below the dark
        // hero. Tap → bottom sheet with full grid + cog → goal editor.
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverToBoxAdapter(child: WeeklyVolumeStripBar()),
        ),
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
              const MenuIconButton(),
              const SizedBox(width: AppSpacing.sm),
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
            'Stronger than last time.',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your training, written down.',
            style: TextStyle(
              color: palette.shade100.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
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

class _WorkoutBody extends ConsumerWidget {
  const _WorkoutBody({
    required this.detail,
    required this.palette,
    required this.previousSetsByExerciseId,
    required this.onAddExercise,
    required this.onAddSet,
    required this.onAddDropSet,
    required this.onUpdateSet,
    required this.onRemoveSet,
    required this.onRemoveExercise,
    required this.onTapSetNumber,
    required this.onFinish,
    required this.onCancel,
  });

  final WorkoutDetail detail;
  final JellyBeanPalette palette;
  final Map<String, List<WorkoutSet>> previousSetsByExerciseId;
  final VoidCallback onAddExercise;
  final Future<void> Function(String workoutExerciseId) onAddSet;
  final Future<void> Function({
    required String workoutExerciseId,
    required String parentSetId,
  })
  onAddDropSet;
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
  final Future<void> Function({
    required String workoutExerciseId,
    required String exerciseName,
  })
  onRemoveExercise;
  final Future<void> Function({
    required WorkoutSet set,
    required bool canBeDrop,
    required BuildContext anchorContext,
  })
  onTapSetNumber;
  final VoidCallback onFinish;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Both totals exclude warm-ups so the X/Y counter reflects working
    // sets only — a 6-set session with one warm-up reads "0/5" rather
    // than "0/6" before the user has done anything serious.
    final int totalSets = detail.exercises.fold<int>(
      0,
      (sum, e) => sum + e.sets.where((s) => s.kind.countsAsWorkingSet).length,
    );
    final int completedSets = detail.exercises
        .expand((e) => e.sets)
        .where((s) => s.completed && s.kind.countsAsWorkingSet)
        .length;
    final bool restActive = ref.watch(
      restTimerControllerProvider.select((s) => s.isActive),
    );
    // Reserve room for the rest-timer sheet so the Finish button isn't
    // covered while resting. Number is roughly the sheet's vertical
    // footprint (~220px) trimmed for the existing AppSpacing.xl bottom
    // pad already present on the Finish sliver.
    final double finishExtraBottom = restActive ? 220 : 0;

    return Stack(
      children: <Widget>[
        CustomScrollView(
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
            // Sticks flush against the top of the viewport once the dark
            // hero header scrolls off, so weekly progress is glanceable
            // while the user works through their exercise list.
            SliverPersistentHeader(
              pinned: true,
              delegate: WeeklyVolumeStripHeaderDelegate(palette: palette),
            ),
            // Auto-close-stale-workout recovery banner — only renders when
            // the user picked "Edit / Add" in the recovery dialog.
            const WorkoutRecoveryBannerSliver(),
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
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final WorkoutExerciseDetail exerciseDetail =
                        detail.exercises[index];
                    return _ExerciseCard(
                      detail: exerciseDetail,
                      palette: palette,
                      previousSets:
                          previousSetsByExerciseId[exerciseDetail
                              .exercise
                              .id] ??
                          const <WorkoutSet>[],
                      onAddSet: () =>
                          onAddSet(exerciseDetail.workoutExercise.id),
                      onAddDropSet: (String parentSetId) => onAddDropSet(
                        workoutExerciseId: exerciseDetail.workoutExercise.id,
                        parentSetId: parentSetId,
                      ),
                      onUpdateSet: onUpdateSet,
                      onRemoveSet: onRemoveSet,
                      onRemoveExercise: () => onRemoveExercise(
                        workoutExerciseId: exerciseDetail.workoutExercise.id,
                        exerciseName: exerciseDetail.exercise.name,
                      ),
                      onTapSetNumber: onTapSetNumber,
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
                  child: _AddExerciseButton(
                    palette: palette,
                    onTap: onAddExercise,
                  ),
                ),
              ),
            ],
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                MediaQuery.paddingOf(context).bottom +
                    AppSpacing.xl +
                    finishExtraBottom,
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
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: RestTimerSheet(),
        ),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
              const MenuIconButton(),
              const SizedBox(width: AppSpacing.sm),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: _ElapsedTimeText(
                  startedAt: startedAt,
                  textStyle: theme.textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.8,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              const _RestTimerToggleButton(),
            ],
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

/// Toggle that flips the "show rest timer between sets" preference. Lives
/// next to the elapsed-time readout in the workout header. Filled clock
/// icon when on, outlined when off. Flipping OFF also dismisses any
/// running timer so the sheet doesn't linger after the user changes
/// their mind mid-rest. Long-press opens the Timer settings screen as a
/// fast path to the global default.
class _RestTimerToggleButton extends ConsumerWidget {
  const _RestTimerToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enabled =
        ref.watch(restTimerEnabledProvider).asData?.value ?? true;
    return Semantics(
      label: enabled ? 'Rest timer on' : 'Rest timer off',
      hint: 'Long-press for timer settings',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await ref
              .read(appSettingsRepositoryProvider)
              .setRestTimerEnabled(!enabled);
          if (enabled) {
            ref.read(restTimerControllerProvider.notifier).clear();
          }
        },
        onLongPress: () {
          HapticFeedback.selectionClick();
          context.push('/settings/timer');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: enabled
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: enabled ? 0.32 : 0.16),
            ),
          ),
          child: Icon(
            enabled ? Icons.timer : Icons.timer_outlined,
            size: 20,
            color: Colors.white.withValues(alpha: enabled ? 1.0 : 0.7),
          ),
        ),
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

String _formatPreviousSetSummary(
  WorkoutSet? set,
  ExerciseType type, {
  List<WorkoutSet> allPreviousSets = const <WorkoutSet>[],
}) {
  // Only completed sets contribute to "previous"; in-progress / abandoned
  // sets shouldn't surface as a target the user is trying to match.
  if (set == null || !set.completed) return '-';
  switch (type) {
    case ExerciseType.weighted:
      // Compact `weight × reps` notation (e.g. `18kg × 10`). The cross is
      // universal in lifting contexts, so dropping the "reps" suffix keeps
      // two-digit rep counts from overflowing the narrow PREVIOUS column.
      final String head = '${_formatNum(set.weightKg ?? 0)}kg × ${set.reps ?? 0}';
      // If this previous set was a working set with drop children attached
      // last time, surface the chain so the user can target the same
      // descent today (e.g. `100×8 → 80×6 → 60×4`).
      final String? chain = (set.kind == WorkoutSetKind.normal ||
              set.kind == WorkoutSetKind.failure)
          ? formatDropChainSuffix(parent: set, allPreviousSets: allPreviousSets)
          : null;
      return chain == null ? head : '$head → $chain';
    case ExerciseType.bodyweight:
      return '${set.reps ?? 0} reps';
    case ExerciseType.cardio:
      final String time = DurationFormatter.formatSeconds(
        set.durationSeconds ?? 0,
      );
      return '${_formatNum(set.distanceKm ?? 0)}km · $time';
  }
}

String _formatNum(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}

/// Starts a rest timer when a set has just transitioned to completed,
/// gated by the user-level toggle and the resolved rest duration. The
/// resolution chain is: per-exercise override → user-level default →
/// per-type fallback. A 0-second result (cardio default, or per-exercise
/// "Off") is the no-op signal — we silently skip rather than show a
/// 00:00 sheet.
void _maybeStartRestTimer(WidgetRef ref, WorkoutExerciseDetail detail) {
  final bool enabled =
      ref.read(restTimerEnabledProvider).asData?.value ?? true;
  if (!enabled) return;
  final int? userDefault =
      ref.read(defaultRestSecondsProvider).asData?.value;
  final int seconds =
      detail.exercise.resolveRestSeconds(userDefault: userDefault);
  if (seconds <= 0) return;
  ref.read(restTimerControllerProvider.notifier).start(
    seconds: seconds,
    workoutExerciseId: detail.workoutExercise.id,
    exerciseId: detail.exercise.id,
    exerciseName: detail.exercise.name,
  );
}

/// Dismisses the rest timer if it belongs to the same workout exercise
/// the user just uncompleted. Avoids cancelling a different exercise's
/// running timer.
void _maybeClearRestTimer(WidgetRef ref, String workoutExerciseId) {
  final RestTimerState state = ref.read(restTimerControllerProvider);
  if (state.workoutExerciseId == workoutExerciseId) {
    ref.read(restTimerControllerProvider.notifier).clear();
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    required this.detail,
    required this.palette,
    required this.previousSets,
    required this.onAddSet,
    required this.onAddDropSet,
    required this.onUpdateSet,
    required this.onRemoveSet,
    required this.onRemoveExercise,
    required this.onTapSetNumber,
  });

  final WorkoutExerciseDetail detail;
  final JellyBeanPalette palette;
  final List<WorkoutSet> previousSets;
  final VoidCallback onAddSet;
  final Future<void> Function(String parentSetId) onAddDropSet;
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
  final VoidCallback onRemoveExercise;
  final Future<void> Function({
    required WorkoutSet set,
    required bool canBeDrop,
    required BuildContext anchorContext,
  })
  onTapSetNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    showExerciseThumbnailEditor(context, ref, detail.exercise),
                child: ExerciseAvatar(exercise: detail.exercise, size: 42),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => ExerciseHistorySheet.show(
                        context,
                        exerciseId: detail.exercise.id,
                        // Surface the Edit button so users can change
                        // per-exercise rest (or anything else) without
                        // leaving the workout via the Exercises tab.
                        showEditButton: true,
                      ),
                      child: Text(
                        detail.exercise.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: palette.shade950,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              _RemoveExerciseButton(palette: palette, onTap: onRemoveExercise),
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
            ..._buildSetRows(context, ref),
          const SizedBox(height: AppSpacing.xs),
          _AddSetButton(palette: palette, onTap: onAddSet),
        ],
      ),
    );
  }

  /// Builds the visual list of rows in display order: warm-ups first,
  /// then each working set immediately followed by any drop children.
  /// Inserts a small "Add drop" affordance after every completed working
  /// set (and after the final drop in an existing chain) so the user can
  /// extend or start a chain in one tap.
  List<Widget> _buildSetRows(BuildContext context, WidgetRef ref) {
    final List<WorkoutSet> ordered = orderedSetsForDisplay(detail.sets);

    // Pre-compute, for each working set, whether the user has already
    // attached at least one drop child below it (live in this exercise).
    // We use this to gate the "Add drop" affordance — we only offer it
    // immediately under a working set that's been completed and not yet
    // had a drop chain extended below it (the user can tap the last drop
    // in an existing chain to add another).
    final Set<String> workingSetsWithDrops = <String>{
      for (final WorkoutSet s in detail.sets)
        if (s.kind == WorkoutSetKind.drop && s.parentSetId != null)
          s.parentSetId!,
    };

    final List<Widget> widgets = <Widget>[];
    for (int i = 0; i < ordered.length; i++) {
      final WorkoutSet set = ordered[i];
      final WorkoutSet? prev = i > 0 ? ordered[i - 1] : null;
      final WorkoutSet? next = i < ordered.length - 1 ? ordered[i + 1] : null;
      final bool prevCompleted = prev != null && prev.completed;
      final bool nextCompleted = next != null && next.completed;

      // Match the previous set on setNumber for the PREVIOUS column. For
      // drop sets, we still surface a useful row from the corresponding
      // setNumber in the prior workout if one exists.
      final WorkoutSet? previousSet = previousSets
          .where((WorkoutSet s) => s.setNumber == set.setNumber)
          .firstOrNull;
      final String previousSummary = _formatPreviousSetSummary(
        previousSet,
        detail.exercise.type,
        allPreviousSets: previousSets,
      );

      // Drop sets are eligible for the bottom sheet's "drop" chip iff a
      // working set precedes them in the same exercise. Warm-ups and the
      // first working set never qualify.
      final bool canBeDrop = detail.sets.any(
        (WorkoutSet s) =>
            s.id != set.id &&
            s.setNumber < set.setNumber &&
            (s.kind == WorkoutSetKind.normal ||
                s.kind == WorkoutSetKind.failure),
      );

      widgets.add(
        Dismissible(
          key: ValueKey<String>('dismiss-${set.id}'),
          direction: DismissDirection.endToStart,
          dismissThresholds: const <DismissDirection, double>{
            DismissDirection.endToStart: 0.32,
          },
          movementDuration: const Duration(milliseconds: 240),
          resizeDuration: const Duration(milliseconds: 260),
          background: const SizedBox.shrink(),
          secondaryBackground: const _SwipeDeleteBackground(),
          onDismissed: (_) => onRemoveSet(set.id),
          child: SetRow(
            key: ValueKey<String>(set.id),
            set: set,
            exerciseType: detail.exercise.type,
            previousSummary: previousSummary,
            // Same gate as `_formatPreviousSetSummary`: an
            // in-progress / abandoned previous set is neither
            // rendered nor offered as a tap target.
            previousSet: (previousSet?.completed ?? false)
                ? previousSet
                : null,
            roundTop: !prevCompleted,
            roundBottom: !nextCompleted,
            onTapSetNumber: (BuildContext anchorContext) => onTapSetNumber(
              set: set,
              canBeDrop: canBeDrop,
              anchorContext: anchorContext,
            ),
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
            onSetCompleted: () => _maybeStartRestTimer(ref, detail),
            onSetUncompleted: () => _maybeClearRestTimer(
              ref,
              detail.workoutExercise.id,
            ),
          ),
        ),
      );

      // "Add drop" affordance: only after a completed working set, and
      // only when the very next row in the display order isn't already
      // its drop child (otherwise the user would see two pills next to
      // each other before the chain). Once a chain exists, the affordance
      // appears under the last drop in the chain — same logic, applied
      // to whichever working set this drop ultimately belongs to.
      final bool isWorkingSet = set.kind == WorkoutSetKind.normal ||
          set.kind == WorkoutSetKind.failure;
      final bool isDropSet = set.kind == WorkoutSetKind.drop;
      String? dropParentForAffordance;
      if (isWorkingSet && set.completed) {
        // Only offer when no drop is currently chained to this working
        // set. If one exists, we'll offer it under the last drop instead.
        if (!workingSetsWithDrops.contains(set.id)) {
          dropParentForAffordance = set.id;
        }
      } else if (isDropSet) {
        // Last drop in a chain → offer to add another to the same parent.
        final bool nextIsSiblingDrop = next != null &&
            next.kind == WorkoutSetKind.drop &&
            next.parentSetId == set.parentSetId;
        if (!nextIsSiblingDrop && set.parentSetId != null) {
          dropParentForAffordance = set.parentSetId;
        }
      }
      if (dropParentForAffordance != null) {
        widgets.add(
          _AddDropSetAffordance(
            palette: palette,
            onTap: () => onAddDropSet(dropParentForAffordance!),
          ),
        );
      }
    }
    return widgets;
  }
}

/// A small inline pill the user taps to extend a working set into a drop.
/// Indented so it visually anchors under the working set (or the drop
/// chain) it belongs to.
class _AddDropSetAffordance extends StatelessWidget {
  const _AddDropSetAffordance({required this.palette, required this.onTap});

  final JellyBeanPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SetKindVisuals visuals = SetKindVisuals.forKind(
      WorkoutSetKind.drop,
      palette,
    );
    final Color accent = visuals.accent ?? palette.shade700;
    return Padding(
      padding: const EdgeInsets.only(left: 22, top: 2, bottom: 2, right: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: visuals.tint?.withValues(alpha: 0.55) ??
                    palette.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accent.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.subdirectory_arrow_right_rounded,
                    size: 14,
                    color: accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add drop set',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 22),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[Color(0xFFFB7185), Color(0xFFE11D48)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const <Widget>[
          Text(
            'Delete set',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.delete_rounded, color: Colors.white, size: 22),
        ],
      ),
    );
  }
}

class _RemoveExerciseButton extends StatelessWidget {
  const _RemoveExerciseButton({required this.palette, required this.onTap});

  final JellyBeanPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Remove exercise',
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.delete_outline_rounded,
            size: 20,
            color: palette.shade600,
          ),
        ),
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
