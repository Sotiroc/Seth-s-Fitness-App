import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/workout.dart';
import '../application/history_providers.dart';

/// List of completed workouts (history tab).
class HistoryListScreen extends ConsumerWidget {
  const HistoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final AsyncValue<List<Workout>> history = ref.watch(workoutHistoryProvider);
    final Map<String, int> setCounts =
        ref.watch(historyCompletedSetCountsProvider).asData?.value ??
        const <String, int>{};

    return Scaffold(
      backgroundColor: palette.shade50,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _Header(
              palette: palette,
              count: history.asData?.value.length,
            ),
          ),
          history.when(
            data: (items) {
              final List<Workout> finished = items
                  .where((w) => w.endedAt != null)
                  .toList(growable: false);
              if (finished.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(palette: palette),
                );
              }
              final List<_HistorySection> sections = _groupByMonth(finished);
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  96,
                ),
                sliver: SliverList.builder(
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final _HistorySection section = sections[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == sections.length - 1
                            ? 0
                            : AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _SectionLabel(text: section.title, palette: palette),
                          const SizedBox(height: AppSpacing.sm),
                          for (int i = 0; i < section.workouts.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i == section.workouts.length - 1
                                    ? 0
                                    : 8,
                              ),
                              child: _HistoryTile(
                                workout: section.workouts[i],
                                palette: palette,
                                setCount: setCounts[section.workouts[i].id] ?? 0,
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
            error: (err, _) => SliverFillRemaining(
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

  List<_HistorySection> _groupByMonth(List<Workout> workouts) {
    final Map<String, List<Workout>> buckets = <String, List<Workout>>{};
    for (final Workout w in workouts) {
      final DateTime d = w.startedAt.toLocal();
      final String key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      buckets.putIfAbsent(key, () => <Workout>[]).add(w);
    }
    final List<String> keys = buckets.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return keys
        .map(
          (key) => _HistorySection(
            title: _formatMonthLabel(key),
            workouts: buckets[key]!,
          ),
        )
        .toList(growable: false);
  }

  String _formatMonthLabel(String key) {
    final List<String> parts = key.split('-');
    final int year = int.parse(parts[0]);
    final int month = int.parse(parts[1]);
    const List<String> names = <String>[
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
    final DateTime now = DateTime.now();
    if (year == now.year) return names[month - 1];
    return '${names[month - 1]} $year';
  }
}

class _HistorySection {
  const _HistorySection({required this.title, required this.workouts});
  final String title;
  final List<Workout> workouts;
}

class _Header extends StatelessWidget {
  const _Header({required this.palette, required this.count});

  final JellyBeanPalette palette;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;
    final ThemeData theme = Theme.of(context);

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
              if (count != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: palette.shade100,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
          const SizedBox(height: 4),
          Text(
            'Every session you have logged, newest first.',
            style: TextStyle(
              color: palette.shade100.withValues(alpha: 0.85),
              fontSize: 13,
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.workout,
    required this.palette,
    required this.setCount,
    required this.onTap,
  });

  final Workout workout;
  final JellyBeanPalette palette;
  final int setCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime started = workout.startedAt.toLocal();
    final Duration duration = (workout.endedAt ?? DateTime.now()).difference(
      workout.startedAt,
    );
    final String? name = _cleaned(workout.name);
    // If the user named the session, make the name the primary line and
    // relegate the weekday/date to the sub-line alongside the time.
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette});

  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: AppSpacing.xl),
          Icon(Icons.history_rounded, size: 48, color: palette.shade400),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No workouts yet',
            style: TextStyle(
              color: palette.shade950,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Finish a session and it will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.shade800.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
