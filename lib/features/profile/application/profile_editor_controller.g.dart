// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfileEditorController)
const profileEditorControllerProvider = ProfileEditorControllerProvider._();

final class ProfileEditorControllerProvider
    extends $AsyncNotifierProvider<ProfileEditorController, void> {
  const ProfileEditorControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileEditorControllerProvider',
        isAutoDispose: false,
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
    r'bf8c653757100c32821784aedbe4108420fd3faf';

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
