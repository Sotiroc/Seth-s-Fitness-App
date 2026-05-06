import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/progression_range.dart';

/// Compact range picker for the progression chart cards. Renders as a
/// chip showing the current range ("3M ▾") and pops a dropdown menu on
/// tap. Mirrors the calendar heatmap's `_RangeDropdown` so both views on
/// the page select ranges the same way.
class ProgressionRangeDropdown extends StatelessWidget {
  const ProgressionRangeDropdown({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ProgressionRange selected;
  final ValueChanged<ProgressionRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    return PopupMenuButton<ProgressionRange>(
      tooltip: 'Change range',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: onChanged,
      itemBuilder: (BuildContext _) => <PopupMenuEntry<ProgressionRange>>[
        for (final ProgressionRange r in ProgressionRange.values)
          PopupMenuItem<ProgressionRange>(
            value: r,
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 20,
                  child: r == selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: palette.shade700,
                        )
                      : null,
                ),
                Text(
                  _fullLabel(r),
                  style: TextStyle(
                    color: palette.shade950,
                    fontWeight: r == selected
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: palette.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              selected.label,
              style: TextStyle(
                color: palette.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: palette.shade700,
            ),
          ],
        ),
      ),
    );
  }

  /// Long-form labels used inside the dropdown menu rows. The chip itself
  /// shows the short labels (`1M`, `3M`, etc.) for compactness, but the
  /// menu has room for full phrasing.
  static String _fullLabel(ProgressionRange r) {
    switch (r) {
      case ProgressionRange.oneMonth:
        return '1 month';
      case ProgressionRange.threeMonths:
        return '3 months';
      case ProgressionRange.sixMonths:
        return '6 months';
      case ProgressionRange.oneYear:
        return '1 year';
      case ProgressionRange.all:
        return 'All time';
    }
  }
}
