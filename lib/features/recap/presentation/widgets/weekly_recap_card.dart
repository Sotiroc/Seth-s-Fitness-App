import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/unit_system.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../data/models/weekly_recap.dart';
import '../../../profile/application/user_profile_provider.dart';
import '../../application/weekly_recap_providers.dart';
import 'weekly_recap_share_button.dart';
import 'weekly_recap_visuals.dart';

/// Home-screen card surfacing the most recent generated [WeeklyRecap].
/// Renders nothing until the recap stream emits a non-null value, so the
/// card silently disappears for users who didn't train last week (per
/// spec: empty weeks get no placeholder).
///
/// The dark teal hero treatment matches the rest of the app — same
/// gradient palette as the Profile / Progression headers — and the
/// "calm, branded, not gamified" tone leaves out trophies, exclamation
/// marks, and motivational copy.
class WeeklyRecapCard extends ConsumerWidget {
  const WeeklyRecapCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<WeeklyRecap?> async = ref.watch(
      currentWeeklyRecapProvider,
    );
    final WeeklyRecap? recap = async.asData?.value;
    if (recap == null) return const SizedBox.shrink();

    final UserProfile? profile = ref
        .watch(userProfileProvider)
        .asData
        ?.value;
    final UnitSystem unitSystem = profile?.unitSystem ?? UnitSystem.metric;

    return WeeklyRecapShareableSurface(
      recap: recap,
      unitSystem: unitSystem,
      userName: profile?.name,
      orientation: WeeklyRecapOrientation.card,
      trailing: WeeklyRecapShareButton(
        recap: recap,
        unitSystem: unitSystem,
        userName: profile?.name,
      ),
    );
  }
}

/// Shared layout used both for the on-screen card and the off-screen
/// portrait render that produces the shareable PNG. The two surfaces
/// only differ in aspect ratio and padding — every data row is rendered
/// the same way so the export looks like a screenshot of the card.
class WeeklyRecapShareableSurface extends StatelessWidget {
  const WeeklyRecapShareableSurface({
    super.key,
    required this.recap,
    required this.unitSystem,
    required this.orientation,
    this.userName,
    this.trailing,
  });

  final WeeklyRecap recap;
  final UnitSystem unitSystem;
  final WeeklyRecapOrientation orientation;
  final String? userName;

  /// Action surface (typically the share button). Only rendered in
  /// [WeeklyRecapOrientation.card] mode — the exported PNG never shows
  /// app chrome.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final bool isPortrait = orientation == WeeklyRecapOrientation.portrait;
    final EdgeInsets padding = isPortrait
        ? const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl + AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl,
          )
        : const EdgeInsets.all(AppSpacing.lg);
    final BorderRadius radius = isPortrait
        ? BorderRadius.zero
        : BorderRadius.circular(20);
    final TextStyle smallCaps = TextStyle(
      color: palette.shade200,
      fontSize: isPortrait ? 12 : 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.6,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.shade950, palette.shade800, palette.shade600],
          stops: const <double>[0.0, 0.55, 1.0],
        ),
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('WEEKLY RECAP', style: smallCaps),
                        const SizedBox(height: 6),
                        Text(
                          _headerLine(recap),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isPortrait ? 26 : 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...<Widget>[
                    const SizedBox(width: AppSpacing.sm),
                    trailing!,
                  ],
                ],
              ),
              SizedBox(height: isPortrait ? AppSpacing.xl : AppSpacing.lg),
              _StatGrid(
                recap: recap,
                unitSystem: unitSystem,
                isPortrait: isPortrait,
                palette: palette,
              ),
              SizedBox(height: isPortrait ? AppSpacing.xl : AppSpacing.lg),
              _DailyVolumeChart(
                recap: recap,
                unitSystem: unitSystem,
                isPortrait: isPortrait,
                palette: palette,
              ),
              SizedBox(height: isPortrait ? AppSpacing.xl : AppSpacing.md),
              _PrList(
                recap: recap,
                unitSystem: unitSystem,
                isPortrait: isPortrait,
                palette: palette,
              ),
              if (_hasComparison(recap)) ...<Widget>[
                SizedBox(height: isPortrait ? AppSpacing.lg : AppSpacing.md),
                _ComparisonRow(
                  recap: recap,
                  unitSystem: unitSystem,
                  isPortrait: isPortrait,
                  palette: palette,
                ),
              ],
              if (isPortrait) ...<Widget>[
                const Spacer(),
                _Watermark(palette: palette, userName: userName),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum WeeklyRecapOrientation { card, portrait }

bool _hasComparison(WeeklyRecap recap) {
  return recap.prevWorkoutCount != null || recap.prevTotalVolumeKg != null;
}

String _headerLine(WeeklyRecap recap) {
  final DateTime startLocal = recap.weekStart.toLocal();
  // weekEnd is exclusive (Mon 00:00 of the next week) — the inclusive
  // last day shown to the user is the previous day (Sun).
  final DateTime endInclusive = recap.weekEnd
      .toLocal()
      .subtract(const Duration(days: 1));
  final DateFormat startFmt = startLocal.year == endInclusive.year
      ? DateFormat('MMM d')
      : DateFormat('MMM d, y');
  final DateFormat endFmt = startLocal.month == endInclusive.month
      ? DateFormat('d')
      : DateFormat('MMM d');
  return 'Week of ${startFmt.format(startLocal)} – '
      '${endFmt.format(endInclusive)}';
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.recap,
    required this.unitSystem,
    required this.isPortrait,
    required this.palette,
  });

  final WeeklyRecap recap;
  final UnitSystem unitSystem;
  final bool isPortrait;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    final List<({String label, String value})> stats =
        <({String label, String value})>[
          (
            label: 'Workouts',
            value: recap.workoutCount.toString(),
          ),
          (
            label: 'Volume',
            value: WeeklyRecapVisuals.formatVolume(
              recap.totalVolumeKg,
              unitSystem,
            ),
          ),
          (
            label: 'Time',
            value: WeeklyRecapVisuals.formatDuration(
              recap.totalDurationSeconds,
            ),
          ),
          (
            label: 'Avg RPE',
            value: recap.averageRpe == null
                ? '—'
                : recap.averageRpe!.toStringAsFixed(1),
          ),
        ];
    final double labelSize = isPortrait ? 12 : 11;
    final double valueSize = isPortrait ? 30 : 22;

    return Row(
      children: <Widget>[
        for (int i = 0; i < stats.length; i++) ...<Widget>[
          if (i > 0)
            Container(
              width: 1,
              height: isPortrait ? 56 : 40,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isPortrait ? AppSpacing.sm : AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    stats[i].value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: valueSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stats[i].label.toUpperCase(),
                    style: TextStyle(
                      color: palette.shade200,
                      fontSize: labelSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DailyVolumeChart extends StatelessWidget {
  const _DailyVolumeChart({
    required this.recap,
    required this.unitSystem,
    required this.isPortrait,
    required this.palette,
  });

  final WeeklyRecap recap;
  final UnitSystem unitSystem;
  final bool isPortrait;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    final double height = isPortrait ? 140 : 80;
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: WeeklyRecapDailyVolumePainter(
          dailyVolumeKg: recap.dailyVolumeKg,
          lineColor: Colors.white,
          fillColor: palette.shade300.withValues(alpha: 0.35),
          dotColor: palette.shade100,
          gridColor: Colors.white.withValues(alpha: 0.08),
          labelColor: palette.shade200,
          labelSize: isPortrait ? 11 : 10,
        ),
      ),
    );
  }
}

class _PrList extends StatelessWidget {
  const _PrList({
    required this.recap,
    required this.unitSystem,
    required this.isPortrait,
    required this.palette,
  });

  final WeeklyRecap recap;
  final UnitSystem unitSystem;
  final bool isPortrait;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    final TextStyle headerStyle = TextStyle(
      color: palette.shade200,
      fontSize: isPortrait ? 12 : 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.4,
    );
    if (recap.prs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('PRS', style: headerStyle),
          const SizedBox(height: 6),
          Text(
            'No new records this week.',
            style: TextStyle(
              color: palette.shade100.withValues(alpha: 0.85),
              fontSize: isPortrait ? 15 : 13,
              height: 1.4,
            ),
          ),
        ],
      );
    }
    // Cap the visible list so the card doesn't run off-screen on tiny
    // viewports. The portrait export always shows the full set.
    const int maxOnCard = 4;
    final List<WeeklyRecapPr> visible = isPortrait || recap.prs.length <= maxOnCard
        ? recap.prs
        : recap.prs.sublist(0, maxOnCard);
    final int hidden = recap.prs.length - visible.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${recap.prs.length} ${recap.prs.length == 1 ? "PR" : "PRs"}',
          style: headerStyle,
        ),
        const SizedBox(height: 6),
        for (final WeeklyRecapPr pr in visible)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              WeeklyRecapVisuals.formatPr(pr, unitSystem),
              style: TextStyle(
                color: Colors.white,
                fontSize: isPortrait ? 16 : 14,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        if (hidden > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '+$hidden more',
              style: TextStyle(
                color: palette.shade200,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.recap,
    required this.unitSystem,
    required this.isPortrait,
    required this.palette,
  });

  final WeeklyRecap recap;
  final UnitSystem unitSystem;
  final bool isPortrait;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    final List<String> parts = <String>[];
    final String? volume = WeeklyRecapVisuals.formatVolumeDelta(
      current: recap.totalVolumeKg,
      previous: recap.prevTotalVolumeKg,
    );
    if (volume != null) parts.add(volume);
    final String? workouts = WeeklyRecapVisuals.formatWorkoutDelta(
      current: recap.workoutCount,
      previous: recap.prevWorkoutCount,
    );
    if (workouts != null) parts.add(workouts);
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      'vs last week:  ${parts.join("   ·   ")}',
      style: TextStyle(
        color: palette.shade100.withValues(alpha: 0.95),
        fontSize: isPortrait ? 14 : 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _Watermark extends StatelessWidget {
  const _Watermark({required this.palette, required this.userName});

  final JellyBeanPalette palette;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final String? trimmedName = userName?.trim();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        if (trimmedName != null && trimmedName.isNotEmpty)
          Text(
            trimmedName,
            style: TextStyle(
              color: palette.shade100.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          )
        else
          const SizedBox.shrink(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.favorite_rounded,
              color: palette.shade300,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'Fitness App',
              style: TextStyle(
                color: palette.shade200,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
