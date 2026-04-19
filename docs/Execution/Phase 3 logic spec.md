# Phase 3 — Logic Spec (Codex)

**Your scope:** domain models, Drift table + DAO, the real `ExerciseRepository` implementation, image file handling, default-exercise seeding, and unit tests. You do not build any widgets, screens, or navigation. You do not touch `lib/features/`.

**Read first:** `PROJECT_CONTEXT.md`, `brand.md`, `/specs/phase_3_ui_spec.md` (only §1 — "The contract" — so you know what shapes the UI expects). This doc assumes you've read them.

---

## 1. The contract you must implement

This is the authoritative interface. The UI side builds against a mock version of this. Your implementation must match exactly.

```dart
abstract class ExerciseRepository {
  Stream<List<Exercise>> watchAll();
  Future<Exercise?> getById(String id);
  Future<void> create(NewExercise input);
  Future<void> update(String id, ExerciseUpdate input);
  Future<void> delete(String id);
  Future<bool> hasLoggedSets(String id);
}
```

The UI side may have created placeholder versions of these files. **You own the authoritative versions.** Replace any placeholders with your real definitions and remove the placeholder comments.

## 2. Domain models

**`lib/data/models/exercise.dart`**

```dart
enum ExerciseType { weighted, bodyweight, cardio }

@immutable
class Exercise {
  final String id;           // UUID v4
  final String name;
  final ExerciseType type;
  final String? thumbnailPath;
  final bool isDefault;
  final DateTime createdAt;

  const Exercise({
    required this.id,
    required this.name,
    required this.type,
    required this.thumbnailPath,
    required this.isDefault,
    required this.createdAt,
  });

  // + copyWith, ==, hashCode, toString
}

@immutable
class NewExercise {
  final String name;
  final ExerciseType type;
  final String? thumbnailPath; // the *source* path picked by the UI, not yet persisted
  const NewExercise({
    required this.name,
    required this.type,
    this.thumbnailPath,
  });
}

@immutable
class ExerciseUpdate {
  final String? name;
  final String? thumbnailPath; // the *source* path picked by the UI, if changing
  final bool clearThumbnail;   // if true, delete existing thumbnail and set null
  const ExerciseUpdate({
    this.name,
    this.thumbnailPath,
    this.clearThumbnail = false,
  });
}
```

Validation rules:
- `name` must be non-empty after trim, ≤ 50 chars. Throw `ArgumentError` on create/update if violated.
- `thumbnailPath` when non-null must point to an existing file. Throw if not.
- Updating `type` is not supported. If the caller tries, there's no field for it — enforced by the shape of `ExerciseUpdate`.

## 3. Drift table

**`lib/data/db/tables/exercises_table.dart`**

```dart
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get type => intEnum<ExerciseType>()();
  TextColumn get thumbnailPath => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Indexes:** add an index on `name` for search (case-insensitive — store lowercased copy if needed, or rely on SQLite's `LIKE`).

**`lib/data/db/app_database.dart`** — if not yet created, scaffold it. If it exists, add `Exercises` to the `tables:` list and bump the schema version.

Run `dart run build_runner build --delete-conflicting-outputs` after changes and commit the generated `.g.dart` files.

## 4. DAO

**`lib/data/db/daos/exercise_dao.dart`**

```dart
@DriftAccessor(tables: [Exercises])
class ExerciseDao extends DatabaseAccessor<AppDatabase> with _$ExerciseDaoMixin {
  ExerciseDao(super.db);

  Stream<List<ExerciseRow>> watchAll();
  Future<ExerciseRow?> findById(String id);
  Future<void> insert(ExerciseRow row);
  Future<void> updateRow(ExerciseRow row);
  Future<void> deleteById(String id);
}
```

Order `watchAll` by `isDefault DESC, createdAt ASC` so default exercises render first and custom ones appear in creation order.

## 5. Repository implementation

**`lib/data/repositories/drift_exercise_repository.dart`**

Implement `ExerciseRepository`. Map between `ExerciseRow` (Drift) and `Exercise` (domain) via a mapper in the same file or `lib/data/models/mappers.dart`.

### `watchAll`

Straight delegation to `dao.watchAll()` with row-to-domain mapping.

### `getById`

Straight delegation with mapping.

### `create`

1. Validate input (non-empty name, ≤ 50, image exists if provided).
2. If `thumbnailPath != null`, call `_persistImage(source)` (§6) and capture the stored path.
3. Generate UUID via `uuid` package.
4. Insert row with `isDefault: false`, `createdAt: DateTime.now().toUtc()`.

### `update`

1. Load existing row. If null, throw `StateError("Exercise not found: $id")`.
2. Build new row:
   - `name`: input.name ?? existing.name (validate again).
   - `thumbnailPath`:
     - If `clearThumbnail == true`: delete the existing file via `_deleteImage(existing.thumbnailPath)`, set to null.
     - Else if `input.thumbnailPath != null` and differs from existing: persist new, delete old, store new path.
     - Else: keep existing.
3. `updateRow(newRow)`.

### `delete`

1. If `await hasLoggedSets(id)` → throw `StateError("Exercise has logged sets, cannot delete")`. (UI checks this first, but enforce at the data layer too.)
2. Load existing row.
3. If it has a thumbnail, `_deleteImage(path)`.
4. `dao.deleteById(id)`.

### `hasLoggedSets`

- **Phase 3 interim behavior:** return `false` unconditionally, but leave a `// TODO(phase-4): query Sets table` comment.
- **After Phase 4** (when the `Sets` table exists): return `true` if any `Set` row joins to this exercise via `WorkoutExercise`.
- Do not wait for Phase 4 to ship Phase 3 — the UI treats `false` gracefully.

## 6. Image file handling

**`lib/data/storage/exercise_image_store.dart`** (or inline in the repo if you prefer — but a separate class is cleaner for testing).

```dart
class ExerciseImageStore {
  Future<String> persist(String sourcePath); // copies to app docs, returns stored path
  Future<void> delete(String storedPath);    // no-op if file doesn't exist
}
```

**`persist` logic:**
1. Get app documents dir via `path_provider`.
2. Ensure subdirectory `exercise_thumbnails/` exists.
3. Generate a new filename: `${uuid()}${extension(sourcePath)}`.
4. Copy source file to `appDocs/exercise_thumbnails/<newname>`.
5. Return the absolute path of the new file.

**Do not move the source file** — it may be in a system picker cache that gets cleaned. Always copy.

**`delete` logic:**
- If file exists at `storedPath`, delete it. Swallow file-not-found errors; re-throw others.

The repository calls this class, not the other way around.

## 7. Seeding defaults

**`lib/data/seed/default_exercises.dart`**

```dart
const defaultExercises = <({String name, ExerciseType type})>[
  (name: 'Bench Press', type: ExerciseType.weighted),
  (name: 'Incline Dumbbell Press', type: ExerciseType.weighted),
  (name: 'Overhead Press', type: ExerciseType.weighted),
  (name: 'Barbell Row', type: ExerciseType.weighted),
  (name: 'Lat Pulldown', type: ExerciseType.weighted),
  (name: 'Squat', type: ExerciseType.weighted),
  (name: 'Deadlift', type: ExerciseType.weighted),
  (name: 'Romanian Deadlift', type: ExerciseType.weighted),
  (name: 'Leg Press', type: ExerciseType.weighted),
  (name: 'Bicep Curl', type: ExerciseType.weighted),
  (name: 'Tricep Pushdown', type: ExerciseType.weighted),
  (name: 'Pull-Up', type: ExerciseType.bodyweight),
  (name: 'Push-Up', type: ExerciseType.bodyweight),
  (name: 'Sit-Up', type: ExerciseType.bodyweight),
  (name: 'Plank', type: ExerciseType.bodyweight),
  (name: 'Treadmill', type: ExerciseType.cardio),
  (name: 'Stationary Bike', type: ExerciseType.cardio),
  (name: 'Rowing Machine', type: ExerciseType.cardio),
];
```

**Seeding logic** lives in a one-shot `AppSeeder` class called on app startup (after DB open, before UI runs):

1. Check a flag — either a row in an `AppSettings` table with key `exercises_seeded` or a `shared_preferences` bool. Prefer the DB-based flag for consistency.
2. If flag is `true`, return immediately.
3. Otherwise, insert each default with `isDefault: true`, unique UUIDs, `createdAt: now`.
4. Set the flag to `true`.

**Idempotency:** seeding must be safe to call multiple times. The flag handles this. Also guard with a unique constraint at the DB level? No — a user could legitimately create a second "Bench Press"; don't enforce uniqueness on name.

## 8. Provider wiring

**`lib/data/repositories/exercise_repository_provider.dart`**

```dart
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftExerciseRepository(
    dao: db.exerciseDao,
    imageStore: ref.watch(exerciseImageStoreProvider),
  );
});

final exerciseImageStoreProvider = Provider<ExerciseImageStore>((ref) {
  return ExerciseImageStore();
});
```

If the UI side committed a provider file with the mock repo wired in, **replace** that wiring with the real one — don't create a duplicate.

## 9. Tests

**`test/data/repositories/drift_exercise_repository_test.dart`**

Use Drift's in-memory database for tests (`NativeDatabase.memory()`).

Cover:

- [ ] `create` with valid input inserts a row with generated UUID, `isDefault: false`.
- [ ] `create` with empty name throws `ArgumentError`.
- [ ] `create` with >50 char name throws `ArgumentError`.
- [ ] `create` with a thumbnail path copies the file to app docs dir and stores the new path (mock the image store).
- [ ] `update` changes name; other fields untouched.
- [ ] `update` with `clearThumbnail: true` sets path to null and calls image store delete.
- [ ] `update` with new thumbnail replaces the old one and deletes the previous file.
- [ ] `update` on missing id throws `StateError`.
- [ ] `delete` removes the row and its thumbnail file.
- [ ] `delete` when `hasLoggedSets` is true throws (stub the check to return true).
- [ ] `watchAll` emits on every mutation.
- [ ] `hasLoggedSets` returns `false` in Phase 3 (document TODO for Phase 4).

**`test/data/seed/app_seeder_test.dart`**

- [ ] First run inserts all default exercises with `isDefault: true`.
- [ ] Second run (flag set) inserts nothing.
- [ ] After user creates their own "Bench Press", seeder still doesn't duplicate (flag is the guard).

Don't write tests for trivial getters, constants, or widget-adjacent code.

## 10. Integration step (joint with UI agent)

When both sides are ready:

1. Delete `lib/data/repositories/mock_exercise_repository.dart`.
2. Confirm `exerciseRepositoryProvider` points to `DriftExerciseRepository`.
3. Launch the app on device. Confirm seeded exercises appear.
4. Create a new exercise with an image. Kill the app. Relaunch. Confirm it persists and the image still renders.

## 11. Acceptance criteria

- [ ] All tests pass.
- [ ] `ExerciseRepository` contract matches the UI's expectations (no extra params, no renamed methods).
- [ ] Seeding runs once on first launch and never again.
- [ ] Thumbnails persist across app restarts.
- [ ] Deleting an exercise deletes its thumbnail file from disk.
- [ ] `build_runner` generates without warnings; generated files committed.
- [ ] No `print` statements in production code; use a logger or remove.
- [ ] No UI imports (`flutter/material.dart`) in any file you wrote — data layer is Flutter-free except for `path_provider`.

## 12. Out of scope for you

- Anything in `lib/features/` — that's the UI agent's territory.
- `LetterAvatar` widget.
- `go_router` routes.
- Loading / empty / error screen designs.
- The placeholder "View History" screen.
- Theme or brand tokens.

If you catch yourself writing a `Widget`, stop — wrong file.