// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TemplateEditorController)
const templateEditorControllerProvider = TemplateEditorControllerProvider._();

final class TemplateEditorControllerProvider
    extends $AsyncNotifierProvider<TemplateEditorController, void> {
  const TemplateEditorControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'templateEditorControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$templateEditorControllerHash();

  @$internal
  @override
  TemplateEditorController create() => TemplateEditorController();
}

String _$templateEditorControllerHash() =>
    r'003cad218bbddc19e3e85a0fb3bc7c5350c552f3';

abstract class _$TemplateEditorController extends $AsyncNotifier<void> {
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
