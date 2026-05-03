import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/unit_conversions.dart';
import '../../../../data/models/unit_system.dart';
import '../../../../data/models/user_profile.dart';
import '../../../profile/application/user_profile_provider.dart';
import '../../../workouts/application/workout_stats_provider.dart';
import '../../application/pr_events_provider.dart';
import '../../application/weight_entries_provider.dart';

/// At-a-glance summary of the user's training momentum: 4 tiles surfacing
/// weekly streak, monthly PR count, weekly volume tonnage, and 30-day
/// body-weight delta. Each value is reactively wired so the strip ticks
/// live as the user logs sets / weight entries.
///
/// Layout adapts to the parent constraints:
///   • narrow phones (`maxWidth < 480`) → 2×2 grid so labels and values
///     have room to breathe instead of truncating in 4 cramped columns.
///   • wider screens (tablets, landscape) → single 1×4 row.
///
/// Tiles are visually consistent (white card, shade100 border, palette
/// accent icons) so the strip reads as one unit; each tile has its own
/// brand-tinted icon so the eye can scan them quickly.
class HeroStatsStrip extends ConsumerWidget {
  const HeroStatsStrip({super.key});

  /// Maximum width below which the strip switches to a 2×2 grid. Tuned so
  /// every common phone (iPhone SE @ 320 → iPhone Pro Max @ 430) lands in
  /// the grid mode while tablets in portrait/landscape still get the
  /// roomier 1×4 row.
  static const double _gridBreakpoint = 480;

  /// Inter-tile gap, used both horizontally and vertically.
  static const double _tileGap = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final UnitSystem unitSystem = ref
        .watch(userProfileProvider)
        .maybeWhen<UnitSystem>(
          data: (UserProfile? p) => p?.unitSystem ?? UnitSystem.metric,
          orElse: () => UnitSystem.metric,
        );

    final int streak = ref.watch(workoutStreakWeeksProvider).maybeWhen(
      data: (int v) => v,
      orElse: () => 0,
    );
    final int prCount = ref.watch(monthlyPrCountProvider).maybeWhen(
      data: (int v) => v,
      orElse: () => 0,
    );
    final double volumeKg = ref.watch(weeklyVolumeKgProvider).maybeWhen(
      data: (double v) => v,
      orElse: () => 0.0,
    );
    final WeightTrend trend = ref.watch(weightTrendProvider);

    final List<_StatTile> tiles = <_StatTile>[
      _StatTile(
        palette: palette,
        icon: Icons.local_fire_department_rounded,
        iconColor: const Color(0xFFEF4444),
        value: '$streak',
        label: 'WEEK STREAK',
        valueIsNumeric: true,
      ),
      _StatTile(
        palette: palette,
        icon: Icons.emoji_events_rounded,
        iconColor: const Color(0xFFF59E0B),
        value: '$prCount',
        label: 'PRS · MONTH',
        valueIsNumeric: true,
      ),
      _StatTile(
        palette: palette,
        icon: Icons.fitness_center_rounded,
        iconColor: palette.shade500,
        value: _formatVolume(volumeKg, unitSystem),
        label: 'VOLUME · WK',
        valueIsNumeric: true,
      ),
      _StatTile(
        palette: palette,
        icon: trend.deltaKg == null
            ? Icons.monitor_weight_outlined
            : (trend.deltaKg! < 0
                ? Icons.trending_down_rounded
                : (trend.deltaKg! > 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_flat_rounded)),
        iconColor: const Color(0xFF22C55E),
        value: _formatWeightDelta(trend, unitSystem),
        label: 'WEIGHT · 30D',
        valueIsNumeric: false,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints constraints) {
        if (constraints.maxWidth < _gridBreakpoint) {
          return Column(
            children: <Widget>[
              _TileRow(left: tiles[0], right: tiles[1]),
              const SizedBox(height: _tileGap),
              _TileRow(left: tiles[2], right: tiles[3]),
            ],
          );
        }
        return Row(
          children: <Widget>[
            for (int i = 0; i < tiles.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: _tileGap),
              Expanded(child: tiles[i]),
            ],
          ],
        );
      },
    );
  }

  static String _formatVolume(double kg, UnitSystem unit) {
    if (kg <= 0) return '0';
    final double display = unit == UnitSystem.metric
        ? kg
        : UnitConversions.kgToLb(kg);
    if (display >= 10000) return '${(display / 1000).round()}k';
    if (display >= 1000) return '${(display / 1000).toStringAsFixed(1)}k';
    return display.round().toString();
  }

  static String _formatWeightDelta(WeightTrend trend, UnitSystem unit) {
    if (!trend.hasComparison || trend.deltaKg == null) return '—';
    final double delta = trend.deltaKg!;
    if (delta.abs() < 0.05) return '0';
    final double displayAbs = unit == UnitSystem.metric
        ? delta.abs()
        : UnitConversions.kgToLb(delta.abs());
    final String sign = delta > 0 ? '+' : '−';
    final String number = displayAbs >= 10
        ? displayAbs.round().toString()
        : displayAbs.toStringAsFixed(1);
    return '$sign$number';
  }
}

class _TileRow extends StatelessWidget {
  const _TileRow({required this.left, required this.right});

  final _StatTile left;
  final _StatTile right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: left),
        const SizedBox(width: HeroStatsStrip._tileGap),
        Expanded(child: right),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.palette,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.valueIsNumeric,
  });

  final JellyBeanPalette palette;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool valueIsNumeric;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Down from 96 → 76: tighter strip without sacrificing legibility.
      // The 2×2 grid mode means each tile gets ~155px wide on a typical
      // phone, so labels and values now have plenty of horizontal room
      // even with a slightly smaller value font.
      height: 76,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.shade100),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      color: palette.shade950,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.0,
                      fontFeatures: valueIsNumeric
                          ? const <FontFeature>[FontFeature.tabularFigures()]
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.shade700,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
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
