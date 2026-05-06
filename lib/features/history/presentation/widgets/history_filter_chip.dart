import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Filter chip used in the History hero. Two visual states:
///
/// - **Inactive**: outlined translucent pill with a faded label.
/// - **Active**: filled teal pill with the chip's current value baked
///   into the label (e.g. "Date · This week"). Optional trailing icon
///   makes it clear when a chip is a multi-value picker (chevron) vs.
///   a binary toggle (none).
class HistoryFilterChip extends StatelessWidget {
  const HistoryFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.activeBadge,
    this.showChevron = true,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  /// Optional small badge appended after the label when active (e.g. the
  /// number of selected exercises). Null for plain chips.
  final String? activeBadge;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final Color foreground = active ? Colors.white : Colors.white;
    final Color iconColor = active
        ? Colors.white
        : palette.shade100.withValues(alpha: 0.85);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
          decoration: BoxDecoration(
            color: active
                ? palette.shade400
                : Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? palette.shade300
                  : Colors.white.withValues(alpha: 0.28),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              if (activeBadge != null) ...<Widget>[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    activeBadge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              if (showChevron) ...<Widget>[
                const SizedBox(width: 4),
                Icon(
                  Icons.expand_more_rounded,
                  size: 14,
                  color: iconColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
