import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/exercise_type.dart';
import '../../../data/models/pr_event.dart';
import '../../../data/models/unit_system.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/workout_detail.dart';
import '../../../data/models/workout_set.dart';
import '../../../data/models/workout_set_kind.dart';
import '../../exercises/presentation/widgets/exercise_avatar.dart';
import '../../exercises/presentation/widgets/exercise_muscle_group_badge.dart';
import '../../exercises/presentation/widgets/exercise_type_badge.dart';
import '../../history/application/history_providers.dart';
import '../../profile/application/user_profile_provider.dart';
import '../../progression/application/pr_events_provider.dart';
import '../../progression/presentation/widgets/pr_event_formatting.dart';
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
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _notesFocus = FocusNode();
  Timer? _saveDebounce;
  Timer? _notesSaveDebounce;
  String? _lastSavedName;
  String? _lastSavedNotes;
  int? _selectedIntensity;
  int? _lastSavedIntensity;
  bool _seeded = false;

  /// Whether the celebration popup has been shown for this entry into
  /// the screen. Guards against re-showing on every rebuild — the
  /// popup fires exactly once when the workout's PR list first
  /// resolves with at least one entry.
  bool _celebrationShown = false;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(_onFocusChange);
    _notesFocus.addListener(_onNotesFocusChange);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _notesSaveDebounce?.cancel();
    _nameFocus.removeListener(_onFocusChange);
    _nameFocus.dispose();
    _nameController.dispose();
    _notesFocus.removeListener(_onNotesFocusChange);
    _notesFocus.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_nameFocus.hasFocus) {
      _flushSave();
    }
  }

  void _onNotesFocusChange() {
    if (!_notesFocus.hasFocus) {
      _flushNotesSave();
    }
  }

  void _seedIfNeeded(
    String? serverName,
    String? serverNotes,
    int? serverIntensity, {
    int? suggestedIntensity,
  }) {
    if (_seeded) return;
    _seeded = true;
    _nameController.text = serverName ?? '';
    _lastSavedName = serverName;
    _notesController.text = serverNotes ?? '';
    _lastSavedNotes = serverNotes;
    // Prefer the value the user actually saved. When they haven't picked
    // one yet, fall back to the max per-set RPE so the chip already
    // reflects the heaviest set's effort. The fallback is "suggested"
    // — we never persist it without an explicit tap, so the user keeps
    // ownership of the number.
    _selectedIntensity = serverIntensity ?? suggestedIntensity;
    // Track only the actually-persisted value here so a later change
    // attributed to the user (tapping the same chip) compares correctly.
    _lastSavedIntensity = serverIntensity;
  }

  void _onNameChanged(String _) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), _flushSave);
  }

  void _onNotesChanged(String _) {
    _notesSaveDebounce?.cancel();
    _notesSaveDebounce =
        Timer(const Duration(milliseconds: 700), _flushNotesSave);
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

  Future<void> _flushNotesSave() async {
    _notesSaveDebounce?.cancel();
    final String trimmed = _notesController.text.trim();
    final String? normalized = trimmed.isEmpty ? null : trimmed;
    if (normalized == _lastSavedNotes) return;
    _lastSavedNotes = normalized;
    try {
      await ref
          .read(workoutSessionControllerProvider.notifier)
          .updateWorkoutNotes(
            workoutId: widget.workoutId,
            notes: normalized,
          );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save note: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _setIntensity(int? value) async {
    if (value == _selectedIntensity) return;
    final int? previous = _selectedIntensity;
    final int? previousSaved = _lastSavedIntensity;
    setState(() {
      _selectedIntensity = value;
    });
    _lastSavedIntensity = value;
    try {
      await ref
          .read(workoutSessionControllerProvider.notifier)
          .updateWorkoutIntensityScore(
            workoutId: widget.workoutId,
            score: value,
          );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _selectedIntensity = previous;
      });
      _lastSavedIntensity = previousSaved;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save intensity: ${error.toString().replaceFirst('Exception: ', '')}',
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
    final AsyncValue<List<PrEvent>> prsAsync = ref.watch(
      prsForWorkoutProvider(widget.workoutId),
    );
    final UnitSystem unitSystem = ref
        .watch(userProfileProvider)
        .maybeWhen<UnitSystem>(
          data: (UserProfile? p) => p?.unitSystem ?? UnitSystem.metric,
          orElse: () => UnitSystem.metric,
        );

    // Trigger the celebration popup the first time PRs resolve with
    // at least one entry. We do it from build() with a post-frame
    // callback so the dialog opens after the screen is in the tree.
    final List<PrEvent> prs = prsAsync.asData?.value ?? const <PrEvent>[];
    if (!_celebrationShown && prs.isNotEmpty) {
      _celebrationShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _PrCelebrationDialog.show(
          context: context,
          palette: palette,
          prs: prs,
          unitSystem: unitSystem,
        );
      });
    }

    return Scaffold(
      backgroundColor: palette.shade50,
      body: detailAsync.when(
        data: (detail) {
          _seedIfNeeded(
            detail.workout.name,
            detail.workout.notes,
            detail.workout.intensityScore,
            suggestedIntensity: _maxPerSetRpe(detail),
          );
          return _SummaryBody(
            detail: detail,
            palette: palette,
            nameController: _nameController,
            nameFocus: _nameFocus,
            onNameChanged: _onNameChanged,
            onSubmitted: _flushSave,
            notesController: _notesController,
            notesFocus: _notesFocus,
            onNotesChanged: _onNotesChanged,
            onNotesSubmitted: _flushNotesSave,
            selectedIntensity: _selectedIntensity,
            onIntensityChanged: _setIntensity,
            isIntensitySuggested:
                detail.workout.intensityScore == null &&
                _selectedIntensity != null,
            prs: prs,
            unitSystem: unitSystem,
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

/// Largest 1–10 per-set RPE recorded across the entire workout, or `null`
/// if no set has an RPE attached. Used as the auto-suggested seed for the
/// workout-level intensity chip on the summary screen — the user can
/// always override.
int? _maxPerSetRpe(WorkoutDetail detail) {
  int? best;
  for (final WorkoutExerciseDetail e in detail.exercises) {
    for (final WorkoutSet s in e.sets) {
      final int? rpe = s.rpe;
      if (rpe == null) continue;
      if (best == null || rpe > best) best = rpe;
    }
  }
  return best;
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({
    required this.detail,
    required this.palette,
    required this.nameController,
    required this.nameFocus,
    required this.onNameChanged,
    required this.onSubmitted,
    required this.notesController,
    required this.notesFocus,
    required this.onNotesChanged,
    required this.onNotesSubmitted,
    required this.selectedIntensity,
    required this.onIntensityChanged,
    required this.isIntensitySuggested,
    required this.prs,
    required this.unitSystem,
  });

  final WorkoutDetail detail;
  final JellyBeanPalette palette;
  final TextEditingController nameController;
  final FocusNode nameFocus;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onSubmitted;
  final TextEditingController notesController;
  final FocusNode notesFocus;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback onNotesSubmitted;
  final int? selectedIntensity;
  final ValueChanged<int?> onIntensityChanged;
  final bool isIntensitySuggested;
  final List<PrEvent> prs;
  final UnitSystem unitSystem;

  Duration get _duration {
    final DateTime end = detail.workout.endedAt ?? DateTime.now();
    return end.difference(detail.workout.startedAt);
  }

  int get _completedSets {
    return detail.exercises
        .expand<WorkoutSet>((e) => e.sets)
        .where((s) => s.completed && s.kind.countsAsWorkingSet)
        .length;
  }

  int get _totalSets {
    return detail.exercises.fold<int>(
      0,
      (sum, e) => sum + e.sets.where((s) => s.kind.countsAsWorkingSet).length,
    );
  }

  double get _totalVolumeKg {
    double total = 0;
    for (final WorkoutExerciseDetail e in detail.exercises) {
      if (e.exercise.type != ExerciseType.weighted) continue;
      for (final WorkoutSet s in e.sets) {
        if (!s.completed) continue;
        if (s.kind == WorkoutSetKind.warmUp) continue;
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
        if (s.kind == WorkoutSetKind.warmUp) continue;
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
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: _IntensityInputCard(
              palette: palette,
              selected: selectedIntensity,
              onChanged: onIntensityChanged,
              isSuggested: isIntensitySuggested,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: _NotesInputCard(
              palette: palette,
              controller: notesController,
              focusNode: notesFocus,
              onChanged: onNotesChanged,
              onSubmitted: onNotesSubmitted,
            ),
          ),
        ),
        if (prs.isNotEmpty) ...<Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            sliver: SliverToBoxAdapter(
              child: _SectionLabel(
                text: 'Records this session',
                palette: palette,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _RecordsBlock(
                prs: prs,
                palette: palette,
                unitSystem: unitSystem,
              ),
            ),
          ),
        ],
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
                onNotesSubmitted();
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

class _NotesInputCard extends StatelessWidget {
  const _NotesInputCard({
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                Icons.sticky_note_2_outlined,
                color: palette.shade800,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'NOTES',
                      style: TextStyle(
                        color: palette.shade700,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    maxLines: null,
                    minLines: 2,
                    maxLength: 500,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: onChanged,
                    onEditingComplete: onSubmitted,
                    style: TextStyle(
                      color: palette.shade950,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      counterText: '',
                      hintText:
                          'How did this workout feel? Anything to remember?',
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

class _IntensityInputCard extends StatelessWidget {
  const _IntensityInputCard({
    required this.palette,
    required this.selected,
    required this.onChanged,
    required this.isSuggested,
  });

  final JellyBeanPalette palette;
  final int? selected;

  /// Receives the new value, or `null` when the user taps the currently
  /// selected chip to clear the score.
  final ValueChanged<int?> onChanged;

  /// True when [selected] reflects a value derived from per-set RPEs that
  /// the user has not yet confirmed. The card prefixes the helper line
  /// with "Suggested" so the user knows tapping a different chip is
  /// expected, not a correction.
  final bool isSuggested;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
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
                  Icons.local_fire_department_rounded,
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
                      'INTENSITY',
                      style: TextStyle(
                        color: palette.shade700,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSuggested
                          ? 'Suggested from your set RPEs · tap to confirm or change'
                          : 'How hard did this feel? (1–10)',
                      style: TextStyle(
                        color: palette.shade700.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (int i = 1; i <= 10; i++)
                _IntensityChip(
                  palette: palette,
                  value: i,
                  selected: selected == i,
                  isSuggested: isSuggested && selected == i,
                  tooltip: i == 1
                      ? 'Very easy'
                      : i == 10
                      ? 'Max effort'
                      : null,
                  // Tapping the suggested chip confirms it (writes through);
                  // tapping any other chip overrides; tapping the same chip
                  // again clears (only after the user has confirmed).
                  onTap: () {
                    if (selected == i && !isSuggested) {
                      onChanged(null);
                    } else {
                      onChanged(i);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntensityChip extends StatelessWidget {
  const _IntensityChip({
    required this.palette,
    required this.value,
    required this.selected,
    required this.onTap,
    this.tooltip,
    this.isSuggested = false,
  });

  final JellyBeanPalette palette;
  final int value;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;

  /// True when this chip is selected via auto-suggest rather than an
  /// explicit user tap. Renders with a softer fill so it doesn't read as
  /// a confirmed answer until the user taps to lock it in.
  final bool isSuggested;

  @override
  Widget build(BuildContext context) {
    final Color fillColor = selected
        ? (isSuggested
            ? palette.shade400.withValues(alpha: 0.55)
            : palette.shade700)
        : palette.shade50;
    final Color borderColor = selected
        ? (isSuggested ? palette.shade500 : palette.shade700)
        : palette.shade100;
    final Color textColor = selected
        ? (isSuggested ? palette.shade950 : Colors.white)
        : palette.shade800;
    final Widget chip = Material(
      color: fillColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );

    if (tooltip == null) return chip;
    return Tooltip(message: tooltip!, child: chip);
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

/// "Records this session" block on the workout summary. One row per
/// PR: trophy icon, exercise name, value, type label. Hidden when the
/// workout had no PRs (the parent only renders us when [prs] is
/// non-empty).
class _RecordsBlock extends StatelessWidget {
  const _RecordsBlock({
    required this.prs,
    required this.palette,
    required this.unitSystem,
  });

  final List<PrEvent> prs;
  final JellyBeanPalette palette;
  final UnitSystem unitSystem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.shade100),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < prs.length; i++) ...<Widget>[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(height: 1, color: palette.shade100),
              ),
            _RecordRow(
              event: prs[i],
              palette: palette,
              unitSystem: unitSystem,
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.event,
    required this.palette,
    required this.unitSystem,
  });

  final PrEvent event;
  final JellyBeanPalette palette;
  final UnitSystem unitSystem;

  @override
  Widget build(BuildContext context) {
    final String value = PrEventFormatting.value(event, unitSystem);
    final String typeLabel = PrEventFormatting.typeLabel(event);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFF59E0B),
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  event.exerciseName,
                  style: TextStyle(
                    color: palette.shade950,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  typeLabel,
                  style: TextStyle(
                    color: palette.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              color: palette.shade950,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Celebratory dialog that fires once when the summary screen first
/// resolves PRs. Shows a big trophy, the count, the records list, and
/// a single dismiss button. Quiet by design — fade-in, no haptics, no
/// confetti.
class _PrCelebrationDialog extends StatelessWidget {
  const _PrCelebrationDialog({
    required this.palette,
    required this.prs,
    required this.unitSystem,
  });

  final JellyBeanPalette palette;
  final List<PrEvent> prs;
  final UnitSystem unitSystem;

  static Future<void> show({
    required BuildContext context,
    required JellyBeanPalette palette,
    required List<PrEvent> prs,
    required UnitSystem unitSystem,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss personal records',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (BuildContext _, Animation<double> _, Animation<double> _) {
        return _PrCelebrationDialog(
          palette: palette,
          prs: prs,
          unitSystem: unitSystem,
        );
      },
      transitionBuilder: (BuildContext _, Animation<double> anim,
          Animation<double> _, Widget child) {
        final CurvedAnimation curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String title = prs.length == 1
        ? 'New personal record!'
        : 'New personal records!';
    final String subtitle = prs.length == 1
        ? 'You set a new best this session.'
        : 'You set ${prs.length} new bests this session.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[palette.shade900, palette.shade700],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFF59E0B)
                              .withValues(alpha: 0.55),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFF59E0B),
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.shade100.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < prs.length && i < 6; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: _DialogPrLine(
                              event: prs[i],
                              unitSystem: unitSystem,
                              palette: palette,
                            ),
                          ),
                        if (prs.length > 6)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+${prs.length - 6} more',
                              style: TextStyle(
                                color: palette.shade100
                                    .withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: palette.shade950,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Nice',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
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

class _DialogPrLine extends StatelessWidget {
  const _DialogPrLine({
    required this.event,
    required this.unitSystem,
    required this.palette,
  });

  final PrEvent event;
  final UnitSystem unitSystem;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    final String value = PrEventFormatting.value(event, unitSystem);
    final String typeLabel = PrEventFormatting.typeLabel(event);
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                event.exerciseName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                typeLabel,
                style: TextStyle(
                  color: palette.shade100.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
