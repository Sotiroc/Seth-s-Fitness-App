import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Result of the per-exercise note bottom sheet. Returned via Navigator.pop
/// so the caller can dispatch a single mutation. A null result means the
/// user dismissed the sheet without saving.
class ExerciseNoteSheetResult {
  const ExerciseNoteSheetResult({required this.note});

  /// New per-exercise note. Null clears it. Already trimmed.
  final String? note;
}

/// Bottom sheet for capturing or editing the free-text note attached to a
/// single exercise within a workout (the per-workout-exercise instance,
/// not the global exercise definition). Mirrors the look and feel of
/// [showSetDetailsSheet] so the three note levels feel consistent.
Future<ExerciseNoteSheetResult?> showExerciseNoteSheet(
  BuildContext context, {
  required String exerciseName,
  required String? initialNote,
}) {
  return showModalBottomSheet<ExerciseNoteSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return _ExerciseNoteSheet(
        exerciseName: exerciseName,
        initialNote: initialNote,
      );
    },
  );
}

class _ExerciseNoteSheet extends StatefulWidget {
  const _ExerciseNoteSheet({
    required this.exerciseName,
    required this.initialNote,
  });

  final String exerciseName;
  final String? initialNote;

  @override
  State<_ExerciseNoteSheet> createState() => _ExerciseNoteSheetState();
}

class _ExerciseNoteSheetState extends State<_ExerciseNoteSheet> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final String trimmed = _noteController.text.trim();
    Navigator.of(context).pop(
      ExerciseNoteSheetResult(
        note: trimmed.isEmpty ? null : trimmed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final ThemeData theme = Theme.of(context);

    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: palette.shade50,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Exercise note',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.shade950,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.exerciseName,
                style: TextStyle(
                  color: palette.shade700.withValues(alpha: 0.8),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _NoteField(
                palette: palette,
                controller: _noteController,
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
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
            ],
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
      autofocus: true,
      maxLines: 4,
      minLines: 3,
      maxLength: 500,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(
        color: palette.shade950,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
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
