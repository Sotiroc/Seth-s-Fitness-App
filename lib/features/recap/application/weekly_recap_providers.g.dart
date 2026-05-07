// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_recap_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The most recent recap that should be shown on the home, or null when
/// there isn't a "current" one (no workouts logged in the past complete
/// week, or the latest stored recap is more than 7 days past its
/// `weekEnd` and hasn't been replaced yet).

@ProviderFor(currentWeeklyRecap)
const currentWeeklyRecapProvider = CurrentWeeklyRecapProvider._();

/// The most recent recap that should be shown on the home, or null when
/// there isn't a "current" one (no workouts logged in the past complete
/// week, or the latest stored recap is more than 7 days past its
/// `weekEnd` and hasn't been replaced yet).

final class CurrentWeeklyRecapProvider
    extends
        $FunctionalProvider<
          AsyncValue<WeeklyRecap?>,
          WeeklyRecap?,
          Stream<WeeklyRecap?>
        >
    with $FutureModifier<WeeklyRecap?>, $StreamProvider<WeeklyRecap?> {
  /// The most recent recap that should be shown on the home, or null when
  /// there isn't a "current" one (no workouts logged in the past complete
  /// week, or the latest stored recap is more than 7 days past its
  /// `weekEnd` and hasn't been replaced yet).
  const CurrentWeeklyRecapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentWeeklyRecapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentWeeklyRecapHash();

  @$internal
  @override
  $StreamProviderElement<WeeklyRecap?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<WeeklyRecap?> create(Ref ref) {
    return currentWeeklyRecap(ref);
  }
}

String _$currentWeeklyRecapHash() =>
    r'07859809709c31b50bcf403182012ef4e876d88e';

/// Every persisted recap, newest first. Surfaced behind the future
/// "Recaps" filter chip on the History screen.

@ProviderFor(allWeeklyRecaps)
const allWeeklyRecapsProvider = AllWeeklyRecapsProvider._();

/// Every persisted recap, newest first. Surfaced behind the future
/// "Recaps" filter chip on the History screen.

final class AllWeeklyRecapsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WeeklyRecap>>,
          List<WeeklyRecap>,
          Stream<List<WeeklyRecap>>
        >
    with
        $FutureModifier<List<WeeklyRecap>>,
        $StreamProvider<List<WeeklyRecap>> {
  /// Every persisted recap, newest first. Surfaced behind the future
  /// "Recaps" filter chip on the History screen.
  const AllWeeklyRecapsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allWeeklyRecapsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allWeeklyRecapsHash();

  @$internal
  @override
  $StreamProviderElement<List<WeeklyRecap>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WeeklyRecap>> create(Ref ref) {
    return allWeeklyRecaps(ref);
  }
}

String _$allWeeklyRecapsHash() => r'8e61681f20ce2d80ec0641935332747d6065435a';
