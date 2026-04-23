import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  bool _isDefault = false;
  Exercise? _original;

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
        );
      } else {
        result = await controller.createExercise(
          name: _nameController.text.trim(),
          type: _type,
          muscleGroup: _muscleGroup,
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

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final ThemeData theme = Theme.of(context);

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
                  _WebAvatarNotice(
                    palette: palette,
                    previewName: _nameController.text.isEmpty
                        ? 'New'
                        : _nameController.text,
                    previewType: _type,
                    previewMuscleGroup: _muscleGroup,
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
                              style: theme.textTheme.bodySmall?.copyWith(
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

class _WebAvatarNotice extends StatelessWidget {
  const _WebAvatarNotice({
    required this.palette,
    required this.previewName,
    required this.previewType,
    required this.previewMuscleGroup,
  });

  final JellyBeanPalette palette;
  final String previewName;
  final ExerciseType previewType;
  final ExerciseMuscleGroup previewMuscleGroup;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Exercise previewExercise = Exercise(
      id: 'preview',
      name: previewName,
      type: previewType,
      muscleGroup: previewMuscleGroup,
      thumbnailPath: null,
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
          ExerciseAvatar(exercise: previewExercise, size: 92),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Avatar',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.shade950,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Web-first build uses generated letter avatars for now.',
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
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Image uploads are deferred so the app works cleanly in the browser and as an iPhone PWA.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.shade800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: ExerciseMuscleGroup.values
          .map(
            (group) => _MuscleGroupOption(
              palette: palette,
              muscleGroup: group,
              selected: selected == group,
              onTap: () => onChanged(group),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MuscleGroupOption extends StatelessWidget {
  const _MuscleGroupOption({
    required this.palette,
    required this.muscleGroup,
    required this.selected,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final ExerciseMuscleGroup muscleGroup;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? palette.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? palette.shade900 : palette.shade100,
            width: 1.2,
          ),
        ),
        child: Text(
          muscleGroup.label,
          style: TextStyle(
            color: selected ? Colors.white : palette.shade900,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
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
        return Icons.self_improvement_rounded;
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
            Text(
              type.label,
              style: TextStyle(
                color: selected ? Colors.white : palette.shade950,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
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
