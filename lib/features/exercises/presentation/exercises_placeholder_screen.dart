import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class ExercisesPlaceholderScreen extends StatelessWidget {
  const ExercisesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: null,
        icon: const Icon(Icons.add),
        label: const Text('New Exercise'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          Text(
            'Exercise management lands in Phase 3.',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This preview shows the tone of the list screen before CRUD, '
            'search, and exercise history are wired in.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _ExercisePreviewTile(
            letter: 'B',
            name: 'Bench Press',
            type: 'Weighted',
          ),
          const SizedBox(height: AppSpacing.md),
          const _ExercisePreviewTile(
            letter: 'P',
            name: 'Pull-Up',
            type: 'Bodyweight',
          ),
          const SizedBox(height: AppSpacing.md),
          const _ExercisePreviewTile(
            letter: 'T',
            name: 'Treadmill',
            type: 'Cardio',
          ),
        ],
      ),
    );
  }
}

class _ExercisePreviewTile extends StatelessWidget {
  const _ExercisePreviewTile({
    required this.letter,
    required this.name,
    required this.type,
  });

  final String letter;
  final String name;
  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 24,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Text(
                letter,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(type, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
