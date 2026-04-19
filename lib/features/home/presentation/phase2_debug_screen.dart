import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/exercise_type.dart';
import '../application/phase2_debug_snapshot_provider.dart';

class Phase2DebugScreen extends ConsumerWidget {
  const Phase2DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Phase2DebugSnapshot> snapshot = ref.watch(
      phase2DebugSnapshotProvider,
    );
    final JellyBeanPalette palette = context.jellyBeanPalette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 2 Debug Data'),
        actions: <Widget>[
          IconButton(
            onPressed: () => ref.invalidate(phase2DebugSnapshotProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: snapshot.when(
        data: (data) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: <Widget>[
                _CountCard(
                  label: 'Exercises',
                  value: data.exercises.length.toString(),
                  palette: palette,
                ),
                _CountCard(
                  label: 'Templates',
                  value: data.templates.length.toString(),
                  palette: palette,
                ),
                _CountCard(
                  label: 'Workouts',
                  value: data.totalWorkoutCount.toString(),
                  palette: palette,
                ),
                _CountCard(
                  label: 'Active workout',
                  value: data.activeWorkout == null ? 'No' : 'Yes',
                  palette: palette,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle(
              title: 'Seeded exercises',
              subtitle:
                  'Defaults should appear once on a fresh database and stay stable.',
            ),
            const SizedBox(height: AppSpacing.md),
            ...ExerciseType.values.map((type) {
              final List<Exercise> typedExercises = data.exercises
                  .where((exercise) => exercise.type == type)
                  .toList(growable: false);

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          type.label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: typedExercises
                              .map(
                                (exercise) => Chip(label: Text(exercise.name)),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Debug data failed to load.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: textTheme.bodyMedium),
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.shade800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
