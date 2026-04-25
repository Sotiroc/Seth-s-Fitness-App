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
