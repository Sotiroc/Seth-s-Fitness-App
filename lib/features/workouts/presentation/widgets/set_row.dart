import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../data/models/exercise_type.dart';
import '../../../../data/models/workout_set.dart';

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
  });

  final WorkoutSet set;
  final ExerciseType exerciseType;

  /// Pre-formatted string for the "Previous" column, or `-` if unavailable.
  final String previousSummary;

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

  Future<void> _commit({
    required bool completed,
    bool showCompletionBusy = false,
  }) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _completing = showCompletionBusy;
    });
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
  }

  Future<void> _toggleCompleted() async {
    if (_saving) return;
    _suppressNextBlurCommit = true;

    final bool next = !widget.set.completed;
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
    await _commit(completed: next, showCompletionBusy: true);
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

    return TextFieldTapRegion(
      child: Opacity(
        opacity: completed ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _SetNumber(number: widget.set.setNumber, palette: palette),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  widget.previousSummary,
                  style: TextStyle(
                    color: palette.shade700.withValues(alpha: 0.75),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
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

class _SetNumber extends StatelessWidget {
  const _SetNumber({required this.number, required this.palette});

  final int number;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.shade100,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: palette.shade800,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
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
