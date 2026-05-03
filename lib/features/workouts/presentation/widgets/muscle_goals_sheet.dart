import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/exercise_muscle_group.dart';
import '../../../../data/repositories/user_profile_repository.dart';
import '../../application/muscle_goals_provider.dart';

const int _minGoal = 0;
const int _maxGoal = 30;
const int _stepGoal = 1;
// Cardio is measured in minutes per week and uses a typed input rather
// than stepper buttons, so it gets a roomier ceiling — 600 = 10 hr/wk,
// well above any reasonable user target.
const int _maxCardioGoal = 600;

int _maxFor(ExerciseMuscleGroup mg) =>
    mg == ExerciseMuscleGroup.cardio ? _maxCardioGoal : _maxGoal;

/// Opens the modal bottom sheet that lets the user customise their weekly
/// per-muscle set goals. Saves are debounced — every change schedules a
/// write 350ms later so rapid taps coalesce into a single DB upsert.
///
/// Uses [AnimationStyle] to stretch the default 250ms slide-up to 400ms
/// (and snap the dismissal back at 220ms) so the sheet glides into place
/// rather than appearing to pop instantly on fast devices. Unlike a
/// manual `transitionAnimationController`, [AnimationStyle] lets Flutter
/// own the controller's lifecycle so we can't leak it or dispose it
/// mid-teardown.
Future<void> showMuscleGoalsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    sheetAnimationStyle: AnimationStyle(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 220),
    ),
    builder: (BuildContext sheetContext) => const _MuscleGoalsSheet(),
  );
}

class _MuscleGoalsSheet extends ConsumerStatefulWidget {
  const _MuscleGoalsSheet();

  @override
  ConsumerState<_MuscleGoalsSheet> createState() => _MuscleGoalsSheetState();
}

class _MuscleGoalsSheetState extends ConsumerState<_MuscleGoalsSheet> {
  late Map<ExerciseMuscleGroup, int> _draft;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _draft = Map<ExerciseMuscleGroup, int>.from(ref.read(muscleGoalsProvider));
  }

  @override
  void dispose() {
    // Flush any pending edit synchronously — fire-and-forget. The provider
    // will pick up the new values on the next watch.
    if (_saveDebounce?.isActive ?? false) {
      _saveDebounce?.cancel();
      _persist(_draft);
    }
    super.dispose();
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 350), () {
      _persist(_draft);
    });
  }

  Future<void> _persist(Map<ExerciseMuscleGroup, int> goals) async {
    try {
      await ref
          .read(userProfileRepositoryProvider)
          .updateMuscleGoals(goals);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save goals: $e')),
      );
    }
  }

  void _setGoal(ExerciseMuscleGroup mg, int value) {
    final int clamped = value.clamp(_minGoal, _maxFor(mg));
    if (_draft[mg] == clamped) return;
    setState(() {
      _draft = <ExerciseMuscleGroup, int>{..._draft, mg: clamped};
    });
    _scheduleSave();
  }

  void _resetToDefaults() {
    setState(() {
      _draft = Map<ExerciseMuscleGroup, int>.from(defaultMuscleGoals);
    });
    _scheduleSave();
  }

  /// Display label for a goal row. Mirrors the abbreviation used in the
  /// in-workout strip ("Delts" instead of "Shoulders") so the same term
  /// appears in both views; other muscles use their canonical label.
  static String _goalRowLabel(ExerciseMuscleGroup mg) {
    if (mg == ExerciseMuscleGroup.shoulders) return 'Delts';
    return mg.label;
  }

  /// Builds the muscle-goal rows interleaved with hairline dividers, so
  /// the sheet has visual rhythm instead of reading as one continuous
  /// block. Cardio uses a typed input; everything else uses steppers.
  List<Widget> _buildGoalRows(JellyBeanPalette palette) {
    final List<Widget> rows = <Widget>[];
    final List<ExerciseMuscleGroup> values = ExerciseMuscleGroup.values;
    for (int i = 0; i < values.length; i++) {
      if (i > 0) {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(height: 1, color: palette.shade100),
          ),
        );
      }
      final ExerciseMuscleGroup mg = values[i];
      if (mg == ExerciseMuscleGroup.cardio) {
        rows.add(
          _CardioGoalRow(
            palette: palette,
            value: _draft[mg] ?? 0,
            onChanged: (int v) => _setGoal(mg, v),
          ),
        );
      } else {
        rows.add(
          _GoalRow(
            palette: palette,
            label: _goalRowLabel(mg),
            value: _draft[mg] ?? 0,
            onDecrement: () => _setGoal(mg, (_draft[mg] ?? 0) - _stepGoal),
            onIncrement: () => _setGoal(mg, (_draft[mg] ?? 0) + _stepGoal),
          ),
        );
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Handle(palette: palette),
              const SizedBox(height: AppSpacing.md),
              // No close button — swipe down or tap outside to dismiss.
              // A manual close icon previously triggered a disposal race
              // with our custom AnimationController; AnimationStyle now
              // owns the lifecycle, but the X button is genuinely
              // redundant alongside the drag handle and barrier tap.
              Text(
                'Weekly set goals',
                style: TextStyle(
                  color: palette.shade950,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Target sets per muscle group, per week.',
                style: TextStyle(
                  color: palette.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ..._buildGoalRows(palette),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton.icon(
                  onPressed: _resetToDefaults,
                  icon: Icon(
                    Icons.restart_alt_rounded,
                    color: palette.shade700,
                    size: 18,
                  ),
                  label: Text(
                    'Reset to defaults',
                    style: TextStyle(
                      color: palette.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle({required this.palette});

  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: palette.shade100,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.palette,
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final JellyBeanPalette palette;
  final String label;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final bool minReached = value <= _minGoal;
    final bool maxReached = value >= _maxGoal;
    final bool disabled = value == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: palette.shade950,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _StepperButton(
            palette: palette,
            icon: Icons.remove_rounded,
            enabled: !minReached,
            isIncrement: false,
            onTap: onDecrement,
          ),
          SizedBox(
            width: 56,
            child: Text(
              disabled ? 'Off' : '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: disabled
                    ? palette.shade700.withValues(alpha: 0.6)
                    : palette.shade950,
                fontSize: disabled ? 13 : 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                fontStyle: disabled ? FontStyle.italic : FontStyle.normal,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          _StepperButton(
            palette: palette,
            icon: Icons.add_rounded,
            enabled: !maxReached,
            isIncrement: true,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

/// Stepper button for the goal rows. Increment (+) is a filled brand-teal
/// pill (primary action — "more, please"); decrement (−) is an outlined
/// chip in light teal (secondary action). The asymmetry is intentional:
/// it gives the row visual weight on the right and lets the eye scan the
/// list as "label → number → action" rather than two identical buttons.
class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.palette,
    required this.icon,
    required this.enabled,
    required this.isIncrement,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final IconData icon;
  final bool enabled;
  final bool isIncrement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ({Color background, Color border, Color icon}) colors = _resolveColors(
      palette,
      enabled: enabled,
      isIncrement: isIncrement,
    );

    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Icon(icon, size: 18, color: colors.icon),
        ),
      ),
    );
  }

  static ({Color background, Color border, Color icon}) _resolveColors(
    JellyBeanPalette palette, {
    required bool enabled,
    required bool isIncrement,
  }) {
    if (isIncrement) {
      // + is filled. Solid brand teal at full strength when enabled,
      // muted shade300 when capped at the max so the user still sees the
      // "+" but understands it's not actionable.
      return enabled
          ? (
              background: palette.shade500,
              border: Colors.transparent,
              icon: Colors.white,
            )
          : (
              background: palette.shade200,
              border: Colors.transparent,
              icon: Colors.white.withValues(alpha: 0.65),
            );
    }
    // − is outlined. White fill, mid-teal border, deeper icon — reads as
    // a secondary action paired with the filled +. Goes lighter when
    // disabled at zero.
    return enabled
        ? (
            background: Colors.white,
            border: palette.shade300,
            icon: palette.shade700,
          )
        : (
            background: palette.shade50,
            border: palette.shade100,
            icon: palette.shade400,
          );
  }
}

/// Cardio's goal row uses a typed number input + "min" suffix because
/// cardio is measured in minutes per week, not sets. The +/- steppers
/// would force the user through tens of taps to reach a sensible value
/// (e.g., 90 min/wk → 90 taps); a text input lets them just type.
///
/// Stateful so it owns its [TextEditingController]. Externally-driven
/// value changes (e.g., "Reset to defaults") only re-seed the field
/// when it doesn't have focus, so the user's typing isn't fought.
class _CardioGoalRow extends StatefulWidget {
  const _CardioGoalRow({
    required this.palette,
    required this.value,
    required this.onChanged,
  });

  final JellyBeanPalette palette;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_CardioGoalRow> createState() => _CardioGoalRowState();
}

class _CardioGoalRowState extends State<_CardioGoalRow> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(_CardioGoalRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      widget.onChanged(0);
      return;
    }
    final int? parsed = int.tryParse(trimmed);
    if (parsed == null) return;
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = widget.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Cardio',
              style: TextStyle(
                color: palette.shade950,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.shade950,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 9,
                ),
                filled: true,
                fillColor: palette.shade50,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: palette.shade100),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: palette.shade500,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: _handleChanged,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'min',
            style: TextStyle(
              color: palette.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
