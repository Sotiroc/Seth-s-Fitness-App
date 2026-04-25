// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(templateList)
const templateListProvider = TemplateListProvider._();

final class TemplateListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkoutTemplate>>,
          List<WorkoutTemplate>,
          Stream<List<WorkoutTemplate>>
        >
    with
        $FutureModifier<List<WorkoutTemplate>>,
        $StreamProvider<List<WorkoutTemplate>> {
  const TemplateListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'templateListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$templateListHash();

  @$internal
  @override
  $StreamProviderElement<List<WorkoutTemplate>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WorkoutTemplate>> create(Ref ref) {
    return templateList(ref);
  }
}

String _$templateListHash() => r'69d03d1451fa860667c477f83488886770df8b19';

@ProviderFor(templateDetail)
const templateDetailProvider = TemplateDetailFamily._();

final class TemplateDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<TemplateDetail>,
          TemplateDetail,
          Stream<TemplateDetail>
        >
    with $FutureModifier<TemplateDetail>, $StreamProvider<TemplateDetail> {
  const TemplateDetailProvider._({
    required TemplateDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'templateDetailProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$templateDetailHash();

  @override
  String toString() {
    return r'templateDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<TemplateDetail> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<TemplateDetail> create(Ref ref) {
    final argument = this.argument as String;
    return templateDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TemplateDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$templateDetailHash() => r'0b71bf6f58ee53515257295da3076304bd4e1326';

final class TemplateDetailFamily extends $Family
    with $FunctionalFamilyOverride<Stream<TemplateDetail>, String> {
  const TemplateDetailFamily._()
    : super(
        retry: null,
        name: r'templateDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  TemplateDetailProvider call(String templateId) =>
      TemplateDetailProvider._(argument: templateId, from: this);

  @override
  String toString() => r'templateDetailProvider';
}

@ProviderFor(templateExerciseOptions)
const templateExerciseOptionsProvider = TemplateExerciseOptionsProvider._();

final class TemplateExerciseOptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Exercise>>,
          List<Exercise>,
          FutureOr<List<Exercise>>
        >
    with $FutureModifier<List<Exercise>>, $FutureProvider<List<Exercise>> {
  const TemplateExerciseOptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'templateExerciseOptionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$templateExerciseOptionsHash();

  @$internal
  @override
  $FutureProviderElement<List<Exercise>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Exercise>> create(Ref ref) {
    return templateExerciseOptions(ref);
  }
}

String _$templateExerciseOptionsHash() =>
    r'c60ab4a3b3045fc1e187117ddaa290b48246c6a2';
