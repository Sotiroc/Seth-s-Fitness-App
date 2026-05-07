import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/weekly_recap.dart';
import '../../../data/repositories/weekly_recap_repository.dart';

part 'weekly_recap_providers.g.dart';

/// The most recent recap that should be shown on the home, or null when
/// there isn't a "current" one (no workouts logged in the past complete
/// week, or the latest stored recap is more than 7 days past its
/// `weekEnd` and hasn't been replaced yet).
@Riverpod(keepAlive: true)
Stream<WeeklyRecap?> currentWeeklyRecap(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  // Trigger generation once on first read so the stream emits a freshly
  // generated recap on cold start without the UI having to wait for a
  // separate listener.
  await ref.read(weeklyRecapRepositoryProvider).generateRecapsIfNeeded();
  yield* ref.read(weeklyRecapRepositoryProvider).watchCurrent();
}

/// Every persisted recap, newest first. Surfaced behind the future
/// "Recaps" filter chip on the History screen.
@Riverpod(keepAlive: true)
Stream<List<WeeklyRecap>> allWeeklyRecaps(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.read(weeklyRecapRepositoryProvider).watchAll();
}
