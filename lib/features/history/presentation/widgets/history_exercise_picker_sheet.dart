import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/exercise.dart';
import '../../../exercises/application/exercise_list_provider.dart';

/// Multi-select exercise picker for the History "Exercise" filter chip.
///
/// Mirrors the single-select sheet on the strength chart card but adds
/// checkbox semantics and an Apply/Clear footer. Returns the chosen ids
/// when the user taps Apply; tapping Clear (or applying with an empty
/// selection) clears the filter.
class HistoryExercisePickerSheet extends ConsumerStatefulWidget {
  const HistoryExercisePickerSheet({super.key, required this.initialIds});

  final Set<String> initialIds;

  @override
  ConsumerState<HistoryExercisePickerSheet> createState() =>
      _HistoryExercisePickerSheetState();
}

class _HistoryExercisePickerSheetState
    extends ConsumerState<HistoryExercisePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = <String>{...widget.initialIds};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Exercise> _filter(List<Exercise> all) {
    final String q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((Exercise e) => e.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final AsyncValue<List<Exercise>> exercisesAsync = ref.watch(
      exerciseListProvider,
    );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _Header(palette: palette, selectedCount: _selected.length),
              const SizedBox(height: AppSpacing.xs),
              _SearchField(
                controller: _searchController,
                palette: palette,
                query: _query,
                onChanged: (String v) => setState(() => _query = v),
              ),
              const SizedBox(height: AppSpacing.xs),
              Flexible(
                child: exercisesAsync.when(
                  data: (List<Exercise> all) {
                    final List<Exercise> visible = _filter(all);
                    if (visible.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          _query.trim().isEmpty
                              ? 'No exercises yet.'
                              : 'No exercises match "${_query.trim()}".',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: visible.length,
                      itemBuilder: (BuildContext _, int index) {
                        final Exercise e = visible[index];
                        final bool isSelected = _selected.contains(e.id);
                        return _ExerciseTile(
                          palette: palette,
                          exercise: e,
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selected.remove(e.id);
                              } else {
                                _selected.add(e.id);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (Object e, _) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'Could not load exercises.\n$e',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.shade700),
                    ),
                  ),
                ),
              ),
              _Footer(
                palette: palette,
                hasSelection: _selected.isNotEmpty,
                onClear: () {
                  Navigator.of(context).pop<Set<String>>(<String>{});
                },
                onApply: () {
                  Navigator.of(
                    context,
                  ).pop<Set<String>>(<String>{..._selected});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.palette, required this.selectedCount});

  final JellyBeanPalette palette;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'FILTER BY EXERCISE',
              style: TextStyle(
                color: palette.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
          if (selectedCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: palette.shade100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$selectedCount selected',
                style: TextStyle(
                  color: palette.shade800,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.palette,
    required this.query,
    required this.onChanged,
  });

  final TextEditingController controller;
  final JellyBeanPalette palette;
  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: palette.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.shade100),
        ),
        child: TextField(
          controller: controller,
          autofocus: false,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          style: TextStyle(
            color: palette.shade950,
            fontWeight: FontWeight.w600,
          ),
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
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: palette.shade700,
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.palette,
    required this.exercise,
    required this.selected,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final Exercise exercise;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        exercise.name,
        style: TextStyle(
          color: palette.shade950,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        exercise.muscleGroup.label,
        style: TextStyle(
          color: palette.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: selected ? palette.shade700 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? palette.shade700 : palette.shade300,
            width: 1.6,
          ),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : null,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.palette,
    required this.hasSelection,
    required this.onClear,
    required this.onApply,
  });

  final JellyBeanPalette palette;
  final bool hasSelection;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: hasSelection ? onClear : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.shade800,
                side: BorderSide(color: palette.shade200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Clear',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FilledButton(
              onPressed: onApply,
              style: FilledButton.styleFrom(
                backgroundColor: palette.shade900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
