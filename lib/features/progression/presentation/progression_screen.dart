import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../home/presentation/widgets/menu_icon_button.dart';
import 'widgets/body_weight_chart_card.dart';
import 'widgets/hero_stats_strip.dart';
import 'widgets/log_weight_sheet.dart';
import 'widgets/pr_feed_card.dart';
import 'widgets/strength_chart_card.dart';
import 'widgets/training_calendar_heatmap.dart';

/// 5th-tab screen surfacing both the body-weight timeline and the
/// per-exercise estimated 1RM trend. Layout mirrors `ProfileScreen`:
/// gradient header on top, scrollable section cards below, FAB for the
/// primary action ("Log weight").
class ProgressionScreen extends ConsumerWidget {
  const ProgressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;

    return Scaffold(
      backgroundColor: palette.shade50,
      drawerEnableOpenDragGesture: false,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(child: _ProgressionHeader(palette: palette)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              120,
            ),
            sliver: SliverList.list(
              children: <Widget>[
                const HeroStatsStrip(),
                const SizedBox(height: AppSpacing.lg),
                const TrainingCalendarHeatmap(),
                const SizedBox(height: AppSpacing.lg),
                const PrFeedCard(),
                const SizedBox(height: AppSpacing.lg),
                BodyWeightChartCard(
                  onLogWeight: () => showLogWeightSheet(context, ref),
                ),
                const SizedBox(height: AppSpacing.lg),
                const StrengthChartCard(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLogWeightSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log weight'),
      ),
    );
  }
}

class _ProgressionHeader extends StatelessWidget {
  const _ProgressionHeader({required this.palette});

  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double topPadding = MediaQuery.paddingOf(context).top;

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
        topPadding + AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const MenuIconButton(),
              const SizedBox(width: AppSpacing.sm),
              Container(width: 2, height: 14, color: palette.shade300),
              const SizedBox(width: 8),
              Text(
                'YOUR TRENDS',
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
            'Progression',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track your body weight and strength gains over time.',
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
