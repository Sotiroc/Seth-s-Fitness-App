import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/pr_event.dart';
import '../../../../data/models/unit_system.dart';
import '../../../../data/models/user_profile.dart';
import '../../../profile/application/user_profile_provider.dart';
import '../../application/pr_events_provider.dart';
import '../../application/strength_series_provider.dart';
import 'pr_row.dart';

/// Home-page slice of the personal-records feed: shows the [_visibleCount]
/// newest PRs and links to the full list when there are more. Both the
/// "PERSONAL RECORDS" section header and the bottom "See all" link
/// navigate to [PrListScreen] at `/progression/prs`.
///
/// Each row is the shared [PrRow] widget so the home card and full screen
/// look identical. Tapping a row pre-selects that exercise in the
/// strength chart card immediately below.
class PrFeedCard extends ConsumerWidget {
  const PrFeedCard({super.key});

  /// How many PRs the home-page card surfaces. The rest live in the full
  /// list screen reachable via the section header / "See all" link.
  static const int _visibleCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final AsyncValue<List<PrEvent>> async = ref.watch(allPrEventsProvider);
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
          _Header(palette: palette),
          const SizedBox(height: AppSpacing.md),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object e, StackTrace _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'Could not load PRs.\n$e',
                style: TextStyle(color: palette.shade700),
              ),
            ),
            data: (List<PrEvent> events) {
              if (events.isEmpty) return const PrEmptyState();
              final List<PrEvent> visible = events.length <= _visibleCount
                  ? events
                  : events.sublist(0, _visibleCount);
              final int hidden = events.length - visible.length;
              return Column(
                children: <Widget>[
                  for (int i = 0; i < visible.length; i++) ...<Widget>[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(height: 1, color: palette.shade100),
                      ),
                    PrRow(
                      event: visible[i],
                      unitSystem: unitSystem,
                      onTap: () => _selectExerciseInStrengthChart(
                        ref,
                        visible[i].exerciseId,
                      ),
                    ),
                  ],
                  if (hidden > 0) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    _SeeAllLink(palette: palette, totalCount: events.length),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static void _selectExerciseInStrengthChart(WidgetRef ref, String exerciseId) {
    ref.read(strengthExerciseSelectionProvider.notifier).select(exerciseId);
  }
}

/// Tappable section header. Trophy icon + "PERSONAL RECORDS" + chevron;
/// the whole row navigates to the full list.
class _Header extends StatelessWidget {
  const _Header({required this.palette});

  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/progression/prs'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFF59E0B),
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'PERSONAL RECORDS',
                style: TextStyle(
                  color: palette.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: palette.shade700,
            ),
          ],
        ),
      ),
    );
  }
}

/// "See all (N) →" link rendered below the visible rows when more PRs
/// exist than the home card surfaces.
class _SeeAllLink extends StatelessWidget {
  const _SeeAllLink({required this.palette, required this.totalCount});

  final JellyBeanPalette palette;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/progression/prs'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: 4,
        ),
        child: Row(
          children: <Widget>[
            Text(
              'See all $totalCount',
              style: TextStyle(
                color: palette.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: palette.shade700,
            ),
          ],
        ),
      ),
    );
  }
}
