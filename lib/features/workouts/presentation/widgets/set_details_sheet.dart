import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/workout_set.dart';

/// Result of the set details bottom sheet. Returned via Navigator.pop so the
/// caller can dispatch a single mutation. Null result means the user
/// dismissed the sheet without saving.
class SetDetailsSheetResult {
  const SetDetailsSheetResult({required this.rpe, required this.note});

  /// New per-set RPE (1–10). Null clears it.
  final int? rpe;

  /// New per-set note. Null clears it. Already trimmed.
  final String? note;
}

/// Bottom sheet for capturing post-set context on a *completed* set: an
/// optional 1–10 RPE and a free-text note (e.g. "left shoulder felt tight").
///
/// Set type is intentionally *not* editable here — it's chosen via the
/// quick popup menu on the still-incomplete row before the work is done
/// (`showSetTypeMenu`). Keeping the two surfaces separate matches the
/// natural workflow: label up front, reflect afterward.
Future<SetDetailsSheetResult?> showSetDetailsSheet(
  BuildContext context, {
  required WorkoutSet set,
}) {
  return showModalBottomSheet<SetDetailsSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return _SetDetailsSheet(set: set);
    },
  );
}

class _SetDetailsSheet extends StatefulWidget {
  const _SetDetailsSheet({required this.set});

  final WorkoutSet set;

  @override
  State<_SetDetailsSheet> createState() => _SetDetailsSheetState();
}

class _SetDetailsSheetState extends State<_SetDetailsSheet> {
  int? _rpe;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _rpe = widget.set.rpe;
    _noteController = TextEditingController(text: widget.set.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final String trimmedNote = _noteController.text.trim();
    Navigator.of(context).pop(
      SetDetailsSheetResult(
        rpe: _rpe,
        note: trimmedNote.isEmpty ? null : trimmedNote,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final ThemeData theme = Theme.of(context);

    // Account for the keyboard so the sticky Save button stays visible
    // while the note field is focused.
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (BuildContext _, ScrollController scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: palette.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    children: <Widget>[
                      Text(
                        'Set details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: palette.shade950,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Set ${widget.set.setNumber}',
                        style: TextStyle(
                          color: palette.shade700.withValues(alpha: 0.8),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 1. Per-set RPE.
                      Row(
                        children: <Widget>[
                          _SectionLabel(text: 'RPE', palette: palette),
                          const Spacer(),
                          if (_rpe != null)
                            _ClearChip(
                              palette: palette,
                              onTap: () => setState(() => _rpe = null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'How hard did this set feel? (optional, 1–10)',
                        style: TextStyle(
                          color: palette.shade700.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _RpePicker(
                        palette: palette,
                        selected: _rpe,
                        onChanged: (int? value) {
                          setState(() => _rpe = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 2. Per-set note.
                      _SectionLabel(text: 'Note', palette: palette),
                      const SizedBox(height: AppSpacing.sm),
                      _NoteField(
                        palette: palette,
                        controller: _noteController,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    MediaQuery.paddingOf(context).bottom + AppSpacing.md,
                  ),
                  child: SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.shade900,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.palette});

  final String text;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: palette.shade700,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _ClearChip extends StatelessWidget {
  const _ClearChip({required this.palette, required this.onTap});

  final JellyBeanPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          'Clear',
          style: TextStyle(
            color: palette.shade700,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _RpePicker extends StatelessWidget {
  const _RpePicker({
    required this.palette,
    required this.selected,
    required this.onChanged,
  });

  final JellyBeanPalette palette;
  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (int i = 1; i <= 10; i++)
          _RpeChip(
            palette: palette,
            value: i,
            isSelected: selected == i,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(selected == i ? null : i);
            },
          ),
      ],
    );
  }
}

class _RpeChip extends StatelessWidget {
  const _RpeChip({
    required this.palette,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final int value;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? palette.shade700 : palette.shade50,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? palette.shade700 : palette.shade100,
            ),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              color: isSelected ? Colors.white : palette.shade800,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.palette, required this.controller});

  final JellyBeanPalette palette;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      maxLength: 280,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(
        color: palette.shade950,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'e.g. left shoulder felt tight',
        hintStyle: TextStyle(
          color: palette.shade700.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(AppSpacing.sm),
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
          borderSide: BorderSide(color: palette.shade500, width: 1.4),
        ),
        counterStyle: TextStyle(
          color: palette.shade700.withValues(alpha: 0.6),
          fontSize: 11,
        ),
      ),
    );
  }
}
