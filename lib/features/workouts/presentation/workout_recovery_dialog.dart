import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/exercise_type.dart';
import '../../../data/models/workout_detail.dart';
import '../../../data/models/workout_set.dart';
import '../../../data/models/workout_set_kind.dart';
import '../../exercises/presentation/widgets/exercise_avatar.dart';
import '../application/workout_recovery_controller.dart';

/// Surfaced via [showDialog] (from [HomeShell]) when the auto-close-stale-
/// workout flow has just closed an abandoned active workout. Designed to
/// echo the visual language of the history list — one card per exercise,
/// minimal chrome — so it feels like an extension of the existing UI
/// rather than a new pattern.
///
/// Intensity is intentionally not editable here. The user can set it from
/// the history detail screen if desired; surfacing it on the recovery
/// dialog made the modal feel cluttered for a flow that's just confirming
/// "save / discard / keep going."
class WorkoutRecoveryDialog extends ConsumerStatefulWidget {
  const WorkoutRecoveryDialog({super.key});

  @override
  ConsumerState<WorkoutRecoveryDialog> createState() =>
      _WorkoutRecoveryDialogState();
}

class _WorkoutRecoveryDialogState extends ConsumerState<WorkoutRecoveryDialog> {
  final TextEditingController _nameController = TextEditingController();
  WorkoutDetail? _seededFor;
  DateTime? _editedEndedAt;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _seedIfNeeded(WorkoutDetail detail) {
    if (identical(_seededFor, detail)) return;
    _seededFor = detail;
    _nameController.text = detail.workout.name ?? '';
    _editedEndedAt = detail.workout.endedAt;
  }

  Future<void> _pickEndTime(WorkoutDetail detail) async {
    final DateTime current = (_editedEndedAt ?? detail.workout.endedAt!)
        .toLocal();
    final DateTime startedLocal = detail.workout.startedAt.toLocal();
    final DateTime lastAllowed = DateTime.now().add(const Duration(days: 1));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: startedLocal,
      lastDate: lastAllowed,
      helpText: 'End date',
    );
    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: 'End time',
    );
    if (pickedTime == null) return;

    final DateTime combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    // Refuse end-before-start: snap to start instead.
    final DateTime safe =
        combined.isBefore(startedLocal) ? startedLocal : combined;
    setState(() => _editedEndedAt = safe.toUtc());
  }

  Future<void> _onSave(WorkoutDetail detail) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final String trimmed = _nameController.text.trim();
      await ref
          .read(workoutRecoveryControllerProvider.notifier)
          .confirmSave(
            name: trimmed.isEmpty ? null : trimmed,
            endedAt: _editedEndedAt,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      _showError('Could not save: $error');
      setState(() => _busy = false);
    }
  }

  Future<void> _onDiscard(WorkoutDetail detail) async {
    if (_busy) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final JellyBeanPalette palette = ctx.jellyBeanPalette;
        return AlertDialog(
          backgroundColor: palette.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Discard workout?',
            style: TextStyle(
              color: palette.shade950,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'This permanently deletes the session and every set you '
            'logged. This cannot be undone.',
            style: TextStyle(color: palette.shade800, height: 1.45),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep'),
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
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(workoutRecoveryControllerProvider.notifier)
          .confirmDiscard();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      _showError('Could not discard: $error');
      setState(() => _busy = false);
    }
  }

  Future<void> _onReopen(WorkoutDetail detail) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(workoutRecoveryControllerProvider.notifier)
          .reopenForEditing();
      if (!mounted) return;
      Navigator.of(context).pop();
      GoRouter.of(context).go('/workouts');
    } catch (error) {
      if (!mounted) return;
      _showError('Could not reopen: $error');
      setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final WorkoutDetail? detail = ref.watch(
      workoutRecoveryControllerProvider.select((s) => s.recoveredWorkout),
    );
    if (detail == null) {
      // State was cleared externally — close ourselves.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }
    _seedIfNeeded(detail);

    final JellyBeanPalette palette = context.jellyBeanPalette;
    final DateTime endedAt = _editedEndedAt ?? detail.workout.endedAt!;
    final Duration duration = endedAt.difference(detail.workout.startedAt);
    final int completedSets = detail.exercises
        .expand<WorkoutSet>((e) => e.sets)
        .where((s) => s.completed && s.kind.countsAsWorkingSet)
        .length;
    final int totalSets = detail.exercises.fold<int>(
      0,
      (sum, e) => sum + e.sets.where((s) => s.kind.countsAsWorkingSet).length,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      backgroundColor: palette.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Header(palette: palette),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _SummaryRow(
                      palette: palette,
                      duration: duration,
                      completedSets: completedSets,
                      totalSets: totalSets,
                      endedAt: endedAt,
                      onPickEndTime: () => _pickEndTime(detail),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _NameField(palette: palette, controller: _nameController),
                    if (detail.exercises.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      for (int i = 0; i < detail.exercises.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i == detail.exercises.length - 1 ? 0 : 8,
                          ),
                          child: _ExerciseTile(
                            detail: detail.exercises[i],
                            palette: palette,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            _Actions(
              palette: palette,
              busy: _busy,
              onDiscard: () => _onDiscard(detail),
              onReopen: () => _onReopen(detail),
              onSave: () => _onSave(detail),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.palette});
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.shade900, palette.shade700],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            "You didn't end your workout",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Save it, change the end time, or pick it back up.',
            style: TextStyle(
              color: palette.shade100.withValues(alpha: 0.9),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single tappable row showing the duration + sets summary, with the
/// end-time editable inline. Replaces the previous layout that split this
/// info across three separate blocks.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.palette,
    required this.duration,
    required this.completedSets,
    required this.totalSets,
    required this.endedAt,
    required this.onPickEndTime,
  });

  final JellyBeanPalette palette;
  final Duration duration;
  final int completedSets;
  final int totalSets;
  final DateTime endedAt;
  final VoidCallback onPickEndTime;

  String _formatTime(DateTime utc) {
    final DateTime local = utc.toLocal();
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPickEndTime,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.shade100),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      DurationFormatter.elapsed(duration),
                      style: TextStyle(
                        color: palette.shade950,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ended at ${_formatTime(endedAt)}  ·  '
                      '$completedSets / $totalSets sets',
                      style: TextStyle(
                        color: palette.shade700,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.edit_calendar_rounded,
                  color: palette.shade800,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.palette, required this.controller});
  final JellyBeanPalette palette;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.shade100),
      ),
      child: TextField(
        controller: controller,
        maxLength: 60,
        textInputAction: TextInputAction.done,
        style: TextStyle(
          color: palette.shade950,
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          counterText: '',
          hintText: 'Name this workout (optional)',
          hintStyle: TextStyle(
            color: palette.shade700.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// One row per exercise — same visual language as the history list tile
/// (avatar + name + trailing chip). Trailing chip shows completed/total
/// sets and, for weighted exercises, total volume.
class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.detail, required this.palette});
  final WorkoutExerciseDetail detail;
  final JellyBeanPalette palette;

  String _trailingText() {
    final int completed = detail.sets
        .where((s) => s.completed && s.kind.countsAsWorkingSet)
        .length;
    final int total = detail.sets
        .where((s) => s.kind.countsAsWorkingSet)
        .length;
    final String setsText = '$completed/$total';
    if (detail.exercise.type == ExerciseType.weighted) {
      final double volume = detail.sets
          .where((s) => s.completed && s.kind != WorkoutSetKind.warmUp)
          .fold<double>(
            0,
            (sum, s) => sum + (s.weightKg ?? 0) * (s.reps ?? 0),
          );
      if (volume > 0) return '$setsText  ·  ${_formatKg(volume)} kg';
    }
    if (detail.exercise.type == ExerciseType.cardio) {
      final double distance = detail.sets
          .where((s) => s.completed && s.kind != WorkoutSetKind.warmUp)
          .fold<double>(0, (sum, s) => sum + (s.distanceKm ?? 0));
      if (distance > 0) return '$setsText  ·  ${_formatKm(distance)} km';
    }
    return setsText;
  }

  static String _formatKg(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  static String _formatKm(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.shade100),
      ),
      child: Row(
        children: <Widget>[
          ExerciseAvatar(exercise: detail.exercise, size: 32),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              detail.exercise.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.shade950,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: palette.shade100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _trailingText(),
              style: TextStyle(
                color: palette.shade800,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.palette,
    required this.busy,
    required this.onDiscard,
    required this.onReopen,
    required this.onSave,
  });

  final JellyBeanPalette palette;
  final bool busy;
  final VoidCallback onDiscard;
  final VoidCallback onReopen;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          TextButton(
            onPressed: busy ? null : onDiscard,
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent.shade200,
            ),
            child: const Text('Discard'),
          ),
          const Spacer(),
          TextButton(
            onPressed: busy ? null : onReopen,
            style: TextButton.styleFrom(foregroundColor: palette.shade800),
            child: const Text('Edit / Add'),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: busy ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: palette.shade900,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: busy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
