import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/user_profile_repository.dart';

part 'user_profile_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<UserProfile?> userProfile(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  final UserProfileRepository repository = ref.watch(
    userProfileRepositoryProvider,
  );
  yield* repository.watchProfile();
}
