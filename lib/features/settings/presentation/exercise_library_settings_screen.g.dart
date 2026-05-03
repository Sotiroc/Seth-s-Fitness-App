// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_library_settings_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Local stream of installed packs for the settings screen. Mirrors the
/// equivalent provider in the exercises feature — kept here so this
/// feature can stand on its own without cross-feature imports.

@ProviderFor(librarySettingsPacks)
const librarySettingsPacksProvider = LibrarySettingsPacksProvider._();

/// Local stream of installed packs for the settings screen. Mirrors the
/// equivalent provider in the exercises feature — kept here so this
/// feature can stand on its own without cross-feature imports.

final class LibrarySettingsPacksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ExercisePack>>,
          List<ExercisePack>,
          Stream<List<ExercisePack>>
        >
    with
        $FutureModifier<List<ExercisePack>>,
        $StreamProvider<List<ExercisePack>> {
  /// Local stream of installed packs for the settings screen. Mirrors the
  /// equivalent provider in the exercises feature — kept here so this
  /// feature can stand on its own without cross-feature imports.
  const LibrarySettingsPacksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'librarySettingsPacksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$librarySettingsPacksHash();

  @$internal
  @override
  $StreamProviderElement<List<ExercisePack>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ExercisePack>> create(Ref ref) {
    return librarySettingsPacks(ref);
  }
}

String _$librarySettingsPacksHash() =>
    r'3b80cc41a59e867893ce625aea590ff64e5928b6';
