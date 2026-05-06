import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/pr_event.dart';
import '../../../../data/models/unit_system.dart';
import 'pr_event_formatting.dart';

/// One PR entry in a vertical feed: trophy + exercise name + PR value
/// + type label + relative date. Tapping invokes [onTap] — the
/// home-page card uses it to drill into the strength chart, the full
/// list and the History flat-PR mode use it for navigation.
///
/// Shared between the home-page [PrFeedCard] (top 5), [PrListScreen]
/// (full list), and the History flat-PR list mode so all surfaces show
/// the same row chrome.
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
    final String value = PrEventFormatting.value(event, unitSystem);
    final String typeLabel = PrEventFormatting.typeLabel(event);
    final String relative = PrEventFormatting.relativeDate(event.achievedAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFF59E0B),
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$typeLabel · $relative',
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
            Text(
              value,
              style: TextStyle(
                color: palette.shade950,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared empty state for both the home-page card and the full list. A
/// trophy outline + friendly nudge to log a first set.
class PrEmptyState extends StatelessWidget {
  const PrEmptyState({super.key, this.padded = true});

  /// Whether to wrap the content in vertical padding. The home card
  /// adds its own padding; the full screen uses the padded version so
  /// the empty state isn't flush against the AppBar.
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
          'Finish a workout and we\'ll celebrate your records here.',
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
