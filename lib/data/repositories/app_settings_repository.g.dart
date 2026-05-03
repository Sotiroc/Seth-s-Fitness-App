// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appSettingsRepository)
const appSettingsRepositoryProvider = AppSettingsRepositoryProvider._();

final class AppSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          AppSettingsRepository,
          AppSettingsRepository,
          AppSettingsRepository
        >
    with $Provider<AppSettingsRepository> {
  const AppSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSettingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AppSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppSettingsRepository create(Ref ref) {
    return appSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppSettingsRepository>(value),
    );
  }
}

String _$appSettingsRepositoryHash() =>
    r'4c23ad996c419cf822b0c5b7123ce110270edf7d';

/// Reactive bool stream for the "show rest timer" toggle in the active
/// workout header. Defaults to `true` when no row exists so first-time
/// users see the timer; flipping the toggle persists immediately.

@ProviderFor(restTimerEnabled)
const restTimerEnabledProvider = RestTimerEnabledProvider._();

/// Reactive bool stream for the "show rest timer" toggle in the active
/// workout header. Defaults to `true` when no row exists so first-time
/// users see the timer; flipping the toggle persists immediately.

final class RestTimerEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Reactive bool stream for the "show rest timer" toggle in the active
  /// workout header. Defaults to `true` when no row exists so first-time
  /// users see the timer; flipping the toggle persists immediately.
  const RestTimerEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restTimerEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restTimerEnabledHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return restTimerEnabled(ref);
  }
}

String _$restTimerEnabledHash() => r'6030ceb712a59675e4448aea3841b00910d4b183';

/// Reactive `int?` stream for the user-level default rest period that
/// applies when an exercise has no per-exercise override. `null` means
/// "fall back to per-type defaults" (weighted=120, bodyweight=60,
/// cardio=0). Set from the Timer settings screen.

@ProviderFor(defaultRestSeconds)
const defaultRestSecondsProvider = DefaultRestSecondsProvider._();

/// Reactive `int?` stream for the user-level default rest period that
/// applies when an exercise has no per-exercise override. `null` means
/// "fall back to per-type defaults" (weighted=120, bodyweight=60,
/// cardio=0). Set from the Timer settings screen.

final class DefaultRestSecondsProvider
    extends $FunctionalProvider<AsyncValue<int?>, int?, Stream<int?>>
    with $FutureModifier<int?>, $StreamProvider<int?> {
  /// Reactive `int?` stream for the user-level default rest period that
  /// applies when an exercise has no per-exercise override. `null` means
  /// "fall back to per-type defaults" (weighted=120, bodyweight=60,
  /// cardio=0). Set from the Timer settings screen.
  const DefaultRestSecondsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'defaultRestSecondsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$defaultRestSecondsHash();

  @$internal
  @override
  $StreamProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int?> create(Ref ref) {
    return defaultRestSeconds(ref);
  }
}

String _$defaultRestSecondsHash() =>
    r'82c48a36a07a49829460721afdaa6c2efe2a7917';
