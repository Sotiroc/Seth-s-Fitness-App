import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

const String _databaseFileName = 'fitness_app.sqlite';
const String _databaseStorageName = 'fitness_app_browser_storage';

QueryExecutor openAppDatabaseConnection() {
  return LazyDatabase(() async {
    final WasmSqlite3 sqlite3 = await WasmSqlite3.loadFromUrl(
      Uri.base.resolve('sqlite3.wasm'),
    );
    final IndexedDbFileSystem fileSystem = await IndexedDbFileSystem.open(
      dbName: _databaseStorageName,
    );
    sqlite3.registerVirtualFileSystem(fileSystem, makeDefault: true);

    return WasmDatabase(
      sqlite3: sqlite3,
      path: _databaseFileName,
      fileSystem: fileSystem,
    );
  });
}
