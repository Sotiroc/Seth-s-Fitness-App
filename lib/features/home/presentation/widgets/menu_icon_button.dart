import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/home_scaffold_key_provider.dart';

/// Hamburger button rendered in the dark gradient header of every main
/// tab. Opens the shell-level [Drawer] via the [GlobalKey] held in
/// [homeScaffoldKeyProvider]. Matches the frosted-glass treatment used
/// by other header chips.
class MenuIconButton extends ConsumerWidget {
  const MenuIconButton({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () =>
            ref.read(homeScaffoldKeyProvider).currentState?.openDrawer(),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            Icons.menu_rounded,
            size: 20,
            color: palette.shade100,
          ),
        ),
      ),
    );
  }
}
