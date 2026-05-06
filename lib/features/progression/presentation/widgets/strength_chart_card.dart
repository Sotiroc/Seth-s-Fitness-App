import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/unit_conversions.dart';
import '../../../../data/models/exercise.dart';
import '../../../../data/models/strength_point.dart';
import '../../../../data/models/unit_system.dart';
import '../../../../data/models/user_profile.dart';
import '../../../profile/application/user_profile_provider.dart';
import '../../application/chart_data_providers.dart';
import '../../application/progression_range.dart';
import '../../application/strength_series_provider.dart';
import 'exercise_picker_field.dart';
import 'progression_chart_empty_state.dart';
import 'range_dropdown.dart';

/// Per-exercise estimated 1RM card. The user picks one of their
/// "trackable" exercises (weighted, with at least one qualifying logged
/// set) and sees the best Epley-estimated 1RM per session over time.
class StrengthChartCard extends ConsumerWidget {
  const StrengthChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final AsyncValue<List<Exercise>> trackableAsync = ref.watch(
      trackableExercisesProvider,
    );
    final String? selectedId = ref.watch(strengthExerciseSelectionProvider);
    final ProgressionRange range = ref.watch(strengthRangeFilterProvider);
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
                  'ESTIMATED 1RM',
                  style: TextStyle(
                    color: palette.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              ProgressionRangeDropdown(
                selected: range,
                onChanged: (ProgressionRange r) => ref
                    .read(strengthRangeFilterProvider.notifier)
                    .set(r),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          trackableAsync.when(
            loading: () => const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object error, StackTrace _) => SizedBox(
              height: 240,
              child: Center(
                child: Text(
                  'Failed to load exercises.\n$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.shade700),
                ),
              ),
            ),
            data: (List<Exercise> trackable) {
              if (trackable.isEmpty) {
                return ProgressionChartEmptyState(
                  icon: Icons.fitness_center_outlined,
                  title: 'Log a weighted set first',
                  subtitle:
                      'Once you log a weighted exercise with reps, you\'ll see your strength progress here.',
                  ctaLabel: 'Start a workout',
                  onCta: () => context.go('/workouts'),
                );
              }
              return _PickerAndChart(
                palette: palette,
                trackable: trackable,
                selectedId: selectedId,
                range: range,
                unitSystem: unitSystem,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PickerAndChart extends ConsumerWidget {
  const _PickerAndChart({
    required this.palette,
    required this.trackable,
    required this.selectedId,
    required this.range,
    required this.unitSystem,
  });

  final JellyBeanPalette palette;
  final List<Exercise> trackable;
  final String? selectedId;
  final ProgressionRange range;
  final UnitSystem unitSystem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Precompute name lookup once per build instead of walking the
    // `trackable` list inside `_nameFor` on every rebuild. Cheap on small
    // lists, but lifts the cost out of the per-frame profile traces.
    final Map<String, String> namesById = <String, String>{
      for (final Exercise e in trackable) e.id: e.name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ExercisePickerField(
          options: trackable,
          selectedId: selectedId,
          onSelect: (String? id) =>
              ref.read(strengthExerciseSelectionProvider.notifier).select(id),
        ),
        const SizedBox(height: AppSpacing.md),
        if (selectedId == null)
          const ProgressionChartEmptyState(
            icon: Icons.show_chart_rounded,
            title: 'Pick an exercise',
            subtitle: 'Choose one of your weighted exercises to see its trend.',
          )
        else
          _SelectedExerciseChart(
            palette: palette,
            exerciseId: selectedId!,
            exerciseName: namesById[selectedId!] ?? 'Exercise',
            range: range,
            unitSystem: unitSystem,
          ),
      ],
    );
  }
}

class _SelectedExerciseChart extends ConsumerWidget {
  const _SelectedExerciseChart({
    required this.palette,
    required this.exerciseId,
    required this.exerciseName,
    required this.range,
    required this.unitSystem,
  });

  final JellyBeanPalette palette;
  final String exerciseId;
  final String exerciseName;
  final ProgressionRange range;
  final UnitSystem unitSystem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<StrengthPoint>> filtered = ref.watch(
      filteredExerciseStrengthSeriesProvider(exerciseId),
    );
    final AsyncValue<List<StrengthPoint>> all = ref.watch(
      exerciseStrengthSeriesProvider(exerciseId),
    );

    return all.when(
      loading: () => const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace _) => SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Failed to load history.\n$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.shade700),
          ),
        ),
      ),
      data: (List<StrengthPoint> allPoints) {
        if (allPoints.isEmpty) {
          return ProgressionChartEmptyState(
            icon: Icons.fitness_center_outlined,
            title: 'No completed sets yet for $exerciseName',
            subtitle:
                'Log a set with weight and reps in your next workout to see it appear here.',
          );
        }

        // Pre-computed once per (filtered points, range, unit-system)
        // change rather than on every rebuild.
        final StrengthChartData? chartData = ref.watch(
          strengthChartDataProvider(exerciseId),
        );
        final bool hasRangePoints = filtered.maybeWhen<bool>(
          data: (List<StrengthPoint> e) => e.isNotEmpty,
          orElse: () => false,
        );
        final List<StrengthPoint> rangePoints =
            filtered.maybeWhen<List<StrengthPoint>>(
              data: (List<StrengthPoint> e) => e,
              orElse: () => const <StrengthPoint>[],
            );

        // Headline figure: best 1RM ever (across the unfiltered series).
        final StrengthPoint best = allPoints.reduce(
          (StrengthPoint a, StrengthPoint b) =>
              a.oneRepMaxKg >= b.oneRepMaxKg ? a : b,
        );
        final String bestLabel =
            UnitConversions.formatWeight(best.oneRepMaxKg, unitSystem) ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              exerciseName,
              style: theme.textTheme.titleMedium?.copyWith(
                color: palette.shade950,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  bestLabel,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: palette.shade950,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'best 1RM',
                    style: TextStyle(
                      color: palette.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 220,
              child: !hasRangePoints || chartData == null
                  ? ProgressionChartEmptyState(
                      icon: Icons.timeline_rounded,
                      title: 'No sets in this range',
                      subtitle:
                          'Try a longer time window to see your full history.',
                      ctaLabel: 'Show all',
                      onCta: () => ref
                          .read(strengthRangeFilterProvider.notifier)
                          .set(ProgressionRange.all),
                    )
                  : _StrengthLineChart(
                      palette: palette,
                      data: chartData,
                      points: rangePoints,
                      unitSystem: unitSystem,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _StrengthLineChart extends StatelessWidget {
  const _StrengthLineChart({
    required this.palette,
    required this.data,
    required this.points,
    required this.unitSystem,
  });

  final JellyBeanPalette palette;
  final StrengthChartData data;
  final List<StrengthPoint> points;
  final UnitSystem unitSystem;

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> spots = data.spots;
    final double minX = data.minX;
    final double maxX = data.maxX;
    final double yMin = data.minY;
    final double yMax = data.maxY;
    final DateFormat dateFmt = data.dateFormat;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: yMin,
        maxY: yMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((yMax - yMin) / 3).clamp(1.0, double.infinity),
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
              interval: ((yMax - yMin) / 3).clamp(1.0, double.infinity),
              getTitlesWidget: (double value, TitleMeta meta) {
                // Edge ticks crowd the chart border; skip them.
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
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
              // Bias toward more ticks so the first and last dates are
              // both reachable; fitInside keeps them from overflowing.
              interval: ((maxX - minX) / 4).clamp(1, double.infinity),
              getTitlesWidget: (double value, TitleMeta meta) {
                final DateTime d = _dateFor(value);
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
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
                final StrengthPoint p = points[spot.spotIndex];
                final String dateLabel = DateFormat.yMMMd().format(
                  p.date.toLocal(),
                );
                final String oneRm =
                    UnitConversions.formatWeight(p.oneRepMaxKg, unitSystem) ??
                        '';
                final String setWeight = UnitConversions.formatWeight(
                      p.bestSetWeightKg,
                      unitSystem,
                    ) ??
                    '';
                return LineTooltipItem(
                  '$dateLabel\nest 1RM $oneRm\n$setWeight × ${p.bestSetReps}',
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

  static DateTime _dateFor(double daysSinceEpoch) {
    final int ms = (daysSinceEpoch * Duration.millisecondsPerDay).round();
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }
}
