import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class WorkoutsPlaceholderScreen extends StatelessWidget {
  const WorkoutsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.jellyBeanPalette;

    return Scaffold(
      backgroundColor: palette.shade50,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(child: _Hero(palette: palette, theme: theme)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            sliver: SliverList.list(
              children: <Widget>[
                _SectionLabel(text: 'Foundation', palette: palette),
                const SizedBox(height: AppSpacing.md),
                _FeatureTile(
                  index: '01',
                  title: 'Jelly-bean system',
                  subtitle:
                      'Material 3 seeded from #289CB2. Full 50 to 950 palette wired as a theme extension.',
                  palette: palette,
                ),
                const SizedBox(height: AppSpacing.sm),
                _FeatureTile(
                  index: '02',
                  title: 'Navigation shell',
                  subtitle:
                      'Workouts, History, Exercises, Templates — stateful branches ready for feature work.',
                  palette: palette,
                ),
                const SizedBox(height: AppSpacing.sm),
                _FeatureTile(
                  index: '03',
                  title: 'Data-ready scaffold',
                  subtitle:
                      'Folders, Riverpod, Drift, and go_router installed. Phase 2 plugs straight in.',
                  palette: palette,
                ),
                const SizedBox(height: AppSpacing.xl),
                _Footnote(palette: palette),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.palette, required this.theme});

  final JellyBeanPalette palette;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            palette.shade950,
            palette.shade800,
            palette.shade600,
          ],
          stops: const <double>[0.0, 0.55, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -60,
            top: -40,
            child: _Blob(color: palette.shade400.withValues(alpha: 0.28), size: 220),
          ),
          Positioned(
            left: -50,
            bottom: -70,
            child: _Blob(color: palette.shade300.withValues(alpha: 0.18), size: 200),
          ),
          Padding(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _GlassPill(
                      palette: palette,
                      icon: Icons.bolt_rounded,
                      label: 'PHASE 1 · PREVIEW',
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(
                        Icons.fitness_center_rounded,
                        color: palette.shade100,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Lift.\nLog.\nRepeat.',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.02,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'A gym log that stays out of the way. You bring the effort — the app remembers the numbers.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: palette.shade100.withValues(alpha: 0.85),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatTile(
                        palette: palette,
                        value: '17',
                        label: 'Seed exercises',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StatTile(
                        palette: palette,
                        value: 'kg · km',
                        label: 'One unit system',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StatTile(
                        palette: palette,
                        value: 'M3',
                        label: 'Material 3',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _PrimaryCta(
                        palette: palette,
                        icon: Icons.play_arrow_rounded,
                        label: 'Start Empty Workout',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _GhostCta(
                      palette: palette,
                      icon: Icons.dashboard_customize_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.palette,
    required this.icon,
    required this.label,
  });

  final JellyBeanPalette palette;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: palette.shade200),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: palette.shade100,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.palette,
    required this.value,
    required this.label,
  });

  final JellyBeanPalette palette;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: palette.shade200.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.palette,
    required this.icon,
    required this.label,
  });

  final JellyBeanPalette palette;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.95,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: palette.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.shade950.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: palette.shade900, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: palette.shade950,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GhostCta extends StatelessWidget {
  const _GhostCta({required this.palette, required this.icon});

  final JellyBeanPalette palette;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: palette.shade100, size: 22),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.palette});

  final String text;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(width: 24, height: 2, color: palette.shade500),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            color: palette.shade700,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.palette,
  });

  final String index;
  final String title;
  final String subtitle;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.shade200),
            ),
            child: Text(
              index,
              style: TextStyle(
                color: palette.shade700,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.shade950,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.shade800.withValues(alpha: 0.75),
                    height: 1.4,
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

class _Footnote extends StatelessWidget {
  const _Footnote({required this.palette});

  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.shade100.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.lock_outline_rounded, size: 16, color: palette.shade700),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Preview only — buttons come alive in Phase 4.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
