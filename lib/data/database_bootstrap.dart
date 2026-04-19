import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'repositories/exercise_repository.dart';

part 'database_bootstrap.g.dart';

@Riverpod(keepAlive: true)
Future<void> databaseBootstrap(Ref ref) async {
  await ref.watch(exerciseRepositoryProvider).seedDefaultsIfNeeded();
}
