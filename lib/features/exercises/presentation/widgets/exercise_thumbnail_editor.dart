import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/images/exercise_thumbnail_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/exercise.dart';
import '../../application/exercise_editor_controller.dart';
import 'exercise_avatar.dart';

/// Opens a viewer modal for the exercise's photo with controls to replace
/// or remove it. Shared by `ExerciseFormScreen` (via the avatar tap on the
/// thumbnail picker) and `ActiveWorkoutScreen` (via the per-exercise card
/// avatar). Persistence flows through [ExerciseEditorController] so the
/// underlying watchers (active workout, exercise list) refresh automatically.
Future<void> showExerciseThumbnailEditor(
  BuildContext context,
  WidgetRef ref,
  Exercise exercise,
) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext sheetContext) {
      return _ThumbnailEditorSheet(initialExercise: exercise);
    },
  );
}

class _ThumbnailEditorSheet extends ConsumerStatefulWidget {
  const _ThumbnailEditorSheet({required this.initialExercise});

  final Exercise initialExercise;

  @override
  ConsumerState<_ThumbnailEditorSheet> createState() =>
      _ThumbnailEditorSheetState();
}

class _ThumbnailEditorSheetState extends ConsumerState<_ThumbnailEditorSheet> {
  late Exercise _exercise = widget.initialExercise;
  bool _processing = false;

  Future<void> _pick(ImageSource source) async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (file == null) return;
      final Uint8List? processed = await ref
          .read(exerciseThumbnailServiceProvider)
          .processPickedImage(file);
      if (!mounted) return;
      if (processed == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't read that image.")),
        );
        return;
      }
      final Exercise updated = await ref
          .read(exerciseEditorControllerProvider.notifier)
          .updateExercise(
            exercise: _exercise,
            name: _exercise.name,
            type: _exercise.type,
            muscleGroup: _exercise.muscleGroup,
            thumbnailBytes: processed,
          );
      if (!mounted) return;
      setState(() => _exercise = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image error: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _remove() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final Exercise updated = await ref
          .read(exerciseEditorControllerProvider.notifier)
          .updateExercise(
            exercise: _exercise,
            name: _exercise.name,
            type: _exercise.type,
            muscleGroup: _exercise.muscleGroup,
            clearThumbnail: true,
          );
      if (!mounted) return;
      setState(() => _exercise = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Remove failed: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final bool hasImage = _exercise.thumbnailBytes != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.shade100,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _exercise.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.shade950,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: palette.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: palette.shade100),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _processing
                      ? const Center(child: CircularProgressIndicator())
                      : Center(
                          child: hasImage
                              ? Image.memory(
                                  _exercise.thumbnailBytes!,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                )
                              : ExerciseAvatar(exercise: _exercise, size: 160),
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ActionButton(
              icon: Icons.photo_library_rounded,
              label: hasImage ? 'Replace from library' : 'Choose from library',
              palette: palette,
              onTap: _processing ? null : () => _pick(ImageSource.gallery),
            ),
            const SizedBox(height: AppSpacing.xs),
            _ActionButton(
              icon: Icons.photo_camera_rounded,
              label: 'Take photo',
              palette: palette,
              onTap: _processing ? null : () => _pick(ImageSource.camera),
            ),
            if (hasImage) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              _ActionButton(
                icon: Icons.delete_outline_rounded,
                label: 'Remove photo',
                palette: palette,
                destructive: true,
                onTap: _processing ? null : _remove,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final JellyBeanPalette palette;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color foreground = destructive
        ? const Color(0xFFB00020)
        : palette.shade950;
    final Color background = destructive
        ? const Color(0xFFB00020).withValues(alpha: 0.06)
        : palette.shade50;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
