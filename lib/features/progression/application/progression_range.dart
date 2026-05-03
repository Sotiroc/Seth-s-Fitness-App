import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'progression_range.g.dart';

/// Time-window options for the body-weight and strength charts. Both
/// charts share the same set of options but each has its own selection
/// notifier so the user can scope them independently.
enum ProgressionRange {
  oneMonth(label: '1M'),
  threeMonths(label: '3M'),
  sixMonths(label: '6M'),
  oneYear(label: '1Y'),
  all(label: 'All');

  const ProgressionRange({required this.label});

  /// Short label rendered inside the segmented control.
  final String label;

  /// Window length, or `null` for "All" (no lower bound).
  Duration? get window {
    switch (this) {
      case ProgressionRange.oneMonth:
        return const Duration(days: 30);
      case ProgressionRange.threeMonths:
        return const Duration(days: 91);
      case ProgressionRange.sixMonths:
        return const Duration(days: 182);
      case ProgressionRange.oneYear:
        return const Duration(days: 365);
      case ProgressionRange.all:
        return null;
    }
  }

  /// Cutoff timestamp for filtering — entries with `measuredAt < cutoff`
  /// are excluded. Returns `null` for "All".
  DateTime? cutoffFrom(DateTime now) {
    final Duration? w = window;
    if (w == null) return null;
    return now.subtract(w);
  }
}

/// Currently-selected window for the body-weight chart. Defaults to 3M
/// — long enough to show a meaningful trend, short enough that the line
/// has texture rather than looking like a flat year-overview.
@Riverpod(keepAlive: true)
class BodyWeightRangeFilter extends _$BodyWeightRangeFilter {
  @override
  ProgressionRange build() => ProgressionRange.threeMonths;

  void set(ProgressionRange next) => state = next;
}

/// Currently-selected window for the per-exercise strength chart.
@Riverpod(keepAlive: true)
class StrengthRangeFilter extends _$StrengthRangeFilter {
  @override
  ProgressionRange build() => ProgressionRange.threeMonths;

  void set(ProgressionRange next) => state = next;
}
