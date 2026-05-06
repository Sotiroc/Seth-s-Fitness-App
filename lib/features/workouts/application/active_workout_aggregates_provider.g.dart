// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_workout_aggregates_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeWorkoutAggregates)
const activeWorkoutAggregatesProvider = ActiveWorkoutAggregatesProvider._();

final class ActiveWorkoutAggregatesProvider
    extends
        $FunctionalProvider<
          ActiveWorkoutAggregates,
          ActiveWorkoutAggregates,
          ActiveWorkoutAggregates
        >
    with $Provider<ActiveWorkoutAggregates> {
  const ActiveWorkoutAggregatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeWorkoutAggregatesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeWorkoutAggregatesHash();

  @$internal
  @override
  $ProviderElement<ActiveWorkoutAggregates> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ActiveWorkoutAggregates create(Ref ref) {
    return activeWorkoutAggregates(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActiveWorkoutAggregates value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActiveWorkoutAggregates>(value),
    );
  }
}

String _$activeWorkoutAggregatesHash() =>
    r'4e5e7b3c073fb9f4795048287010fc4007d1a885';
