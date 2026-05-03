// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rest_timer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the bottom-sheet overlay shown during inter-set rest. Exposed as a
/// `keepAlive` Riverpod notifier so dismissing the sheet (or navigating away
/// briefly) doesn't lose the running timer.

@ProviderFor(RestTimerController)
const restTimerControllerProvider = RestTimerControllerProvider._();

/// Drives the bottom-sheet overlay shown during inter-set rest. Exposed as a
/// `keepAlive` Riverpod notifier so dismissing the sheet (or navigating away
/// briefly) doesn't lose the running timer.
final class RestTimerControllerProvider
    extends $NotifierProvider<RestTimerController, RestTimerState> {
  /// Drives the bottom-sheet overlay shown during inter-set rest. Exposed as a
  /// `keepAlive` Riverpod notifier so dismissing the sheet (or navigating away
  /// briefly) doesn't lose the running timer.
  const RestTimerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restTimerControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restTimerControllerHash();

  @$internal
  @override
  RestTimerController create() => RestTimerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestTimerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestTimerState>(value),
    );
  }
}

String _$restTimerControllerHash() =>
    r'1b6d2a05adf2ad2520d9dae1e09b48872e20cd6d';

/// Drives the bottom-sheet overlay shown during inter-set rest. Exposed as a
/// `keepAlive` Riverpod notifier so dismissing the sheet (or navigating away
/// briefly) doesn't lose the running timer.

abstract class _$RestTimerController extends $Notifier<RestTimerState> {
  RestTimerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<RestTimerState, RestTimerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RestTimerState, RestTimerState>,
              RestTimerState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
