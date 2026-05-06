import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/exercise_muscle_group.dart';
import '../../../data/models/gender.dart';
import '../../../data/models/unit_system.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../../data/repositories/weight_entry_repository.dart';

part 'profile_editor_controller.g.dart';

/// Page-local — bound to the profile form's lifecycle. Auto-disposed
/// so the busy/error AsyncValue starts fresh on each open.
@riverpod
class ProfileEditorController extends _$ProfileEditorController {
  @override
  FutureOr<void> build() {}

  Future<UserProfile> saveProfile({
    String? name,
    int? ageYears,
    Gender? gender,
    double? heightCm,
    double? weightKg,
    double? goalWeightKg,
    double? bodyFatPercent,
    bool? diabetic,
    ExerciseMuscleGroup? muscleGroupPriority,
    UnitSystem unitSystem = UnitSystem.metric,
  }) {
    return _runMutation(() async {
      final UserProfileRepository repository = ref.read(
        userProfileRepositoryProvider,
      );
      // Snapshot the existing weight BEFORE the upsert so we can detect a
      // change and auto-log a history entry. Without this, we'd always
      // see the new value and never know whether to append.
      final UserProfile? existing = await repository.getProfile();

      final UserProfile saved = await repository.upsertProfile(
        name: name,
        ageYears: ageYears,
        gender: gender,
        heightCm: heightCm,
        weightKg: weightKg,
        goalWeightKg: goalWeightKg,
        bodyFatPercent: bodyFatPercent,
        diabetic: diabetic,
        muscleGroupPriority: muscleGroupPriority,
        unitSystem: unitSystem,
      );

      // Auto-log to the body-weight timeline whenever the user changed
      // their weight via the profile form. Deduped per local day inside
      // the repository so repeated edits in one session collapse to one
      // chart point.
      if (saved.weightKg != null && saved.weightKg != existing?.weightKg) {
        await ref.read(weightEntryRepositoryProvider).upsertProfileEntry(
              weightKg: saved.weightKg!,
              measuredAt: DateTime.now().toUtc(),
            );
      }

      return saved;
    });
  }

  Future<T> _runMutation<T>(Future<T> Function() action) async {
    state = const AsyncLoading<void>();
    try {
      final T result = await action();
      state = const AsyncData<void>(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}
