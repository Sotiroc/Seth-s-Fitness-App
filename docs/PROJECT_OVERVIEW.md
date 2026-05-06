# Fitness App — Project Overview

A single-document tour of what this project is, how it's built, where it
runs, and where it's going. Pulled together from the existing source-of-
truth docs (`AGENTS.md`, `EXECUTION_PLAN.md`, `Brand.md`, `BACKLOG.md`,
`PERFORMANCE_BACKLOG.md`) and the current state of the codebase.

---

## What it is

A personal workout tracker built in Flutter, shipping first as a
**web-first PWA** that the user installs from Safari on iPhone via "Add
to Home Screen". Native iOS/Android, app-store release, and any backend
sync are deliberately deferred.

It is built for **one user**. Not a social app, not a coaching app, not
an AI workout planner. The job is: open the app, start a workout, log
sets, finish, look at history.

---

## Hosting & runtime

- **Hosted on Vercel** as a static Flutter web build.
- Project: `seth-fitness-app`, scope `sethsotiralis-gmailcoms-projects`.
- One-command deployment via [`deploy-web-vercel.ps1`](../deploy-web-vercel.ps1)
  — runs `flutter build web --release`, drops a `vercel.json` with SPA
  rewrites into `build/web`, links the project, and deploys to prod.
- PWA installable: `web/manifest.json` declares standalone display,
  brand teal `#289CB2` as `theme_color`, and the full icon set (192/512,
  plus maskable).
- Persistence is **local browser storage** (Drift configured for
  browser-safe local persistence). No accounts, no auth, no cloud sync.

---

## Stack

| Layer        | Choice                                    |
|--------------|-------------------------------------------|
| Framework    | Flutter (Dart, SDK ^3.10.8)               |
| UI           | Material 3, light mode default            |
| State        | Riverpod 3 with `riverpod_generator`      |
| Navigation   | `go_router` (StatefulShellRoute)          |
| Persistence  | Drift, browser-safe configuration         |
| Charts       | `fl_chart`                                |
| Fonts        | Inter (bundled local assets)              |
| IDs          | UUID v4 strings                           |
| Units        | kg + km only (no toggles)                 |
| Dates        | UTC stored, local-rendered via `intl`     |

Dev tooling: `build_runner`, `drift_dev`, `riverpod_generator`,
`riverpod_lint`, `custom_lint`, `flutter_lints`.

---

## Brand

The brand brief is short on purpose.

- **Seed color:** `#289CB2` ("jelly-bean teal"), with a documented 10-step
  ramp from `#EFFBFC` (50) to `#122E3A` (950).
- **Typography:** Inter (bundled), Manrope as a fallback only when needed.
- **Surface:** Material 3, light mode by default, restrained color use,
  strong readability, no noisy decoration.
- **Spacing scale:** 4 / 8 / 12 / 16 / 24 / 32.
- **Letter-avatar fallback** for exercises (no thumbnail uploads in the
  current phase).
- **PWA install chrome** (`theme_color`, `background_color`, manifest)
  matches the brand teal exactly so the home-screen icon and splash feel
  native.

The product should feel: fast, simple, dependable, uncluttered. It
should **not** feel: social, gamified, enterprise, or over-designed.
That tone is enforced quietly across the backlog — no toasts on PRs, no
celebration animations, no emoji. The trophy icon appearing on the
summary screen IS the celebration.

---

## Architecture

```
lib/
  app.dart                  ← root MaterialApp.router + splash + recovery
  main.dart                 ← ProviderScope + runApp
  core/
    router/                 ← go_router config, AppTab enum, StatefulShell
    theme/                  ← Material 3 theme, jelly-bean palette
    images/                 ← brand assets
    utils/
    widgets/                ← shared (splash, heartbeat logo, etc.)
  data/
    db/                     ← Drift schema, web/native connection split
    models/                 ← typed domain models + mappers
    repositories/           ← exercise, workout, template, profile, etc.
    seed/                   ← default exercises seeded on first run
    database_bootstrap.dart ← first-load DB warm-up + seed
  features/
    workouts/               ← active workout, summary, recovery
    history/                ← list + detail
    templates/              ← list + form
    exercises/              ← library list + form
    progression/            ← strength, body weight, PR feed, calendar heatmap
    profile/                ← profile, profile editor
    home/                   ← shell (drawer, bottom nav)
    settings/               ← settings + timer settings
```

Hard rules baked into the codebase:

- `features/` never imports another feature.
- `data/` never imports `features/`.
- UI never talks to Drift directly — repositories + Riverpod providers
  in between.
- Repository providers live in `data/`; screen/application providers
  live with their feature.

---

## Domain model

Exercise types: `weighted`, `bodyweight`, `cardio`.

Muscle groups: `legs`, `biceps`, `triceps`, `chest`, `back`, `shoulders`,
`abs`, `cardio`.

Entities:

- **Exercise** — `id, name, type, muscleGroup, thumbnailPath?, isDefault, createdAt, updatedAt`
- **WorkoutTemplate** — `id, name, createdAt, updatedAt`
- **TemplateExercise** — `id, templateId, exerciseId, orderIndex, defaultSets`
- **Workout** — `id, startedAt, endedAt?, templateId?, notes?`
- **WorkoutExercise** — `id, workoutId, exerciseId, orderIndex`
- **Set** — `id, workoutExerciseId, setNumber, weightKg?, reps?, distanceKm?, durationSeconds?, completed, kind, rpe?, note?`
- **WeightEntry** — bodyweight log, indexed by `measuredAt`
- **PrEvent** — derived PR records
- **UserProfile** — user-level data (name, height, bodyweight, goals, …)

Invariants:

- At most one active workout at a time (cold-start recovery is wired).
- Completed workouts are read-only in v1.
- Deleting an exercise must not break past workout history.
- Editing a template must not mutate past workouts.

---

## Current features (shipped)

### Core workout loop
- Start an empty workout or start from a template.
- Add exercises mid-workout (picker sheet with type filter chips).
- Log sets per exercise type:
  - **Weighted** — weight + reps, "PREVIOUS" tap-to-fill from last
    completed set for that exercise.
  - **Bodyweight** — reps.
  - **Cardio** — distance (km) + duration.
- Per-set kinds: **Normal**, **Warm-up** (amber W badge, excluded from
  volume/PRs), **Drop** (purple, indented under parent set), **Failure**
  (red F badge).
- Per-set RPE and per-set note via the set details bottom sheet.
- Per-exercise note (per workout instance), captured via "+ Note" on
  the exercise card.
- Per-workout note + per-workout RPE on the summary screen.
- **Rest timer** — auto-start when a set is completed, customizable
  default per-exercise rest, sheet UI with countdown.
- Finish / cancel flows with confirm dialogs.
- Workout summary screen on finish (name, intensity slider, notes, list
  of detected PRs for the session).
- **Workout recovery** — if the app was killed mid-workout, on cold
  start (or app resume) the active-workout stream triggers a recovery
  check; a non-dismissible recovery dialog opens from `HomeShell` to
  let the user resume or discard.

### History
- History list (newest first), grouped by month.
- Workout detail screen (read-only) showing exercises, sets, per-level
  notes, RPE, total volume, distance, duration.
- Search field with live filtering.
- Filter chips: Exercise (multi-select picker), Date range presets +
  custom, "PRs only" toggle.
- All filters AND together with search; persists across navigation;
  "X filters active · Clear all" strip.
- Empty states with meaningful CTAs.

### Templates
- Template list, create/edit form (name + ordered exercises with
  default set counts), delete.
- "Start workout from template" instantiates a fresh workout.

### Exercises
- Default seed library on first run.
- Search, type filter chips.
- Create / edit / delete with confirm.
- Letter-avatar fallback (typed initial on a teal background).
- Image upload support exists in the codebase (`image`, `image_picker`)
  but uploads are deferred for the web-first phase per Brand.md.

### Progression
- **Strength chart** — per-exercise estimated 1RM (Epley) over time,
  exercise picker, time-range selector.
- **Body weight chart** — line chart of `WeightEntry` log, with delta
  vs goal weight.
- **PR feed card** + dedicated PR list screen.
- **Training calendar heatmap** — workouts-per-day grid.
- **Hero stats strip** — high-level period totals.
- "Log weight" sheet for fast bodyweight entries.

### Profile
- Profile screen + editor: name, gender, height, body weight, goal
  weight, weekly workout target, weekly per-muscle set goals.
- Derived profile stats provider.
- Muscle goals sheet on the active workout for editing weekly targets
  inline.

### Settings
- Settings screen.
- Rest timer settings (default duration, sound/haptic preferences).

### Cross-cutting
- `HomeShell` with bottom navigation (Workouts, Progression, Templates,
  Exercises) backed by a `StatefulShellRoute`, plus a side drawer for
  Profile, History, Settings.
- Splash screen with a heartbeat logo animation; held until both DB
  bootstrap and the first screen's data have settled, so the handoff is
  a direct cut to the ready screen with no spinner flash.
- Custom indicator-line bottom nav bar (brand-styled).

---

## Recently completed work (from the performance audit)

The full performance audit (`PERFORMANCE_BACKLOG.md`) ran on
2026-05-03. Most of the high-impact items have already been picked up
— visible in the recent commit history (`Optimized Riverpod`,
`Speed optimization`, `UI Tweaks`, `Major Push`):

- Database indexes on hot foreign-key columns.
- Inter font bundled as local assets (no `google_fonts` runtime fetch).
- Live-workout typing storm fixed (debounced exercise-history streams,
  PR scanner deduped, strength-series memoized).
- Single-query progression first-load.
- Per-exercise previous-set refresh (no longer re-fetches all
  exercises).
- Active-workout header aggregates memoized.
- Chart memoization + `RepaintBoundary` isolation.
- History list grouping memoized.
- Set-row rebuild scope tightened.
- `ref.watch` / `.select` audit.
- Workout-detail aggregations memoized.
- Exercise-list filter debounced.
- Letter-avatar decoupled from theme palette.
- Workout-detail stream split into structure + sets.
- `keepAlive: true` audit (page-local providers now auto-dispose).
- Type-chip filter row memoized.

A handful of low-impact polish items remain open at the bottom of
`PERFORMANCE_BACKLOG.md` (#17–#21).

---

## Features still to implement

From `BACKLOG.md`. Each one already has a locked design direction —
ready to pick up.

### New functionality
- **Personal records** — full v1 scope: best set, e1RM, rep-range
  bests, cardio distance/duration PRs, bodyweight PRs. Detection fires
  at workout completion, surfaces on the summary, exercise history
  sheet, history list (trophy badge), and via a "PRs" filter chip on
  history.
- **A real exercise library** — replace the ~18 default exercises with
  ~150–250 curated entries from the Free Exercise DB (MIT-licensed).
  Adds secondary muscle group, equipment, and a hand-written one-line
  form cue per exercise.
- **Charts beyond bodyweight** — weekly volume per muscle group
  (stacked bars), total volume per week, workout frequency. Time-range
  pills with per-chart persistence.
- **A real home dashboard** — last-workout card, muscle-group balance
  ring, weekly recap card, this-month KPI tiles, optional auto-deload
  banner.
- **"Auto-deload" nudge** — fires when 4+ workouts in 14 days AND
  rolling avg RPE ≥ 8.5 AND no nudge in last 7 days. Quiet dismissible
  card on home.
- **Muscle-group balance ring** — Apple Activity Rings analog, one
  ring per muscle group, weekly target fill.
- **Quick-log mode for cardio** — single-screen "5 km, 28 min" logger
  that creates a one-exercise workout under the hood.
- **Weekly recap card** — Sunday-generated summary (volume, PRs,
  intensity, week-over-week deltas, daily volume sparkline). Shareable
  PNG. Archived in history via a "Recaps" filter chip.

### Polish on existing surfaces
- **Data-driven hero per tab** (Hevy/Strava-style):
  - **Workouts hero** — greeting eyebrow, streak/smart-suggestion/
    comeback punchline, live data sub-line, primary "Start workout"
    button moved INTO the hero, secondary "Pick template" link.
    *Highest priority — biggest perceived-quality lift.*
  - **History hero** — week-strip calendar (last 8 weeks, dot per day,
    tap-to-jump).
  - **Templates hero** — quick-start carousel of 2–3 most-recent
    templates (one-tap start, no confirmation).
  - **Exercises hero** — search promoted into the hero, recent
    exercises chip row.
- **Quick start vs. Start from template hierarchy** — mostly absorbed
  by the Workouts hero work above.
- **Label the intensity slider** — show a live label under the RPE
  slider ("Felt easy" → "All out — couldn't do another").
- **Dark mode** — Light / Dark / Match system in Settings + drawer
  toggle. Hero stays dark teal in both themes; per-screen palette
  tuning required for charts, set-row backgrounds, empty-state
  illustrations.

### Deferred until later
Native iOS / Android builds. App Store / Play Store. Supabase or any
sync. Authentication. Exercise thumbnail uploads (data layer is
present but UI is parked). Coaching, AI planning, social, video.

---

## Philosophies (picked up from the docs and the code)

These show up consistently across `AGENTS.md`, `Brand.md`, and the
backlog tone — they read as the project's actual operating principles.

1. **Web-first wins over native.** When a UI choice conflicts with
   web/PWA simplicity, choose the simpler web-safe option. No `dart:io`,
   no native-only filesystem paths, no native image-picker flows in
   runtime app code.
2. **Simple working code over clever code.** When in doubt, default to
   the simpler implementation even if a "more correct" architecture
   exists. Keep changes small and reviewable.
3. **One user, end-to-end.** Don't design for multiple users, accounts,
   or cloud sync. Optimize for one person's day-to-day.
4. **Speed of logging over feature depth.** The common case (a normal
   working set) should stay one tap. Set kinds, RPE, notes — all live
   one tap deeper, never in the way.
5. **Quiet, branded, not gamified.** No toasts on PRs, no celebration
   animations, no haptics, no emoji. The trophy icon on the summary
   screen IS the celebration. Keep tone factual.
6. **Empty states must have a CTA.** Don't show empty charts or empty
   lists without a meaningful next action.
7. **Destructive actions stay behind confirms.** Always.
8. **Don't blow away user data on upgrade.** Default seed changes must
   preserve user-created exercises, custom templates, history.
9. **Decisions get locked, then implemented.** The backlog reads like
   product specs — visual treatments, edge cases, deferred items, and
   open questions are spelled out before code is written.
10. **Vibe-coded direction.** The collaborator (Claude on frontend,
    Codex on data/runtime) is directed from intent. Status updates and
    plans are written in product language, not engineering jargon.
    Restate the ask, name the goal, sketch the approach. Skip file
    paths and code unless asked.

---

## Current state — at a glance

- **Phase:** post-W5. The W1–W5 execution plan (web-first runtime, PWA
  on iPhone, exercise CRUD, workout logging core loop, history +
  templates) is essentially complete.
- **Live and usable:** the full core loop works end-to-end on the
  hosted Vercel build, on iPhone Safari "Add to Home Screen", with
  data persisting locally across refresh.
- **Active focus:** finishing the performance polish backlog and
  starting on the next feature wave (Personal Records → Workouts hero
  → Charts → Home dashboard → Dark mode → bigger exercise library).
- **Working branch:** `main`, with a sizeable in-flight set of
  modifications across most features (visible in `git status`).
  Recent commit cadence: large pushes squashed into "Major Push" /
  "Test Push" / "Optimized Riverpod" rather than fine-grained commits.

The app is in the "stable enough to use daily, polishing toward
something I'd be proud to share" zone — no longer scaffolding, not yet
feature-complete against its own roadmap.
