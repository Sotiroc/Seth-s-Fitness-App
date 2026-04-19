# Project Context

**Read this first.** This file is the source of truth for any AI session working on this codebase. If something conflicts with this doc, this doc wins. If a user request contradicts this doc, ask before proceeding.

---

## What this project is

A personal workout tracker mobile app. Built primarily for the author's own gym use, with the long-term option to publish publicly on the App Store and Play Store.

**Core loop:** user opens the app at the gym → starts a workout (empty or from a template) → logs exercises, sets, reps, weight (or distance/time for cardio) → finishes the workout → sees history and progress over time.

**Non-goals:** social features, coaching, workout recommendations, AI-generated plans, video exercise demos, community. Don't build these. Don't suggest them unprompted.

---

## Stack

- **Framework:** Flutter (Dart), latest stable.
- **UI:** Material 3 (`useMaterial3: true`). No third-party UI kits.
- **Fonts:** `google_fonts` package. Font is Roboto (fallback Manrope).
- **Local DB:** Drift (SQLite under the hood). Local-first — the app must be fully functional offline.
- **Remote sync (later phases only):** Supabase. Not wired until Phase 9 of `EXECUTION_PLAN.md`.
- **Auth (later phases only):** Supabase email/password.
- **Charts:** `fl_chart` (added in Phase 8).
- **State management:** Riverpod. Use `riverpod_generator` / `@riverpod` annotations.
- **Navigation:** `go_router`.
- **IDs:** UUID v4 strings via the `uuid` package. No auto-increment ints — makes sync simpler later.
- **Dates:** Store as `DateTime` in UTC, display in device local time via `intl`.

### Key packages
```
drift, drift_flutter, path_provider, path
flutter_riverpod, riverpod_annotation
go_router
google_fonts
intl
uuid
image_picker (for exercise thumbnails)
```
Dev: `drift_dev`, `build_runner`, `riverpod_generator`, `custom_lint`, `riverpod_lint`.

---

## Design tokens

**Seed color:** `#289CB2` (jelly-bean 500).

**Full jelly-bean ramp** (use for custom surfaces outside M3's generated scheme):
```
50:  #EFFBFC
100: #D7F3F6
200: #B3E7EE
300: #7FD4E1
400: #44B8CC
500: #289CB2   ← seed
600: #26849D
700: #24667A
800: #255565
900: #234756
950: #122E3A
```

**Theme:** both light and dark generated via `ColorScheme.fromSeed`. Default mode is dark.

**Shapes:** M3 defaults (rounded corners, ~12px on cards).

**Spacing:** 4 / 8 / 12 / 16 / 24 / 32 grid. No arbitrary values.

---

## Units — locked

- Weight: **kg only**. No lbs. No unit toggle.
- Distance: **km only**. No miles.
- Time (cardio): **minutes** in UI, stored as seconds in DB.
- Do not add unit conversion code. Do not add a settings toggle for units.

---

=> 📍 Read till here

## Domain model

Three exercise types, and only three:

| Type | Tracks | Set row columns |
|---|---|---|
| `weighted` | reps + kg | Set \| Previous \| Kg \| Reps \| ✅ |
| `bodyweight` | reps | Set \| Previous \| Reps \| ✅ |
| `cardio` | distance + time | Set \| Previous \| Km \| Time \| ✅ |

### Entities
- **Exercise** — `id`, `name`, `type`, `thumbnailPath?`, `isDefault`, `createdAt`, `updatedAt`.
- **WorkoutTemplate** — `id`, `name`, `createdAt`, `updatedAt`.
- **TemplateExercise** — `id`, `templateId`, `exerciseId`, `orderIndex`, `defaultSets`.
- **Workout** — `id`, `startedAt`, `endedAt?` (null = in-progress), `templateId?`, `notes?`.
- **WorkoutExercise** — `id`, `workoutId`, `exerciseId`, `orderIndex`.
- **Set** — `id`, `workoutExerciseId`, `setNumber`, `weightKg?`, `reps?`, `distanceKm?`, `durationSeconds?`, `completed`.

Nullable weight/reps/distance/duration because different exercise types use different fields. Repositories validate which fields are required per type.

### Invariants
- At most one workout has `endedAt == null` at a time (the active workout).
- Deleting an Exercise does not delete past Sets — soft-delete or block deletion if referenced. Pick blocking for v1.
- Editing a template does not affect past workouts or the currently active workout.
- Past workouts are **read-only** in v1. Do not build edit UI for completed workouts.

---

## Project structure

```
lib/
  core/
    theme/          (AppTheme, color extensions)
    router/         (go_router config)
    utils/          (formatters, extensions)
  data/
    db/             (Drift database, tables, DAOs)
    models/         (domain models, not DB rows — mappers between them)
    repositories/   (ExerciseRepository, WorkoutRepository, TemplateRepository)
    seed/           (default exercise list)
  features/
    workouts/       (active workout screen, summary, start flow)
    exercises/      (list, create/edit, history view)
    templates/      (list, create/edit)
    history/        (workout history list + detail)
    home/           (bottom nav shell)
  app.dart          (MaterialApp.router + theme)
  main.dart         (ProviderScope, DB init, runApp)
```

**Rules:**
- `features/` never imports from another feature. Cross-feature sharing goes through `data/` or `core/`.
- `data/` never imports from `features/`.
- UI widgets never touch Drift directly — always go through a repository.
- Providers for repositories live in `data/`. Providers for screen state live alongside their feature.

---

## Coding conventions

- **Formatting:** `dart format` (80 cols). Lints: `flutter_lints` + `riverpod_lint` + `custom_lint`. All warnings must be zero before a commit.
- **Naming:** files `snake_case.dart`, classes `PascalCase`, vars `camelCase`, constants `SCREAMING_CASE`.
- **Widgets:** prefer `StatelessWidget` + Riverpod `ConsumerWidget`. Avoid `StatefulWidget` unless you need a controller lifecycle (e.g., `TextEditingController`, animation).
- **Async:** every async function has explicit return types. No `dynamic`. No `!` null-bangs unless the null case is impossible and commented why.
- **Errors:** repositories throw typed exceptions (`ExerciseNotFoundException`, etc.). UI catches and shows a `SnackBar`. Never swallow errors silently.
- **Magic numbers:** none. Lift to constants in `core/` or the relevant feature folder.
- **Comments:** explain *why*, not *what*. The code already says what.

---

## UI conventions

- **Letter-avatar fallback:** when an exercise has no `thumbnailPath`, render a circle with the first letter of the name. Background color derived from a hash of the name (stable across sessions). Build this once as a shared widget.
- **Set table:** matches the mockup in the brief exactly — rows per set, tappable ✅ to complete, previous set data pulled from most recent prior completed set for that exercise.
- **Persist-as-you-go:** every field change in an active workout writes to DB immediately. Do not rely on a "save" button mid-workout. If the app crashes, nothing is lost.
- **Empty states:** every list screen has a meaningful empty state with a CTA, not just a blank page.
- **Destructive actions:** always behind a confirm dialog (cancel workout, delete exercise, delete template).

---

## Testing

- Repositories must have unit tests. Cover happy path + the one or two realistic error paths. No testing for testing's sake.
- Widget tests only for the active workout screen's set-logging logic — that's the most critical UI.
- Integration tests: skip for v1.

---

## What not to do

- **Don't add features outside the current phase** of `EXECUTION_PLAN.md`. Ideas go in `BACKLOG.md`, not the codebase.
- **Don't introduce new state management libraries** (no Bloc, no GetX, no Provider-the-package). Riverpod only.
- **Don't wire Supabase before Phase 9.** Local-first. No network calls in the critical path.
- **Don't build a unit toggle.** kg/km only, see above.
- **Don't build edit-past-workout UI** in v1.
- **Don't add rest timers, workout plans, social features, or exercise demo videos.** Out of scope.
- **Don't invent new colors** outside the jelly-bean ramp or M3-generated scheme.
- **Don't use `setState` in `ConsumerWidget`.** If it's feeling tempting, model the state as a Riverpod provider.
- **Don't scaffold entire features in one go.** Small, reviewable chunks.

---

## How to work with this codebase (AI instructions)

When asked to implement something:

1. **Re-read this file and the relevant phase section of `EXECUTION_PLAN.md`.** Confirm the task is in scope for the current phase.
2. **Ask before deviating.** If the request conflicts with rules above, flag it and wait for a decision. Don't "helpfully" expand scope.
3. **Work in small commits.** One logical change per commit. Commit messages start with the phase number, e.g. `P4: add set-completion toggle`.
4. **Show your plan before writing code** for anything non-trivial — list files you'll create or change, then wait for a go-ahead.
5. **Generated code** (Drift, Riverpod) — always run the build step and commit the `.g.dart` files alongside source.
6. **When in doubt, pick the simpler option.** This app is a personal tool first. Elegance beats cleverness.

---

## Current phase

**Phase 0 (Completed) ** — pre-code decisions. Update this line as you advance through `EXECUTION_PLAN.md`.

**Phase 1 **
  -> 
