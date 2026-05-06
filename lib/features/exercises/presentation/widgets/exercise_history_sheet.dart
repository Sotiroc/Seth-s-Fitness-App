import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/illustrated_empty_state.dart';
import '../../../../data/models/exercise.dart';
import '../../../../data/models/exercise_history_day.dart';
import '../../../../data/models/exercise_type.dart';
import '../../../../data/models/pr_event.dart';
import '../../../../data/models/unit_system.dart';
import '../../../../data/models/user_profile.dart';
import '../../../profile/application/user_profile_provider.dart';
import '../../../progression/application/pr_events_provider.dart';
import '../../../progression/application/strength_series_provider.dart';
import '../../application/exercise_history_provider.dart';
import 'exercise_avatar.dart';
import 'exercise_history_day_card.dart';
import 'exercise_history_pr_card.dart';
import 'exercise_history_summary.dart';

/// Bottom sheet that shows an exercise's all-time best PR plus every past
/// session as date-ordered cards. Used both during an active workout (tap
/// the exercise title) and from the Exercises menu (tap a row).
///
/// Pass `showEditButton: true` to surface a one-tap path into the
/// exercise form — both call sites today opt in so users can adjust
/// per-exercise settings (rest timer, name, type, etc.) without
/// hunting for the exercise on the Exercises tab.
class ExerciseHistorySheet extends ConsumerWidget {
  const ExerciseHistorySheet({
    super.key,
    required this.exerciseId,
    this.showEditButton = false,
  });

  final String exerciseId;
  final bool showEditButton;

  static Future<void> show(
    BuildContext context, {
    required String exerciseId,
    bool showEditButton = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseHistorySheet(
        exerciseId: exerciseId,
        showEditButton: showEditButton,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final AsyncValue<Exercise?> exerciseAsync = ref.watch(
      exerciseByIdStreamProvider(exerciseId),
    );
    final AsyncValue<List<ExerciseHistoryDay>> historyAsync = ref.watch(
      exerciseHistoryByDayProvider(exerciseId),
    );
    final AsyncValue<ExercisePrBests> bestsAsync = ref.watch(
      exerciseBestsProvider(exerciseId),
    );
    final AsyncValue<Set<String>> prSetIdsAsync = ref.watch(
      exercisePrSetIdsProvider(exerciseId),
    );
    final UnitSystem unitSystem = ref
        .watch(userProfileProvider)
        .maybeWhen<UnitSystem>(
          data: (UserProfile? p) => p?.unitSystem ?? UnitSystem.metric,
          orElse: () => UnitSystem.metric,
        );

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: palette.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: AppSpacing.sm),
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: _Header(
                  palette: palette,
                  exercise: exerciseAsync.asData?.value,
                  showEditButton: showEditButton,
                  onEdit: showEditButton
                      ? () => _openEdit(context, exerciseId)
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: historyAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => _ErrorView(palette: palette, error: err),
                  data: (history) {
                    if (history.isEmpty) {
                      return const _EmptyView();
                    }
                    return _HistoryBody(
                      scrollController: scrollController,
                      history: history,
                      palette: palette,
                      exercise: exerciseAsync.asData?.value,
                      bests: bestsAsync.asData?.value ??
                          const ExercisePrBests(),
                      unitSystem: unitSystem,
                      prSetIds:
                          prSetIdsAsync.asData?.value ?? const <String>{},
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void _openEdit(BuildContext context, String exerciseId) {
    Navigator.of(context).pop();
    context.push('/exercises/$exerciseId/edit');
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.palette,
    required this.exercise,
    required this.showEditButton,
    required this.onEdit,
  });

  final JellyBeanPalette palette;
  final Exercise? exercise;
  final bool showEditButton;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String title = exercise?.name ?? 'History';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (exercise != null)
          ExerciseAvatar(exercise: exercise!, size: 44)
        else
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.shade100,
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: palette.shade950,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'History',
                style: TextStyle(
                  color: palette.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        if (showEditButton && onEdit != null)
          FilledButton.tonalIcon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
            style: FilledButton.styleFrom(
              backgroundColor: palette.shade100,
              foregroundColor: palette.shade900,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ),
      ],
    );
  }
}

class _HistoryBody extends StatefulWidget {
  const _HistoryBody({
    required this.scrollController,
    required this.history,
    required this.palette,
    required this.exercise,
    required this.bests,
    required this.unitSystem,
    required this.prSetIds,
  });

  final ScrollController scrollController;
  final List<ExerciseHistoryDay> history;
  final JellyBeanPalette palette;
  final Exercise? exercise;
  final ExercisePrBests bests;
  final UnitSystem unitSystem;
  final Set<String> prSetIds;

  @override
  State<_HistoryBody> createState() => _HistoryBodyState();
}

class _HistoryBodyState extends State<_HistoryBody> {
  /// One GlobalKey per day card, keyed by the day's local-midnight
  /// timestamp. Used by the PR card's tap handler to scroll the list to
  /// the day card whose date matches the chosen PR's `achievedAt`.
  final Map<DateTime, GlobalKey> _dayKeys = <DateTime, GlobalKey>{};

  GlobalKey _keyForDay(DateTime date) {
    final DateTime midnight = DateTime(date.year, date.month, date.day);
    return _dayKeys.putIfAbsent(midnight, () => GlobalKey());
  }

  void _scrollToPrEvent(PrEvent event) {
    final DateTime local = event.achievedAt.toLocal();
    final DateTime target = DateTime(local.year, local.month, local.day);
    final GlobalKey? key = _dayKeys[target];
    final BuildContext? ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ExerciseType type = widget.exercise?.type ?? ExerciseType.weighted;
    final bool showPr = !widget.bests.isEmpty;

    return ListView.separated(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: widget.history.length + (showPr ? 2 : 1),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (showPr && index == 0) {
          return ExerciseHistoryPrCard(
            palette: widget.palette,
            bests: widget.bests,
            exerciseType: type,
            unitSystem: widget.unitSystem,
            onTapEvent: _scrollToPrEvent,
          );
        }
        final int summaryIndex = showPr ? 1 : 0;
        if (index == summaryIndex) {
          return ExerciseHistorySummary(
            history: widget.history,
            palette: widget.palette,
          );
        }
        final ExerciseHistoryDay day =
            widget.history[index - summaryIndex - 1];
        return ExerciseHistoryDayCard(
          key: _keyForDay(day.date),
          day: day,
          palette: widget.palette,
          exerciseType: type,
          prSetIds: widget.prSetIds,
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: IllustratedEmptyState(
        illustrationAsset: AppIllustrations.emptyExercises,
        title: 'No history yet',
        message:
            'Complete a set with this exercise to start your history.',
        illustrationSize: 160,
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            size: 36,
            color: palette.shade600,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Could not load history',
            style: TextStyle(
              color: palette.shade950,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.shade700),
          ),
        ],
      ),
    );
  }
}
