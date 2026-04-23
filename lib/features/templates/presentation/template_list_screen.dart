import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/template_detail.dart';
import '../../../data/models/workout_template.dart';
import '../../../data/repositories/repository_exceptions.dart';
import '../application/template_editor_controller.dart';
import '../application/template_providers.dart';

/// Templates tab — lists routines the user has saved; each card offers
/// "start" (spawns a workout from the template) and edit/delete through a
/// popup menu.
class TemplateListScreen extends ConsumerWidget {
  const TemplateListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final AsyncValue<List<WorkoutTemplate>> templates = ref.watch(
      templateListProvider,
    );

    return Scaffold(
      backgroundColor: palette.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/templates/new'),
        backgroundColor: palette.shade900,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New template'),
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _Header(
              palette: palette,
              count: templates.asData?.value.length,
            ),
          ),
          templates.when(
            data: (items) {
              if (items.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(palette: palette),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  120,
                ),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _TemplateCard(template: items[index], palette: palette),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text('Could not load templates: $err'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.palette, required this.count});

  final JellyBeanPalette palette;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double topPadding = MediaQuery.paddingOf(context).top;

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
                  Container(width: 2, height: 14, color: palette.shade300),
                  const SizedBox(width: 8),
                  Text(
                    'ROUTINES',
                    style: TextStyle(
                      color: palette.shade200,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
              if (count != null)
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
                    '$count',
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
            'Templates',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reusable workout plans. Start one and every exercise is ready to go.',
            style: TextStyle(
              color: palette.shade100.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.template, required this.palette});

  final WorkoutTemplate template;
  final JellyBeanPalette palette;

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(templateEditorControllerProvider.notifier)
          .startWorkoutFromTemplate(template.id);
      if (!context.mounted) return;
      context.go('/workouts/active');
    } on ActiveWorkoutAlreadyExistsException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You already have an active workout — finish or cancel it first.',
          ),
        ),
      );
      context.go('/workouts/active');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start: $error')));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete "${template.name}"?',
          style: TextStyle(
            color: palette.shade950,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'This removes the template. Workouts already logged from it stay '
          'in your history.',
          style: TextStyle(color: palette.shade800, height: 1.4),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent.shade200,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(templateEditorControllerProvider.notifier)
          .deleteTemplate(template.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${template.name} deleted.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<TemplateDetail> detailAsync = ref.watch(
      templateDetailProvider(template.id),
    );
    final TemplateDetail? detail = detailAsync.asData?.value;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => context.push('/templates/${template.id}/edit'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      template.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.shade950,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<_TemplateAction>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: palette.shade700,
                    ),
                    onSelected: (action) {
                      switch (action) {
                        case _TemplateAction.edit:
                          context.push('/templates/${template.id}/edit');
                        case _TemplateAction.delete:
                          _delete(context, ref);
                      }
                    },
                    itemBuilder: (_) => const <PopupMenuEntry<_TemplateAction>>[
                      PopupMenuItem<_TemplateAction>(
                        value: _TemplateAction.edit,
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.edit_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem<_TemplateAction>(
                        value: _TemplateAction.delete,
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.delete_outline_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2),
              _TemplateSummary(detail: detail, palette: palette),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      onTap: () => _start(context, ref),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: palette.shade900,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Start workout',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  InkWell(
                    onTap: () => context.push('/templates/${template.id}/edit'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 46,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: palette.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.shade200),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: palette.shade800,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TemplateAction { edit, delete }

class _TemplateSummary extends StatelessWidget {
  const _TemplateSummary({required this.detail, required this.palette});

  final TemplateDetail? detail;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    if (detail == null) {
      return Text(
        'Loading exercises…',
        style: TextStyle(
          color: palette.shade700.withValues(alpha: 0.7),
          fontSize: 12.5,
        ),
      );
    }
    if (detail!.exercises.isEmpty) {
      return Text(
        'No exercises yet — tap to add some.',
        style: TextStyle(
          color: palette.shade700.withValues(alpha: 0.7),
          fontSize: 12.5,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    final int totalSets = detail!.exercises.fold<int>(
      0,
      (sum, e) => sum + e.templateExercise.defaultSets,
    );
    final String summary = detail!.exercises
        .take(3)
        .map((e) => e.exercise.name)
        .join(' · ');
    final String suffix = detail!.exercises.length > 3
        ? ' · +${detail!.exercises.length - 3}'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${detail!.exercises.length} '
          '${detail!.exercises.length == 1 ? "exercise" : "exercises"} · '
          '$totalSets '
          '${totalSets == 1 ? "set" : "sets"}',
          style: TextStyle(
            color: palette.shade700,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$summary$suffix',
          style: TextStyle(
            color: palette.shade800.withValues(alpha: 0.8),
            fontSize: 12.5,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette});

  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: AppSpacing.xl),
          Icon(Icons.auto_awesome_rounded, size: 48, color: palette.shade400),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No templates yet',
            style: TextStyle(
              color: palette.shade950,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Build a routine once, run it as often as you like.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.shade800.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
