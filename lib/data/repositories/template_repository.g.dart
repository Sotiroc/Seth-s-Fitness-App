// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(templateRepository)
const templateRepositoryProvider = TemplateRepositoryProvider._();

final class TemplateRepositoryProvider
    extends
        $FunctionalProvider<
          TemplateRepository,
          TemplateRepository,
          TemplateRepository
        >
    with $Provider<TemplateRepository> {
  const TemplateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'templateRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$templateRepositoryHash();

  @$internal
  @override
  $ProviderElement<TemplateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TemplateRepository create(Ref ref) {
    return templateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TemplateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TemplateRepository>(value),
    );
  }
}

String _$templateRepositoryHash() =>
    r'671a46041d149718be3ce014a0b73f1a123d50b9';
