import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/pr_event.dart';
import '../../../data/models/unit_system.dart';
import '../../../data/models/user_profile.dart';
import '../../profile/application/user_profile_provider.dart';
import '../application/pr_events_provider.dart';
import '../application/strength_series_provider.dart';
import 'widgets/pr_row.dart';

/// Full list of every personal record the user has set. Reachable from
/// the "PERSONAL RECORDS" section header on the Progression page or the
/// "See all" link at the bottom of the home-page PR feed card.
///
/// Tapping a row pre-selects that exercise in the strength chart and
/// pops back to Progression so the user lands on the trend that
/// produced the PR.
class PrListScreen extends ConsumerWidget {
  const PrListScreen({super.key});

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

    return Scaffold(
      backgroundColor: palette.shade50,
      appBar: AppBar(
        backgroundColor: palette.shade950,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Personal Records',
          style: TextStyle(
            // Explicit white — providing a custom `style` would otherwise
            // shadow the AppBar's `foregroundColor` for the title text and
            // fall back to the theme's default dark colour.
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Could not load PRs.\n$e',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.shade700),
            ),
          ),
        ),
        data: (List<PrEvent> events) {
          if (events.isEmpty) {
            return const Center(child: PrEmptyState());
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            itemCount: events.length,
            separatorBuilder: (BuildContext _, int _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(height: 1, color: palette.shade100),
            ),
            itemBuilder: (BuildContext _, int index) {
              final PrEvent event = events[index];
              return PrRow(
                event: event,
                unitSystem: unitSystem,
                onTap: () {
                  ref
                      .read(strengthExerciseSelectionProvider.notifier)
                      .select(event.exerciseId);
                  if (context.canPop()) context.pop();
                },
              );
            },
          );
        },
      ),
    );
  }
}
