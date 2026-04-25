import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/images/exercise_thumbnail_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/exercise_muscle_group.dart';
import '../../../data/models/exercise_type.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../application/exercise_editor_controller.dart';
import 'widgets/exercise_avatar.dart';
import 'widgets/exercise_muscle_group_badge.dart';
import 'widgets/exercise_type_badge.dart';

class ExerciseFormScreen extends ConsumerStatefulWidget {
  const ExerciseFormScreen({super.key, this.exerciseId});

  final String? exerciseId;

  bool get isEditing => exerciseId != null;

  @override
  ConsumerState<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends ConsumerState<ExerciseFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  ExerciseType _type = ExerciseType.weighted;
  ExerciseMuscleGroup _muscleGroup = ExerciseMuscleGroup.chest;
  bool _loading = false;
  bool _loadingInitial = false;
  bool _processingImage = false;
  bool _isDefault = false;
  Exercise? _original;
  Uint8List? _thumbnailBytes;
  bool _thumbnailCleared = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadingInitial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      final Exercise exercise = await ref
          .read(exerciseRepositoryProvider)
          .getExerciseById(widget.exerciseId!);
      if (!mounted) return;
      setState(() {
        _original = exercise;
        _nameController.text = exercise.name;
        _type = exercise.type;
        _muscleGroup = exercise.muscleGroup;
        _isDefault = exercise.isDefault;
        _thumbnailBytes = exercise.thumbnailBytes;
        _loadingInitial = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
      setState(() => _loadingInitial = false);
      if (context.canPop()) context.pop();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final ExerciseEditorController controller = ref.read(
      exerciseEditorControllerProvider.notifier,
    );

    try {
      Exercise? result;
      if (widget.isEditing && _original != null) {
        result = await controller.updateExercise(
          exercise: _original!,
          name: _nameController.text.trim(),
          type: _type,
          muscleGroup: _muscleGroup,
          thumbnailBytes: _thumbnailCleared ? null : _thumbnailBytes,
          clearThumbnail: _thumbnailCleared,
        );
      } else {
        result = await controller.createExercise(
          name: _nameController.text.trim(),
          type: _type,
          muscleGroup: _muscleGroup,
          thumbnailBytes: _thumbnailBytes,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing ? 'Exercise updated.' : 'Exercise created.',
          ),
        ),
      );
      // Pop with the created/updated exercise so callers (like the
      // add-exercise sheet) can react to the new value.
      if (context.canPop()) context.pop<Exercise>(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openThumbnailSheet() async {
    if (_processingImage) return;
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final bool hasImage = _thumbnailBytes != null;
    final _ThumbnailAction? action = await showModalBottomSheet<_ThumbnailAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _SheetTile(
                  icon: Icons.photo_library_rounded,
                  label: 'Choose from library',
                  palette: palette,
                  onTap: () => Navigator.of(sheetContext).pop(
                    _ThumbnailAction.gallery,
                  ),
                ),
                _SheetTile(
                  icon: Icons.photo_camera_rounded,
                  label: 'Take photo',
                  palette: palette,
                  onTap: () => Navigator.of(sheetContext).pop(
                    _ThumbnailAction.camera,
                  ),
                ),
                if (hasImage)
                  _SheetTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove photo',
                    palette: palette,
                    destructive: true,
                    onTap: () => Navigator.of(sheetContext).pop(
                      _ThumbnailAction.remove,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null || !mounted) return;

    if (action == _ThumbnailAction.remove) {
      setState(() {
        _thumbnailBytes = null;
        _thumbnailCleared = true;
      });
      return;
    }

    await _pickAndProcess(
      action == _ThumbnailAction.camera
          ? ImageSource.camera
          : ImageSource.gallery,
    );
  }

  Future<void> _pickAndProcess(ImageSource source) async {
    setState(() => _processingImage = true);
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

      setState(() {
        _thumbnailBytes = processed;
        _thumbnailCleared = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image error: $e')));
    } finally {
      if (mounted) setState(() => _processingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;

    return Scaffold(
      backgroundColor: palette.shade50,
      appBar: AppBar(
        backgroundColor: palette.shade50,
        title: Text(widget.isEditing ? 'Edit Exercise' : 'New Exercise'),
      ),
      body: _loadingInitial
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  120,
                ),
                children: <Widget>[
                  _ThumbnailPicker(
                    palette: palette,
                    previewName: _nameController.text.isEmpty
                        ? 'New'
                        : _nameController.text,
                    previewType: _type,
                    previewMuscleGroup: _muscleGroup,
                    thumbnailBytes: _thumbnailBytes,
                    processing: _processingImage,
                    onTap: _openThumbnailSheet,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _FieldLabel(text: 'Name', palette: palette),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'e.g. Romanian Deadlift',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: palette.shade100),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: palette.shade100),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: palette.shade500,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Give it a name.';
                      }
                      if (value.trim().length > 60) {
                        return 'Keep it under 60 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FieldLabel(text: 'Type', palette: palette),
                  const SizedBox(height: AppSpacing.xs),
                  _TypePicker(
                    palette: palette,
                    selected: _type,
                    onChanged: (value) => setState(() => _type = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FieldLabel(text: 'Muscle Group', palette: palette),
                  const SizedBox(height: AppSpacing.xs),
                  _MuscleGroupPicker(
                    palette: palette,
                    selected: _muscleGroup,
                    onChanged: (value) => setState(() => _muscleGroup = value),
                  ),
                  if (_isDefault) ...<Widget>[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: palette.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: palette.shade700,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Default exercise. Your edits apply locally.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: palette.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _loading || _loadingInitial ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: palette.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.isEditing ? 'Save changes' : 'Create exercise',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ThumbnailAction { gallery, camera, remove }

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, required this.palette});

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

class _ThumbnailPicker extends StatelessWidget {
  const _ThumbnailPicker({
    required this.palette,
    required this.previewName,
    required this.previewType,
    required this.previewMuscleGroup,
    required this.thumbnailBytes,
    required this.processing,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final String previewName;
  final ExerciseType previewType;
  final ExerciseMuscleGroup previewMuscleGroup;
  final Uint8List? thumbnailBytes;
  final bool processing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasImage = thumbnailBytes != null;
    final Exercise previewExercise = Exercise(
      id: 'preview',
      name: previewName,
      type: previewType,
      muscleGroup: previewMuscleGroup,
      thumbnailPath: null,
      thumbnailBytes: thumbnailBytes,
      isDefault: false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.shade100),
      ),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: processing ? null : onTap,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                ExerciseAvatar(exercise: previewExercise, size: 92),
                if (processing)
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(92 / 4),
                    ),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: palette.shade900,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Thumbnail',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.shade950,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasImage
                      ? 'Tap the avatar to change or remove.'
                      : 'Tap the avatar to add a photo.',
                  style: TextStyle(
                    color: palette.shade800.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    ExerciseTypeBadge(type: previewType),
                    ExerciseMuscleGroupBadge(muscleGroup: previewMuscleGroup),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final JellyBeanPalette palette;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color foreground = destructive
        ? const Color(0xFFB00020)
        : palette.shade950;
    return ListTile(
      leading: Icon(icon, color: foreground),
      title: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}

class _TypePicker extends StatelessWidget {
  const _TypePicker({
    required this.palette,
    required this.selected,
    required this.onChanged,
  });

  final JellyBeanPalette palette;
  final ExerciseType selected;
  final ValueChanged<ExerciseType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (final ExerciseType type in ExerciseType.values) ...<Widget>[
          Expanded(
            child: _TypeOption(
              palette: palette,
              type: type,
              selected: selected == type,
              onTap: () => onChanged(type),
            ),
          ),
          if (type != ExerciseType.values.last)
            const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _MuscleGroupPicker extends StatelessWidget {
  const _MuscleGroupPicker({
    required this.palette,
    required this.selected,
    required this.onChanged,
  });

  final JellyBeanPalette palette;
  final ExerciseMuscleGroup selected;
  final ValueChanged<ExerciseMuscleGroup> onChanged;

  Future<void> _openSheet(BuildContext context) async {
    final ExerciseMuscleGroup? picked =
        await showModalBottomSheet<ExerciseMuscleGroup>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (BuildContext sheetContext) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final ExerciseMuscleGroup group
                        in ExerciseMuscleGroup.values)
                      ListTile(
                        title: Text(
                          group.label,
                          style: TextStyle(
                            color: palette.shade950,
                            fontWeight: group == selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                        trailing: group == selected
                            ? Icon(
                                Icons.check_rounded,
                                color: palette.shade700,
                              )
                            : null,
                        onTap: () =>
                            Navigator.of(sheetContext).pop(group),
                      ),
                  ],
                ),
              ),
            );
          },
        );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.shade100),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                selected.label,
                style: TextStyle(
                  color: palette.shade950,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.expand_more_rounded, color: palette.shade700),
          ],
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.palette,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final ExerciseType type;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (type) {
      case ExerciseType.weighted:
        return Icons.fitness_center_rounded;
      case ExerciseType.bodyweight:
        return Icons.sports_gymnastics_rounded;
      case ExerciseType.cardio:
        return Icons.directions_run_rounded;
    }
  }

  String get _subtitle {
    switch (type) {
      case ExerciseType.weighted:
        return 'kg × reps';
      case ExerciseType.bodyweight:
        return 'reps only';
      case ExerciseType.cardio:
        return 'km × time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? palette.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? palette.shade900 : palette.shade100,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              _icon,
              color: selected ? Colors.white : palette.shade700,
              size: 20,
            ),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                type.label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? Colors.white : palette.shade950,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _subtitle,
              style: TextStyle(
                color: selected
                    ? palette.shade200
                    : palette.shade700.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
