import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/workout_recovery_controller.dart';

/// Sliver shown at the top of the active workout screen *only* after the
/// user picked "Edit / Add" in the recovery dialog. Reminds them why
/// they're back inside this workout (it had been auto-closed for
/// inactivity and was just re-activated). Dismiss button clears the
/// banner without touching the workout.
class WorkoutRecoveryBannerSliver extends ConsumerWidget {
  const WorkoutRecoveryBannerSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool show = ref.watch(
      workoutRecoveryControllerProvider.select((s) => s.resumedBanner),
    );
    if (!show) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final JellyBeanPalette palette = context.jellyBeanPalette;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: palette.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.shade300),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.history_toggle_off_rounded,
                color: palette.shade800,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'This workout was paused due to inactivity. Continue '
                  'logging or finish when ready.',
                  style: TextStyle(
                    color: palette.shade900,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                icon: Icon(
                  Icons.close_rounded,
                  color: palette.shade800,
                  size: 18,
                ),
                onPressed: () {
                  ref
                      .read(workoutRecoveryControllerProvider.notifier)
                      .clearResumedBanner();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
