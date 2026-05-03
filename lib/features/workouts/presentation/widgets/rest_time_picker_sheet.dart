import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../data/repositories/exercise_repository.dart';

/// Wraps the picked seconds so callers can distinguish "user cancelled"
/// (a `null` Future) from "user picked Default / 0" (a non-null result
/// whose `seconds` field is itself null or 0).
class RestTimeChoice {
  const RestTimeChoice(this.seconds);

  /// `null` clears the per-exercise override; `0` explicitly disables
  /// the rest timer for this exercise; positive values are explicit
  /// seconds.
  final int? seconds;
}

/// Modal bottom sheet that lets the user adjust a single exercise's
/// rest-timer override. Reachable from the long-press on the running
/// rest-timer sheet so users can tune mid-workout without leaving.
/// Persists the new override on the exercise on Save and returns the
/// chosen value (or `null` if cancelled).
Future<int?> showRestTimePickerSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String exerciseId,
  required String exerciseName,
  required int initialSeconds,
}) async {
  final RestTimeChoice? choice = await showModalBottomSheet<RestTimeChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return RestTimePickerSheet(
        exerciseName: exerciseName,
        initialSeconds: initialSeconds,
      );
    },
  );
  if (choice == null) return null;
  await ref
      .read(exerciseRepositoryProvider)
      .updateExerciseRestSeconds(
        exerciseId: exerciseId,
        restSeconds: choice.seconds,
      );
  return choice.seconds;
}

/// Tile-grid picker matching the Timer settings and exercise form
/// styling so users see the same vocabulary in every place rest is
/// configured. "Default" clears the per-exercise override; "Off"
/// disables the timer for this exercise; presets and Custom set an
/// explicit override.
class RestTimePickerSheet extends StatefulWidget {
  const RestTimePickerSheet({
    super.key,
    required this.exerciseName,
    required this.initialSeconds,
  });

  final String exerciseName;
  final int initialSeconds;

  @override
  State<RestTimePickerSheet> createState() => _RestTimePickerSheetState();
}

class _RestTimePickerSheetState extends State<RestTimePickerSheet> {
  static const List<int> _presets = <int>[0, 60, 90, 120, 180];

  late int? _seconds;
  bool _editingCustom = false;
  late TextEditingController _customController;
  String? _customError;

  @override
  void initState() {
    super.initState();
    _seconds = widget.initialSeconds;
    _editingCustom = !_presets.contains(widget.initialSeconds);
    _customController = TextEditingController(
      text: _editingCustom
          ? DurationFormatter.formatSeconds(widget.initialSeconds)
          : '',
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final ThemeData theme = Theme.of(context);
    final List<_PickerTileData> tiles = <_PickerTileData>[
      const _PickerTileData(
        sentinel: _kDefaultSentinel,
        label: 'Default',
        icon: Icons.auto_awesome_rounded,
      ),
      for (final int preset in _presets)
        _PickerTileData(
          sentinel: preset,
          label: preset == 0
              ? 'Off'
              : DurationFormatter.formatSeconds(preset),
          icon: preset == 0
              ? Icons.timer_off_rounded
              : Icons.timer_outlined,
        ),
      const _PickerTileData(
        sentinel: _kCustomSentinel,
        label: 'Custom',
        icon: Icons.edit_rounded,
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Rest between sets',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.shade950,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.exerciseName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSpacing.xs,
                  mainAxisSpacing: AppSpacing.xs,
                  childAspectRatio: 1.4,
                  children: <Widget>[
                    for (final _PickerTileData tile in tiles)
                      _PickerTile(
                        palette: palette,
                        data: tile,
                        selected: _selectedFor(tile),
                        onTap: () => _onTileTap(tile),
                      ),
                  ],
                ),
              ),
              if (_editingCustom)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: TextField(
                    controller: _customController,
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                    ],
                    style: TextStyle(
                      color: palette.shade950,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                    decoration: InputDecoration(
                      hintText: '01:30',
                      suffixText: 'mm:ss',
                      suffixStyle: TextStyle(
                        color: palette.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      errorText: _customError,
                      filled: true,
                      fillColor: palette.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: palette.shade100),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: palette.shade100),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: palette.shade500, width: 1.5),
                      ),
                    ),
                    onChanged: (_) {
                      if (_customError != null) {
                        setState(() => _customError = null);
                      }
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.shade900,
                          side: BorderSide(color: palette.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.shade900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _onSave,
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _selectedFor(_PickerTileData tile) {
    if (tile.sentinel == _kCustomSentinel) {
      return _editingCustom;
    }
    if (_editingCustom) return false;
    if (tile.sentinel == _kDefaultSentinel) {
      return _seconds == null;
    }
    return _seconds == tile.sentinel;
  }

  void _onTileTap(_PickerTileData tile) {
    setState(() {
      _customError = null;
      if (tile.sentinel == _kCustomSentinel) {
        _editingCustom = true;
        return;
      }
      _editingCustom = false;
      _seconds =
          tile.sentinel == _kDefaultSentinel ? null : tile.sentinel;
    });
  }

  void _onSave() {
    int? value;
    if (_editingCustom) {
      final String raw = _customController.text.trim();
      if (raw.isEmpty) {
        setState(() => _customError = 'Enter a duration like 1:30');
        return;
      }
      final int? parsed = DurationFormatter.parseSeconds(raw);
      if (parsed == null || parsed > 3600) {
        setState(() => _customError = 'Enter a duration up to 60:00');
        return;
      }
      value = parsed;
    } else {
      value = _seconds;
    }
    Navigator.of(context).pop(RestTimeChoice(value));
  }
}

// Sentinels for the tile data so we can model "Default" (clear override)
// and "Custom" (open input) without colliding with real preset seconds.
const int _kDefaultSentinel = -2;
const int _kCustomSentinel = -1;

class _PickerTileData {
  const _PickerTileData({
    required this.sentinel,
    required this.label,
    required this.icon,
  });

  final int sentinel;
  final String label;
  final IconData icon;
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.palette,
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final _PickerTileData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? palette.shade900 : Colors.white;
    final Color fg = selected ? Colors.white : palette.shade950;
    final Color subFg = selected
        ? palette.shade200.withValues(alpha: 0.8)
        : palette.shade700.withValues(alpha: 0.7);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? palette.shade900 : palette.shade100,
              width: 1.2,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: palette.shade900.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(data.icon, color: subFg, size: 14),
              const Spacer(),
              Text(
                data.label,
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
