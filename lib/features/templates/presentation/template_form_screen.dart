import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/exercise_type.dart';
import '../../../data/models/template_detail.dart';
import '../../../data/models/template_exercise.dart';
import '../../exercises/presentation/widgets/exercise_avatar.dart';
import '../../exercises/presentation/widgets/exercise_muscle_group_badge.dart';
import '../../exercises/presentation/widgets/exercise_type_badge.dart';
import '../application/template_editor_controller.dart';
import '../application/template_providers.dart';

/// Create/edit template screen. When [templateId] is null we are creating a
/// new template; otherwise we seed the form from [templateDetailProvider] and
/// save updates back via [templateEditorControllerProvider].
class TemplateFormScreen extends ConsumerStatefulWidget {
  const TemplateFormScreen({super.key, this.templateId});

  final String? templateId;

  bool get isEditing => templateId != null;

  @override
  ConsumerState<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends ConsumerState<TemplateFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  final List<_DraftRow> _rows = <_DraftRow>[];
  bool _loadedInitial = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isEditing) {
      _loadedInitial = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _seedFromDetail(TemplateDetail detail) {
    if (_loadedInitial) return;
    _loadedInitial = true;
    _nameController.text = detail.template.name;
    _rows
      ..clear()
      ..addAll(
        detail.exercises.map(
          (e) => _DraftRow(
            exercise: e.exercise,
            defaultSets: e.templateExercise.defaultSets,
          ),
        ),
      );
  }

  Future<void> _pickExercise() async {
    final List<Exercise>? options = ref
        .read(templateExerciseOptionsProvider)
        .asData
        ?.value;
    if (options == null) return;

    final Exercise? picked = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExercisePickerSheet(options: options),
    );

    if (picked == null || !mounted) return;
    setState(() {
      _rows.add(_DraftRow(exercise: picked, defaultSets: 3));
    });
  }

  void _removeRow(int index) {
    setState(() => _rows.removeAt(index));
  }

  void _updateSets(int index, int sets) {
    setState(() {
      _rows[index] = _rows[index].copyWith(defaultSets: sets);
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final _DraftRow item = _rows.removeAt(oldIndex);
      _rows.insert(newIndex, item);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final List<TemplateExerciseDraft> drafts = <TemplateExerciseDraft>[
        for (int i = 0; i < _rows.length; i++)
          TemplateExerciseDraft(
            exerciseId: _rows[i].exercise.id,
            orderIndex: i,
            defaultSets: _rows[i].defaultSets,
          ),
      ];
      final String name = _nameController.text.trim();
      if (widget.isEditing) {
        final TemplateDetail current = await ref.read(
          templateDetailProvider(widget.templateId!).future,
        );
        await ref
            .read(templateEditorControllerProvider.notifier)
            .updateTemplate(
              template: current.template.copyWith(name: name),
              exercises: drafts,
            );
      } else {
        await ref
            .read(templateEditorControllerProvider.notifier)
            .createTemplate(name: name, exercises: drafts);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing ? 'Template updated.' : 'Template created.',
          ),
        ),
      );
      if (context.canPop()) context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;

    if (widget.isEditing && !_loadedInitial) {
      final AsyncValue<TemplateDetail> detailAsync = ref.watch(
        templateDetailProvider(widget.templateId!),
      );
      return detailAsync.when(
        data: (detail) {
          _seedFromDetail(detail);
          return _buildContent(context, palette);
        },
        loading: () => Scaffold(
          backgroundColor: palette.shade50,
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Scaffold(
          backgroundColor: palette.shade50,
          appBar: AppBar(backgroundColor: palette.shade50),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('Could not load template: $err'),
            ),
          ),
        ),
      );
    }

    return _buildContent(context, palette);
  }

  Widget _buildContent(BuildContext context, JellyBeanPalette palette) {
    return Scaffold(
      backgroundColor: palette.shade50,
      appBar: AppBar(
        backgroundColor: palette.shade50,
        title: Text(widget.isEditing ? 'Edit template' : 'New template'),
        foregroundColor: palette.shade950,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            120,
          ),
          children: <Widget>[
            _FieldLabel(text: 'Name', palette: palette),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'e.g. Push day A',
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
                  borderSide: BorderSide(color: palette.shade500, width: 1.5),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Give your template a name.';
                }
                if (value.trim().length > 60) {
                  return 'Keep it under 60 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _FieldLabel(text: 'Exercises', palette: palette),
            const SizedBox(height: AppSpacing.xs),
            if (_rows.isEmpty)
              _EmptyExercises(palette: palette)
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: _reorder,
                itemCount: _rows.length,
                itemBuilder: (context, index) {
                  final _DraftRow row = _rows[index];
                  return Padding(
                    key: ValueKey<String>('row-${row.exercise.id}-$index'),
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _DraftRowCard(
                      palette: palette,
                      index: index,
                      row: row,
                      onRemove: () => _removeRow(index),
                      onSetsChanged: (v) => _updateSets(index, v),
                    ),
                  );
                },
              ),
            const SizedBox(height: AppSpacing.xs),
            _AddExerciseTile(palette: palette, onTap: _pickExercise),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: palette.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.isEditing ? 'Save changes' : 'Create template',
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

class _DraftRow {
  const _DraftRow({required this.exercise, required this.defaultSets});

  final Exercise exercise;
  final int defaultSets;

  _DraftRow copyWith({Exercise? exercise, int? defaultSets}) => _DraftRow(
    exercise: exercise ?? this.exercise,
    defaultSets: defaultSets ?? this.defaultSets,
  );
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

class _DraftRowCard extends StatelessWidget {
  const _DraftRowCard({
    required this.palette,
    required this.index,
    required this.row,
    required this.onRemove,
    required this.onSetsChanged,
  });

  final JellyBeanPalette palette;
  final int index;
  final _DraftRow row;
  final VoidCallback onRemove;
  final ValueChanged<int> onSetsChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.shade100),
        ),
        child: Row(
          children: <Widget>[
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: palette.shade400,
                ),
              ),
            ),
            ExerciseAvatar(
              exercise: row.exercise,
              size: 40,
              letterBackgroundColor: palette.shade500,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    row.exercise.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: palette.shade950,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: <Widget>[
                      ExerciseTypeBadge(type: row.exercise.type),
                      ExerciseMuscleGroupBadge(
                        muscleGroup: row.exercise.muscleGroup,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _SetsStepper(
              palette: palette,
              value: row.defaultSets,
              onChanged: onSetsChanged,
            ),
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.close_rounded,
                color: palette.shade600,
                size: 20,
              ),
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }
}

class _SetsStepper extends StatelessWidget {
  const _SetsStepper({
    required this.palette,
    required this.value,
    required this.onChanged,
  });

  final JellyBeanPalette palette;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.shade50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepperButton(
            icon: Icons.remove_rounded,
            palette: palette,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.shade900,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            palette: palette,
            onTap: value < 20 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final JellyBeanPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;
    return InkResponse(
      onTap: onTap,
      radius: 16,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: disabled ? palette.shade300 : palette.shade800,
        ),
      ),
    );
  }
}

class _EmptyExercises extends StatelessWidget {
  const _EmptyExercises({required this.palette});

  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.shade100.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.shade200),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline_rounded, size: 16, color: palette.shade700),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Add exercises below. Drag the handles to reorder.',
              style: TextStyle(
                color: palette.shade800,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddExerciseTile extends StatelessWidget {
  const _AddExerciseTile({required this.palette, required this.onTap});

  final JellyBeanPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.shade200, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.add_circle_outline_rounded, color: palette.shade900),
            const SizedBox(width: 8),
            Text(
              'Add exercise',
              style: TextStyle(
                color: palette.shade950,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet({required this.options});

  final List<Exercise> options;

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  ExerciseType? _typeFilter;

  Future<void> _createNew() async {
    final Exercise? created = await context.push<Exercise>('/exercises/new');
    if (created != null && mounted) {
      Navigator.of(context).pop(created);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Exercise> get _filtered {
    final String q = _query.trim().toLowerCase();
    return widget.options
        .where((e) {
          if (_typeFilter != null && e.type != _typeFilter) return false;
          if (q.isEmpty) return true;
          return e.name.toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final ThemeData theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: palette.shade50,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Pick exercise',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.shade950,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.shade100),
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    hintText: 'Search exercises',
                    hintStyle: TextStyle(
                      color: palette.shade700.withValues(alpha: 0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: palette.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    _FilterChip(
                      palette: palette,
                      label: 'All',
                      selected: _typeFilter == null,
                      onTap: () => setState(() => _typeFilter = null),
                    ),
                    const SizedBox(width: 6),
                    for (final ExerciseType t
                        in ExerciseType.values) ...<Widget>[
                      _FilterChip(
                        palette: palette,
                        label: t.label,
                        selected: _typeFilter == t,
                        onTap: () => setState(() => _typeFilter = t),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: <Widget>[
                  _CreateExerciseTile(palette: palette, onTap: _createNew),
                  const SizedBox(height: AppSpacing.sm),
                  if (_filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          _query.isEmpty
                              ? 'No exercises in your library yet.'
                              : 'No matches.',
                          style: TextStyle(color: palette.shade800),
                        ),
                      ),
                    )
                  else
                    ..._filtered.map(
                      (exercise) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(exercise),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: palette.shade100),
                              ),
                              child: Row(
                                children: <Widget>[
                                  ExerciseAvatar(
                                    exercise: exercise,
                                    size: 40,
                                    letterBackgroundColor: palette.shade500,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          exercise.name,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                color: palette.shade950,
                                                fontWeight: FontWeight.w700,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: AppSpacing.xs,
                                          runSpacing: AppSpacing.xs,
                                          children: <Widget>[
                                            ExerciseTypeBadge(
                                              type: exercise.type,
                                            ),
                                            ExerciseMuscleGroupBadge(
                                              muscleGroup: exercise.muscleGroup,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: palette.shade600,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
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
    );
  }
}

class _CreateExerciseTile extends StatelessWidget {
  const _CreateExerciseTile({required this.palette, required this.onTap});

  final JellyBeanPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.shade900,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: palette.shade100,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Create new exercise',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Add it to your library and this template.',
                      style: TextStyle(
                        color: palette.shade200.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.shade200,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.palette,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? palette.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? palette.shade900 : palette.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : palette.shade800,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
