import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../data/models/exercise_type.dart';
import '../../../../data/models/workout_set.dart';
import '../../../../data/models/workout_set_kind.dart';
import 'set_kind_visuals.dart';

/// A single row in the set-logging table. Three visual variants depending on
/// the exercise type; commits to the backend via [onChanged] callbacks.
///
/// Local [TextEditingController]s hold the user's in-progress input. We commit
/// upward on field submission (enter) or focus loss, and on complete-toggle.
class SetRow extends StatefulWidget {
  const SetRow({
    super.key,
    required this.set,
    required this.exerciseType,
    required this.previousSummary,
    required this.onCommit,
    this.previousSet,
    this.roundTop = true,
    this.roundBottom = true,
    this.onSetCompleted,
    this.onSetUncompleted,
    this.onTapSetNumber,
  });

  final WorkoutSet set;
  final ExerciseType exerciseType;

  /// Pre-formatted string for the "Previous" column, or `-` if unavailable.
  final String previousSummary;

  /// The user's last completed set at this set number, if any. When non-null
  /// and tapped, its values fill the row's input fields and commit. Kept
  /// alongside [previousSummary] (which is the rendered string) so we don't
  /// have to re-parse the formatted text.
  final WorkoutSet? previousSet;

  /// Called to persist a change. Pass the next full value set; the caller
  /// forwards to the session controller.
  final Future<void> Function({
    double? weightKg,
    int? reps,
    double? distanceKm,
    int? durationSeconds,
    required bool completed,
  })
  onCommit;

  /// Whether the completed-state overlay should round its top corners. The
  /// parent sets these to false when the neighbouring row is also completed,
  /// so a run of completed rows reads as a single rounded block instead of a
  /// stack of individually-rounded pills.
  final bool roundTop;
  final bool roundBottom;

  /// Fires after a successful false→true completion transition. Parent
  /// uses this to start the rest timer. Not called on re-saves of an
  /// already-completed set or when the commit fails.
  final VoidCallback? onSetCompleted;

  /// Fires after a successful true→false uncomplete transition. Parent
  /// uses this to dismiss the running rest timer when the user changes
  /// their mind.
  final VoidCallback? onSetUncompleted;

  /// Tapped when the user hits the set-number badge. The parent decides
  /// what UI to show based on `set.completed` — a quick popup menu (type
  /// picker) for incomplete sets, or the richer details sheet (RPE +
  /// note) for completed ones. The [BuildContext] handed back is the
  /// badge's own context, so the parent can anchor a popup menu directly
  /// to the tapped widget.
  final void Function(BuildContext anchorContext)? onTapSetNumber;

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late final TextEditingController _distanceController;
  late final TextEditingController _durationController;

  final FocusNode _weightFocus = FocusNode();
  final FocusNode _repsFocus = FocusNode();
  final FocusNode _distanceFocus = FocusNode();
  final FocusNode _durationFocus = FocusNode();

  bool _saving = false;
  bool _completing = false;
  bool _suppressNextBlurCommit = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.set.weightKg == null
          ? ''
          : _formatNumber(widget.set.weightKg!),
    );
    _repsController = TextEditingController(
      text: widget.set.reps == null ? '' : widget.set.reps.toString(),
    );
    _distanceController = TextEditingController(
      text: widget.set.distanceKm == null
          ? ''
          : _formatNumber(widget.set.distanceKm!),
    );
    _durationController = TextEditingController(
      text: widget.set.durationSeconds == null
          ? ''
          : DurationFormatter.formatSeconds(widget.set.durationSeconds!),
    );

    _weightFocus.addListener(() => _commitOnBlur(_weightFocus));
    _repsFocus.addListener(() => _commitOnBlur(_repsFocus));
    _distanceFocus.addListener(() => _commitOnBlur(_distanceFocus));
    _durationFocus.addListener(() => _commitOnBlur(_durationFocus));
  }

  @override
  void didUpdateWidget(covariant SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Server state can change when a set is replaced or when validation
    // normalises values. Sync controllers if the field isn't currently focused.
    if (!_weightFocus.hasFocus) {
      final String next = widget.set.weightKg == null
          ? ''
          : _formatNumber(widget.set.weightKg!);
      if (_weightController.text != next) _weightController.text = next;
    }
    if (!_repsFocus.hasFocus) {
      final String next = widget.set.reps == null
          ? ''
          : widget.set.reps.toString();
      if (_repsController.text != next) _repsController.text = next;
    }
    if (!_distanceFocus.hasFocus) {
      final String next = widget.set.distanceKm == null
          ? ''
          : _formatNumber(widget.set.distanceKm!);
      if (_distanceController.text != next) _distanceController.text = next;
    }
    if (!_durationFocus.hasFocus) {
      final String next = widget.set.durationSeconds == null
          ? ''
          : DurationFormatter.formatSeconds(widget.set.durationSeconds!);
      if (_durationController.text != next) _durationController.text = next;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    _distanceFocus.dispose();
    _durationFocus.dispose();
    super.dispose();
  }

  void _commitOnBlur(FocusNode node) {
    if (_suppressNextBlurCommit) {
      _suppressNextBlurCommit = false;
      return;
    }
    if (!node.hasFocus && !widget.set.completed) {
      _commit(completed: widget.set.completed);
    }
  }

  double? _parseWeight() {
    final String text = _weightController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  int? _parseReps() {
    final String text = _repsController.text.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  double? _parseDistance() {
    final String text = _distanceController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  int? _parseDuration() {
    final String text = _durationController.text.trim();
    if (text.isEmpty) return null;
    return DurationFormatter.parseSeconds(text);
  }

  /// Returns `true` when the commit reached the server successfully so
  /// callers can distinguish a real completion from a swallowed error.
  Future<bool> _commit({
    required bool completed,
    bool showCompletionBusy = false,
  }) async {
    if (_saving) return false;
    setState(() {
      _saving = true;
      _completing = showCompletionBusy;
    });
    bool ok = false;
    try {
      switch (widget.exerciseType) {
        case ExerciseType.weighted:
          await widget.onCommit(
            weightKg: _parseWeight(),
            reps: _parseReps(),
            distanceKm: null,
            durationSeconds: null,
            completed: completed,
          );
        case ExerciseType.bodyweight:
          await widget.onCommit(
            weightKg: null,
            reps: _parseReps(),
            distanceKm: null,
            durationSeconds: null,
            completed: completed,
          );
        case ExerciseType.cardio:
          await widget.onCommit(
            weightKg: null,
            reps: null,
            distanceKm: _parseDistance(),
            durationSeconds: _parseDuration(),
            completed: completed,
          );
      }
      ok = true;
    } catch (_) {
      // Error surfaced by the parent via snackbar; keep local state intact so
      // the user can correct without losing input.
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _completing = false;
        });
      }
    }
    return ok;
  }

  Future<void> _toggleCompleted() async {
    if (_saving) return;
    _suppressNextBlurCommit = true;

    final bool wasCompleted = widget.set.completed;
    final bool next = !wasCompleted;
    if (next) {
      // Validate client-side to give immediate feedback; backend validation
      // is authoritative.
      final String? error = _validateForCompletion();
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), duration: const Duration(seconds: 2)),
        );
        return;
      }
    }
    final bool ok = await _commit(completed: next, showCompletionBusy: true);
    if (!ok || !mounted) return;
    if (next && !wasCompleted) {
      widget.onSetCompleted?.call();
    } else if (!next && wasCompleted) {
      widget.onSetUncompleted?.call();
    }
  }

  Future<void> _applyPrevious() async {
    final WorkoutSet? prev = widget.previousSet;
    if (prev == null) return;
    if (widget.set.completed) return;
    if (_saving) return;

    // Updating controllers will fire focus-loss commits later if the user
    // already had a field focused; suppress that one to keep this to a single
    // explicit commit.
    _suppressNextBlurCommit = true;

    switch (widget.exerciseType) {
      case ExerciseType.weighted:
        _weightController.text = prev.weightKg == null
            ? ''
            : _formatNumber(prev.weightKg!);
        _repsController.text = prev.reps?.toString() ?? '';
      case ExerciseType.bodyweight:
        _repsController.text = prev.reps?.toString() ?? '';
      case ExerciseType.cardio:
        _distanceController.text = prev.distanceKm == null
            ? ''
            : _formatNumber(prev.distanceKm!);
        _durationController.text = prev.durationSeconds == null
            ? ''
            : DurationFormatter.formatSeconds(prev.durationSeconds!);
    }

    await _commit(completed: false);
  }

  String? _validateForCompletion() {
    switch (widget.exerciseType) {
      case ExerciseType.weighted:
        if (_parseWeight() == null) return 'Enter a weight first.';
        if (_parseReps() == null) return 'Enter reps first.';
      case ExerciseType.bodyweight:
        if (_parseReps() == null) return 'Enter reps first.';
      case ExerciseType.cardio:
        if (_parseDistance() == null) return 'Enter distance first.';
        if (_parseDuration() == null) return 'Enter time first.';
    }
    return null;
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final bool completed = widget.set.completed;
    final WorkoutSetKind kind = widget.set.kind;
    final SetKindVisuals visuals = SetKindVisuals.forKind(kind, palette);
    final bool isDrop = kind == WorkoutSetKind.drop;
    // Drops are visually nested under the parent working set with a small
    // left indent + a connector strip on the leading edge so the chain is
    // legible at a glance even before the user opens the sheet.
    final double leftPad = isDrop ? 22.0 : 4.0;

    return TextFieldTapRegion(
      child: Stack(
        children: <Widget>[
          // Per-kind tint stripe sits underneath the row content. Subtle by
          // design — the brand teal still wins.
          if (visuals.tint != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: visuals.tint!.withValues(
                      alpha: completed ? 0.35 : 0.6,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(widget.roundTop ? 10 : 0),
                      topRight: Radius.circular(widget.roundTop ? 10 : 0),
                      bottomLeft: Radius.circular(widget.roundBottom ? 10 : 0),
                      bottomRight: Radius.circular(widget.roundBottom ? 10 : 0),
                    ),
                  ),
                ),
              ),
            ),
          // Drop-set connector: a short vertical bar on the leading edge so
          // the indented row reads as a child of the working set above it.
          if (isDrop && visuals.accent != null)
            Positioned(
              left: 6,
              top: 4,
              bottom: 4,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: visuals.accent!.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Container(
            padding: EdgeInsets.fromLTRB(leftPad, 6, 4, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _SetNumberButton(
                  set: widget.set,
                  palette: palette,
                  visuals: visuals,
                  onTap: widget.onTapSetNumber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Builder(
                    builder: (BuildContext context) {
                      final bool actionable =
                          widget.previousSet != null && !completed;
                      return Semantics(
                        button: actionable,
                        label: actionable ? 'Use previous set values' : null,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: actionable ? _applyPrevious : null,
                          child: Text(
                            widget.previousSummary,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: palette.shade700.withValues(
                                alpha: actionable ? 0.85 : 0.5,
                              ),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ..._valueFields(palette),
                const SizedBox(width: 8),
                _CompleteButton(
                  completed: completed,
                  busy: _completing,
                  palette: palette,
                  onPressed: _toggleCompleted,
                  onPressStart: () => _suppressNextBlurCommit = true,
                ),
              ],
            ),
          ),
          // Experimental: when a set is marked complete, drop a translucent
          // tint over the whole row so the "done" state reads at a glance,
          // instead of relying solely on the disabled input fill colour.
          // Lets pointer events through so the complete-toggle remains tappable.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: completed ? 1.0 : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.shade300.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(widget.roundTop ? 10 : 0),
                      topRight: Radius.circular(widget.roundTop ? 10 : 0),
                      bottomLeft: Radius.circular(widget.roundBottom ? 10 : 0),
                      bottomRight: Radius.circular(widget.roundBottom ? 10 : 0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _valueFields(JellyBeanPalette palette) {
    switch (widget.exerciseType) {
      case ExerciseType.weighted:
        return <Widget>[
          Expanded(
            flex: 2,
            child: _NumberField(
              controller: _weightController,
              focusNode: _weightFocus,
              palette: palette,
              hint: 'kg',
              decimal: true,
              enabled: !widget.set.completed,
              onSubmitted: () => _commit(completed: false),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: _NumberField(
              controller: _repsController,
              focusNode: _repsFocus,
              palette: palette,
              hint: 'reps',
              decimal: false,
              enabled: !widget.set.completed,
              onSubmitted: () => _commit(completed: false),
            ),
          ),
        ];
      case ExerciseType.bodyweight:
        return <Widget>[
          Expanded(
            flex: 4,
            child: _NumberField(
              controller: _repsController,
              focusNode: _repsFocus,
              palette: palette,
              hint: 'reps',
              decimal: false,
              enabled: !widget.set.completed,
              onSubmitted: () => _commit(completed: false),
            ),
          ),
        ];
      case ExerciseType.cardio:
        return <Widget>[
          Expanded(
            flex: 2,
            child: _NumberField(
              controller: _distanceController,
              focusNode: _distanceFocus,
              palette: palette,
              hint: 'km',
              decimal: true,
              enabled: !widget.set.completed,
              onSubmitted: () => _commit(completed: false),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: _DurationField(
              controller: _durationController,
              focusNode: _durationFocus,
              palette: palette,
              enabled: !widget.set.completed,
              onSubmitted: () => _commit(completed: false),
            ),
          ),
        ];
    }
  }
}

/// The leading "set number" cell. Tappable on every set — opens the set
/// details sheet so the user can attach kind / RPE / note. Renders the
/// kind's short letter (W / D / F) when set, or the position number for
/// normal sets. A small RPE/note dot row sits underneath the badge.
class _SetNumberButton extends StatelessWidget {
  const _SetNumberButton({
    required this.set,
    required this.palette,
    required this.visuals,
    required this.onTap,
  });

  final WorkoutSet set;
  final JellyBeanPalette palette;
  final SetKindVisuals visuals;
  final void Function(BuildContext anchorContext)? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isCustomKind = set.kind != WorkoutSetKind.normal;
    final Color badgeColor = isCustomKind
        ? (visuals.accent ?? palette.shade100)
        : palette.shade100;
    final Color textColor = isCustomKind ? Colors.white : palette.shade800;
    final String label = isCustomKind ? visuals.shortLabel : '${set.setNumber}';

    final Widget badge = Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );

    // Builder gives us a BuildContext whose RenderObject is the badge
    // itself, so the parent can anchor the popup menu directly under it.
    return Builder(
      builder: (BuildContext anchorContext) {
        return Semantics(
          button: onTap != null,
          label: 'Set ${set.setNumber} details',
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap!(anchorContext);
                  },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  badge,
                  if (set.rpe != null ||
                      (set.note != null && set.note!.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: _ExtrasIndicators(set: set, palette: palette),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExtrasIndicators extends StatelessWidget {
  const _ExtrasIndicators({required this.set, required this.palette});

  final WorkoutSet set;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    if (set.rpe != null) {
      children.add(
        Text(
          '${set.rpe}',
          style: TextStyle(
            color: palette.shade700,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            height: 1.0,
          ),
        ),
      );
    }
    if (set.note != null && set.note!.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 3));
      children.add(
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: palette.shade700.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.focusNode,
    required this.palette,
    required this.hint,
    required this.decimal,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final JellyBeanPalette palette;
  final String hint;
  final bool decimal;
  final bool enabled;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: <TextInputFormatter>[
        if (decimal)
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]*[.,]?[0-9]*'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmitted(),
      style: TextStyle(
        color: palette.shade950,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        hintText: hint,
        hintStyle: TextStyle(
          color: palette.shade700.withValues(alpha: 0.45),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: enabled ? palette.shade50 : palette.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.shade500, width: 1.4),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.shade100),
        ),
      ),
    );
  }
}

class _DurationField extends StatelessWidget {
  const _DurationField({
    required this.controller,
    required this.focusNode,
    required this.palette,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final JellyBeanPalette palette;
  final bool enabled;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
      ],
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmitted(),
      style: TextStyle(
        color: palette.shade950,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        hintText: 'mm:ss',
        hintStyle: TextStyle(
          color: palette.shade700.withValues(alpha: 0.45),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: enabled ? palette.shade50 : palette.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.shade500, width: 1.4),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.shade100),
        ),
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({
    required this.completed,
    required this.busy,
    required this.palette,
    required this.onPressed,
    required this.onPressStart,
  });

  final bool completed;
  final bool busy;
  final JellyBeanPalette palette;
  final VoidCallback onPressed;
  final VoidCallback onPressStart;

  @override
  Widget build(BuildContext context) {
    final Color bg = completed ? palette.shade500 : Colors.white;
    final Color fg = completed ? Colors.white : palette.shade700;
    final Color border = completed ? palette.shade500 : palette.shade200;

    return Semantics(
      label: completed ? 'Mark set incomplete' : 'Mark set complete',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: busy
            ? null
            : (_) {
                onPressStart();
                onPressed();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Icon(Icons.check_rounded, color: fg, size: 22),
        ),
      ),
    );
  }
}
