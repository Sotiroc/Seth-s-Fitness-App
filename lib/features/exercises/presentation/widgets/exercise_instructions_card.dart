import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Collapsible card that renders the multi-step form instructions
/// imported from a library pack. Shows nothing when [steps] is empty.
class ExerciseInstructionsCard extends StatefulWidget {
  const ExerciseInstructionsCard({
    super.key,
    required this.steps,
    this.initiallyExpanded = false,
  });

  final List<String> steps;
  final bool initiallyExpanded;

  @override
  State<ExerciseInstructionsCard> createState() =>
      _ExerciseInstructionsCardState();
}

class _ExerciseInstructionsCardState extends State<ExerciseInstructionsCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final ThemeData theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: palette.shade100),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: palette.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HOW TO',
                    style: TextStyle(
                      color: palette.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.steps.length} step${widget.steps.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: palette.shade700.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: palette.shade700,
                  ),
                ],
              ),
              if (_expanded) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                for (int i = 0; i < widget.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: palette.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            widget.steps[i],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.shade950,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ] else ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.steps.first,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
