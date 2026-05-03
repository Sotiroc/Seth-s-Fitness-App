import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/unit_conversions.dart';
import '../../../../data/models/unit_system.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../data/models/weight_entry.dart';
import '../../../progression/application/weight_entries_provider.dart';
import '../../../progression/presentation/widgets/log_weight_sheet.dart';
import '../../application/user_profile_provider.dart';

/// Profile-screen weight surface. Replaces the static "Weight" [StatTile]
/// with a richer, tappable card that ties the user's profile weight to
/// the body-weight log on the Progression tab:
///
/// - Headline value comes from the latest log entry (with [profile.weightKg]
///   as a fallback during the first frame after startup, before the stream
///   has emitted).
/// - "Logged today / N days ago" caption derived from `latest.measuredAt`
///   in the device's local time so users can tell at a glance how fresh
///   their data is.
/// - Trend chip (`↑/↓ X.X kg vs 30 days ago`) shown only when [WeightTrend]
///   reports `hasComparison`.
/// - Tapping anywhere on the card opens the same `showLogWeightSheet` used
///   from the Progression page, so users never have to leave the Profile
///   screen to log a fresh measurement.
class WeightCard extends ConsumerWidget {
  const WeightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final UserProfile? profile = ref.watch(userProfileProvider).asData?.value;
    final WeightEntry? latest = ref
        .watch(latestWeightEntryProvider)
        .asData
        ?.value;
    final WeightTrend trend = ref.watch(weightTrendProvider);
    final UnitSystem unitSystem = profile?.unitSystem ?? UnitSystem.metric;

    // Prefer the log entry's value over `profile.weightKg`. With reverse
    // sync in place these match, but reading the entry directly future-
    // proofs the card against any drift and gives the empty state a clean
    // null check (no weight = no log entries AND no profile fallback).
    final double? displayKg = latest?.weightKg ?? profile?.weightKg;
    final bool hasValue = displayKg != null;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showLogWeightSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _HeaderRow(palette: palette),
            const SizedBox(height: AppSpacing.xs),
            if (hasValue)
              _ValueAndTrend(
                palette: palette,
                weightKg: displayKg,
                unitSystem: unitSystem,
                trend: trend,
              )
            else
              _EmptyValue(palette: palette),
            const SizedBox(height: AppSpacing.xxs),
            _RecencyLine(
              palette: palette,
              latest: latest,
              hasProfileFallback: profile?.weightKg != null,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.palette});

  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: palette.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.monitor_weight_outlined,
            size: 18,
            color: palette.shade700,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'WEIGHT',
            style: TextStyle(
              color: palette.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: palette.shade100,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.add_rounded, size: 14, color: palette.shade900),
              const SizedBox(width: 2),
              Text(
                'Log',
                style: TextStyle(
                  color: palette.shade900,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ValueAndTrend extends StatelessWidget {
  const _ValueAndTrend({
    required this.palette,
    required this.weightKg,
    required this.unitSystem,
    required this.trend,
  });

  final JellyBeanPalette palette;
  final double weightKg;
  final UnitSystem unitSystem;
  final WeightTrend trend;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            UnitConversions.formatWeight(weightKg, unitSystem) ?? '',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: palette.shade950,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          if (trend.hasComparison && trend.deltaKg != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _TrendChip(
                palette: palette,
                deltaKg: trend.deltaKg!,
                unitSystem: unitSystem,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({
    required this.palette,
    required this.deltaKg,
    required this.unitSystem,
  });

  final JellyBeanPalette palette;
  final double deltaKg;
  final UnitSystem unitSystem;

  @override
  Widget build(BuildContext context) {
    // Treat ±0.05 kg as "no change" so floating-point noise doesn't pick a
    // direction that wouldn't read as meaningful to the user.
    final bool flat = deltaKg.abs() < 0.05;
    final IconData icon;
    if (flat) {
      icon = Icons.remove_rounded;
    } else if (deltaKg < 0) {
      icon = Icons.arrow_downward_rounded;
    } else {
      icon = Icons.arrow_upward_rounded;
    }
    final String formatted =
        UnitConversions.formatWeight(deltaKg.abs(), unitSystem) ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: palette.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: palette.shade900),
          const SizedBox(width: 2),
          Text(
            flat ? 'flat 30d' : '$formatted · 30d',
            style: TextStyle(
              color: palette.shade900,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyValue extends StatelessWidget {
  const _EmptyValue({required this.palette});

  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Text(
        'Tap to log your first weight',
        style: TextStyle(
          color: palette.shade700,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _RecencyLine extends StatelessWidget {
  const _RecencyLine({
    required this.palette,
    required this.latest,
    required this.hasProfileFallback,
  });

  final JellyBeanPalette palette;
  final WeightEntry? latest;
  final bool hasProfileFallback;

  @override
  Widget build(BuildContext context) {
    final String text = _captionText();
    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Text(
        text,
        style: TextStyle(
          color: palette.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _captionText() {
    if (latest == null) {
      // Profile-only fallback (the user filled in weight via the form before
      // any log entry existed). Tapping the card still opens the log sheet
      // so the next save creates a real entry and bumps recency forward.
      return hasProfileFallback ? 'No log entries yet' : 'Tap to log';
    }
    final DateTime now = DateTime.now();
    final DateTime localMeasured = latest!.measuredAt.toLocal();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime measuredDay = DateTime(
      localMeasured.year,
      localMeasured.month,
      localMeasured.day,
    );
    final int daysAgo = today.difference(measuredDay).inDays;
    if (daysAgo <= 0) return 'Logged today';
    if (daysAgo == 1) return 'Logged yesterday';
    if (daysAgo < 7) return 'Logged $daysAgo days ago';
    return 'Logged on ${_monthShort(measuredDay.month)} ${measuredDay.day}';
  }

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _monthShort(int month) => _months[month - 1];
}
