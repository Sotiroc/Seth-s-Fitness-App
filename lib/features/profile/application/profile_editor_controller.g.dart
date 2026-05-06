// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Page-local — bound to the profile form's lifecycle. Auto-disposed
/// so the busy/error AsyncValue starts fresh on each open.

@ProviderFor(ProfileEditorController)
const profileEditorControllerProvider = ProfileEditorControllerProvider._();

/// Page-local — bound to the profile form's lifecycle. Auto-disposed
/// so the busy/error AsyncValue starts fresh on each open.
final class ProfileEditorControllerProvider
    extends $AsyncNotifierProvider<ProfileEditorController, void> {
  /// Page-local — bound to the profile form's lifecycle. Auto-disposed
  /// so the busy/error AsyncValue starts fresh on each open.
  const ProfileEditorControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileEditorControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileEditorControllerHash();

  @$internal
  @override
  ProfileEditorController create() => ProfileEditorController();
}

String _$profileEditorControllerHash() =>
    r'8006350d13917115079f2f9df8bcbcd70703083b';

/// Page-local — bound to the profile form's lifecycle. Auto-disposed
/// so the busy/error AsyncValue starts fresh on each open.

abstract class _$ProfileEditorController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
