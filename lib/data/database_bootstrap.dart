import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'repositories/exercise_repository.dart';

part 'database_bootstrap.g.dart';

/// Minimum time the cold-start splash stays on screen so the heartbeat
/// animation has room to land before the app appears. On already-seeded
/// installs the actual seeding work finishes nearly instantly, so without
/// this floor the splash would just flash.
const Duration _minSplashDuration = Duration(milliseconds: 1100);

@Riverpod(keepAlive: true)
Future<void> databaseBootstrap(Ref ref) async {
  await Future.wait<void>(<Future<void>>[
    ref.watch(exerciseRepositoryProvider).seedDefaultsIfNeeded(),
    Future<void>.delayed(_minSplashDuration),
  ]);
}
