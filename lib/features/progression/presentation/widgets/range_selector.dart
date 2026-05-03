import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/progression_range.dart';

/// Compact 5-segment toggle that scopes a chart to a time window. Designed
/// to live inside a chart card directly under the plot, so the
/// horizontal padding is intentionally minimal.
class RangeSelector extends StatelessWidget {
  const RangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ProgressionRange selected;
  final ValueChanged<ProgressionRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    return SegmentedButton<ProgressionRange>(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return palette.shade900;
          return Colors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return palette.shade900;
        }),
        side: WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: palette.shade100),
        ),
      ),
      showSelectedIcon: false,
      segments: <ButtonSegment<ProgressionRange>>[
        for (final ProgressionRange r in ProgressionRange.values)
          ButtonSegment<ProgressionRange>(value: r, label: Text(r.label)),
      ],
      selected: <ProgressionRange>{selected},
      onSelectionChanged: (Set<ProgressionRange> set) {
        if (set.isEmpty) return;
        onChanged(set.first);
      },
    );
  }
}
