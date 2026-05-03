import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/unit_conversions.dart';
import '../../../../data/models/unit_system.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../data/models/weight_entry.dart';
import '../../../../data/repositories/user_profile_repository.dart';
import '../../../../data/repositories/weight_entry_repository.dart';
import '../../../profile/application/user_profile_provider.dart';

/// Opens the modal sheet to log a body-weight entry. Defaults the date
/// to "today" but lets the user pick any past date so they can backfill
/// historical readings.
Future<void> showLogWeightSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
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
        child: const _LogWeightForm(),
      );
    },
  );
}

class _LogWeightForm extends ConsumerStatefulWidget {
  const _LogWeightForm();

  @override
  ConsumerState<_LogWeightForm> createState() => _LogWeightFormState();
}

class _LogWeightFormState extends ConsumerState<_LogWeightForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _weightController = TextEditingController();
  late DateTime _selectedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final ThemeData theme = Theme.of(context);
    final UnitSystem unitSystem = ref
        .watch(userProfileProvider)
        .maybeWhen<UnitSystem>(
          data: (UserProfile? p) => p?.unitSystem ?? UnitSystem.metric,
          orElse: () => UnitSystem.metric,
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'LOG WEIGHT',
                style: TextStyle(
                  color: palette.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Add a new point to your timeline',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: palette.shade950,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Weight (${unitSystem.weightUnit})',
                style: TextStyle(
                  color: palette.shade900,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              TextFormField(
                controller: _weightController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9]*[.,]?[0-9]*'),
                  ),
                ],
                style: TextStyle(
                  color: palette.shade950,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: unitSystem == UnitSystem.metric
                      ? 'e.g. 78.5'
                      : 'e.g. 173',
                  filled: true,
                  fillColor: palette.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: palette.shade100),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: palette.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: palette.shade500, width: 1.5),
                  ),
                ),
                validator: (String? value) =>
                    _validateWeight(value, unitSystem),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Date',
                style: TextStyle(
                  color: palette.shade900,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              InkWell(
                onTap: _saving ? null : _pickDate,
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
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: palette.shade700,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _formatDate(_selectedDate),
                          style: TextStyle(
                            color: palette.shade950,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(Icons.expand_more_rounded, color: palette.shade700),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: palette.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.shade900,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateWeight(String? value, UnitSystem unitSystem) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final double? kg = UnitConversions.parseWeightToKg(value, unitSystem);
    if (kg == null) return 'Invalid number';
    if (kg < 20 || kg > 400) return 'Out of range';
    return null;
  }

  String _formatDate(DateTime date) {
    final DateTime today = DateTime.now();
    final DateTime localDate = DateTime(date.year, date.month, date.day);
    final DateTime localToday = DateTime(today.year, today.month, today.day);
    if (localDate == localToday) return 'Today';
    if (localDate == localToday.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return DateFormat.yMMMMd().format(date);
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final UnitSystem unitSystem = ref
        .read(userProfileProvider)
        .maybeWhen(
          data: (UserProfile? p) => p?.unitSystem ?? UnitSystem.metric,
          orElse: () => UnitSystem.metric,
        );
    final double? kg = UnitConversions.parseWeightToKg(
      _weightController.text,
      unitSystem,
    );
    if (kg == null) return;

    setState(() => _saving = true);
    try {
      await syncProfileWeightFromLog(
        weightRepo: ref.read(weightEntryRepositoryProvider),
        profileRepo: ref.read(userProfileRepositoryProvider),
        weightKg: kg,
        measuredAt: _selectedDate,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $error')));
    }
  }
}

/// Inserts a manual weight log entry and, if it's now the chronologically
/// latest entry, syncs `profile.weightKg` to it so BMI / goal-delta / the
/// profile screen all reflect the new measurement.
///
/// Backdated entries (older than the existing latest) deliberately do NOT
/// touch the profile — the user's "current weight" anchor stays put.
///
/// Takes the repos directly (rather than a [WidgetRef]) so the same flow
/// can be unit-tested without a [ProviderContainer] and reused from any
/// surface (e.g. the Profile screen's tap-to-log card) without leaking
/// Riverpod into otherwise-pure plumbing.
Future<WeightEntry> syncProfileWeightFromLog({
  required WeightEntryRepository weightRepo,
  required UserProfileRepository profileRepo,
  required double weightKg,
  required DateTime measuredAt,
}) async {
  final WeightEntry inserted = await weightRepo.logEntry(
    weightKg: weightKg,
    measuredAt: measuredAt,
    source: WeightEntrySource.manual,
  );

  final WeightEntry? latest = await weightRepo.getLatestEntry();
  if (latest != null && latest.id == inserted.id) {
    await profileRepo.updateWeightFromLog(latest.weightKg);
  }

  return inserted;
}
