import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/exercise.dart';
import '../../../../data/models/exercise_type.dart';
import '../../../exercises/presentation/widgets/exercise_avatar.dart';
import '../../../exercises/presentation/widgets/exercise_muscle_group_badge.dart';
import '../../../exercises/presentation/widgets/exercise_type_badge.dart';
import '../../application/active_workout_provider.dart';

/// Shows the add-exercise bottom sheet for the active workout.
///
/// Returns the chosen [Exercise] when the user picks one, or `null` if the
/// sheet is dismissed.
Future<Exercise?> showAddExerciseSheet(BuildContext context) {
  return showModalBottomSheet<Exercise>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _AddExerciseSheet(),
  );
}

class _AddExerciseSheet extends ConsumerStatefulWidget {
  const _AddExerciseSheet();

  @override
  ConsumerState<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<_AddExerciseSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  ExerciseType? _typeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Exercise> _filter(List<Exercise> items) {
    final String q = _query.trim().toLowerCase();
    return items
        .where((e) {
          if (_typeFilter != null && e.type != _typeFilter) return false;
          if (q.isEmpty) return true;
          return e.name.toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  Future<void> _createNew() async {
    // Pushing the form returns the created Exercise when it succeeds.
    final Exercise? created = await context.push<Exercise>('/exercises/new');
    if (created != null && mounted) {
      Navigator.of(context).pop(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<Exercise>> options = ref.watch(
      workoutExerciseOptionsProvider,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
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
                        'Add exercise',
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
                    controller: _searchController,
                    autofocus: false,
                    onChanged: (value) => setState(() => _query = value),
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
                child: _TypeFilter(
                  palette: palette,
                  selected: _typeFilter,
                  onChanged: (value) => setState(() => _typeFilter = value),
                ),
              ),
              Expanded(
                child: options.when(
                  data: (items) {
                    final List<Exercise> filtered = _filter(items);
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xs,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      children: <Widget>[
                        _CreateNewTile(palette: palette, onTap: _createNew),
                        const SizedBox(height: AppSpacing.sm),
                        if (filtered.isEmpty)
                          _EmptyState(
                            palette: palette,
                            hasQuery: _query.trim().isNotEmpty,
                          )
                        else
                          ...filtered.map(
                            (exercise) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xs,
                              ),
                              child: _ExerciseOption(
                                exercise: exercise,
                                palette: palette,
                                onTap: () =>
                                    Navigator.of(context).pop(exercise),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text('Could not load exercises: $err'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TypeFilter extends StatelessWidget {
  const _TypeFilter({
    required this.palette,
    required this.selected,
    required this.onChanged,
  });

  final JellyBeanPalette palette;
  final ExerciseType? selected;
  final ValueChanged<ExerciseType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _Chip(
            palette: palette,
            label: 'All',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 6),
          for (final ExerciseType type in ExerciseType.values) ...<Widget>[
            _Chip(
              palette: palette,
              label: type.label,
              selected: selected == type,
              onTap: () => onChanged(type),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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

class _CreateNewTile extends StatelessWidget {
  const _CreateNewTile({required this.palette, required this.onTap});

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
                      'Add it to your library and this workout.',
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

class _ExerciseOption extends StatelessWidget {
  const _ExerciseOption({
    required this.exercise,
    required this.palette,
    required this.onTap,
  });

  final Exercise exercise;
  final JellyBeanPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.shade100),
          ),
          child: Row(
            children: <Widget>[
              ExerciseAvatar(exercise: exercise, size: 40),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.shade950,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        ExerciseTypeBadge(type: exercise.type),
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette, required this.hasQuery});

  final JellyBeanPalette palette;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        children: <Widget>[
          Icon(
            hasQuery ? Icons.search_off_rounded : Icons.fitness_center_rounded,
            size: 32,
            color: palette.shade600,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasQuery ? 'No matches' : 'No exercises yet',
            style: TextStyle(
              color: palette.shade950,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasQuery ? 'Try a different search.' : 'Create one to get started.',
            style: TextStyle(
              color: palette.shade800.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
