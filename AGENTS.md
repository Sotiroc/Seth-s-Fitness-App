# Project Context

**Read this first.** This file is the source of truth for any AI session working on this codebase. If something conflicts with this doc, this doc wins.

---

## Current product goal

Ship a **working web-first fitness tracker by the end of today**.

The app should run as a **Flutter web app / PWA** and be usable on an iPhone through Safari "Add to Home Screen". Store release and native mobile builds are deferred.

This repo is now **web first**:
- browser runtime is the priority
- local browser persistence is the priority
- native-only APIs are out of scope for the current delivery target

---

## What this project is

A personal workout tracker for one primary user.

Core loop:
- open the app
- start a workout
- log exercises and sets
- finish the workout
- review history and progress

Non-goals:
- social features
- coaching
- AI workout planning
- video demos
- community features

Do not add these unless explicitly requested later.

---

## Delivery mindset

Right now, optimize for:
- simplest working implementation
- one-user practicality
- end-of-day usability
- minimal moving parts

Do **not** optimize for:
- store readiness
- native parity
- perfect long-term abstractions
- extra backend services
- heavy new libraries unless they are necessary to make web/PWA work today

If there is a choice between a simpler working web solution and a more "correct" architecture, pick the simpler working web solution.

---

## Runtime and stack

- **Framework:** Flutter (Dart)
- **Primary target:** Web / PWA
- **UI:** Material 3 only
- **Fonts:** Inter via `google_fonts` with Manrope fallback
- **State:** Riverpod with `riverpod_generator`
- **Navigation:** `go_router`
- **Persistence:** local browser storage
- **Database layer:** Drift, but configured for browser-safe local persistence
- **IDs:** UUID v4 strings
- **Dates:** store UTC `DateTime`, display in local time via `intl`

### Important runtime rule

For the current phase, do not introduce or reintroduce:
- `dart:io` in app runtime code
- native SQLite bootstrap paths
- filesystem-based document storage
- native-only image/file handling

Native support can come later. Web support is the priority now.

---

## Design tokens

**Seed color:** `#289CB2`

**Jelly-bean ramp**
```
50:  #EFFBFC
100: #D7F3F6
200: #B3E7EE
300: #7FD4E1
400: #44B8CC
500: #289CB2
600: #26849D
700: #24667A
800: #255565
900: #234756
950: #122E3A
```

**Theme:** Material 3, light mode default.

**Spacing:** 4 / 8 / 12 / 16 / 24 / 32.

---

## Units

- Weight: **kg only**
- Distance: **km only**
- Cardio time in UI: **minutes**
- Cardio time in storage: **seconds**

Do not add unit toggles or conversion code.

---

## Domain model

Exercise types:
- `weighted`
- `bodyweight`
- `cardio`

Entities:
- **Exercise** - `id`, `name`, `type`, `thumbnailPath?`, `isDefault`, `createdAt`, `updatedAt`
- **WorkoutTemplate** - `id`, `name`, `createdAt`, `updatedAt`
- **TemplateExercise** - `id`, `templateId`, `exerciseId`, `orderIndex`, `defaultSets`
- **Workout** - `id`, `startedAt`, `endedAt?`, `templateId?`, `notes?`
- **WorkoutExercise** - `id`, `workoutId`, `exerciseId`, `orderIndex`
- **Set** - `id`, `workoutExerciseId`, `setNumber`, `weightKg?`, `reps?`, `distanceKm?`, `durationSeconds?`, `completed`

Invariants:
- at most one active workout at a time
- completed workouts are read-only in v1
- deleting an exercise must not break past workout history
- editing a template must not mutate past workouts

---

## Project structure

```text
lib/
  core/
    theme/
    router/
    utils/
  data/
    db/
    models/
    repositories/
    seed/
  features/
    workouts/
    exercises/
    templates/
    history/
    home/
  app.dart
  main.dart
```

Rules:
- `features/` never imports another feature
- `data/` never imports `features/`
- UI never talks to Drift directly
- repository providers live in `data/`
- screen/application providers live with their feature

---

## UI rules for the current web phase

- Letter-avatar fallback is the default thumbnail treatment
- For the current web-first build, **exercise thumbnails are deferred**
- Do not design flows that depend on native filesystem image picking
- Empty states must have a meaningful CTA
- Destructive actions stay behind confirm dialogs

If a UI choice conflicts with web/PWA simplicity, choose the simpler web-safe option.

---

## Testing

- Repository tests are required
- Add only the highest-value widget tests
- Prioritize:
  - web build success
  - browser persistence across refresh
  - seeded data appearing on first load
  - critical workout logging behavior

---

## Working split

- **Claude** owns frontend/UI work
- **Codex** owns logic, data, runtime, storage, repo wiring, and technical fixes unless told otherwise

When editing docs or implementation, keep this split visible so frontend work is built against the correct web-first assumptions.

---

## What not to do

- Don't optimize for App Store / Play Store right now
- Don't add Supabase right now
- Don't add sync right now
- Don't reintroduce native-only runtime APIs
- Don't add new product scope outside the current delivery goal
- Don't build for multiple users yet
- Don't add complicated infrastructure if a simple local solution works

---

## How to work in this repo

1. Re-read this file and the relevant execution doc before implementing.
2. Keep changes small and reviewable.
3. Prefer simple working code over clever code.
4. Keep generated files committed when generators are used.
5. Keep docs aligned with the actual runtime target.

---

## Current phase

**Phase W1** - web-first PWA conversion and same-day usable delivery.
