import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/exercise_muscle_group.dart';
import '../../application/muscle_goals_provider.dart';
import '../../application/workout_stats_provider.dart';
import 'muscle_goals_sheet.dart';

/// Slim, always-visible strip showing weekly progress while the user is
/// mid-workout. All 8 muscle groups share the row evenly via [Expanded] —
/// no horizontal scrolling. Cardio is special-cased to show minutes
/// instead of a set fraction, since cardio progress is naturally measured
/// in time.
///
/// Tapping the bar opens [showMuscleGoalsSheet] for editing per-muscle
/// weekly targets — the strip itself already surfaces the live count, so
/// the tap takes the user straight to the only useful action (configure)
/// instead of through an intermediate "expanded view". Values tick up in
/// real time as sets are logged.
class WeeklyVolumeStripBar extends ConsumerWidget {
  const WeeklyVolumeStripBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final AsyncValue<Map<ExerciseMuscleGroup, int>> weeklyAsync = ref.watch(
      weeklyMuscleGroupSetsProvider,
    );
    final Map<ExerciseMuscleGroup, int> goals = ref.watch(muscleGoalsProvider);
    final int cardioMinutes = ref
        .watch(weeklyCardioMinutesProvider)
        .maybeWhen<int>(data: (int m) => m, orElse: () => 0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => showMuscleGoalsSheet(context),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.shade100),
          ),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: weeklyAsync.when(
              data: (Map<ExerciseMuscleGroup, int> counts) => _MusclePillRow(
                palette: palette,
                counts: counts,
                goals: goals,
                cardioMinutes: cardioMinutes,
              ),
              loading: () => _LoadingStrip(palette: palette),
              error: (Object _, _) => _ErrorStrip(palette: palette),
            ),
          ),
        ),
      ),
    );
  }
}

class _MusclePillRow extends StatelessWidget {
  const _MusclePillRow({
    required this.palette,
    required this.counts,
    required this.goals,
    required this.cardioMinutes,
  });

  final JellyBeanPalette palette;
  final Map<ExerciseMuscleGroup, int> counts;
  final Map<ExerciseMuscleGroup, int> goals;
  final int cardioMinutes;

  @override
  Widget build(BuildContext context) {
    // Stable enum order so the same pill is always in the same place.
    final List<ExerciseMuscleGroup> order = ExerciseMuscleGroup.values;
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < order.length; i++) {
      if (i > 0) {
        children.add(const SizedBox(width: 3));
      }
      final ExerciseMuscleGroup mg = order[i];
      children.add(
        Expanded(
          child: _MusclePill(
            palette: palette,
            label: _compactLabel(mg),
            count: counts[mg] ?? 0,
            goal: goals[mg] ?? 0,
            minutesOverride: mg == ExerciseMuscleGroup.cardio
                ? cardioMinutes
                : null,
          ),
        ),
      );
    }
    return Row(children: children);
  }

  /// Compact, gym-recognisable abbreviations so all 8 pills fit a single
  /// row without horizontal scrolling, even on narrow phones. The bottom
  /// sheet shows the full names.
  static String _compactLabel(ExerciseMuscleGroup mg) {
    switch (mg) {
      case ExerciseMuscleGroup.legs:
        return 'LEGS';
      case ExerciseMuscleGroup.biceps:
        return 'BIS';
      case ExerciseMuscleGroup.triceps:
        return 'TRIS';
      case ExerciseMuscleGroup.chest:
        return 'CHEST';
      case ExerciseMuscleGroup.back:
        return 'BACK';
      case ExerciseMuscleGroup.shoulders:
        return 'DELTS';
      case ExerciseMuscleGroup.abs:
        return 'ABS';
      case ExerciseMuscleGroup.cardio:
        return 'CARDIO';
    }
  }
}

class _MusclePill extends StatelessWidget {
  const _MusclePill({
    required this.palette,
    required this.label,
    required this.count,
    required this.goal,
    this.minutesOverride,
  });

  final JellyBeanPalette palette;
  final String label;
  final int count;
  final int goal;

  /// When set, renders `"$value min"` in place of the count/goal fraction.
  /// Used for the cardio pill — cardio progress is measured in time, not
  /// in sets, so the strip surfaces minutes instead.
  final int? minutesOverride;

  @override
  Widget build(BuildContext context) {
    final bool isMinutesMode = minutesOverride != null;
    final bool hasGoal = goal > 0;
    final double ratio = isMinutesMode || !hasGoal
        ? 0.0
        : (count / goal).clamp(0.0, 1.0);
    final bool hit = !isMinutesMode && hasGoal && count >= goal;

    // Hit pills use the brand hero gradient (shade950 → shade700) with white
    // text for a premium, on-brand "completed" cue. Non-hit pills stay
    // neutral and tint progressively toward shade300 as the user approaches
    // their weekly goal — same logic as WeeklyVolumeCard's _MuscleTile so
    // progress reads identically across both views.
    final Gradient? hitGradient = hit
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[palette.shade950, palette.shade700],
          )
        : null;
    final Color? background = hit
        ? null
        : Color.lerp(
                palette.shade50,
                palette.shade300.withValues(alpha: 0.5),
                ratio,
              ) ??
              palette.shade50;
    final Color borderColor = hit ? palette.shade900 : palette.shade100;
    final Color labelColor = hit
        ? Colors.white.withValues(alpha: 0.85)
        : palette.shade700;
    final Color valueColor = hit ? Colors.white : palette.shade950;
    final Color secondaryColor = hit
        ? Colors.white.withValues(alpha: 0.75)
        : palette.shade700;

    return Container(
      decoration: BoxDecoration(
        color: background,
        gradient: hitGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                height: 1.0,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: isMinutesMode
                ? _MinutesValue(
                    minutes: minutesOverride!,
                    foreground: valueColor,
                    suffixColor: secondaryColor,
                  )
                : _Fraction(
                    count: count,
                    goal: goal,
                    hasGoal: hasGoal,
                    foreground: valueColor,
                    goalColor: secondaryColor,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Fraction extends StatelessWidget {
  const _Fraction({
    required this.count,
    required this.goal,
    required this.hasGoal,
    required this.foreground,
    required this.goalColor,
  });

  final int count;
  final int goal;
  final bool hasGoal;
  final Color foreground;
  final Color goalColor;

  @override
  Widget build(BuildContext context) {
    if (!hasGoal) {
      return Text(
        '$count',
        style: TextStyle(
          color: foreground,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          height: 1.0,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      );
    }
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '$count',
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              height: 1.0,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(
            text: '/$goal',
            style: TextStyle(
              color: goalColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.0,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MinutesValue extends StatelessWidget {
  const _MinutesValue({
    required this.minutes,
    required this.foreground,
    required this.suffixColor,
  });

  final int minutes;
  final Color foreground;
  final Color suffixColor;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '$minutes',
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              height: 1.0,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(
            text: ' min',
            style: TextStyle(
              color: suffixColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingStrip extends StatelessWidget {
  const _LoadingStrip({required this.palette});

  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 14,
        width: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: palette.shade400,
        ),
      ),
    );
  }
}

class _ErrorStrip extends StatelessWidget {
  const _ErrorStrip({required this.palette});

  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Could not load weekly volume.',
        style: TextStyle(color: palette.shade700, fontSize: 11),
      ),
    );
  }
}

/// Sliver-persistent-header delegate that pins [WeeklyVolumeStripBar] flush
/// against the top of the active workout's scroll viewport. Min and max
/// extent are equal — there's no expand/collapse on scroll, just a fixed
/// chrome that stays visible.
class WeeklyVolumeStripHeaderDelegate extends SliverPersistentHeaderDelegate {
  WeeklyVolumeStripHeaderDelegate({required this.palette});

  final JellyBeanPalette palette;

  // 48 strip + 16 top + 4 bottom padding.
  static const double _height = 68;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: palette.shade50,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: const WeeklyVolumeStripBar(),
    );
  }

  @override
  bool shouldRebuild(WeeklyVolumeStripHeaderDelegate oldDelegate) =>
      oldDelegate.palette != palette;
}
