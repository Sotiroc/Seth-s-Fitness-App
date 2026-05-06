import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/unit_conversions.dart';
import '../../../data/models/strength_point.dart';
import '../../../data/models/unit_system.dart';
import '../../../data/models/weight_entry.dart';
import '../../profile/application/user_profile_provider.dart';
import 'progression_range.dart';
import 'strength_series_provider.dart';
import 'weight_entries_provider.dart';

part 'chart_data_providers.g.dart';

/// Pre-computed chart inputs for the body-weight card: the daily-aggregated
/// FlSpot list, axis bounds, and the headline delta label. Derived once
/// per (entries, range, unit-system) change instead of on every widget
/// rebuild.
class BodyWeightChartData {
  const BodyWeightChartData({
    required this.spots,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.delta,
    required this.dateFormat,
  });

  final List<FlSpot> spots;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  /// "+1.2 kg in 3M", "Steady", or empty when there isn't enough data.
  final String delta;

  /// Formatter to use on bottom-axis tick labels.
  final DateFormat dateFormat;
}

/// Pre-computed chart inputs for the per-exercise strength card.
class StrengthChartData {
  const StrengthChartData({
    required this.spots,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.dateFormat,
  });

  final List<FlSpot> spots;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final DateFormat dateFormat;
}

/// Page-local — only mounted while the progression tab is in view.
/// Auto-disposes when the user navigates away; the underlying weight
/// entries provider is global, so revisiting the tab feels instant.
@riverpod
BodyWeightChartData? bodyWeightChartData(Ref ref) {
  final List<WeightEntry>? entries = ref
      .watch(filteredWeightEntriesProvider)
      .asData
      ?.value;
  final ProgressionRange range = ref.watch(bodyWeightRangeFilterProvider);
  final UnitSystem unitSystem =
      ref.watch(userProfileProvider).asData?.value?.unitSystem ??
      UnitSystem.metric;

  if (entries == null || entries.isEmpty) return null;
  final List<WeightEntry> daily = _aggregateByDay(entries);
  if (daily.isEmpty) return null;

  double displayValue(double kg) =>
      unitSystem == UnitSystem.metric ? kg : UnitConversions.kgToLb(kg);

  final List<FlSpot> spots = daily
      .map(
        (WeightEntry e) => FlSpot(
          _xFor(e.measuredAt),
          displayValue(e.weightKg),
        ),
      )
      .toList(growable: false);

  final double minX = spots.first.x;
  final double maxX = spots.last.x == minX ? minX + 1 : spots.last.x;
  final double minY = spots.map((FlSpot s) => s.y).reduce(_min);
  final double maxY = spots.map((FlSpot s) => s.y).reduce(_max);
  final double yPadding = ((maxY - minY).abs() * 0.15).clamp(0.5, 5.0);

  return BodyWeightChartData(
    spots: spots,
    minX: minX,
    maxX: maxX,
    minY: minY - yPadding,
    maxY: maxY + yPadding,
    delta: _formatBodyWeightDelta(daily, range, unitSystem),
    dateFormat: _dateFormatFor(range),
  );
}

/// Page-local strength chart inputs, auto-disposed alongside the
/// strength series provider it derives from.
@riverpod
StrengthChartData? strengthChartData(Ref ref, String exerciseId) {
  final List<StrengthPoint>? points = ref
      .watch(filteredExerciseStrengthSeriesProvider(exerciseId))
      .asData
      ?.value;
  final ProgressionRange range = ref.watch(strengthRangeFilterProvider);
  final UnitSystem unitSystem =
      ref.watch(userProfileProvider).asData?.value?.unitSystem ??
      UnitSystem.metric;

  if (points == null || points.isEmpty) return null;

  double displayValue(double kg) =>
      unitSystem == UnitSystem.metric ? kg : UnitConversions.kgToLb(kg);

  final List<FlSpot> spots = points
      .map(
        (StrengthPoint p) =>
            FlSpot(_xFor(p.date), displayValue(p.oneRepMaxKg)),
      )
      .toList(growable: false);

  final double minX = spots.first.x;
  final double maxX = spots.last.x == minX ? minX + 1 : spots.last.x;
  final double minY = spots.map((FlSpot s) => s.y).reduce(_min);
  final double maxY = spots.map((FlSpot s) => s.y).reduce(_max);
  final double yPadding = ((maxY - minY).abs() * 0.15).clamp(1.0, 10.0);

  return StrengthChartData(
    spots: spots,
    minX: minX,
    maxX: maxX,
    minY: minY - yPadding,
    maxY: maxY + yPadding,
    dateFormat: _dateFormatFor(range),
  );
}

double _xFor(DateTime instant) =>
    instant.toUtc().millisecondsSinceEpoch / Duration.millisecondsPerDay;

double _min(double a, double b) => a < b ? a : b;
double _max(double a, double b) => a > b ? a : b;

DateFormat _dateFormatFor(ProgressionRange range) {
  switch (range) {
    case ProgressionRange.oneMonth:
    case ProgressionRange.threeMonths:
      return DateFormat.MMMd();
    case ProgressionRange.sixMonths:
    case ProgressionRange.oneYear:
    case ProgressionRange.all:
      return DateFormat.MMM();
  }
}

/// One body-weight reading per local day — keep the latest entry of each
/// day so morning/evening duplicates don't render as wobbles on the chart.
List<WeightEntry> _aggregateByDay(List<WeightEntry> entries) {
  final Map<DateTime, WeightEntry> latestPerDay = <DateTime, WeightEntry>{};
  for (final WeightEntry e in entries) {
    final DateTime local = e.measuredAt.toLocal();
    final DateTime day = DateTime(local.year, local.month, local.day);
    final WeightEntry? existing = latestPerDay[day];
    if (existing == null || e.measuredAt.isAfter(existing.measuredAt)) {
      latestPerDay[day] = e;
    }
  }
  final List<WeightEntry> result = latestPerDay.values.toList();
  result.sort(
    (WeightEntry a, WeightEntry b) => a.measuredAt.compareTo(b.measuredAt),
  );
  return result;
}

String _formatBodyWeightDelta(
  List<WeightEntry> daily,
  ProgressionRange range,
  UnitSystem unitSystem,
) {
  if (daily.length < 2) return '';
  final WeightEntry first = daily.first;
  final WeightEntry last = daily.last;
  final double diffKg = last.weightKg - first.weightKg;
  if (diffKg.abs() < 0.05) return 'Steady';
  final String? formattedAbs = UnitConversions.formatWeight(
    diffKg.abs(),
    unitSystem,
  );
  if (formattedAbs == null) return '';
  final String sign = diffKg > 0 ? '+' : '−';
  return '$sign$formattedAbs in ${range.label}';
}
