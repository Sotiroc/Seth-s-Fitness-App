import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/exercise.dart';

/// Tap target inside the strength chart card. Shows the currently
/// selected exercise (or a placeholder), and opens a modal sheet listing
/// all trackable exercises when tapped. Mirrors `_OptionPickerField` /
/// `_pickGender` behaviour from the profile form.
class ExercisePickerField extends StatelessWidget {
  const ExercisePickerField({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Exercise> options;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final ThemeData theme = Theme.of(context);
    final Exercise? selected = selectedId == null
        ? null
        : options.cast<Exercise?>().firstWhere(
            (Exercise? e) => e?.id == selectedId,
            orElse: () => null,
          );
    final String label = selected?.name ?? 'Choose exercise';
    final bool hasSelection = selected != null;

    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: palette.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.shade100),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: hasSelection ? palette.shade950 : palette.shade700,
                  fontWeight: hasSelection
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontStyle: hasSelection ? null : FontStyle.italic,
                ),
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              color: palette.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _ExercisePickerSheet(
            options: options,
            selectedId: selectedId,
            onSelect: (String? id) {
              onSelect(id);
              Navigator.of(sheetContext).pop();
            },
          ),
        );
      },
    );
  }
}

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet({
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Exercise> options;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Exercise> get _filtered {
    final String q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options
        .where((Exercise e) => e.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final List<Exercise> visible = _filtered;
    final MediaQueryData mq = MediaQuery.of(context);
    // Target ~85% of the screen so the picker dominates the view, but
    // shrink by the keyboard height when it's open so the sheet doesn't
    // overflow the viewport. Falls back gracefully on very short screens.
    final double availableHeight = mq.size.height - mq.viewInsets.bottom;
    final double targetHeight = (availableHeight * 0.85).clamp(
      300.0,
      availableHeight,
    );

    return SafeArea(
      child: SizedBox(
        height: targetHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      'CHOOSE EXERCISE',
                      style: TextStyle(
                        color: palette.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
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
                    color: palette.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.shade100),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: (String value) =>
                        setState(() => _query = value),
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
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                              ),
                              color: palette.shade700,
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: visible.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          'No exercises match "${_query.trim()}".',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (BuildContext _, int index) {
                          final Exercise e = visible[index];
                          final bool isSelected = e.id == widget.selectedId;
                          return ListTile(
                            title: Text(
                              e.name,
                              style: TextStyle(
                                color: palette.shade950,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_rounded,
                                    color: palette.shade700,
                                  )
                                : null,
                            onTap: () => widget.onSelect(e.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
