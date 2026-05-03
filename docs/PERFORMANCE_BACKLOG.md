# Performance backlog

Generated from a full audit of the app on 2026-05-03. Ordered by impact-per-effort: highest leverage first.

Each entry is **self-contained** — a fresh agent can pick one up cold without reading the others. Each entry includes:

- **Feels like** — what the user notices once it's fixed
- **Where it lives** — files involved (so the agent knows where to look)
- **What's happening today** — the current behavior causing the slowdown
- **Fix direction** — the shape of the change (not a step-by-step)
- **Done when** — acceptance signal..

When a task is complete, mark its title with a trailing ✅ and leave the entry in place for reference.

---

## High impact

### 1. Add missing database indexes

**Feels like:** lookups across history (active workout previous sets, exercise history sheet, progression charts, workout detail) become near-instant. Especially noticeable as a user accumulates more workouts.

**Where it lives:** `lib/data/db/app_database.dart` (currently only `weight_entries.measured_at` is indexed, around lines 341–345).

**What's happening today:** the most-queried foreign-key columns have no indexes, so SQLite does full-table scans on every hot path: `sets.workout_exercise_id`, `workout_exercises.workout_id`, `workout_exercises.exercise_id`, `workouts.ended_at`, `workouts.started_at`, and the date column on `weight_entries` if it's not already covered. Every history query, muscle-group volume query, and "previous set for exercise" query pays this cost.

**Fix direction:** add a Drift schema migration (bump the schema version) that creates indexes on each of the listed columns. No application-code changes required — Drift handles the rest.

**Done when:** schema version is bumped, migration runs cleanly on existing databases, and a quick before/after on the active workout screen shows no noticeable lag when adding the first exercise to a workout that has lots of history.

---

### 2. Bundle the Inter font instead of fetching it from Google

**Feels like:** the app paints the right font on the very first frame instead of briefly showing a fallback and then snapping to Inter. No network request on cold start.

**Where it lives:** `lib/core/theme/app_theme.dart` (uses `GoogleFonts.interTextTheme()` around line 26). `pubspec.yaml` will need an asset font declaration. The `google_fonts` package can stay in the dependency list if it's used elsewhere, but the runtime fetch must go.

**What's happening today:** on every cold load (which on a PWA is often), the `google_fonts` package issues a network request for Inter. This blocks first paint and produces a flash of unstyled text. On poor connections it can hang the app's first frame for hundreds of milliseconds.

**Fix direction:** download the Inter family weights actually used by the app, drop them into `assets/fonts/`, declare them under `flutter.fonts` in `pubspec.yaml`, and replace the `GoogleFonts.interTextTheme()` call with a regular `TextTheme` that uses `fontFamily: 'Inter'`. Keep the same weights/styles the theme already uses so nothing visually shifts.

**Done when:** disabling network in DevTools and reloading the app shows Inter rendered correctly on the first frame, with no FOUT.

---

### 3. Stop the live-workout typing storm

**Feels like:** typing weight and reps during an active workout stays buttery even after months of history. No mounting lag as you add more workouts.

**Where it lives:**
- `lib/data/repositories/workout_repository.dart` — `watchExerciseHistoryByDay` (around lines 1254–1312), `watchWorkoutDetail` (around 1326–1391), and the `watchAllPrEvents` PR scanner (around 1095–1147).
- `lib/features/workouts/application/active_workout_provider.dart` — providers downstream of these streams.
- `lib/features/progression/application/strength_series_provider.dart` — `exerciseStrengthSeries` (around lines 85–92, `_mapHistoryToPoints` 178–202).

**What's happening today:** each Drift stream above subscribes to *every* row change on the workouts/workout_exercises/sets/exercises tables. So a single keystroke in one set's weight field re-fires:
1. The exercise-history stream for *every* exercise the user has data for, not just the one being edited.
2. The PR event scanner, which walks the user's entire completed-set history in chronological order to recompute running maxes per exercise.
3. The strength-series mapper, which re-derives chart points from the re-emitted history even though the user isn't on the chart.
4. The workout-detail stream, which rebuilds the whole workout aggregate even when only an unrelated detail changed.

**Fix direction:** three coordinated changes —
1. Narrow the per-exercise history stream so it only re-emits when rows touching that specific exercise change. The simplest approach is a debounce (300–500 ms) on emissions, which collapses keystroke bursts. A better approach is to filter the underlying table-update set so the stream only listens to the exercise it's about.
2. Add a structural-equality dedupe to the PR event stream (`distinct` by the latest PR id or by the full list hash) so it stops re-emitting when nothing actually changed.
3. Memoize the strength-series mapping so it returns the same `List<StrengthPoint>` instance when its input list is structurally equal — this prevents downstream rebuilds even if the source stream re-emits.

**Done when:** typing rapidly into a set's weight or reps field on an exercise that has lots of history no longer causes visible jank, and a quick log/print confirms PR scanning and strength-series mapping are not re-running on every keystroke.

---

### 4. Single-query the progression first-load

**Feels like:** the progression tab opens immediately the first time, even for a user with dozens of distinct exercises in their history.

**Where it lives:** `lib/features/progression/application/strength_series_provider.dart` (the `trackableExercises` provider, around lines 46–48). Underlying repository call lives in `lib/data/repositories/workout_repository.dart`.

**What's happening today:** to figure out which exercises have any logged sets and what their most-recent session was, the provider loops over every weighted exercise and calls `getExerciseHistoryByDay(exerciseId)` once per exercise. Each call pulls the *full history* for that exercise just to extract the most-recent date. Cost scales with `(exercises × average_sessions_per_exercise)`.

**Fix direction:** add a single repository method that returns a list of `(exerciseId, latestStartedAt)` rows in one SQL query — `SELECT exercise_id, MAX(workouts.started_at) ... GROUP BY exercise_id`. Replace the loop with a single call to that method. The trackable-exercises provider then sorts/filters that small result set in memory.

**Done when:** opening the progression tab from cold no longer takes a noticeable beat, and the network/profiler shows one query instead of N.

---

### 5. Refresh "previous set" data for one exercise, not all of them

**Feels like:** adding or removing an exercise mid-workout is instant, no half-second pause.

**Where it lives:** `lib/features/workouts/application/active_workout_provider.dart` (`activeWorkoutPreviousSets`, around lines 47–68) and the underlying `getLastCompletedSetsForExercises` in `lib/data/repositories/workout_repository.dart` (around 822–879).

**What's happening today:** the provider depends on a workout signature that changes whenever the exercise list changes. On any change it re-fetches "previous best set" data for *all* exercises in the workout, walking finished workouts newest-first to find a match for each. A 6-exercise workout re-runs the full lookup six times when only one exercise was added.

**Fix direction:** track which exercise IDs were added or removed and only re-fetch previous-sets for those. The cache should preserve entries for unchanged exercises across signature updates.

**Done when:** adding or removing an exercise during an active workout doesn't produce any visible pause, even with substantial history.

---

### 6. Memoize the active-workout header aggregates

**Feels like:** the header at the top of the active workout (set counts, totals) doesn't burn CPU re-counting every frame while you're typing.

**Where it lives:** `lib/features/workouts/presentation/active_workout_screen.dart` (header section around lines 1214–1224, the `_buildSetRows` helper around 1922–2059).

**What's happening today:** the header recomputes `totalSets` and `completedSets` by chaining `.expand()` and `.fold()` over every exercise and set on every rebuild. Inside `_buildSetRows`, helpers like `canBeDrop` are computed per row by walking the sibling list — turning each rebuild into O(n²) for the set count.

**Fix direction:** lift these aggregates into a memoized provider keyed on the workout's exercise/set structure so they're only recomputed when the structure actually changes. For per-row helpers like `canBeDrop`, build the lookup map once before the loop and pass it down.

**Done when:** the header text and per-row badges still update correctly, but a profiler shows the aggregate functions are no longer called on every frame during active typing.

---

### 7. Memoize the chart data + isolate chart paints

**Feels like:** charts on the progression tab don't repaint each other when you change the time range on one. Less GPU/CPU when scrolling through the page.

**Where it lives:**
- `lib/features/progression/presentation/widgets/body_weight_chart_card.dart` (around lines 243–250)
- `lib/features/progression/presentation/widgets/strength_chart_card.dart` (around 337–342)
- `lib/features/progression/presentation/progression_screen.dart` (the SliverList around line 38)

**What's happening today:** each chart card builds its `FlSpot` list, axis bounds, and padding inside the build method on every rebuild. None of the cards is wrapped in a `RepaintBoundary`, so a state change in one card invalidates the paint surface shared with its siblings.

**Fix direction:**
1. Move chart-data derivation (the `FlSpot` list, axis bounds, formatted deltas) into providers keyed by the underlying entries + selected range, so chart inputs are reused across rebuilds when the data hasn't changed.
2. Wrap each chart card in `RepaintBoundary` so changing one card's range doesn't invalidate the others.

**Done when:** changing the range selector on one chart no longer triggers visible repaint work on the other charts (verifiable with the Flutter performance overlay's "repaint rainbow"), and chart-data computation only runs when its inputs change.

---

### 8. Memoize history list grouping and labels

**Feels like:** scrolling the history list is consistently smooth even with hundreds of workouts.

**Where it lives:** `lib/features/history/presentation/history_list_screen.dart` (`_groupByMonth` around lines 45–86, `_formatMonthLabel` around 110–150).

**What's happening today:** the list re-buckets every workout into months on each render (an O(n log n) operation), and the month-label formatter parses and indexes a month-name list per row as you scroll. Both repeat on every rebuild even when the underlying history is unchanged.

**Fix direction:** move the grouping into a memoized provider that watches `workoutHistoryProvider` and emits the pre-grouped structure. Replace per-row month-label parsing with a const lookup so it's just an array index.

**Done when:** scrolling a long history feels smooth, and grouping logic is no longer called on every frame.

---

### 9. Tighten set-row rebuild scope

**Feels like:** focusing or editing one set doesn't rebuild the entire set table for that exercise.

**Where it lives:** `lib/features/workouts/presentation/widgets/set_row.dart` (`_valueFields` around lines 469–541) and the row-building loop in `lib/features/workouts/presentation/active_workout_screen.dart` (around 1922–2059).

**What's happening today:** the row's value fields are reconstructed as fresh widget lists on every build (no const constructors, no extracted child widgets), and helpers like `canBeDrop` and `previousSet` are looked up per row by walking siblings. Result: editing one set rebuilds many siblings unnecessarily.

**Fix direction:** extract the number/duration field widgets into `const` stateless children that take primitive values; precompute the per-row helpers once in the parent and pass them as parameters; ensure each row has a stable `ValueKey` on the set's id so Flutter can match identity across rebuilds.

**Done when:** focusing or editing a single set only invalidates that row in a profiler/inspector, and `_valueFields` no longer allocates new widget trees per build.

---

## Medium impact

### 10. Audit `ref.watch` for missing `.select` filters

**Feels like:** the active workout screen rebuilds less often, especially while the rest timer is ticking.

**Where it lives:** `lib/features/workouts/presentation/active_workout_screen.dart` (multiple `ref.watch` calls in the header and body), and similar patterns across `lib/features/workouts/presentation/`, `lib/features/profile/presentation/`, and the home shell.

**What's happening today:** several screens watch entire provider states when they only need one slice. Most visible: while the rest timer is active and ticking once a second, the active workout screen rebuilds top-to-bottom every second because it watches the timer state without `.select`.

**Fix direction:** find every `ref.watch(provider)` where the consumer only reads a small slice of the value. Replace with `ref.watch(provider.select((s) => s.<slice>))`. The rest-timer header is the highest-priority case — the per-second tick should only invalidate the seconds-counter widget, not the whole header.

**Done when:** the rest timer counting down does not trigger rebuilds on the surrounding header (verifiable with the inspector), and similar over-broad watches are tightened.

---

### 11. Memoize workout-detail aggregations

**Feels like:** opening a past workout from history is snappy even for sessions with many exercises.

**Where it lives:** `lib/features/history/presentation/workout_detail_screen.dart` (volume/distance getters around lines 100–126).

**What's happening today:** total volume and total distance are computed as getters that run on every build, doing an O(n) walk over every exercise and set. Multiple `String` formatters (`_formatKg`, `_formatKm`, `_formatDate`) re-format on every build too.

**Fix direction:** lift the aggregate computations into a memoized provider (or `late final` fields on a controller) so they're computed once per detail load. Cache formatted strings alongside.

**Done when:** opening a heavy past workout no longer pauses, and aggregates aren't re-computed on every rebuild.

---

### 12. Debounce the exercise-list filter

**Feels like:** typing quickly into the exercise search field stays smooth and doesn't re-scan the list on every keystroke.

**Where it lives:** `lib/features/exercises/application/exercise_list_provider.dart` (`filteredExercises`, around lines 73–79).

**What's happening today:** every keystroke mutates the filter, which re-emits, which re-filters the entire list. A 10-character query fires 10 separate filter passes.

**Fix direction:** debounce the filter state with ~300 ms of input quiet before propagating, or split the debounce into a separate "pending" state vs "applied" state so the input stays responsive while the list lags slightly.

**Done when:** rapid typing into the search field no longer causes per-keystroke filter work, and search results still update with no perceptible delay.

---

### 13. Decouple letter-avatar rendering from theme palette

**Feels like:** lists of exercises don't ripple-rebuild when an unrelated theme value changes.

**Where it lives:** `lib/features/exercises/presentation/widgets/exercise_avatar.dart` (around lines 15–51), and the various places it's used (exercise list, workout add-exercise sheet, exercise picker).

**What's happening today:** the avatar reads `context.jellyBeanPalette` inside its build method. Any theme change cascades into a rebuild of every avatar in every list. The widget also lacks const constructors where it could have them.

**Fix direction:** pass the resolved color directly into the avatar as a parameter (computed once at the list level), or hoist the palette into a value that doesn't change when other theme bits do. Make the avatar `const`-constructable wherever possible.

**Done when:** changing an unrelated theme value doesn't rebuild the avatar tiles, and the widget's constructor is `const` where its arguments allow.

---

### 14. Narrow the workout-detail stream

**Feels like:** tweaking small per-set fields (set kind, RPE) on a past workout's detail screen doesn't cause a visible flicker as the whole detail rebuilds.

**Where it lives:** `lib/data/repositories/workout_repository.dart` (`watchWorkoutDetail` around 1326–1391, `_buildWorkoutDetail` around 1393–1415).

**What's happening today:** the stream listens to all four workout/exercise/set tables and rebuilds the whole detail on any change. Editing a set kind triggers the same full three-query rebuild as adding a new exercise.

**Fix direction:** split the stream — one for workout/exercise structure (rare changes), one for the set list (frequent changes). The detail screen composes the two so set edits update the set list portion without rebuilding the structural shell.

**Done when:** editing a set's kind/RPE on the detail screen updates without a full screen flicker, and a profiler shows only the affected portion rebuilds.

---

### 15. Audit `keepAlive: true` across providers

**Feels like:** memory usage stays flat over multi-day app sessions instead of slowly creeping up.

**Where it lives:** `lib/data/db/database_providers.dart` (around line 8) and most providers under `lib/features/*/application/`.

**What's happening today:** almost every provider is marked `keepAlive: true`. That means once a screen is visited, its data + its underlying database stream subscription is held forever even if the user never returns. Some of these (`userProfile`, `exerciseList`, `workoutHistory`) genuinely deserve it. Others (page-local: `exerciseStrengthSeries(id)`, `exerciseHistorySheet(id)`, profile editor state) do not.

**Fix direction:** classify each `keepAlive` provider as either "global" (keep) or "page-local" (drop the flag, let it auto-dispose when the screen is gone). Be conservative — only flip ones that are clearly tied to a single screen. Test that revisiting those screens still feels instant in normal usage (the underlying DB will refetch quickly).

**Done when:** providers tied to single screens auto-dispose when those screens are popped, and a long usage session doesn't show steadily climbing memory in the inspector.

---

### 16. Memoize the type-chip filter row

**Feels like:** typing into the exercise search doesn't waste work rebuilding the unrelated type-chip strip above it.

**Where it lives:** `lib/features/exercises/presentation/exercise_list_screen.dart` (`_TypeChips`, around lines 414–437).

**What's happening today:** the chip row maps over the full list of exercise types on every rebuild, with no `const` and no memoization. So a search-field rebuild also rebuilds the chip row even when the selected chip hasn't changed.

**Fix direction:** extract the chip row into its own consumer widget that only watches the selected-type slice via `.select`, with `const` chip widgets where possible.

**Done when:** searching no longer rebuilds the chip row (verifiable in the inspector).

---

## Low impact / polish

### 17. Move the splash logo image out of the animation builder

**Feels like:** marginally cooler GPU on the splash screen; tiny battery improvement on cold start.

**Where it lives:** `lib/core/widgets/heartbeat_logo.dart` (around lines 147–155).

**What's happening today:** `Image.asset()` is called inside an `AnimatedBuilder`'s `builder` callback, so the image widget is reconstructed on every animation frame even though only the scale/glow values change.

**Fix direction:** pass the `Image.asset(...)` as the `child` argument of the `AnimatedBuilder`. The builder receives that child and applies the animated transforms, but the image widget itself is built once.

**Done when:** the splash still animates correctly and only the transform widgets are rebuilt per frame.

---

### 18. Memoize chart helper formatters and lookups

**Feels like:** marginal CPU savings on the progression tab.

**Where it lives:**
- `lib/features/progression/presentation/widgets/body_weight_chart_card.dart` (`_formatDelta`, around lines 212–225)
- `lib/features/progression/presentation/widgets/strength_chart_card.dart` (`_nameFor`, around 183–188)
- Active workout `_formatPreviousSetSummary` and drop-chain formatting in `lib/features/workouts/presentation/active_workout_screen.dart` (around 1735–1770)

**What's happening today:** small format/lookup helpers run on every build. Some walk lists to find a name; others reformat strings that haven't changed.

**Fix direction:** lift formatting/lookups into providers keyed on their inputs, or pass the resolved value down as a parameter from a memoized parent.

**Done when:** these helpers no longer appear in the per-frame profile traces during active workout / chart interaction.

---

### 19. Add equality short-circuits to derived profile providers

**Feels like:** editing your name or other unrelated profile fields doesn't unnecessarily kick downstream providers (muscle goals, profile stats).

**Where it lives:**
- `lib/features/workouts/application/muscle_goals_provider.dart` (around lines 31–44)
- `lib/features/profile/application/profile_stats_provider.dart` (around 108–112)

**What's happening today:** these providers watch the full user profile and recompute their outputs on every emission, including emissions caused by edits to fields they don't read (name, etc.).

**Fix direction:** use `.select` to watch only the specific fields each provider depends on (height, weight, goal weight, muscle-goal overrides), so they only recompute when their actual inputs change.

**Done when:** editing the user's name doesn't trigger a recompute in muscle-goals or profile-stats (verifiable with a print or breakpoint).

---

### 20. Replace remaining client-side aggregations with SQL

**Feels like:** mostly invisible, but cleaner code and faster on large datasets.

**Where it lives:**
- `lib/features/progression/application/weight_entries_provider.dart` (`weightTrend`, around lines 93–100): linear scan to find a window-boundary entry. Replace with `WHERE measured_at >= ? AND measured_at < ?` query.
- `lib/features/workouts/application/workout_stats_provider.dart` (`workoutStreakWeeks`, around 138–162): walks every workout to compute ISO weeks. Replace with a `SELECT DISTINCT week_of(started_at)` query.
- `lib/data/repositories/workout_repository.dart` `listHistory()` and `watchHistory()` (around 774–803): loads the full history table when a paginated cursor would do.

**What's happening today:** small in-memory aggregations and full-table loads. Each one is sub-millisecond on typical data, but they belong in SQL — both for correctness at scale and to keep the Dart layer small.

**Fix direction:** replace each with a targeted SQL query. For history pagination, decide a cursor strategy (likely "page by `started_at` DESC with a limit").

**Done when:** these helpers no longer load full tables into Dart, and pagination on history works on a synthetic large dataset.

---

### 21. Reduce deep `Theme.of` / `MediaQuery.of` reads

**Feels like:** mostly invisible, but reduces the blast radius of theme/media changes.

**Where it lives:** various widgets in `lib/features/history/presentation/`, `lib/features/workouts/presentation/`, deep in headers and tiles.

**What's happening today:** several deep widgets read `Theme.of(context)` or `MediaQuery.of(context)` directly in their build methods. Any theme or media change invalidates all of them.

**Fix direction:** hoist the relevant resolved values (text styles, padding, brand colors) into constants or a high-level inherited value so deep widgets read primitives instead of registering for theme/media changes.

**Done when:** rotating the device or toggling theme (when dark mode lands) doesn't rebuild the entire screen, only the parts that genuinely depend on the changed value.

---

## Order of attack — recommendation

For maximum felt improvement at minimum risk:

1. **#1 (indexes)** — fastest win, every query benefits.
2. **#2 (font)** — instant first-paint improvement, you'll feel it on the next reload.
3. **#3 (live-typing storm)** — biggest "feels good" win on the most-used screen.
4. **#4 (progression first-load)** and **#5 (per-exercise refresh)** — kill the two visible pauses.
5. **#6–#9** — list and rebuild scope cleanups; cumulative smoothness.
6. **#10–#16** — medium polish, individually small.
7. **#17–#21** — last-mile polish.
