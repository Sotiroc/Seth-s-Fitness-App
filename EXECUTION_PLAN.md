# Workout App - Execution Plan

A step-by-step build plan, ordered so each phase gives you something usable before moving on. Tick items off as you go. Keep this doc in the repo root.

---

## Phase 0 - Foundations (pre-code decisions)

Lock these down before writing a single line. They're all small but they block everything downstream if left fuzzy.

- [ Confirmed ] **Confirm stack:** Flutter (Dart), Material 3, Drift (local DB, SQLite under the hood), `fl_chart` for graphs later, Supabase for sync only (added late).
- [ Confirmed ] **Confirm units:** kg and km throughout. No unit toggle for v1.
- [ Confirmed ] **Confirm exercise types:** `weighted` (reps + kg), `bodyweight` (reps only), `cardio` (distance km + time minutes).
- [ Confirmed ] **Seed color & theme tokens:** jelly-bean `#289CB2` as seed. Default mode is light for first launch.
- [ Confirmed ] **Pick a font:** Inter via `google_fonts` package with Manrope fallback.
- [ Confirmed ] **Decide default exercise list:** Bench Press, Incline Dumbbell Press, Overhead Press, Pull-Up, Barbell Row, Lat Pulldown, Seated Cable Row, Squat, Deadlift, Romanian Deadlift, Leg Press, Bicep Curl, Tricep Pushdown, Plank, Push-Up, Sit-Up, Treadmill, Stationary Bike.

---

## Phase 1 - Project scaffold & theme

Goal: a running Flutter app on your phone with your brand theme applied. No features yet.

- [x] Scaffold the Flutter app in the repo root with package id `com.seths.fitnessapp`.
- [x] Add dependencies: `drift`, `drift_flutter`, `path_provider`, `path`, `google_fonts`, `intl`, `uuid`, `flutter_riverpod`, `riverpod_annotation`, `go_router`, `image_picker`. Dev deps: `drift_dev`, `build_runner`, `riverpod_generator`, `custom_lint`, `riverpod_lint`.
- [x] Set up folder structure:
  ```
  lib/
    core/        (theme, constants, utils)
    data/        (db, repositories, models)
    features/    (workouts/, exercises/, history/, templates/)
    app.dart
    main.dart
  ```
- [x] Build `AppTheme` class with `ColorScheme.fromSeed(seedColor: Color(0xFF289CB2))` for both light and dark. Wire `useMaterial3: true`.
- [x] Add custom jelly-bean palette extension for cases where you want specific shades outside M3's generated scheme.
- [x] Build a placeholder home screen with a bottom nav (Workouts, History, Exercises) so you can see the theme live.
- [ ] Run on your physical device. Confirm the vibe. Adjust seed or brightness if needed.

---

## Phase 2 - Data layer

Goal: local database with all tables and repositories, no UI wiring yet. "Repository interface" here IS the local DB - don't build a separate fake layer.

- [x] Define Drift tables:
  - `Exercises` - id, name, type (enum: weighted/bodyweight/cardio), thumbnailPath (nullable), isDefault (bool), createdAt.
  - `WorkoutTemplates` - id, name, createdAt, updatedAt.
  - `TemplateExercises` - id, templateId, exerciseId, orderIndex, defaultSets (int).
  - `Workouts` - id, startedAt, endedAt (nullable - null means in-progress), templateId (nullable), notes.
  - `WorkoutExercises` - id, workoutId, exerciseId, orderIndex.
  - `Sets` - id, workoutExerciseId, setNumber, weightKg (nullable), reps (nullable), distanceKm (nullable), durationSeconds (nullable), completed (bool).
- [x] Generate Drift code with `build_runner`.
- [x] Write repository classes:
  - `ExerciseRepository` - CRUD, list by type, seed defaults on first launch.
  - `WorkoutRepository` - start, end, cancel, list history, get with exercises & sets.
  - `TemplateRepository` - CRUD, duplicate into a new workout.
- [x] Seed the default exercise list on first launch with a Drift `AppSettings` flag.
- [x] Write a quick debug screen that dumps all exercises & workouts so you can confirm the DB works without UI polish.

---

## Phase 3 - Exercise management

Goal: full CRUD on exercises. This is a small surface area and warms you up for the real workout screen.

- [ ] Exercise list screen - tiles with thumbnail (first-letter-in-colored-circle fallback) + name + type badge.
- [ ] Letter-avatar widget - generates a colored circle with the first letter, color derived from exercise name hash so it's stable.
- [ ] Create/edit exercise screen - name, type picker (3 options), optional image picker (stored to app documents dir, path saved in DB).
- [ ] Delete exercise (with confirm; soft-block deleting defaults or just let them go - your call).
- [ ] Search/filter bar on the list screen.
- [ ] 3-dot menu on each exercise: View History (stub for now), Edit, Delete.

---

## Phase 4 - Workout logging (the core loop)

Goal: the thing you'll actually use at the gym. Ship this before anything else downstream.

- [ ] "Start Empty Workout" button on home screen -> creates a Workout row with `startedAt = now`.
- [ ] Active workout screen:
  - Elapsed timer at top (ticking from startedAt).
  - List of exercises added to this workout.
  - Each exercise block shows the sets table from your mockup: Set # | Previous | Kg (or Km) | Reps (or Time) | ✅.
  - "+ Add Set" button per exercise.
  - "Add Exercise" button at bottom - opens a searchable picker; includes "Create New Exercise" option inline.
  - "Finish Workout" button - sets `endedAt = now`, navigates to a summary.
  - "Cancel Workout" button - deletes the Workout row, confirms first.
- [ ] "Previous" column logic: query the most recent completed set for that exercise before this workout; display as `"60 kg x 10"` or `-` if none.
- [ ] Tapping ✅ marks the set as completed and locks the row visually (greyed out, still editable).
- [ ] Persist every change to DB as it happens - if the app crashes mid-workout, nothing is lost.
- [ ] Handle the "cardio" variant of the sets table (Km + Time columns instead of Kg + Reps).
- [ ] Handle the "bodyweight" variant (Reps column only).
- [ ] Finish screen - shows duration, total sets, total volume (kg × reps summed across weighted sets), list of exercises done.

**Milestone:** after this phase, use the app for a week of real workouts. Fix anything annoying before moving on. This is the only way to know what actually matters.

---

## Phase 5 - Workout history

Goal: see past workouts.

- [ ] History list screen - date, duration, exercise count, top-line summary ("Bench 3×10, Squat 4×8, ...").
- [ ] Workout detail screen - full breakdown, read-only for now.
- [ ] Empty state with a nudge to start a workout.

---

## Phase 6 - Templates

Goal: save a workout structure and start from it.

- [ ] Template list screen.
- [ ] Create/edit template screen - name + ordered list of exercises with default set counts.
- [ ] "Save as Template" option from a finished workout (or from any workout).
- [ ] "Start from Template" on home screen - creates a new Workout pre-populated with the template's exercises and empty sets.
- [ ] Editing a template does not retroactively change past workouts.
- [ ] Allow editing a template while an active workout uses it - changes apply only to the template, not the live workout (simpler behavior).

---

## Phase 7 - Exercise history view

Goal: the 3-dot -> "View History" from Phase 3 comes alive.

- [ ] Per-exercise history screen - list of dates the exercise was performed.
- [ ] Each date entry shows all sets done (weight × reps or km × time).
- [ ] Accessible from exercise list AND from inside an active workout.

---

## Phase 8 - Graphs & progress

Goal: visual motivation.

- [ ] Add `fl_chart`.
- [ ] Gym frequency chart - workouts per week / month / year, toggleable.
- [ ] Per-exercise progression charts - max weight over time, estimated 1RM over time, total volume per session over time. User picks which metric.
- [ ] Put these behind a "Progress" tab or inside the exercise history screen.

---

## Phase 9 - Supabase sync + Auth

Goal: multi-device and ready to publish. **Only do this when you actually want to ship publicly or use the app on a second device.**

- [ ] Set up Supabase project. Mirror the local schema in Postgres.
- [ ] Add `supabase_flutter` package.
- [ ] Implement email/password auth (or magic link) with a simple login screen.
- [ ] Add `userId` to all synced tables in Supabase with row-level security.
- [ ] Sync strategy: on login and on app foreground with connectivity, push local changes then pull remote. Use `updatedAt` timestamps and a `syncedAt` flag per row. Last-write-wins is fine for v1 - you're the only user.
- [ ] Handle conflicts by trusting the most recent `updatedAt`.
- [ ] Test offline -> online transition hard. Airplane-mode the gym session, come home, confirm it syncs cleanly.

---

## Phase 10 - Excel export/import

Goal: nice-to-have. Skip unless you find yourself wanting it.

- [ ] Add `excel` package.
- [ ] Export: date range picker -> .xlsx with sheets for Workouts, Exercises, Sets. Share sheet to send it off the device.
- [ ] Import: file picker -> parse -> merge (skip duplicates by id).

---

## Phase 11 - Polish & store prep (only if publishing)

- [ ] App icon and splash screen using jelly-bean palette.
- [ ] Onboarding (one screen, skippable).
- [ ] Crash reporting (Sentry free tier).
- [ ] Privacy policy (required for stores).
- [ ] Screenshots, store listing copy.
- [ ] Test on a cheap Android and an iPhone.

---

## Working rules for AI-assisted builds

Stick to these and the project stays clean:

1. **One phase at a time.** Don't prompt "build the whole workout feature." Prompt "build the Active Workout screen given this data model and this repository, matching this mockup."
2. **Paste this plan + the relevant section of your brief into every session.** Fresh AI sessions have no memory.
3. **Commit after each sub-bullet.** Small commits = easy rollback when the AI goes off the rails.
4. **Resist feature creep.** Ideas that aren't in this plan go in a `BACKLOG.md`, not into the current phase.
5. **Use the app between phases.** Dogfood hard. The app you think you want is never the app you actually want.
