import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../workouts/application/workout_stats_provider.dart';
import '../../application/calendar_range.dart';

/// GitHub-style training calendar: N columns (one per ISO week, where N
/// is the user-selected range), 7 rows (Mon → Sun). Cells tint by the
/// completed-set count for that day. The most recent week is always on
/// the right; today's cell highlights with a brand-teal stroke.
///
/// Range is picked via the segmented selector at the bottom of the card
/// (12W default / 26W / 52W). Cell sizing adapts to the parent constraints
/// — 12W fits naturally in a phone-width card, while 26W and 52W trigger
/// horizontal scrolling at a fixed cell size with auto-pin to the most
/// recent week so the user always lands on "now" first.
///
/// Reads from `dailyTrainingSetCountsProvider(weeks: ...)` so it ticks
/// live during a workout — the cell for today brightens as sets complete.
class TrainingCalendarHeatmap extends ConsumerWidget {
  const TrainingCalendarHeatmap({super.key});

  static const int daysPerWeek = 7;
  static const double cellGap = 4;
  static const double dayLabelGap = 4;
  static const double dayLabelColumnWidth = 14;
  static const double maxCellSize = 26;
  static const double minCellSize = 12;
  static const double scrollFallbackCellSize = 16;
  static const double monthRowHeight = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final CalendarRange range = ref.watch(calendarRangeFilterProvider);
    final AsyncValue<Map<DateTime, int>> async = ref.watch(
      dailyTrainingSetCountsProvider(weeks: range.weeks),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  'TRAINING CALENDAR',
                  style: TextStyle(
                    color: palette.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              _RangeDropdown(
                palette: palette,
                selected: range,
                onChanged: (CalendarRange r) =>
                    ref.read(calendarRangeFilterProvider.notifier).set(r),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          async.when(
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object e, StackTrace _) => SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'Could not load training calendar.\n$e',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.shade700),
                ),
              ),
            ),
            data: (Map<DateTime, int> counts) => _CalendarBody(
              palette: palette,
              counts: counts,
              weeks: range.weeks,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Legend(palette: palette),
        ],
      ),
    );
  }
}

/// Owns the [ScrollController] for the (sometimes-scrollable) grid so we
/// can auto-pin to the most recent week on first render and whenever the
/// user changes range. Stateful for that lifecycle alone — the actual
/// drawing is in stateless children.
class _CalendarBody extends StatefulWidget {
  const _CalendarBody({
    required this.palette,
    required this.counts,
    required this.weeks,
  });

  final JellyBeanPalette palette;
  final Map<DateTime, int> counts;
  final int weeks;

  @override
  State<_CalendarBody> createState() => _CalendarBodyState();
}

class _CalendarBodyState extends State<_CalendarBody> {
  final ScrollController _scrollController = ScrollController();

  /// Tracks the `weeks` value we last auto-scrolled for so we don't fight
  /// the user's manual scroll position on every rebuild — only the first
  /// render of a given range triggers an auto-pin.
  int? _autoScrolledWeeks;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_CalendarBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeks != widget.weeks) {
      _autoScrolledWeeks = null;
    }
  }

  void _maybeAutoScroll() {
    if (_autoScrolledWeeks == widget.weeks) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      if (!_scrollController.position.hasContentDimensions) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      _autoScrolledWeeks = widget.weeks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints constraints) {
        final double available = constraints.maxWidth -
            TrainingCalendarHeatmap.dayLabelColumnWidth -
            TrainingCalendarHeatmap.dayLabelGap;
        final double natural = (available -
                TrainingCalendarHeatmap.cellGap * (widget.weeks - 1)) /
            widget.weeks;
        final bool useScroll =
            natural < TrainingCalendarHeatmap.minCellSize;
        final double cellSize = useScroll
            ? TrainingCalendarHeatmap.scrollFallbackCellSize
            : natural.clamp(
                TrainingCalendarHeatmap.minCellSize,
                TrainingCalendarHeatmap.maxCellSize,
              );

        if (useScroll) _maybeAutoScroll();

        final Widget grid = _GridContent(
          palette: widget.palette,
          counts: widget.counts,
          cellSize: cellSize,
          weeks: widget.weeks,
        );

        // Day labels sit on the left of the grid. When the grid fits
        // naturally (no scrolling), we wrap the whole [labels][gap][grid]
        // group in `Center` so it doesn't pin to the left edge on wider
        // viewports. When scrolling, the grid takes Expanded so the
        // SingleChildScrollView gets a bounded width and the labels stay
        // pinned to the left of the visible viewport.
        if (useScroll) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DayLabelsColumn(palette: widget.palette, cellSize: cellSize),
              const SizedBox(width: TrainingCalendarHeatmap.dayLabelGap),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: grid,
                ),
              ),
            ],
          );
        }
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DayLabelsColumn(palette: widget.palette, cellSize: cellSize),
              const SizedBox(width: TrainingCalendarHeatmap.dayLabelGap),
              grid,
            ],
          ),
        );
      },
    );
  }
}

class _DayLabelsColumn extends StatelessWidget {
  const _DayLabelsColumn({required this.palette, required this.cellSize});

  final JellyBeanPalette palette;
  final double cellSize;

  // Mon → Sun. All seven labels render so each row is identifiable, not
  // just every other row. Duplicate letters (T/T, S/S) are unavoidable
  // with single-character abbreviations and match the convention used by
  // most fitness apps.
  static const List<String> _dayLabels = <String>[
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Match the month-row height + gap so the labels align with the
      // first day-row inside the grid.
      padding: const EdgeInsets.only(
        top: TrainingCalendarHeatmap.monthRowHeight +
            TrainingCalendarHeatmap.cellGap,
      ),
      child: SizedBox(
        width: TrainingCalendarHeatmap.dayLabelColumnWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int day = 0;
                day < TrainingCalendarHeatmap.daysPerWeek;
                day++)
              SizedBox(
                height: cellSize + TrainingCalendarHeatmap.cellGap,
                child: Text(
                  _dayLabels[day],
                  style: TextStyle(
                    color: palette.shade700,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GridContent extends StatelessWidget {
  const _GridContent({
    required this.palette,
    required this.counts,
    required this.cellSize,
    required this.weeks,
  });

  final JellyBeanPalette palette;
  final Map<DateTime, int> counts;
  final double cellSize;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final DateTime today = _localMidnight(DateTime.now());
    // Anchor: Monday of the most recent week so the rightmost column
    // contains today (and pre-fills future days with empty cells).
    final DateTime thisMonday = today.subtract(
      Duration(days: today.weekday - 1),
    );
    final List<DateTime> weekStarts = <DateTime>[
      for (int i = weeks - 1; i >= 0; i--)
        thisMonday.subtract(Duration(days: i * 7)),
    ];
    // Find the highest count to scale the colour ramp dynamically — a
    // user with high-volume sessions still gets the full gradient range,
    // a beginner doesn't have every cell saturate at the top step.
    final int maxCount = counts.values.fold<int>(
      0,
      (int a, int b) => a > b ? a : b,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _MonthRow(
          palette: palette,
          weekStarts: weekStarts,
          cellSize: cellSize,
        ),
        const SizedBox(height: TrainingCalendarHeatmap.cellGap),
        for (int day = 0;
            day < TrainingCalendarHeatmap.daysPerWeek;
            day++)
          Padding(
            padding: const EdgeInsets.only(
              bottom: TrainingCalendarHeatmap.cellGap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int week = 0; week < weekStarts.length; week++) ...<Widget>[
                  if (week > 0)
                    const SizedBox(width: TrainingCalendarHeatmap.cellGap),
                  _Cell(
                    palette: palette,
                    size: cellSize,
                    date: weekStarts[week].add(Duration(days: day)),
                    today: today,
                    count: counts[weekStarts[week].add(Duration(days: day))] ??
                        0,
                    maxCount: maxCount,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  static DateTime _localMidnight(DateTime instant) {
    final DateTime local = instant.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({
    required this.palette,
    required this.weekStarts,
    required this.cellSize,
  });

  final JellyBeanPalette palette;
  final List<DateTime> weekStarts;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final DateFormat fmt = DateFormat.MMM();
    final List<Widget> children = <Widget>[];
    int? lastMonth;
    for (int i = 0; i < weekStarts.length; i++) {
      if (i > 0) {
        children.add(const SizedBox(width: TrainingCalendarHeatmap.cellGap));
      }
      final DateTime weekStart = weekStarts[i];
      final bool newMonth = weekStart.month != lastMonth;
      lastMonth = weekStart.month;
      children.add(
        SizedBox(
          width: cellSize,
          height: TrainingCalendarHeatmap.monthRowHeight,
          child: newMonth
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    fmt.format(weekStart),
                    style: TextStyle(
                      color: palette.shade700,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.palette,
    required this.size,
    required this.date,
    required this.today,
    required this.count,
    required this.maxCount,
  });

  final JellyBeanPalette palette;
  final double size;
  final DateTime date;
  final DateTime today;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final bool isFuture = date.isAfter(today);
    final bool isToday = date.isAtSameMomentAs(today);
    final Color fill = isFuture
        ? palette.shade50.withValues(alpha: 0.4)
        : _fillFor(count, maxCount);

    return Tooltip(
      message: _tooltipFor(date, count, isFuture),
      preferBelow: false,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(3),
          border: isToday
              ? Border.all(color: palette.shade700, width: 1.4)
              : Border.all(color: palette.shade100, width: 0.5),
        ),
      ),
    );
  }

  /// 4-step colour ramp from neutral → palette teal saturating with
  /// volume. `maxCount` is the brightest value in the visible window;
  /// using it scales the ramp so a beginner sees variety, not every cell
  /// stuck at the dimmest step.
  Color _fillFor(int count, int maxCount) {
    if (count == 0) return palette.shade50;
    if (maxCount <= 1) return palette.shade300;
    final double ratio = count / maxCount;
    if (ratio < 0.34) return palette.shade200;
    if (ratio < 0.67) return palette.shade400;
    return palette.shade600;
  }

  static String _tooltipFor(DateTime date, int count, bool isFuture) {
    final String dateLabel = DateFormat.yMMMd().format(date);
    if (isFuture) return dateLabel;
    if (count == 0) return '$dateLabel · no training';
    if (count == 1) return '$dateLabel · 1 set';
    return '$dateLabel · $count sets';
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.palette});

  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    final List<Color> swatches = <Color>[
      palette.shade50,
      palette.shade200,
      palette.shade400,
      palette.shade600,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Text(
          'Less',
          style: TextStyle(
            color: palette.shade700,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        for (int i = 0; i < swatches.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 3),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: swatches[i],
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: palette.shade100, width: 0.5),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Text(
          'More',
          style: TextStyle(
            color: palette.shade700,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Top-right range picker for the heatmap. Renders as a slim button
/// showing the current range ("12 weeks ▾"); tapping pops a menu with
/// the three options. Less screen real estate than a segmented control,
/// and keeps the card chrome tight.
class _RangeDropdown extends StatelessWidget {
  const _RangeDropdown({
    required this.palette,
    required this.selected,
    required this.onChanged,
  });

  final JellyBeanPalette palette;
  final CalendarRange selected;
  final ValueChanged<CalendarRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CalendarRange>(
      tooltip: 'Change range',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: onChanged,
      itemBuilder: (BuildContext _) => <PopupMenuEntry<CalendarRange>>[
        for (final CalendarRange r in CalendarRange.values)
          PopupMenuItem<CalendarRange>(
            value: r,
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 20,
                  child: r == selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: palette.shade700,
                        )
                      : null,
                ),
                Text(
                  '${r.weeks} weeks',
                  style: TextStyle(
                    color: palette.shade950,
                    fontWeight: r == selected
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: palette.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '${selected.weeks} weeks',
              style: TextStyle(
                color: palette.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: palette.shade700,
            ),
          ],
        ),
      ),
    );
  }
}
