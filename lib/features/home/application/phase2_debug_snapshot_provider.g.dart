// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phase2_debug_snapshot_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(phase2DebugSnapshot)
const phase2DebugSnapshotProvider = Phase2DebugSnapshotProvider._();

final class Phase2DebugSnapshotProvider
    extends
        $FunctionalProvider<
          AsyncValue<Phase2DebugSnapshot>,
          Phase2DebugSnapshot,
          FutureOr<Phase2DebugSnapshot>
        >
    with
        $FutureModifier<Phase2DebugSnapshot>,
        $FutureProvider<Phase2DebugSnapshot> {
  const Phase2DebugSnapshotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'phase2DebugSnapshotProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$phase2DebugSnapshotHash();

  @$internal
  @override
  $FutureProviderElement<Phase2DebugSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Phase2DebugSnapshot> create(Ref ref) {
    return phase2DebugSnapshot(ref);
  }
}

String _$phase2DebugSnapshotHash() =>
    r'5042b0472cd6f8f75acf65b7ff00f9ef7e6b963e';
