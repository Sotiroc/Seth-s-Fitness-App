import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/illustrated_empty_state.dart';
import '../../../data/models/pr_event.dart';
import '../../../data/models/unit_system.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/workout_detail.dart';
import '../../profile/application/user_profile_provider.dart';
import '../../progression/application/pr_events_provider.dart';
import '../../progression/presentation/widgets/pr_event_formatting.dart';
import '../../workouts/application/active_workout_provider.dart';
import '../application/history_filter.dart';
import '../application/history_providers.dart';
import 'widgets/history_date_range_sheet.dart';
import 'widgets/history_exercise_picker_sheet.dart';
import 'widgets/history_filter_chip.dart';
import 'widgets/history_search_field.dart';

/// List of completed workouts (history tab) with search + filters.
///
/// Layout from top to bottom:
/// 1. Hero (gradient): back/title bar, search field, three filter chips,
///    and a 5-week dot strip that visualises which days have matching
///    workouts.
/// 2. Active-filter strip ("3 filters active · Clear all") — only when
///    something is on.
/// 3. Optional pinned in-progress workout tile.
/// 4. Filtered, month-grouped list of finished workouts.
class HistoryListScreen extends ConsumerWidget {
  const HistoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final HistoryFilter filter = ref.watch(historyFilterControllerProvider);
    final AsyncValue<List<Workout>> filtered = ref.watch(
      filteredHistoryProvider,
    );
    final AsyncValue<List<Workout>> all = ref.watch(workoutHistoryProvider);
    final Map<String, int> setCounts =
        ref.watch(historyCompletedSetCountsProvider).asData?.value ??
        const <String, int>{};
    final WorkoutDetail? activeDetail = ref
        .watch(activeWorkoutDetailProvider)
        .asData
        ?.value;

    return Scaffold(
      backgroundColor: palette.shade50,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _Hero(
              palette: palette,
              filter: filter,
              totalCount: all.asData?.value
                  .where((Workout w) => w.endedAt != null)
                  .length,
              filteredCount: filtered.asData?.value.length,
            ),
          ),
          if (filter.activeChipCount > 0 || filter.query.trim().isNotEmpty)
            SliverToBoxAdapter(
              child: _ActiveFiltersStrip(
                palette: palette,
                filter: filter,
                onClear: () => ref
                    .read(historyFilterControllerProvider.notifier)
                    .clear(),
              ),
            ),
          if (activeDetail != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _ActiveWorkoutPinTile(
                  palette: palette,
                  detail: activeDetail,
                  onTap: () => context.go('/workouts/active'),
                ),
              ),
            ),
          if (filter.prsOnly)
            _PrFlatListSliver(palette: palette, filter: filter)
          else
            filtered.when(
              data: (List<Workout> items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: filter.hasAnyFilter
                        ? _NoMatchesState(
                            palette: palette,
                            filter: filter,
                            onClear: () => ref
                                .read(historyFilterControllerProvider.notifier)
                                .clear(),
                          )
                        : const _EmptyState(),
                  );
                }
                final List<HistorySection> sections = ref.watch(
                  historyGroupedByMonthProvider,
                );
                final Set<String> prWorkouts =
                    ref.watch(prWorkoutIdsProvider);
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    96,
                  ),
                  sliver: SliverList.builder(
                    itemCount: sections.length,
                    itemBuilder: (BuildContext _, int index) {
                      final HistorySection section = sections[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == sections.length - 1
                              ? 0
                              : AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _SectionLabel(
                              text: section.title,
                              palette: palette,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            for (int i = 0;
                                i < section.workouts.length;
                                i++)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: i == section.workouts.length - 1
                                      ? 0
                                      : 8,
                                ),
                                child: _HistoryTile(
                                  workout: section.workouts[i],
                                  palette: palette,
                                  setCount:
                                      setCounts[section.workouts[i].id] ?? 0,
                                  hasPr: prWorkouts
                                      .contains(section.workouts[i].id),
                                  onTap: () => context.push(
                                    '/history/${section.workouts[i].id}',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object err, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text('Could not load history: $err'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

}

class _Hero extends ConsumerWidget {
  const _Hero({
    required this.palette,
    required this.filter,
    required this.totalCount,
    required this.filteredCount,
  });

  final JellyBeanPalette palette;
  final HistoryFilter filter;
  final int? totalCount;
  final int? filteredCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double topPadding = MediaQuery.paddingOf(context).top;
    final ThemeData theme = Theme.of(context);
    final bool filtering = filter.hasAnyFilter;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topPadding + AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.shade950, palette.shade700],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.white,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(width: 2, height: 14, color: palette.shade300),
                  const SizedBox(width: 8),
                  Text(
                    'LOGBOOK',
                    style: TextStyle(
                      color: palette.shade200,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
              if (totalCount != null)
                _HeroCountBadge(
                  palette: palette,
                  filtering: filtering,
                  filteredCount: filteredCount ?? 0,
                  totalCount: totalCount!,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'History',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          HistorySearchField(
            initialValue: filter.query,
            onDebouncedChanged: (String value) => ref
                .read(historyFilterControllerProvider.notifier)
                .setQuery(value),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ChipRow(palette: palette, filter: filter),
        ],
      ),
    );
  }
}

class _HeroCountBadge extends StatelessWidget {
  const _HeroCountBadge({
    required this.palette,
    required this.filtering,
    required this.filteredCount,
    required this.totalCount,
  });

  final JellyBeanPalette palette;
  final bool filtering;
  final int filteredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final String label = filtering ? '$filteredCount / $totalCount' : '$totalCount';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.shade100,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _ChipRow extends ConsumerWidget {
  const _ChipRow({required this.palette, required this.filter});

  final JellyBeanPalette palette;
  final HistoryFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          HistoryFilterChip(
            label: 'Exercise',
            icon: Icons.fitness_center_rounded,
            active: filter.exerciseIds.isNotEmpty,
            activeBadge: filter.exerciseIds.isEmpty
                ? null
                : '${filter.exerciseIds.length}',
            onTap: () => _openExercisePicker(context, ref),
          ),
          const SizedBox(width: 8),
          HistoryFilterChip(
            label: filter.datePreset == HistoryDateRangePreset.allTime
                ? 'Date'
                : filter.dateChipLabel(),
            icon: Icons.calendar_today_rounded,
            active: filter.datePreset != HistoryDateRangePreset.allTime,
            onTap: () => _openDateSheet(context, ref),
          ),
          const SizedBox(width: 8),
          HistoryFilterChip(
            label: 'PRs',
            icon: Icons.emoji_events_rounded,
            active: filter.prsOnly,
            showChevron: false,
            onTap: () => ref
                .read(historyFilterControllerProvider.notifier)
                .setPrsOnly(!filter.prsOnly),
          ),
          const SizedBox(width: 8),
          HistoryFilterChip(
            label: 'Notes',
            icon: Icons.sticky_note_2_rounded,
            active: filter.hasNotes,
            showChevron: false,
            onTap: () => ref
                .read(historyFilterControllerProvider.notifier)
                .setHasNotes(!filter.hasNotes),
          ),
        ],
      ),
    );
  }

  Future<void> _openExercisePicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final Set<String>? picked = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: HistoryExercisePickerSheet(initialIds: filter.exerciseIds),
        );
      },
    );
    if (picked == null) return;
    ref
        .read(historyFilterControllerProvider.notifier)
        .setExerciseIds(picked);
  }

  Future<void> _openDateSheet(BuildContext context, WidgetRef ref) async {
    final DateTime? customEndInclusive = filter.customEnd?.subtract(
      const Duration(days: 1),
    );
    final HistoryDateSheetResult? result =
        await showModalBottomSheet<HistoryDateSheetResult>(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (BuildContext sheetContext) {
            return HistoryDateRangeSheet(
              currentPreset: filter.datePreset,
              currentStart: filter.customStart,
              currentEndInclusive: customEndInclusive,
            );
          },
        );
    if (result == null) return;
    if (result.preset == HistoryDateRangePreset.custom) {
      if (result.customStart != null && result.customEndInclusive != null) {
        ref
            .read(historyFilterControllerProvider.notifier)
            .setCustomRange(
              start: result.customStart!,
              endInclusive: result.customEndInclusive!,
            );
      }
    } else {
      ref
          .read(historyFilterControllerProvider.notifier)
          .setDatePreset(result.preset);
    }
  }
}

class _ActiveFiltersStrip extends StatelessWidget {
  const _ActiveFiltersStrip({
    required this.palette,
    required this.filter,
    required this.onClear,
  });

  final JellyBeanPalette palette;
  final HistoryFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final int chipCount = filter.activeChipCount;
    final bool hasQuery = filter.query.trim().isNotEmpty;
    final List<String> bits = <String>[
      if (hasQuery) '"${filter.query.trim()}"',
      if (chipCount == 1)
        '1 filter active'
      else if (chipCount > 1)
        '$chipCount filters active',
    ];
    final String summary = bits.isEmpty
        ? 'Filtering'
        : bits.join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              summary,
              style: TextStyle(
                color: palette.shade800,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: palette.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  'Clear all',
                  style: TextStyle(
                    color: palette.shade700,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveWorkoutPinTile extends StatelessWidget {
  const _ActiveWorkoutPinTile({
    required this.palette,
    required this.detail,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final WorkoutDetail detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime started = detail.workout.startedAt.toLocal();
    final Duration duration = DateTime.now().difference(detail.workout.startedAt);
    final String? name = _cleaned(detail.workout.name);
    final String primaryText = name ?? 'Workout in progress';
    final String subText = '${_formatWeekday(started)} · ${_formatTime(started)}';
    final int exerciseCount = detail.exercises.length;

    return Material(
      color: palette.shade100,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.shade400, width: 1.4),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'IN PROGRESS',
                          style: TextStyle(
                            color: palette.shade800,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: palette.shade700,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      primaryText,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: palette.shade950,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exerciseCount == 0
                          ? subText
                          : '$subText · ${exerciseCount == 1 ? '1 exercise' : '$exerciseCount exercises'}',
                      style: TextStyle(
                        color: palette.shade800.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  DurationFormatter.elapsed(duration),
                  style: TextStyle(
                    color: palette.shade900,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.shade700,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatWeekday(DateTime d) {
    const List<String> weekdays = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
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
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  static String _formatTime(DateTime d) {
    final String hh = d.hour.toString().padLeft(2, '0');
    final String mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String? _cleaned(String? value) {
    if (value == null) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.workout,
    required this.palette,
    required this.setCount,
    required this.hasPr,
    required this.onTap,
  });

  final Workout workout;
  final JellyBeanPalette palette;
  final int setCount;

  /// True when this workout contains at least one PR. Drives the small
  /// amber trophy badge on the tile so users can scan history for
  /// breakthrough sessions at a glance.
  final bool hasPr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime started = workout.startedAt.toLocal();
    final Duration duration = (workout.endedAt ?? DateTime.now()).difference(
      workout.startedAt,
    );
    final String? name = _cleaned(workout.name);
    final String primaryText = name ?? _formatWeekday(started);
    final String subText = name != null
        ? '${_formatWeekday(started)} · ${_formatTime(started)}'
        : _formatTime(started);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.shade100),
          ),
          child: Row(
            children: <Widget>[
              _SetCountBadge(count: setCount, palette: palette),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            primaryText,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: palette.shade950,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasPr) ...<Widget>[
                          const SizedBox(width: 6),
                          const _TrophyBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subText,
                      style: TextStyle(
                        color: palette.shade700.withValues(alpha: 0.8),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: palette.shade100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  DurationFormatter.elapsed(duration),
                  style: TextStyle(
                    color: palette.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
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

  String _formatWeekday(DateTime d) {
    const List<String> weekdays = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
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
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  String _formatTime(DateTime d) {
    final String hh = d.hour.toString().padLeft(2, '0');
    final String mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String? _cleaned(String? value) {
    if (value == null) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _SetCountBadge extends StatelessWidget {
  const _SetCountBadge({required this.count, required this.palette});

  final int count;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '$count',
            style: TextStyle(
              color: palette.shade900,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: -0.4,
              height: 1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            count == 1 ? 'set' : 'sets',
            style: TextStyle(
              color: palette.shade700,
              fontWeight: FontWeight.w700,
              fontSize: 9,
              letterSpacing: 0.4,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMatchesState extends StatelessWidget {
  const _NoMatchesState({
    required this.palette,
    required this.filter,
    required this.onClear,
  });

  final JellyBeanPalette palette;
  final HistoryFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> bits = <String>[];
    if (filter.query.trim().isNotEmpty) {
      bits.add('Search: "${filter.query.trim()}"');
    }
    if (filter.exerciseIds.isNotEmpty) {
      bits.add(
        filter.exerciseIds.length == 1
            ? '1 exercise selected'
            : '${filter.exerciseIds.length} exercises selected',
      );
    }
    if (filter.datePreset != HistoryDateRangePreset.allTime) {
      bits.add('Date: ${filter.dateChipLabel()}');
    }
    if (filter.prsOnly) bits.add('PRs only');
    if (filter.hasNotes) bits.add('Has notes');

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.search_off_rounded, size: 56, color: palette.shade400),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No workouts match your filters',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.shade950,
              letterSpacing: -0.2,
            ),
          ),
          if (bits.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            for (final String bit in bits)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  bit,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton.tonal(
            onPressed: onClear,
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const IllustratedEmptyState(
      illustrationAsset: AppIllustrations.emptyHistory,
      title: 'Your training journal starts here',
      message:
          'Finish your first workout and it will land here, '
          'with duration, exercises, and your set-by-set log.',
    );
  }
}

/// Tiny amber trophy chip rendered next to a workout name when that
/// workout contains at least one PR.
class _TrophyBadge extends StatelessWidget {
  const _TrophyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Icon(
        Icons.emoji_events_rounded,
        color: Color(0xFFF59E0B),
        size: 14,
      ),
    );
  }
}

/// History list switches into this mode when the "PRs" filter chip is
/// active. The list becomes a flat newest-first feed of PR
/// achievements — one row per PR, not one per workout. Tapping a row
/// jumps to the workout that contained the PR.
///
/// Replaces the standalone "Records" screen idea — same value with no
/// extra surface to design or maintain.
class _PrFlatListSliver extends ConsumerWidget {
  const _PrFlatListSliver({required this.palette, required this.filter});

  final JellyBeanPalette palette;
  final HistoryFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PrEvent>> async = ref.watch(allPrEventsProvider);
    final UnitSystem unitSystem = ref
        .watch(userProfileProvider)
        .maybeWhen<UnitSystem>(
          data: (UserProfile? p) => p?.unitSystem ?? UnitSystem.metric,
          orElse: () => UnitSystem.metric,
        );

    return async.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object err, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Could not load PRs: $err'),
          ),
        ),
      ),
      data: (List<PrEvent> events) {
        // Apply secondary chip filters that still make sense in flat
        // mode — the date range and the search query against exercise
        // name. Notes / exercise-id pickers don't translate cleanly so
        // they are intentionally ignored in this mode.
        final HistoryDateBounds bounds =
            filter.dateBounds(DateTime.now());
        final String query = filter.query.trim().toLowerCase();
        final List<PrEvent> filtered = events.where((PrEvent e) {
          if (!bounds.contains(e.achievedAt)) return false;
          if (query.isNotEmpty &&
              !e.exerciseName.toLowerCase().contains(query)) {
            return false;
          }
          return true;
        }).toList(growable: false);

        if (filtered.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: palette.shade300,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No PRs yet',
                      style: TextStyle(
                        color: palette.shade950,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Finish more workouts and your records will land here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            96,
          ),
          sliver: SliverList.separated(
            itemCount: filtered.length,
            separatorBuilder: (BuildContext _, int _) =>
                const SizedBox(height: 8),
            itemBuilder: (BuildContext _, int index) {
              final PrEvent e = filtered[index];
              return _PrFlatTile(
                event: e,
                palette: palette,
                unitSystem: unitSystem,
                onTap: () => context.push('/history/${e.workoutId}'),
              );
            },
          ),
        );
      },
    );
  }
}

class _PrFlatTile extends StatelessWidget {
  const _PrFlatTile({
    required this.event,
    required this.palette,
    required this.unitSystem,
    required this.onTap,
  });

  final PrEvent event;
  final JellyBeanPalette palette;
  final UnitSystem unitSystem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String value = PrEventFormatting.value(event, unitSystem);
    final String typeLabel = PrEventFormatting.typeLabel(event);
    final String relative =
        PrEventFormatting.relativeDate(event.achievedAt);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.shade100),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      event.exerciseName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: palette.shade950,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$typeLabel · $relative',
                      style: TextStyle(
                        color: palette.shade700.withValues(alpha: 0.85),
                        fontSize: 12.5,
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
              const SizedBox(width: 6),
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
