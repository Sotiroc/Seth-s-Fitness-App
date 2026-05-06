// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Page-local — bound to the template form's lifecycle. Auto-disposed
/// so the busy/error AsyncValue resets cleanly when the editor closes.

@ProviderFor(TemplateEditorController)
const templateEditorControllerProvider = TemplateEditorControllerProvider._();

/// Page-local — bound to the template form's lifecycle. Auto-disposed
/// so the busy/error AsyncValue resets cleanly when the editor closes.
final class TemplateEditorControllerProvider
    extends $AsyncNotifierProvider<TemplateEditorController, void> {
  /// Page-local — bound to the template form's lifecycle. Auto-disposed
  /// so the busy/error AsyncValue resets cleanly when the editor closes.
  const TemplateEditorControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'templateEditorControllerProvider',
        isAutoDispose: true,
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
    r'40ca93191ba577f0281e9dbf11d096e3fd1af55c';

/// Page-local — bound to the template form's lifecycle. Auto-disposed
/// so the busy/error AsyncValue resets cleanly when the editor closes.

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
