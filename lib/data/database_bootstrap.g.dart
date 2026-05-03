// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_bootstrap.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(databaseBootstrap)
const databaseBootstrapProvider = DatabaseBootstrapProvider._();

final class DatabaseBootstrapProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  const DatabaseBootstrapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseBootstrapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseBootstrapHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return databaseBootstrap(ref);
  }
}

String _$databaseBootstrapHash() => r'e0e97491c93ed38a25ffef21cb1ace9eadbf28ed';
