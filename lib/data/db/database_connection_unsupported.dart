import 'package:drift/drift.dart';

QueryExecutor openAppDatabaseConnection() {
  return LazyDatabase(() async {
    throw UnsupportedError(
      'This project is web-first for now. Run it with a web target.',
    );
  });
}
