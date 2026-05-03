import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/unit_conversions.dart';
import '../../../data/models/exercise_muscle_group.dart';
import '../../../data/models/gender.dart';
import '../../../data/models/unit_system.dart';
import '../../../data/models/user_profile.dart';
import '../application/profile_editor_controller.dart';
import '../application/user_profile_provider.dart';

/// Edit (or first-time create) form for the singleton [UserProfile]. All
/// inputs are optional — empty saves cleanly. Storage is canonical metric;
/// the active unit system only affects the form's UI and any conversions
/// applied at save time.
class ProfileFormScreen extends ConsumerStatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightCmController = TextEditingController();
  final TextEditingController _heightFeetController = TextEditingController();
  final TextEditingController _heightInchesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _goalWeightController = TextEditingController();
  final TextEditingController _bodyFatController = TextEditingController();

  Gender? _gender;
  ExerciseMuscleGroup? _musclePriority;
  bool? _diabetic;
  UnitSystem _unitSystem = UnitSystem.metric;
  bool _loading = false;
  bool _loadingInitial = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightCmController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _weightController.dispose();
    _goalWeightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  Future<void> _hydrate() async {
    try {
      // Read the current value once via the stream provider — avoids missing
      // the first emission while the database bootstraps.
      final UserProfile? profile = await ref.read(userProfileProvider.future);
      if (!mounted) return;
      setState(() {
        if (profile != null) {
          _unitSystem = profile.unitSystem;
          _nameController.text = profile.name ?? '';
          _ageController.text = profile.ageYears?.toString() ?? '';
          _bodyFatController.text = profile.bodyFatPercent != null
              ? _formatBodyFat(profile.bodyFatPercent!)
              : '';
          _gender = profile.gender;
          _musclePriority = profile.muscleGroupPriority;
          _diabetic = profile.diabetic;
          _seedHeightControllers(profile.heightCm);
          _seedWeightControllers(
            weightKg: profile.weightKg,
            goalWeightKg: profile.goalWeightKg,
          );
        }
        _loadingInitial = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      setState(() => _loadingInitial = false);
    }
  }

  void _seedHeightControllers(double? cm) {
    switch (_unitSystem) {
      case UnitSystem.metric:
        _heightCmController.text = UnitConversions.heightCmInputValue(cm);
        _heightFeetController.text = '';
        _heightInchesController.text = '';
      case UnitSystem.imperial:
        final ({String feet, String inches}) parts =
            UnitConversions.heightFeetInchesInputValue(cm);
        _heightFeetController.text = parts.feet;
        _heightInchesController.text = parts.inches;
        _heightCmController.text = '';
    }
  }

  void _seedWeightControllers({
    required double? weightKg,
    required double? goalWeightKg,
  }) {
    _weightController.text = UnitConversions.weightInputValue(
      weightKg,
      _unitSystem,
    );
    _goalWeightController.text = UnitConversions.weightInputValue(
      goalWeightKg,
      _unitSystem,
    );
  }

  String _formatBodyFat(double value) {
    final String s = value.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  void _onUnitSystemChanged(UnitSystem next) {
    if (next == _unitSystem) return;
    final double? heightCm = _readHeightCm();
    final double? weightKg = _readWeightKg(_weightController.text);
    final double? goalKg = _readWeightKg(_goalWeightController.text);
    setState(() {
      _unitSystem = next;
      _seedHeightControllers(heightCm);
      _seedWeightControllers(weightKg: weightKg, goalWeightKg: goalKg);
    });
  }

  double? _readHeightCm() {
    switch (_unitSystem) {
      case UnitSystem.metric:
        return UnitConversions.parseHeightCm(_heightCmController.text);
      case UnitSystem.imperial:
        return UnitConversions.parseHeightFeetInchesToCm(
          _heightFeetController.text,
          _heightInchesController.text,
        );
    }
  }

  double? _readWeightKg(String text) {
    return UnitConversions.parseWeightToKg(text, _unitSystem);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final ProfileEditorController controller = ref.read(
      profileEditorControllerProvider.notifier,
    );

    final String trimmedName = _nameController.text.trim();
    final String trimmedAge = _ageController.text.trim();
    final String trimmedBodyFat = _bodyFatController.text.trim();

    try {
      await controller.saveProfile(
        name: trimmedName.isEmpty ? null : trimmedName,
        ageYears: trimmedAge.isEmpty ? null : int.tryParse(trimmedAge),
        gender: _gender,
        heightCm: _readHeightCm(),
        weightKg: _readWeightKg(_weightController.text),
        goalWeightKg: _readWeightKg(_goalWeightController.text),
        bodyFatPercent: trimmedBodyFat.isEmpty
            ? null
            : double.tryParse(trimmedBodyFat),
        diabetic: _diabetic,
        muscleGroupPriority: _musclePriority,
        unitSystem: _unitSystem,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
      if (context.canPop()) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;

    return Scaffold(
      backgroundColor: palette.shade50,
      appBar: AppBar(
        backgroundColor: palette.shade50,
        title: const Text('Edit profile'),
      ),
      body: _loadingInitial
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  120,
                ),
                children: <Widget>[
                  _SectionLabel(text: 'Units', palette: palette),
                  const SizedBox(height: AppSpacing.sm),
                  _UnitSystemToggle(
                    palette: palette,
                    selected: _unitSystem,
                    onChanged: _onUnitSystemChanged,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _SectionLabel(text: 'About you', palette: palette),
                  const SizedBox(height: AppSpacing.md),
                  _FieldLabel(text: 'Name', palette: palette),
                  const SizedBox(height: AppSpacing.xxs),
                  _StyledTextField(
                    controller: _nameController,
                    palette: palette,
                    hintText: 'e.g. Sam',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: _validateName,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FieldLabel(text: 'Age', palette: palette),
                  const SizedBox(height: AppSpacing.xxs),
                  _StyledTextField(
                    controller: _ageController,
                    palette: palette,
                    hintText: 'Years',
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: _validateAge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FieldLabel(text: 'Gender', palette: palette),
                  const SizedBox(height: AppSpacing.xxs),
                  _OptionPickerField(
                    palette: palette,
                    valueLabel: _gender?.label,
                    placeholder: 'Not specified',
                    onTap: () => _pickGender(context),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _SectionLabel(text: 'Body', palette: palette),
                  const SizedBox(height: AppSpacing.md),
                  _FieldLabel(
                    text: 'Height (${_unitSystem.heightUnit})',
                    palette: palette,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  if (_unitSystem == UnitSystem.metric)
                    _StyledTextField(
                      controller: _heightCmController,
                      palette: palette,
                      hintText: 'e.g. 175',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) =>
                          _validateRange(v, min: 50, max: 300, label: 'Height'),
                    )
                  else
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _StyledTextField(
                            controller: _heightFeetController,
                            palette: palette,
                            hintText: 'ft',
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) => _validateRange(
                              v,
                              min: 1,
                              max: 9,
                              label: 'Feet',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _StyledTextField(
                            controller: _heightInchesController,
                            palette: palette,
                            hintText: 'in',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) => _validateRange(
                              v,
                              min: 0,
                              max: 11.99,
                              label: 'Inches',
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.md),
                  _FieldLabel(
                    text: 'Weight (${_unitSystem.weightUnit})',
                    palette: palette,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  _StyledTextField(
                    controller: _weightController,
                    palette: palette,
                    hintText: _unitSystem == UnitSystem.metric
                        ? 'e.g. 80'
                        : 'e.g. 176',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _validateWeight(v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FieldLabel(text: 'Body fat (%)', palette: palette),
                  const SizedBox(height: AppSpacing.xxs),
                  _StyledTextField(
                    controller: _bodyFatController,
                    palette: palette,
                    hintText: 'e.g. 18',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) =>
                        _validateRange(v, min: 1, max: 70, label: 'Body fat'),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _SectionLabel(text: 'Goals', palette: palette),
                  const SizedBox(height: AppSpacing.md),
                  _FieldLabel(
                    text: 'Goal weight (${_unitSystem.weightUnit})',
                    palette: palette,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  _StyledTextField(
                    controller: _goalWeightController,
                    palette: palette,
                    hintText: _unitSystem == UnitSystem.metric
                        ? 'e.g. 75'
                        : 'e.g. 165',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _validateWeight(v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FieldLabel(text: 'Muscle priority', palette: palette),
                  const SizedBox(height: AppSpacing.xxs),
                  _OptionPickerField(
                    palette: palette,
                    valueLabel: _musclePriority?.label,
                    placeholder: 'No priority',
                    onTap: () => _pickMusclePriority(context),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _SectionLabel(text: 'Health', palette: palette),
                  const SizedBox(height: AppSpacing.md),
                  _FieldLabel(text: 'Are you diabetic?', palette: palette),
                  const SizedBox(height: AppSpacing.xs),
                  _DiabeticSegmented(
                    palette: palette,
                    selected: _diabetic,
                    onChanged: (value) => setState(() => _diabetic = value),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _loading || _loadingInitial ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: palette.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save profile',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- Pickers ----

  Future<void> _pickGender(BuildContext context) async {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  title: Text(
                    'Not specified',
                    style: TextStyle(
                      color: palette.shade700,
                      fontStyle: FontStyle.italic,
                      fontWeight: _gender == null
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                  trailing: _gender == null
                      ? Icon(Icons.check_rounded, color: palette.shade700)
                      : null,
                  onTap: () {
                    setState(() => _gender = null);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                for (final Gender option in Gender.values)
                  ListTile(
                    title: Text(
                      option.label,
                      style: TextStyle(
                        color: palette.shade950,
                        fontWeight: option == _gender
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    trailing: option == _gender
                        ? Icon(Icons.check_rounded, color: palette.shade700)
                        : null,
                    onTap: () {
                      setState(() => _gender = option);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickMusclePriority(BuildContext context) async {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    // Filter out cardio — it's not a muscle group.
    final List<ExerciseMuscleGroup> options = ExerciseMuscleGroup.values
        .where((g) => g != ExerciseMuscleGroup.cardio)
        .toList(growable: false);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  title: Text(
                    'No priority',
                    style: TextStyle(
                      color: palette.shade700,
                      fontStyle: FontStyle.italic,
                      fontWeight: _musclePriority == null
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                  trailing: _musclePriority == null
                      ? Icon(Icons.check_rounded, color: palette.shade700)
                      : null,
                  onTap: () {
                    setState(() => _musclePriority = null);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                for (final ExerciseMuscleGroup group in options)
                  ListTile(
                    title: Text(
                      group.label,
                      style: TextStyle(
                        color: palette.shade950,
                        fontWeight: group == _musclePriority
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    trailing: group == _musclePriority
                        ? Icon(Icons.check_rounded, color: palette.shade700)
                        : null,
                    onTap: () {
                      setState(() => _musclePriority = group);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- Validators (all permit empty input — every field is optional) ----

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > 60) return 'Keep it under 60 characters.';
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final int? age = int.tryParse(value.trim());
    if (age == null) return 'Enter a whole number.';
    if (age < 1 || age > 120) return 'Enter an age between 1 and 120.';
    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final double? weight = double.tryParse(value.trim());
    if (weight == null) return 'Enter a number.';
    final double kg = _unitSystem == UnitSystem.metric
        ? weight
        : UnitConversions.lbToKg(weight);
    if (kg < 20 || kg > 400) return 'That weight looks out of range.';
    return null;
  }

  String? _validateRange(
    String? value, {
    required double min,
    required double max,
    required String label,
  }) {
    if (value == null || value.trim().isEmpty) return null;
    final double? parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a number.';
    if (parsed < min || parsed > max) {
      return '$label must be between $min and $max.';
    }
    return null;
  }
}

/// Section heading — the loud, uppercase "stamp" that anchors a group of
/// related fields. Heavily contrasted against [_FieldLabel] so the two never
/// read as siblings stacked on top of each other.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.palette});

  final String text;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: palette.shade950,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }
}

/// Field label — the quiet, sentence-case caption above a single input.
/// Lower contrast and weight than [_SectionLabel] so it reads as helper
/// text rather than a competing heading.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, required this.palette});

  final String text;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: palette.shade700,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Bordered text input shared by every field on the form. Uses a soft
/// neutral grey for hint text — distinct from [_FieldLabel] (teal) so the
/// two never visually collide.
class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.palette,
    required this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final JellyBeanPalette palette;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(
        color: palette.shade950,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: _hintColor,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.shade500, width: 1.5),
        ),
      ),
    );
  }
}

/// Bordered tap-to-pick field used for enum selectors that open a modal
/// sheet (Gender, Muscle priority). Mirrors [_StyledTextField]'s chrome and
/// hint color so empty-state placeholders match across the form.
class _OptionPickerField extends StatelessWidget {
  const _OptionPickerField({
    required this.palette,
    required this.valueLabel,
    required this.placeholder,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final String? valueLabel;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = valueLabel != null;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.shade100),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                hasValue ? valueLabel! : placeholder,
                style: TextStyle(
                  color: hasValue ? palette.shade950 : _hintColor,
                  fontSize: 15,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: _hintColor),
          ],
        ),
      ),
    );
  }
}

/// Soft neutral grey used for placeholder text and trailing icons. Sits
/// distinctly outside the teal palette so hint text never reads as another
/// labeled value.
const Color _hintColor = Color(0xFFA3ACB3);

class _UnitSystemToggle extends StatelessWidget {
  const _UnitSystemToggle({
    required this.palette,
    required this.selected,
    required this.onChanged,
  });

  final JellyBeanPalette palette;
  final UnitSystem selected;
  final ValueChanged<UnitSystem> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<UnitSystem>(
      segments: <ButtonSegment<UnitSystem>>[
        for (final UnitSystem option in UnitSystem.values)
          ButtonSegment<UnitSystem>(value: option, label: Text(option.label)),
      ],
      selected: <UnitSystem>{selected},
      onSelectionChanged: (Set<UnitSystem> values) => onChanged(values.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) return palette.shade900;
          return Colors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return palette.shade900;
        }),
        side: WidgetStateProperty.all<BorderSide>(
          BorderSide(color: palette.shade100),
        ),
      ),
    );
  }
}

class _DiabeticSegmented extends StatelessWidget {
  const _DiabeticSegmented({
    required this.palette,
    required this.selected,
    required this.onChanged,
  });

  final JellyBeanPalette palette;
  final bool? selected;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Use a sentinel int to distinguish null from true/false in the selected
    // set required by SegmentedButton.
    const int yes = 1;
    const int no = 0;
    const int unspecified = -1;
    final int current = switch (selected) {
      true => yes,
      false => no,
      null => unspecified,
    };
    return SegmentedButton<int>(
      showSelectedIcon: false,
      segments: const <ButtonSegment<int>>[
        ButtonSegment<int>(value: yes, label: Text('Yes')),
        ButtonSegment<int>(value: no, label: Text('No')),
        ButtonSegment<int>(
          value: unspecified,
          label: Text('Prefer not to say'),
        ),
      ],
      selected: <int>{current},
      onSelectionChanged: (Set<int> values) {
        switch (values.first) {
          case yes:
            onChanged(true);
          case no:
            onChanged(false);
          default:
            onChanged(null);
        }
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) return palette.shade900;
          return Colors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return palette.shade900;
        }),
        side: WidgetStateProperty.all<BorderSide>(
          BorderSide(color: palette.shade100),
        ),
      ),
    );
  }
}
