import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/workout_set.dart';
import '../../../../data/models/workout_set_kind.dart';
import 'set_kind_visuals.dart';

/// Quick popup-menu type picker that anchors to the tapped set-number badge.
///
/// Shown only on *incomplete* sets — a fast "this is going to be a warm-up /
/// drop / failure" label before the user actually does the work. Once the set
/// is completed, the badge tap routes to the richer bottom sheet (RPE + note)
/// instead, so the two surfaces don't compete.
///
/// Returns the picked [WorkoutSetKind], or `null` when the user dismissed
/// the menu without choosing. [canBeDrop] disables the Drop entry on rows
/// that have no working set above them to drop from — visible but greyed
/// so the layout stays stable.
Future<WorkoutSetKind?> showSetTypeMenu({
  required BuildContext anchorContext,
  required WorkoutSet set,
  required bool canBeDrop,
}) async {
  final RenderBox? button =
      anchorContext.findRenderObject() as RenderBox?;
  final RenderBox? overlay =
      Overlay.of(anchorContext).context.findRenderObject() as RenderBox?;
  if (button == null || overlay == null) return null;

  // Place the menu just below the badge's bottom-left corner, like the
  // Material default for a leading icon button — feels native, doesn't
  // cover the row content the user just tapped.
  final Offset topLeft = button.localToGlobal(
    Offset(0, button.size.height),
    ancestor: overlay,
  );
  final Offset bottomRight = button.localToGlobal(
    button.size.bottomRight(Offset.zero),
    ancestor: overlay,
  );
  final RelativeRect position = RelativeRect.fromRect(
    Rect.fromPoints(topLeft, bottomRight),
    Offset.zero & overlay.size,
  );

  final JellyBeanPalette palette = anchorContext.jellyBeanPalette;

  return showMenu<WorkoutSetKind>(
    context: anchorContext,
    position: position,
    color: palette.shade50,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    elevation: 6,
    items: <PopupMenuEntry<WorkoutSetKind>>[
      _buildItem(
        kind: WorkoutSetKind.normal,
        palette: palette,
        isSelected: set.kind == WorkoutSetKind.normal,
        enabled: true,
      ),
      _buildItem(
        kind: WorkoutSetKind.warmUp,
        palette: palette,
        isSelected: set.kind == WorkoutSetKind.warmUp,
        enabled: true,
      ),
      _buildItem(
        kind: WorkoutSetKind.drop,
        palette: palette,
        isSelected: set.kind == WorkoutSetKind.drop,
        enabled: canBeDrop,
      ),
      _buildItem(
        kind: WorkoutSetKind.failure,
        palette: palette,
        isSelected: set.kind == WorkoutSetKind.failure,
        enabled: true,
      ),
    ],
  );
}

PopupMenuItem<WorkoutSetKind> _buildItem({
  required WorkoutSetKind kind,
  required JellyBeanPalette palette,
  required bool isSelected,
  required bool enabled,
}) {
  final SetKindVisuals visuals = SetKindVisuals.forKind(kind, palette);
  final Color accent = visuals.accent ?? palette.shade700;
  final Color tint = visuals.tint ?? palette.shade100;

  return PopupMenuItem<WorkoutSetKind>(
    value: kind,
    enabled: enabled,
    onTap: enabled ? () => HapticFeedback.selectionClick() : null,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    height: 40,
    child: Row(
      children: <Widget>[
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            visuals.shortLabel,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          visuals.longLabel,
          style: TextStyle(
            color: enabled
                ? palette.shade950
                : palette.shade700.withValues(alpha: 0.55),
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(width: 16),
        const Spacer(),
        if (isSelected)
          Icon(Icons.check_rounded, size: 16, color: palette.shade700),
      ],
    ),
  );
}
