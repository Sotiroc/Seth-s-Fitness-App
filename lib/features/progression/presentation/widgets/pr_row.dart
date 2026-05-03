import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/unit_conversions.dart';
import '../../../../data/models/pr_event.dart';
import '../../../../data/models/unit_system.dart';

/// One PR entry: exercise name (top), source set + relative date (bottom),
/// and the estimated 1RM right-aligned. Tapping invokes [onTap] — the
/// home-page card uses it to drill into the strength chart, the full PR
/// list screen uses it the same way.
///
/// Shared between the home-page [PrFeedCard] (top 5) and [PrListScreen]
/// (full list) so both views show identical row chrome.
class PrRow extends StatelessWidget {
  const PrRow({
    super.key,
    required this.event,
    required this.unitSystem,
    required this.onTap,
  });

  final PrEvent event;
  final UnitSystem unitSystem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final String oneRm =
        UnitConversions.formatWeight(event.oneRepMaxKg, unitSystem) ?? '';
    final String setLabel = UnitConversions.formatWeight(
          event.weightKg,
          unitSystem,
        ) ??
        '';
    final String relative = _relativeDate(event.achievedAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    event.exerciseName,
                    style: TextStyle(
                      color: palette.shade950,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$setLabel × ${event.reps} · $relative',
                    style: TextStyle(
                      color: palette.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  oneRm,
                  style: TextStyle(
                    color: palette.shade950,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                Text(
                  'est 1RM',
                  style: TextStyle(
                    color: palette.shade700,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "today", "yesterday", "3d ago", "Mar 14" — human-readable date for
  /// the row's secondary line. Switches to absolute date for entries
  /// older than a week so the relative phrasing doesn't get awkward.
  static String _relativeDate(DateTime achievedAt) {
    final DateTime now = DateTime.now();
    final DateTime localAchieved = achievedAt.toLocal();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime achievedDay = DateTime(
      localAchieved.year,
      localAchieved.month,
      localAchieved.day,
    );
    final int daysAgo = today.difference(achievedDay).inDays;
    if (daysAgo == 0) return 'today';
    if (daysAgo == 1) return 'yesterday';
    if (daysAgo < 7) return '${daysAgo}d ago';
    return DateFormat.yMMMd().format(localAchieved);
  }
}

/// Shared empty state for both the home-page card and the full list. A
/// trophy outline + friendly nudge to log a weighted set.
class PrEmptyState extends StatelessWidget {
  const PrEmptyState({super.key, this.padded = true});

  /// Whether to wrap the content in vertical padding. The home card adds
  /// its own padding; the full screen uses the padded version so the
  /// empty state isn't flush against the AppBar.
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final Widget content = Column(
      children: <Widget>[
        Icon(
          Icons.emoji_events_outlined,
          size: 48,
          color: palette.shade300,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'No PRs yet',
          style: TextStyle(
            color: palette.shade950,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Log a weighted set with reps and we\'ll celebrate your records here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ],
    );
    if (!padded) return content;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: content,
    );
  }
}
