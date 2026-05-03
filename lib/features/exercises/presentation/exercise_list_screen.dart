import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/illustrated_empty_state.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/exercise_type.dart';
import '../../../data/repositories/repository_exceptions.dart';
import '../../home/presentation/widgets/menu_icon_button.dart';
import '../application/exercise_editor_controller.dart';
import '../application/exercise_list_provider.dart';
import 'widgets/exercise_avatar.dart';
import 'widgets/exercise_history_sheet.dart';
import 'widgets/exercise_muscle_group_badge.dart';
import 'widgets/exercise_type_badge.dart';

class ExerciseListScreen extends ConsumerWidget {
  const ExerciseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final AsyncValue<List<Exercise>> all = ref.watch(exerciseListProvider);
    final AsyncValue<List<Exercise>> filtered = ref.watch(
      filteredExercisesProvider,
    );
    final ExerciseListFilter filter = ref.watch(exerciseFilterProvider);
    final int? totalCount = all.asData?.value.length;

    return Scaffold(
      backgroundColor: palette.shade50,
      drawerEnableOpenDragGesture: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/exercises/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Exercise'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(exerciseListProvider);
        },
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: _Header(palette: palette, totalCount: totalCount),
            ),
            SliverToBoxAdapter(
              child: _FilterBar(
                palette: palette,
                filter: filter,
                onQueryChanged: (value) =>
                    ref.read(exerciseFilterProvider.notifier).setQuery(value),
                onTypeChanged: (value) =>
                    ref.read(exerciseFilterProvider.notifier).setType(value),
              ),
            ),
            filtered.when(
              data: (items) => items.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        hasFilter:
                            filter.query.isNotEmpty || filter.type != null,
                        onClear: () =>
                            ref.read(exerciseFilterProvider.notifier).clear(),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        96,
                      ),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final Exercise exercise = items[index];
                          return _ExerciseTile(
                            exercise: exercise,
                            palette: palette,
                            onTap: () => ExerciseHistorySheet.show(
                              context,
                              exerciseId: exercise.id,
                              showEditButton: true,
                            ),
                            onEdit: () =>
                                context.push('/exercises/${exercise.id}/edit'),
                            onViewHistory: () => ExerciseHistorySheet.show(
                              context,
                              exerciseId: exercise.id,
                              showEditButton: true,
                            ),
                            onDelete: () =>
                                _confirmDelete(context, ref, exercise),
                          );
                        },
                      ),
                    ),
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  palette: palette,
                  message: err.toString(),
                  onRetry: () => ref.invalidate(exerciseListProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Exercise exercise,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${exercise.name}?'),
        content: Text(
          exercise.isDefault
              ? 'This is a default exercise. Deleting it removes it only from your device.'
              : 'This exercise will be removed permanently.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(exerciseEditorControllerProvider.notifier)
          .deleteExercise(exercise);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${exercise.name} deleted.')));
    } on ExerciseDeleteBlockedException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This exercise is used by a workout or template and cannot be deleted.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.palette, required this.totalCount});

  final JellyBeanPalette palette;
  final int? totalCount;

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topPadding + AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.shade950, palette.shade700],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const MenuIconButton(),
                  const SizedBox(width: AppSpacing.sm),
                  Container(width: 2, height: 14, color: palette.shade300),
                  const SizedBox(width: 8),
                  Text(
                    'LIBRARY',
                    style: TextStyle(
                      color: palette.shade200,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
              if (totalCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    '$totalCount',
                    style: TextStyle(
                      color: palette.shade100,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Exercises',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your catalogue of lifts, bodyweight work, and cardio.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.shade100.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.palette,
    required this.filter,
    required this.onQueryChanged,
    required this.onTypeChanged,
  });

  final JellyBeanPalette palette;
  final ExerciseListFilter filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<ExerciseType?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SearchField(
            palette: palette,
            value: filter.query,
            onChanged: onQueryChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          _TypeChips(
            palette: palette,
            selected: filter.type,
            onChanged: onTypeChanged,
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.palette,
    required this.value,
    required this.onChanged,
  });

  final JellyBeanPalette palette;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.palette.shade100),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          hintText: 'Search exercises',
          hintStyle: TextStyle(
            color: widget.palette.shade700.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: widget.palette.shade600,
            size: 20,
          ),
          suffixIcon: widget.value.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: widget.palette.shade700,
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}

class _TypeChips extends StatelessWidget {
  const _TypeChips({
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
      physics: const ClampingScrollPhysics(),
      child: Row(
        children: <Widget>[
          _Chip(
            palette: palette,
            label: 'All',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: AppSpacing.xs),
          for (final ExerciseType type in ExerciseType.values) ...<Widget>[
            _Chip(
              palette: palette,
              label: type.label,
              selected: selected == type,
              onTap: () => onChanged(type),
            ),
            const SizedBox(width: AppSpacing.xs),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.exercise,
    required this.palette,
    required this.onTap,
    required this.onEdit,
    required this.onViewHistory,
    required this.onDelete,
  });

  final Exercise exercise;
  final JellyBeanPalette palette;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onViewHistory;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              ExerciseAvatar(exercise: exercise, size: 44),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            exercise.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.shade950,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (exercise.isDefault) ...<Widget>[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: palette.shade500,
                          ),
                        ],
                      ],
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
              _TileMenu(
                palette: palette,
                onEdit: onEdit,
                onViewHistory: onViewHistory,
                onDelete: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileMenu extends StatelessWidget {
  const _TileMenu({
    required this.palette,
    required this.onEdit,
    required this.onViewHistory,
    required this.onDelete,
  });

  final JellyBeanPalette palette;
  final VoidCallback onEdit;
  final VoidCallback onViewHistory;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: palette.shade700),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        switch (value) {
          case 'history':
            onViewHistory();
          case 'edit':
            onEdit();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'history',
          child: _MenuRow(icon: Icons.timeline_rounded, label: 'View History'),
        ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'delete',
          child: _MenuRow(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            destructive: true,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color color = destructive ? colors.error : colors.onSurface;
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasFilter,
    required this.onClear,
  });

  final bool hasFilter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return IllustratedEmptyState(
      illustrationAsset: AppIllustrations.emptyExercises,
      title: hasFilter ? 'Nothing matches' : 'No exercises yet',
      message: hasFilter
          ? 'Try a different search or clear the filter to see your full library.'
          : 'Add your first exercise to start building workouts.',
      actionLabel: hasFilter ? 'Clear filters' : null,
      onAction: hasFilter ? onClear : null,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.palette,
    required this.message,
    required this.onRetry,
  });

  final JellyBeanPalette palette;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.error_outline_rounded, size: 40, color: palette.shade700),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Failed to load exercises',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: palette.shade800),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
