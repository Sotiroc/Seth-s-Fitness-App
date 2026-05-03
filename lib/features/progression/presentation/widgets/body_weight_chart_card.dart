import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/unit_conversions.dart';
import '../../../../data/models/unit_system.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../data/models/weight_entry.dart';
import '../../../profile/application/user_profile_provider.dart';
import '../../application/progression_range.dart';
import '../../application/weight_entries_provider.dart';
import 'progression_chart_empty_state.dart';
import 'range_selector.dart';

/// Top card on the Progression screen: latest body-weight headline,
/// delta-since-range-start figure, line chart, and the range selector.
class BodyWeightChartCard extends ConsumerWidget {
  const BodyWeightChartCard({super.key, required this.onLogWeight});

  /// Callback fired by the inline "Log" button — wired up by the screen
  /// to the same sheet the floating action button opens.
  final VoidCallback onLogWeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final AsyncValue<List<WeightEntry>> filtered = ref.watch(
      filteredWeightEntriesProvider,
    );
    final AsyncValue<List<WeightEntry>> all = ref.watch(weightEntriesProvider);
    final ProgressionRange range = ref.watch(bodyWeightRangeFilterProvider);
    final UnitSystem unitSystem = ref
        .watch(userProfileProvider)
        .maybeWhen<UnitSystem>(
          data: (UserProfile? p) => p?.unitSystem ?? UnitSystem.metric,
          orElse: () => UnitSystem.metric,
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
            children: <Widget>[
              Expanded(
                child: Text(
                  'BODY WEIGHT',
                  style: TextStyle(
                    color: palette.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              IconButton(
                onPressed: onLogWeight,
                icon: Icon(Icons.add_rounded, color: palette.shade900),
                tooltip: 'Log weight',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          all.when(
            loading: () => const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object error, StackTrace _) => SizedBox(
              height: 240,
              child: Center(
                child: Text(
                  'Failed to load weight history.\n$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.shade700),
                ),
              ),
            ),
            data: (List<WeightEntry> allEntries) {
              if (allEntries.isEmpty) {
                return const ProgressionChartEmptyState(
                  icon: Icons.monitor_weight_outlined,
                  title: 'No weight logged yet',
                  subtitle:
                      'Tap Log weight to start your timeline. We\'ll plot every entry here.',
                );
              }
              final List<WeightEntry> entries = filtered.maybeWhen<List<WeightEntry>>(
                data: (List<WeightEntry> e) => e,
                orElse: () => const <WeightEntry>[],
              );
              return _ChartBody(
                palette: palette,
                allEntries: allEntries,
                rangeEntries: entries,
                range: range,
                unitSystem: unitSystem,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: RangeSelector(
              selected: range,
              onChanged: (ProgressionRange r) => ref
                  .read(bodyWeightRangeFilterProvider.notifier)
                  .set(r),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBody extends StatelessWidget {
  const _ChartBody({
    required this.palette,
    required this.allEntries,
    required this.rangeEntries,
    required this.range,
    required this.unitSystem,
  });

  final JellyBeanPalette palette;
  final List<WeightEntry> allEntries;
  final List<WeightEntry> rangeEntries;
  final ProgressionRange range;
  final UnitSystem unitSystem;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WeightEntry latest = allEntries.last;
    final String latestLabel =
        UnitConversions.formatWeight(latest.weightKg, unitSystem) ?? '';
    final String delta = _formatDelta();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              latestLabel,
              style: theme.textTheme.displaySmall?.copyWith(
                color: palette.shade950,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (delta.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.shade100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    delta,
                    style: TextStyle(
                      color: palette.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 220,
          child: rangeEntries.isEmpty
              ? const ProgressionChartEmptyState(
                  icon: Icons.timeline_rounded,
                  title: 'No entries in this range',
                  subtitle:
                      'Switch the range below to see more of your timeline.',
                )
              : _LineChart(
                  palette: palette,
                  entries: rangeEntries,
                  range: range,
                  unitSystem: unitSystem,
                ),
        ),
      ],
    );
  }

  String _formatDelta() {
    if (rangeEntries.length < 2) return '';
    final WeightEntry first = rangeEntries.first;
    final WeightEntry last = rangeEntries.last;
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
}

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.palette,
    required this.entries,
    required this.range,
    required this.unitSystem,
  });

  final JellyBeanPalette palette;
  final List<WeightEntry> entries;
  final ProgressionRange range;
  final UnitSystem unitSystem;

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> spots = entries
        .map(
          (WeightEntry e) => FlSpot(
            _xFor(e.measuredAt),
            _displayValue(e.weightKg),
          ),
        )
        .toList(growable: false);

    final double minX = spots.first.x;
    final double maxX = spots.last.x == minX ? minX + 1 : spots.last.x;
    final double minY = spots.map((FlSpot s) => s.y).reduce(_min);
    final double maxY = spots.map((FlSpot s) => s.y).reduce(_max);
    final double yPadding = ((maxY - minY).abs() * 0.15).clamp(0.5, 5.0);
    final double yMin = minY - yPadding;
    final double yMax = maxY + yPadding;

    final DateFormat dateFmt = _dateFormatFor(range);

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: yMin,
        maxY: yMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((yMax - yMin) / 3).clamp(0.5, double.infinity),
          getDrawingHorizontalLine: (double _) =>
              FlLine(color: palette.shade100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: ((yMax - yMin) / 3).clamp(0.5, double.infinity),
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      color: palette.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: ((maxX - minX) / 3).clamp(1, double.infinity),
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                final DateTime d = _dateFor(value);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    dateFmt.format(d),
                    style: TextStyle(
                      color: palette.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (LineBarSpot _) => palette.shade950,
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipItems: (List<LineBarSpot> spots) {
              return spots.map((LineBarSpot spot) {
                final DateTime d = _dateFor(spot.x);
                final String dateLabel = DateFormat.yMMMd().format(d);
                final String value = '${spot.y.toStringAsFixed(1)} '
                    '${unitSystem.weightUnit}';
                return LineTooltipItem(
                  '$dateLabel\n$value',
                  TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: palette.shade500,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (FlSpot _, double _, LineChartBarData _, int _) {
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: palette.shade500,
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  palette.shade300.withValues(alpha: 0.45),
                  palette.shade300.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _displayValue(double kg) => unitSystem == UnitSystem.metric
      ? kg
      : UnitConversions.kgToLb(kg);

  static double _xFor(DateTime instant) =>
      instant.toUtc().millisecondsSinceEpoch / Duration.millisecondsPerDay;

  static DateTime _dateFor(double daysSinceEpoch) {
    final int ms = (daysSinceEpoch * Duration.millisecondsPerDay).round();
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }

  static double _min(double a, double b) => a < b ? a : b;
  static double _max(double a, double b) => a > b ? a : b;

  static DateFormat _dateFormatFor(ProgressionRange range) {
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
}
