import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/unit_conversions.dart';
import '../../../data/models/user_profile.dart';
import '../application/profile_stats_provider.dart';
import '../application/user_profile_provider.dart';
import 'widgets/bmi_stats_card.dart';
import 'widgets/stat_tile.dart';
import 'widgets/weight_card.dart';

/// Read-only summary of the current user's profile. Surfaces computed BMI and
/// goal-delta stats, and links to [ProfileFormScreen] for edits.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final AsyncValue<UserProfile?> async = ref.watch(userProfileProvider);
    final ProfileStats stats = ref.watch(profileStatsProvider);

    return Scaffold(
      backgroundColor: palette.shade50,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Failed to load profile: $error'),
          ),
        ),
        data: (UserProfile? profile) {
          final bool empty = profile == null || profile.isEmpty;
          return CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _ProfileHeader(palette: palette, profile: profile),
              ),
              if (empty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    palette: palette,
                    onTap: () => context.push('/profile/edit'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    120,
                  ),
                  sliver: SliverList.list(
                    children: <Widget>[
                      BmiStatsCard(stats: stats),
                      const SizedBox(height: AppSpacing.xl),
                      _Section(
                        title: 'About you',
                        palette: palette,
                        tiles: <Widget>[
                          StatTile(
                            icon: Icons.badge_outlined,
                            label: 'Name',
                            value: profile.name,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          StatTile(
                            icon: Icons.cake_outlined,
                            label: 'Age',
                            value: profile.ageYears == null
                                ? null
                                : '${profile.ageYears} years',
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          StatTile(
                            icon: Icons.person_outline_rounded,
                            label: 'Gender',
                            value: profile.gender?.label,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _Section(
                        title: 'Body',
                        palette: palette,
                        tiles: <Widget>[
                          StatTile(
                            icon: Icons.straighten_rounded,
                            label: 'Height',
                            value: UnitConversions.formatHeight(
                              profile.heightCm,
                              profile.unitSystem,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const WeightCard(),
                          const SizedBox(height: AppSpacing.xs),
                          StatTile(
                            icon: Icons.water_drop_outlined,
                            label: 'Body fat',
                            value: profile.bodyFatPercent == null
                                ? null
                                : '${_formatBodyFat(profile.bodyFatPercent!)}%',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _Section(
                        title: 'Goals',
                        palette: palette,
                        tiles: <Widget>[
                          StatTile(
                            icon: Icons.flag_outlined,
                            label: 'Goal weight',
                            value: UnitConversions.formatWeight(
                              profile.goalWeightKg,
                              profile.unitSystem,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          StatTile(
                            icon: Icons.fitness_center_rounded,
                            label: 'Muscle priority',
                            value: profile.muscleGroupPriority?.label,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _Section(
                        title: 'Health',
                        palette: palette,
                        tiles: <Widget>[
                          StatTile(
                            icon: Icons.medical_information_outlined,
                            label: 'Diabetic',
                            value: switch (profile.diabetic) {
                              true => 'Yes',
                              false => 'No',
                              null => null,
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: async.maybeWhen(
        data: (UserProfile? profile) {
          if (profile == null || profile.isEmpty) return null;
          return FloatingActionButton.extended(
            backgroundColor: palette.shade900,
            foregroundColor: Colors.white,
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit profile'),
          );
        },
        orElse: () => null,
      ),
    );
  }

  static String _formatBodyFat(double value) {
    final String s = value.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.palette, required this.profile});

  final JellyBeanPalette palette;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double topPadding = MediaQuery.paddingOf(context).top;
    final String title = (profile?.name?.trim().isNotEmpty ?? false)
        ? profile!.name!.trim()
        : 'Profile';
    final String subtitle = profile == null || profile!.isEmpty
        ? 'Tell us about yourself for smarter suggestions.'
        : 'These metrics help personalize your training.';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.shade950, palette.shade800, palette.shade600],
          stops: const <double>[0.0, 0.55, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topPadding + AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(width: 2, height: 14, color: palette.shade300),
              const SizedBox(width: 8),
              Text(
                'YOUR PROFILE',
                style: TextStyle(
                  color: palette.shade200,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: palette.shade100.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette, required this.onTap});

  final JellyBeanPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.shade100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.person_add_alt_1_rounded,
                size: 72,
                color: palette.shade300,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tell us about yourself',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: palette.shade950,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Add a few details so we can tailor workouts and track your progress.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Get started'),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.shade900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.palette,
    required this.tiles,
  });

  final String title;
  final JellyBeanPalette palette;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: palette.shade900,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...tiles,
      ],
    );
  }
}
