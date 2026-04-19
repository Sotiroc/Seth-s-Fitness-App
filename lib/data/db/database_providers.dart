import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

part 'database_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final AppDatabase database = AppDatabase();
  ref.onDispose(() {
    database.close();
  });
  return database;
}

@Riverpod(keepAlive: true)
Uuid uuid(Ref ref) {
  return const Uuid();
}
