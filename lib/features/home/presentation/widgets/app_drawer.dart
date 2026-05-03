import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/unit_system.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../data/repositories/user_profile_repository.dart';
import '../../../profile/application/user_profile_provider.dart';
import '../../../progression/presentation/widgets/log_weight_sheet.dart';

/// Slide-in navigation menu reachable from every main tab's header.
/// Header reflects the saved profile (initial + name) so the drawer
/// keeps the identity affordance the old profile avatar button had.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final UserProfile? profile = ref.watch(userProfileProvider).asData?.value;
    final UnitSystem unitSystem = profile?.unitSystem ?? UnitSystem.metric;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _DrawerHeader(palette: palette, profile: profile),
            const SizedBox(height: AppSpacing.sm),
            _DrawerTile(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              palette: palette,
              onTap: () {
                Navigator.of(context).pop();
                context.push('/profile');
              },
            ),
            _DrawerTile(
              icon: Icons.history_rounded,
              label: 'History',
              palette: palette,
              onTap: () {
                Navigator.of(context).pop();
                context.push('/history');
              },
            ),
            _DrawerTile(
              icon: Icons.monitor_weight_outlined,
              label: 'Log weight',
              palette: palette,
              onTap: () {
                Navigator.of(context).pop();
                showLogWeightSheet(context, ref);
              },
            ),
            _DrawerTile(
              icon: Icons.add_circle_outline_rounded,
              label: 'Add exercise',
              palette: palette,
              onTap: () {
                Navigator.of(context).pop();
                context.push('/exercises/new');
              },
            ),
            const Divider(height: AppSpacing.lg, indent: 16, endIndent: 16),
            _UnitToggleTile(
              palette: palette,
              current: unitSystem,
              onChanged: (UnitSystem next) {
                if (next == unitSystem) return;
                ref.read(userProfileRepositoryProvider).updateUnitSystem(next);
              },
            ),
            _DrawerTile(
              icon: Icons.timer_outlined,
              label: 'Timer settings',
              palette: palette,
              onTap: () {
                Navigator.of(context).pop();
                context.push('/settings/timer');
              },
            ),
            _DrawerTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              palette: palette,
              onTap: () {
                Navigator.of(context).pop();
                context.push('/settings');
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.palette, required this.profile});

  final JellyBeanPalette palette;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? initial = _initialOf(profile?.name);
    final bool filled = initial != null;
    final String displayName = (profile?.name ?? '').trim().isEmpty
        ? 'Welcome'
        : profile!.name!.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.shade950, palette.shade700],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? palette.shade300
                  : Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: filled
                    ? palette.shade300
                    : Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: filled
                ? Text(
                    initial,
                    style: TextStyle(
                      color: palette.shade950,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  )
                : Icon(
                    Icons.person_outline_rounded,
                    size: 26,
                    color: palette.shade100,
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            displayName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              context.push('/profile');
            },
            child: Text(
              filled ? 'Edit profile' : 'Set up your profile',
              style: TextStyle(
                color: palette.shade100.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: palette.shade100.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String? _initialOf(String? name) {
    if (name == null) return null;
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.characters.first.toUpperCase();
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final JellyBeanPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: palette.shade800),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _UnitToggleTile extends StatelessWidget {
  const _UnitToggleTile({
    required this.palette,
    required this.current,
    required this.onChanged,
  });

  final JellyBeanPalette palette;
  final UnitSystem current;
  final ValueChanged<UnitSystem> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.straighten_rounded, color: palette.shade800),
      title: const Text(
        'Units',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: palette.shade100,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _UnitChip(
              palette: palette,
              label: 'kg',
              selected: current == UnitSystem.metric,
              onTap: () => onChanged(UnitSystem.metric),
            ),
            _UnitChip(
              palette: palette,
              label: 'lb',
              selected: current == UnitSystem.imperial,
              onTap: () => onChanged(UnitSystem.imperial),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({
    required this.palette,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: selected ? palette.shade900 : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : palette.shade800,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
