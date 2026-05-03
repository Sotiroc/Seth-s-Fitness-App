import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/database_bootstrap.dart';
import '../../../data/models/exercise_pack.dart';
import '../../../data/repositories/exercise_pack_repository.dart';

part 'exercise_library_settings_screen.g.dart';

/// Local stream of installed packs for the settings screen. Mirrors the
/// equivalent provider in the exercises feature — kept here so this
/// feature can stand on its own without cross-feature imports.
@riverpod
Stream<List<ExercisePack>> librarySettingsPacks(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(exercisePackRepositoryProvider).watchAllPacks();
}

class ExerciseLibrarySettingsScreen extends ConsumerWidget {
  const ExerciseLibrarySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final AsyncValue<List<ExercisePack>> packs = ref.watch(
      librarySettingsPacksProvider,
    );

    return Scaffold(
      backgroundColor: palette.shade50,
      appBar: AppBar(
        backgroundColor: palette.shade50,
        title: const Text('Exercise library'),
      ),
      body: packs.when(
        data: (items) => _PackList(items: items, palette: palette),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Could not load packs: $err'),
          ),
        ),
      ),
    );
  }
}

class _PackList extends ConsumerWidget {
  const _PackList({required this.items, required this.palette});

  final List<ExercisePack> items;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'No packs installed yet.',
            style: TextStyle(color: palette.shade800),
          ),
        ),
      );
    }

    final int totalExercises = items.fold<int>(
      0,
      (sum, p) => sum + p.exerciseCount,
    );
    final int activeCount = items.where((p) => p.isActive).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: <Widget>[
        Text(
          '$totalExercises exercises across ${items.length} packs · '
          '$activeCount active',
          style: TextStyle(
            color: palette.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...items.map(
          (pack) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _PackTile(
              pack: pack,
              palette: palette,
              onChanged: (next) async {
                await ref
                    .read(exercisePackRepositoryProvider)
                    .setPackActive(packId: pack.id, isActive: next);
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (items.isNotEmpty)
          Text(
            'Source: ${items.first.credit}\nLicense: ${items.first.license}',
            style: TextStyle(
              color: palette.shade700.withValues(alpha: 0.75),
              fontSize: 11,
              height: 1.4,
            ),
          ),
      ],
    );
  }
}

class _PackTile extends StatelessWidget {
  const _PackTile({
    required this.pack,
    required this.palette,
    required this.onChanged,
  });

  final ExercisePack pack;
  final JellyBeanPalette palette;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onChanged(!pack.isActive),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.shade100),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            pack.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.shade950,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.shade100,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${pack.exerciseCount}',
                            style: TextStyle(
                              color: palette.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pack.description,
                      style: TextStyle(
                        color: palette.shade800.withValues(alpha: 0.8),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: pack.isActive,
                onChanged: onChanged,
                activeThumbColor: palette.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
