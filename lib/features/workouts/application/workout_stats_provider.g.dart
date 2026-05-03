// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stats for the current calendar month (local time). Rebuilds whenever the
/// underlying history stream emits — e.g. after finishing a workout.

@ProviderFor(monthlyWorkoutStats)
const monthlyWorkoutStatsProvider = MonthlyWorkoutStatsProvider._();

/// Stats for the current calendar month (local time). Rebuilds whenever the
/// underlying history stream emits — e.g. after finishing a workout.

final class MonthlyWorkoutStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkoutPeriodStats>,
          AsyncValue<WorkoutPeriodStats>,
          AsyncValue<WorkoutPeriodStats>
        >
    with $Provider<AsyncValue<WorkoutPeriodStats>> {
  /// Stats for the current calendar month (local time). Rebuilds whenever the
  /// underlying history stream emits — e.g. after finishing a workout.
  const MonthlyWorkoutStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthlyWorkoutStatsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthlyWorkoutStatsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<WorkoutPeriodStats>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<WorkoutPeriodStats> create(Ref ref) {
    return monthlyWorkoutStats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<WorkoutPeriodStats> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<WorkoutPeriodStats>>(
        value,
      ),
    );
  }
}

String _$monthlyWorkoutStatsHash() =>
    r'b7191ba80d201ba908a197861c794a86aa343aff';

/// Completed sets grouped by muscle group for the current training week
/// (Monday-Sunday, local time). Streams from Drift so the count ticks up
/// in real time as the user completes sets in the active workout.

@ProviderFor(weeklyMuscleGroupSets)
const weeklyMuscleGroupSetsProvider = WeeklyMuscleGroupSetsProvider._();

/// Completed sets grouped by muscle group for the current training week
/// (Monday-Sunday, local time). Streams from Drift so the count ticks up
/// in real time as the user completes sets in the active workout.

final class WeeklyMuscleGroupSetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<ExerciseMuscleGroup, int>>,
          Map<ExerciseMuscleGroup, int>,
          Stream<Map<ExerciseMuscleGroup, int>>
        >
    with
        $FutureModifier<Map<ExerciseMuscleGroup, int>>,
        $StreamProvider<Map<ExerciseMuscleGroup, int>> {
  /// Completed sets grouped by muscle group for the current training week
  /// (Monday-Sunday, local time). Streams from Drift so the count ticks up
  /// in real time as the user completes sets in the active workout.
  const WeeklyMuscleGroupSetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weeklyMuscleGroupSetsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weeklyMuscleGroupSetsHash();

  @$internal
  @override
  $StreamProviderElement<Map<ExerciseMuscleGroup, int>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<ExerciseMuscleGroup, int>> create(Ref ref) {
    return weeklyMuscleGroupSets(ref);
  }
}

String _$weeklyMuscleGroupSetsHash() =>
    r'289160cc8690db47824d5517e74f76efbe9b0e58';

/// Total cardio minutes completed in the current training week (Monday-
/// Sunday, local time). Cardio progress is naturally measured in time, not
/// set count, so the in-workout strip surfaces this for the cardio pill
/// instead of the set fraction. Streams from Drift; updates the moment a
/// cardio set is marked complete.

@ProviderFor(weeklyCardioMinutes)
const weeklyCardioMinutesProvider = WeeklyCardioMinutesProvider._();

/// Total cardio minutes completed in the current training week (Monday-
/// Sunday, local time). Cardio progress is naturally measured in time, not
/// set count, so the in-workout strip surfaces this for the cardio pill
/// instead of the set fraction. Streams from Drift; updates the moment a
/// cardio set is marked complete.

final class WeeklyCardioMinutesProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Total cardio minutes completed in the current training week (Monday-
  /// Sunday, local time). Cardio progress is naturally measured in time, not
  /// set count, so the in-workout strip surfaces this for the cardio pill
  /// instead of the set fraction. Streams from Drift; updates the moment a
  /// cardio set is marked complete.
  const WeeklyCardioMinutesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weeklyCardioMinutesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weeklyCardioMinutesHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return weeklyCardioMinutes(ref);
  }
}

String _$weeklyCardioMinutesHash() =>
    r'1d521dcb145d08df589d47abb3cf167c528a7dff';

/// Total tonnage (kg × reps) completed in the current training week.
/// Powers the "Volume this week" tile in the Progression hero strip.
/// Streams from Drift; updates live as sets complete.

@ProviderFor(weeklyVolumeKg)
const weeklyVolumeKgProvider = WeeklyVolumeKgProvider._();

/// Total tonnage (kg × reps) completed in the current training week.
/// Powers the "Volume this week" tile in the Progression hero strip.
/// Streams from Drift; updates live as sets complete.

final class WeeklyVolumeKgProvider
    extends $FunctionalProvider<AsyncValue<double>, double, Stream<double>>
    with $FutureModifier<double>, $StreamProvider<double> {
  /// Total tonnage (kg × reps) completed in the current training week.
  /// Powers the "Volume this week" tile in the Progression hero strip.
  /// Streams from Drift; updates live as sets complete.
  const WeeklyVolumeKgProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weeklyVolumeKgProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weeklyVolumeKgHash();

  @$internal
  @override
  $StreamProviderElement<double> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double> create(Ref ref) {
    return weeklyVolumeKg(ref);
  }
}

String _$weeklyVolumeKgHash() => r'd937a93e74a6e3c3c935828a9bbd937c8a69b65e';

/// Per-day completed set counts for the last [weeks] ISO weeks, keyed by
/// local-midnight DateTime. Drives the GitHub-style training calendar
/// heatmap on the Progression page; the heatmap reads its preferred
/// window length from `calendarRangeFilterProvider`.

@ProviderFor(dailyTrainingSetCounts)
const dailyTrainingSetCountsProvider = DailyTrainingSetCountsFamily._();

/// Per-day completed set counts for the last [weeks] ISO weeks, keyed by
/// local-midnight DateTime. Drives the GitHub-style training calendar
/// heatmap on the Progression page; the heatmap reads its preferred
/// window length from `calendarRangeFilterProvider`.

final class DailyTrainingSetCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<DateTime, int>>,
          Map<DateTime, int>,
          Stream<Map<DateTime, int>>
        >
    with
        $FutureModifier<Map<DateTime, int>>,
        $StreamProvider<Map<DateTime, int>> {
  /// Per-day completed set counts for the last [weeks] ISO weeks, keyed by
  /// local-midnight DateTime. Drives the GitHub-style training calendar
  /// heatmap on the Progression page; the heatmap reads its preferred
  /// window length from `calendarRangeFilterProvider`.
  const DailyTrainingSetCountsProvider._({
    required DailyTrainingSetCountsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'dailyTrainingSetCountsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dailyTrainingSetCountsHash();

  @override
  String toString() {
    return r'dailyTrainingSetCountsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<DateTime, int>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<DateTime, int>> create(Ref ref) {
    final argument = this.argument as int;
    return dailyTrainingSetCounts(ref, weeks: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DailyTrainingSetCountsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dailyTrainingSetCountsHash() =>
    r'7e354dac7dacac7f2a4782daabcd5888acb70aa4';

/// Per-day completed set counts for the last [weeks] ISO weeks, keyed by
/// local-midnight DateTime. Drives the GitHub-style training calendar
/// heatmap on the Progression page; the heatmap reads its preferred
/// window length from `calendarRangeFilterProvider`.

final class DailyTrainingSetCountsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<DateTime, int>>, int> {
  const DailyTrainingSetCountsFamily._()
    : super(
        retry: null,
        name: r'dailyTrainingSetCountsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Per-day completed set counts for the last [weeks] ISO weeks, keyed by
  /// local-midnight DateTime. Drives the GitHub-style training calendar
  /// heatmap on the Progression page; the heatmap reads its preferred
  /// window length from `calendarRangeFilterProvider`.

  DailyTrainingSetCountsProvider call({int weeks = 12}) =>
      DailyTrainingSetCountsProvider._(argument: weeks, from: this);

  @override
  String toString() => r'dailyTrainingSetCountsProvider';
}

/// Number of consecutive ISO weeks (Mon-Sun) ending at the current week
/// in which the user finished at least one workout. Hits 0 when the
/// current week has no finished workouts; otherwise grows back through
/// history. Used by the "Streak" tile in the hero strip.
///
/// Synchronously-derived from [workoutHistoryProvider] so it doesn't open
/// a new Drift stream — re-emits whenever history does.

@ProviderFor(workoutStreakWeeks)
const workoutStreakWeeksProvider = WorkoutStreakWeeksProvider._();

/// Number of consecutive ISO weeks (Mon-Sun) ending at the current week
/// in which the user finished at least one workout. Hits 0 when the
/// current week has no finished workouts; otherwise grows back through
/// history. Used by the "Streak" tile in the hero strip.
///
/// Synchronously-derived from [workoutHistoryProvider] so it doesn't open
/// a new Drift stream — re-emits whenever history does.

final class WorkoutStreakWeeksProvider
    extends
        $FunctionalProvider<AsyncValue<int>, AsyncValue<int>, AsyncValue<int>>
    with $Provider<AsyncValue<int>> {
  /// Number of consecutive ISO weeks (Mon-Sun) ending at the current week
  /// in which the user finished at least one workout. Hits 0 when the
  /// current week has no finished workouts; otherwise grows back through
  /// history. Used by the "Streak" tile in the hero strip.
  ///
  /// Synchronously-derived from [workoutHistoryProvider] so it doesn't open
  /// a new Drift stream — re-emits whenever history does.
  const WorkoutStreakWeeksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutStreakWeeksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutStreakWeeksHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AsyncValue<int> create(Ref ref) {
    return workoutStreakWeeks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<int>>(value),
    );
  }
}

String _$workoutStreakWeeksHash() =>
    r'f3a1c3f807972d56b8a789cd8d4f2a5bb62a5616';
