import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_range.g.dart';

/// How far back the training calendar heatmap looks. The default 12 weeks
/// fits comfortably in a single phone-width row of cells; the larger
/// options (26W / 52W) overflow horizontally and the heatmap auto-scrolls
/// with the most recent week pinned to the right.
enum CalendarRange {
  twelveWeeks(label: '12W', weeks: 12),
  twentySixWeeks(label: '26W', weeks: 26),
  fiftyTwoWeeks(label: '52W', weeks: 52);

  const CalendarRange({required this.label, required this.weeks});

  final String label;
  final int weeks;
}

/// Currently-selected window for the training calendar heatmap.
@Riverpod(keepAlive: true)
class CalendarRangeFilter extends _$CalendarRangeFilter {
  @override
  CalendarRange build() => CalendarRange.twelveWeeks;

  void set(CalendarRange next) => state = next;
}
