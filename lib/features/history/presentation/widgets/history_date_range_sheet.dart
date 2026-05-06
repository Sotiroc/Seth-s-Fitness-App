import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/history_filter.dart';

/// Result of the date range sheet — either the user picked a preset or
/// they picked a custom range with concrete start/end inclusive dates.
class HistoryDateSheetResult {
  const HistoryDateSheetResult.preset(this.preset)
    : customStart = null,
      customEndInclusive = null;
  const HistoryDateSheetResult.custom({
    required DateTime start,
    required DateTime endInclusive,
  }) : preset = HistoryDateRangePreset.custom,
       customStart = start,
       customEndInclusive = endInclusive;

  final HistoryDateRangePreset preset;
  final DateTime? customStart;
  final DateTime? customEndInclusive;
}

/// Bottom sheet for the History "Date" filter chip. Lists the five
/// presets plus a "Custom range" entry that opens the system date-range
/// picker. Returning `null` from the sheet means "user dismissed without
/// changing anything."
class HistoryDateRangeSheet extends StatelessWidget {
  const HistoryDateRangeSheet({
    super.key,
    required this.currentPreset,
    required this.currentStart,
    required this.currentEndInclusive,
  });

  final HistoryDateRangePreset currentPreset;
  final DateTime? currentStart;
  final DateTime? currentEndInclusive;

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    'FILTER BY DATE',
                    style: TextStyle(
                      color: palette.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            for (final HistoryDateRangePreset p
                in HistoryDateRangePreset.values)
              _PresetTile(
                palette: palette,
                preset: p,
                isSelected: p == currentPreset,
                customStart: currentStart,
                customEndInclusive: currentEndInclusive,
                onTap: () => _handleTap(context, p),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    HistoryDateRangePreset preset,
  ) async {
    if (preset != HistoryDateRangePreset.custom) {
      Navigator.of(context).pop<HistoryDateSheetResult>(
        HistoryDateSheetResult.preset(preset),
      );
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime firstAllowed = DateTime(now.year - 5, 1, 1);
    final DateTime lastAllowed = DateTime(now.year, now.month, now.day);
    final DateTime initialStart =
        currentStart ?? lastAllowed.subtract(const Duration(days: 30));
    final DateTime initialEnd = currentEndInclusive ?? lastAllowed;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: firstAllowed,
      lastDate: lastAllowed,
      initialDateRange: DateTimeRange(
        start: initialStart.isBefore(firstAllowed) ? firstAllowed : initialStart,
        end: initialEnd.isAfter(lastAllowed) ? lastAllowed : initialEnd,
      ),
      helpText: 'Select date range',
      saveText: 'Apply',
      builder: (BuildContext ctx, Widget? child) {
        final JellyBeanPalette palette = ctx.jellyBeanPalette;
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: palette.shade700,
              onPrimary: Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (!context.mounted) return;
    if (picked == null) return;
    Navigator.of(context).pop<HistoryDateSheetResult>(
      HistoryDateSheetResult.custom(
        start: picked.start,
        endInclusive: picked.end,
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.palette,
    required this.preset,
    required this.isSelected,
    required this.customStart,
    required this.customEndInclusive,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final HistoryDateRangePreset preset;
  final bool isSelected;
  final DateTime? customStart;
  final DateTime? customEndInclusive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String? subtitle = _subtitle();
    return ListTile(
      onTap: onTap,
      title: Text(
        preset.label,
        style: TextStyle(
          color: palette.shade950,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(
                color: palette.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: palette.shade700)
          : preset == HistoryDateRangePreset.custom
              ? Icon(Icons.chevron_right_rounded, color: palette.shade400)
              : null,
    );
  }

  String? _subtitle() {
    if (preset != HistoryDateRangePreset.custom) return null;
    if (customStart == null || customEndInclusive == null) return null;
    return _formatRange(customStart!, customEndInclusive!);
  }

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return _formatDate(start);
    }
    return '${_formatDate(start)} – ${_formatDate(end)}';
  }

  String _formatDate(DateTime d) {
    final DateTime now = DateTime.now();
    final String year = d.year == now.year ? '' : ' ${d.year}';
    return '${d.day} ${_months[d.month - 1]}$year';
  }
}
