# Backlog

Working list. Top section is new functionality. Bottom section is polish on
things that already exist.

---

## Features to add

### Tap "PREVIOUS" to fill the row ✅

Quick "repeat last set" / "fill from previous workout". Tapping the "PREVIOUS"
cell should populate kg + reps. Right now that column is decorative.

---

### Rest timer ✅

The single most-used feature in any strength app. Auto-start it when a set is
checked off. Customizable per exercise, with a visible countdown and a gentle
haptic/sound at zero. Without this, anyone training seriously will keep their
phone clock open alongside the app.

---

### Set types beyond "regular" ✅

Warm-up sets, drop sets, failure flag, and an RPE field per set (we have RPE
for the whole workout — most people want it per set too). Without this you
can't faithfully log a real workout.

**Decisions made — design direction is locked, ready to implement:**

UI pattern: Hevy-style. Tap the set number on any row to open a bottom sheet
("set details") that contains, in this order:

1. **Set type picker** — Normal / Warm-up / Drop / Failure (single-select).
2. **RPE for this set** — 1–10 scale, optional, skippable.
3. **Note for this set** — free-text field (e.g. "left shoulder felt tight").

The row itself stays unchanged in its default state
(# / PREVIOUS / kg / reps / check) so the common case is still as fast as it
is today. All extras live one tap away.

**Behavior per set type:**

- **Normal** — the default for every new set. Counts toward volume, the
  X/Y completion counter, and PR detection.
- **Warm-up** — shows a "W" badge in place of the numbered position.
  Excluded from total volume, the X/Y completion counter, and PR detection.
  Still shown in the PREVIOUS reference. Warm-ups always render above the
  working sets in the row order. ( use a very light amber color for this, very subtle to not distract from teal brand)
- **Drop** — visually indented under the parent working set, with a
  connector line or shifted column so the parent/child relationship is
  obvious at a glance. Counts toward volume. The PREVIOUS reference should
  show the chain ("100×8 → 80×6 → 60×4"). The affordance to add a drop
  should only appear on completed working sets — adding a drop to a blank
  row doesn't make sense. (make this color a slighlt purple color again very subtle darker purple D and light light purple background)
- **Failure** — a marker that "I went to true failure on this set."
  Note: RPE 10 also implies failure. For now keep both signals; we may
  collapse them later. A small "F" badge appears on the row when set. (implement the same design as drop but make it red )

**Per-set RPE vs. per-workout RPE:**

Keep both. The per-workout RPE that already exists on the summary screen
should auto-suggest itself from the per-set values (max or average — TBD)
once per-set RPE is in place, but the user can override on the summary.

**Visible badges on the set row when collapsed:**

If a set has any extras attached (non-Normal type, RPE, or note), show small
indicators on the row so the user can see at a glance which sets have
context without having to open each one. Examples: "W" for warm-up,
"D" for drop, "F" for failure, a small dot for "has note", an RPE number
in a quiet color.

---

### Personal records ✅

Detect them on workout completion ("New PR: bench 102.5 kg!") and surface
them somewhere persistent. Right now you log a 5RM and the app shrugs.

**Decisions made — design direction is locked, ready to implement:**

**What counts as a PR (track these in v1):**

For weighted exercises:
- **Best set** — heaviest single set ever for that exercise (weight × reps).
- **Estimated 1RM (Epley)** — already calculated for the strength chart;
  just wire it into PR detection.
- **Heaviest weight at any rep count** — the rep-range PR ("5RM, 8RM, 10RM"
  bests). Track every distinct rep count the user has logged, not a fixed
  ladder. If they've ever done 7 reps, the 7RM is tracked separately.

For cardio:
- **Longest distance** (km).
- **Longest duration** (minutes).

For bodyweight:
- **Most reps in a single set.**
- **Most reps in a single workout** (total volume across all sets of that
  exercise in the session).

**When detection fires:**

Only at workout completion. No live toast/badge/haptic during the workout
itself. The summary screen surfaces PRs in a dedicated "Records this
session" block — that's the celebration moment.

**Where PRs surface persistently:**

1. **Workout summary screen** — "Records this session" block listing every
   PR detected in that workout. Each PR shown with the existing trophy icon.
2. **Exercise history sheet** — "Personal records" section at the top
   showing the current best set, current e1RM, and rep-range bests for that
   exercise.
3. **History list** — workouts that contained a PR get a small trophy
   badge in the corner of their card. Lets you scan history for breakthrough
   sessions at a glance.
4. **History list filter** — a "PRs" filter chip at the top of the History
   screen. When active, the list **switches mode** from "list of workouts"
   to "flat list of PR achievements." Each row in the filtered view is
   one PR: exercise name, the PR value (e.g. "102.5 kg × 5" or "5.2 km"),
   the PR type label (best set / e1RM / 5RM / longest distance), date, and
   the trophy icon. Sorted newest first. Tap a row to jump to the workout
   where it was set.

   This filter replaces the idea of a standalone "Records" screen — same
   value, no extra surface to design or maintain.

**Visual treatment:**

- Use the existing trophy icon throughout. Not a star.
- No live toast, no haptic, no celebration animation. The trophy icon
  appearing on the summary screen IS the celebration. Brand-safe and quiet.

**Edge cases — locked behavior:**

- **First-ever workout for an exercise.** Suppress PR detection. The
  exercise needs at least one prior completed workout in history before any
  of its sets can trigger a PR. Otherwise the first leg day fires 30 PRs.
- **Warm-up sets never trigger PRs.** Aligned with the set-type spec.
- **Failure sets can trigger PRs.** RPE 10 doesn't disqualify the lift.
- **Same weight, more reps = PR.** Yes.
- **More weight, fewer reps = PR for that new rep count.** Yes — a new 3RM
  is a PR even if it doesn't improve e1RM. They're separate PR concepts.
- **Editing a past workout that contained a PR.** Recompute affected PRs
  on edit/delete, not only on workout finish.
- **Unit system changes.** PRs stored in kg/km internally; displayed in the
  user's preferred unit.

**What's deferred for later:**

- Live toast / haptic on detection during the workout (could layer in v2
  if the silent celebration feels too quiet).
- Standalone Records screen (the History filter delivers the same value
  with less surface area).
- Trophy icon next to PRs in the PREVIOUS column on future workouts
  (rejected for now).
- Volume-PR per session for weighted exercises (not table stakes).
- Pace-based PRs for cardio (advanced metric — basic distance/duration
  covers v1).

---

### A real exercise library

18 default exercises is thin. Expect ~150–300, organized by muscle group and
equipment, each with a one-line form cue. No video needed — text cues are
enough and free to ship.

**Scope:**

Replace the current short default list with a curated library of ~150–250
common gym, bodyweight, and cardio exercises. Existing user-created
exercises must be preserved on upgrade — never blow away custom data.

**Per-exercise metadata (extends the current model):**

- Name (e.g. "Barbell Bench Press") — already exists.
- Type (weighted / bodyweight / cardio) — already exists.
- Primary muscle group — already exists.
- Secondary muscle group (optional, e.g. bench → primary chest, secondary
  triceps) — NEW.
- Equipment (barbell / dumbbell / machine / cable / bodyweight / kettlebell /
  band / cardio-machine) — NEW.
- One-line form cue (e.g. "Drive feet, retract shoulders, bar to lower
  chest"). Plain text, ~80 chars max — NEW.
- isDefault flag — already exists.

**Source for the seed data:**

Use a permissively-licensed public exercise dataset (Free Exercise DB on
GitHub is MIT-licensed, ~870 exercises with metadata). Filter to ~200 most
common across the supported muscle groups. Hand-write the form cue line in
the project's voice — don't import wordy descriptions verbatim.

**UI changes that fall out of this:**

- Exercise library screen gets an equipment filter chip alongside the
  existing type filter chip.
- Exercise create/edit form gets equipment dropdown + form cue field.
- Exercise card shows the form cue underneath the name (small, quiet text)
  on the library AND inside the exercise picker during a workout.
- Per the existing decision in this backlog, type chips/badges stay HIDDEN
  in the exercise-picker-during-workout flow.

**Open question:**

- Should the library default screen group exercises by muscle group
  (collapsible sections) or stay as a flat alphabetical list with filters?
  Recommend flat with filters — simpler, matches current pattern.

---

### Notes per workout and per exercise ✅

Free-text notes at multiple levels (e.g. "left shoulder felt tight").
Originally scoped as workout + exercise; per-set landed earlier as part of
the set details bottom sheet, so this entry now covers what's still left.

**Current state:**

| Level | Data layer | Capture UI | Visible in history |
|---|---|---|---|
| **Per-set** | ✅ | ✅ (set details sheet) | ❌ captured but not rendered |
| **Per-workout** | ✅ (column, repo, controller, history reader) | ❌ no input UI | ✅ history detail renders if present |
| **Per-exercise** (per workout-exercise instance) | ❌ | ❌ | ❌ |

**Decisions made — design direction is locked, ready to implement:**

**1. Render per-set notes (and per-set RPE) in the history detail.**

The data is already captured but never displayed in history, which makes
the existing per-set feature a dead-end. On the history detail screen,
each set row should show:
- A small dot/indicator when a note exists.
- The note text either inline (small italic line under the set) or
  expanded on tap.
- The RPE number in a quiet color when set.

This is a small render-only change — no new data, no new capture UI.

**2. Workout-level notes input on the summary screen.**

The plumbing exists (column, repository methods, controller method,
history detail already renders it). The only missing piece is the input.

Add a "Notes" field to the workout summary screen, below the existing name
field and intensity slider. Multiline TextField, optional, debounced save
(same pattern the name field already uses). Hint text: "How did this
workout feel? Anything to remember?"

The summary screen is the natural reflection moment — it's where you've
just finished and you're already in "review" mode. This is the single
most important note level for most users.

Workout-level notes live ONLY on the summary screen. No entry point on the
active workout screen header — keep the active screen focused on logging.

**3. Per-exercise notes (per workout-exercise instance).**

This covers the "left shoulder felt tight on bench" use case — a note
attached to one specific exercise within one specific workout, NOT to
the global exercise definition.

Required:
- Add a `notes` column to the WorkoutExercises table (migration).
- Repository + controller methods to read/write.
- UI: a small "+ Note" affordance on each exercise card header in the
  active workout screen. Tap opens a small bottom sheet with a single
  TextField (or inline expand). Save on dismiss. When a note exists,
  show a small indicator on the card header so it stays discoverable.
- Render the note on the exercise block in the history detail (small
  italic line under the exercise name).

**User-facing flow once shipped:**

- During a workout, the user can drop a note at three levels:
  - **Set-level** — tap the set number (already exists via the set
    details bottom sheet).
  - **Exercise-level** — tap "+ Note" on the exercise card header.
  - **Workout-level** — write a note on the summary screen at the end.
- In history, all three levels render where they were written: workout
  note at the top of the detail, exercise note on the exercise block,
  set note on the set row.
- Tapping any existing note re-opens its input. Clear-to-delete supported.

The hierarchy mirrors the workout structure, so where the note lives
matches what it was about.

---

### Search and filter on history ✅

Today it's a flat reverse-chronological list. Users want "find every leg day"
or "find when I last benched 100 kg".

**Decisions made — design direction is locked, ready to implement:**

**v1 — ship first**

Search field and three filter chips, all living in the History hero.

*Search field*

- Promoted into the hero (collapses back to the title when empty).
- Free-text, live as you type with a small debounce.
- Matches workout names and exercise names inside the workout.
- Doesn't match raw numbers (weights, reps).

*Filter chips, in order*

1. **Exercise** — tap opens the existing exercise picker in multi-select.
   Multiple selections = workouts containing any of them. No AND/OR toggle —
   keep it simple.
2. **Date range** — presets: This week / This month / Last 3 months / This
   year / All time. Plus a "Custom range" option for arbitrary start/end.
3. **PRs only** — toggle. Reuses the PR data from the personal-records
   feature.

*Behavior*

- All active filters AND together, and AND with the search text.
- "3 filters active · Clear all" strip appears above the list whenever
  anything is on.
- Search and filters **persist** across navigation. Reset only via
  "Clear all."
- Sort stays newest-first.
- The week-strip calendar in the hero reflects active filters — dots only
  fill in for matching workouts, so the calendar doubles as a visual result
  map.
- Empty result state lists the active filters with a "Clear filters" button.
- An in-progress active workout stays pinned at the top regardless of
  filters.

**v2 — defer**

Three more chips, added once v1 is live and the underlying data exists:

- **Muscle group** — chest / back / legs / shoulders / arms / core, derived
  from the workout's exercises.
- **Has notes** — needs the per-workout notes feature to ship first.
- **Weight threshold** — "find when I benched ≥100 kg." Lives inside the
  Exercise chip's flow: after picking an exercise, optionally set a minimum
  weight.

**Out of scope (not v1, not v2):**

- Duration
- Per-workout intensity (RPE bucket)
- Templates (workout name search covers this informally)

**Sketch:**

```
┌────────────────────────────────────────┐
│ LOGBOOK                                │
│                                        │
│ ┌────────────────────────────────────┐ │
│ │ Search workouts                    │ │
│ └────────────────────────────────────┘ │
│                                        │
│  Exercise   Date   PRs                 │
│                                        │
│ Apr 8  Apr 15  Apr 22  Apr 29  May 6   │
│ ●○●○●○○ ○●○●○○● ●○○●○●○ ●○●○●○○ ○●○○○○○│
└────────────────────────────────────────┘

3 filters active · Clear all

[workout cards, narrowed to matches]
```

Active chips are filled teal; inactive are outlined pills. Tapping a
multi-value chip (Exercise, Date) opens a small bottom sheet for picking
values. Tapping a binary chip (PRs) just toggles it.

---

### Charts beyond bodyweight

We already have the data for estimated 1RM and weekly volume per muscle.
Surface it. A "show me my bench over the last 3 months" chart is the single
most-asked-for feature on every lifting app's subreddit.

**Scope:**

Build out the Progression tab beyond the current bodyweight + single
strength chart. The data exists — we have set logs, e1RM math (Epley),
muscle group classification, and timestamps. Just visualize it.

**Charts to add (in priority order):**

1. **Per-exercise strength chart** — line chart of estimated 1RM over time
   for any single weighted exercise. User picks the exercise from a small
   picker at the top of the chart card. Defaults to the most recently
   logged weighted exercise. Each point is one workout's best e1RM for
   that exercise.
2. **Weekly volume per muscle group** — stacked bar chart, one bar per week,
   stacks segmented by muscle group. Last 8–12 weeks. Tap a bar to see the
   underlying numbers.
3. **Total volume per week** — single line chart, last 12 weeks. Quick
   "am I doing more or less than I was?" glance.
4. **Workout frequency** — small bar at top of the page showing workouts
   per week for the last 8 weeks.

**Layout:**

Each chart is its own card on the Progression tab. Order: bodyweight
(exists), per-exercise strength, weekly volume per muscle, total volume,
frequency.

**Time range selector:**

Pills: 1M / 3M / 6M / 1Y / All. Default to 3M for most charts. Persists
per chart across sessions.

**Tech:**

Use the existing fl_chart package (already in pubspec). Use the existing
StrengthFormulas utility for e1RM. No new dependencies needed.

**Empty / sparse data states:**

- Fewer than 2 workouts containing that exercise → "Log a couple more
  sessions to see your trend." Don't render an empty chart.
- A muscle group with zero data this period → omit it from stacks instead
  of showing a 0-height segment.

**Open questions:**

- Per-exercise chart: should weight-on-best-set also be a togglable line
  alongside e1RM? Useful for users who don't trust the e1RM formula.
- Color: each muscle group needs its own subtle accent for the stacked
  bars. Derive from the existing palette.

---

### A real home dashboard

> I like this idea of making a better home page, but need to discuss some
> better ideas.

Right now Workouts is the home and the only personal data is an empty weekly
volume strip. After a month of training, the home should show streak, last
workout, this week's volume vs. last week's, next muscle group due. Make the
home screen earn its keep.

**Coordination note:**

This entry is the umbrella for "the home screen below the hero." The hero
itself is owned by the Hero header backlog item below — that's where
streak, greeting, smart suggestions, and the primary Start button live.
Don't duplicate work.

**What this entry covers — the body of the Workouts tab below the hero:**

1. **Last workout card** — first card below the hero. Shows: workout name,
   relative date ("Yesterday" / "3 days ago"), exercise count, set count,
   duration. Tap to jump to the workout detail. Hidden when there's no
   history.
2. **Muscle-group balance ring** — separate backlog item, lives here. The
   "weekly habit loop" visual.
3. **Weekly recap card** — separate backlog item, lives here. Renders for
   the 7 days following its weekly generation, then auto-replaces.
4. **This-month-at-a-glance row** — small horizontal strip of 3 KPI tiles:
   workouts this month, total volume this month, average intensity. The
   current home already has workouts + duration tiles — extend.
5. **Auto-deload nudge** — separate backlog item, surfaces here as a quiet
   dismissible banner when triggered.

**Empty state (zero data yet):**

Keep the current welcome-flavored layout — minimal stats, prominent Start
workout, prominent Start from template. The dashboard pattern only
"earns" itself once the user has data.

**Composition (top to bottom):**

1. Hero (data-driven, see Hero header item)
2. Muscle-group balance ring
3. Last workout card
4. Weekly recap card (Sunday → Saturday window)
5. This-month KPI row
6. Optional: auto-deload nudge banner (when triggered)

**Open question:**

- Reorderable or fixed? Fixed for v1 to keep complexity low. Consider
  user-customizable order in v2.

---

### "Auto-deload" nudge

We're already collecting RPE per session. After a few high-RPE weeks, suggest
a lighter week. This is the kind of thing only paid coaching apps do, and it
falls out naturally from data we already have.

**Trigger logic (start simple):**

Fire the nudge when ALL of these are true:
- The user has logged 4 or more workouts in the last 14 days.
- The rolling average per-workout RPE over the last 14 days is ≥ 8.5.
- The user has NOT been nudged in the last 7 days.
- The most recent week's average RPE is ≥ 8.0 (so we don't fire when
  they've already started easing up).

**Where it appears:**

A small dismissible card on the home screen, between the muscle-group ring
and the last-workout card. Quiet treatment — soft amber accent, info icon,
one paragraph of copy.

**Copy (default):**

> "You've been pushing hard. Average effort the last two weeks has been
>  high — consider a deload week: same exercises, same volume, drop the
>  weight by 30–40%. Your CNS will thank you."

**User actions on the card:**

- "Got it" — dismiss for 7 days.
- "Tell me more" — opens a small explainer sheet on what a deload is and
  why it helps. (Optional for v1.)

**Implementation notes:**

- Once per-set RPE is fully shipped, the math should average per-set RPE
  rather than per-workout RPE — finer signal. Until then, per-workout RPE
  is fine.
- Persist last-nudged timestamp in app settings so the 7-day cooldown
  survives app restarts.
- Don't show during an active workout — check only on app open and on
  workout completion.

**Out of scope for v1:**

- Auto-generating an actual deload program.
- Push notifications outside the app.
- Adjusting the suggestion text per user volume / experience level.

---

### Muscle-group balance ring

> Good solution to add to the home page.
> we already have something like this, the weekly muscle group (weekly_volume_strip_bar.dart). But we can maybe look at adding this to the progression page

A simple visual on the home that fills in as you hit each muscle group's
weekly set goal — like Apple's activity rings, but for legs/back/chest/etc.
Turns existing weekly target data into a glanceable habit loop.

**What we already have:**

The weekly volume strip bar already shows sets-this-week vs. weekly-goal
per muscle group. Data layer is done. The strip works but is text-heavy
and easy to skim past.

**What this adds:**

A more visually engaging treatment of the same data. Two placement
options to consider — could ship one or both.

**Placement A — home screen (compact ring stack):**

A compact card on the home, below the hero. Shows 6–8 small concentric
rings (one per muscle group) inside a single tile. Each ring fills as the
user hits its weekly set goal. Apple Activity Rings analog but with more
than 3 rings.

- Fully closed ring → solid teal.
- Partial → arc fills proportionally.
- Zero progress → outline only, faded.

Tap the card to expand to the full per-muscle-group breakdown (could
deep-link to the existing strip view, or open a bottom sheet).

**Placement B — progression page (large detailed ring set):**

A larger version, with each muscle group as its own ring side-by-side,
labeled with the actual set count vs goal underneath. Lives at the top
of the Progression tab.

**Recommendation:**

Ship Placement A first (home screen, compact). It's the habit-loop value
the original idea was about. Add Placement B later as a nice-to-have on
the progression page.

**Visual:**

- Use the existing teal palette. Different muscle groups can share the
  same teal but vary in shade subtly.
- Match Apple Rings geometry (concentric, animated stroke fill on update).
- Animation: gentle ease as the ring fills on load. No bouncy motion —
  match the brand's calm tone.

**Open question:**

- Should the ring reset visually each Sunday (week boundary), or animate
  from "100% of last week" down to "0% of this week"? Recommend snap-reset
  on Sunday with no animation — clearer mental model.

---

### Quick-log mode for cardio

A single-screen logger for "I went on a 5 km run, 28 min" without going
through the full active-workout flow. Right now logging cardio takes the same
number of taps as a full lifting session.

**Entry points:**

- Drawer: "Quick log cardio" tile.
- Workouts hero: small secondary action (alongside the Start workout
  button, if room).

**The flow (one screen, one save):**

A bottom sheet (or full-screen modal) with:
- **Exercise picker** — defaults to the most recently logged cardio
  exercise. Tap to change.
- **Distance** — km, numeric, optional (some cardio is duration-only).
- **Duration** — mm:ss, numeric.
- **Date** — defaults to "now". Tap to pick a different time/date for
  retroactive logging.
- **Note** — optional single-line text.
- **Save** button at the bottom.

**On save:**

Creates a one-exercise, one-set workout under the hood that lands in
history like any other workout. Same data model, no new entity. Bypasses
the active-workout screen and the summary screen entirely. Fires a brief
snackbar confirming, then dismisses to wherever the user came from.

**Visual treatment:**

Same hero-style header (eyebrow "QUICK LOG", title "Cardio"). Body is
just the form.

**Out of scope for v1:**

- Quick-log for weighted exercises (separate use case — tougher because
  set counts vary).
- GPS tracking, route maps, etc. The user logs what they did; the app
  doesn't try to measure during the run.
- Heart rate, calories.

**Open question:**

- Should the same flow also work for bodyweight exercises ("100 push-ups
  spread across 5 sets")? Recommend defer — different shape of data
  (multiple sets) doesn't fit the one-screen model as cleanly.

---

### Weekly recap card

Every Sunday, generate a one-screen summary ("3 workouts, 9.2 t volume,
1 PR on deadlift, intensity avg 7.4"). Shareable. Even if we never ship
social, this is the kind of thing people screenshot and post themselves.

**Generation cadence:**

A new recap is generated automatically once per week (Sunday end-of-day).
The most recent recap is displayed on the home for the next 7 days, then
the new one replaces it.

**What the recap contains:**

- Header line: "Week of May 5 – May 11"
- Workouts logged: 3
- Total volume: 9.2 t (in user's preferred unit)
- Total time: 3h 14m
- PRs set: list each one (e.g. "Deadlift 142.5 × 3")
- Average intensity: 7.4 RPE
- Small line chart: daily volume across the 7 days (or daily set count).
- Compared to last week: "↑ 12% volume" or "↓ 1 workout"

**Where it lives:**

- Home screen: as a card below the muscle-group ring.
- History: archived recaps reachable via a "Recaps" filter chip on the
  history screen filter row (added once history filtering ships).

**Sharing:**

A "Share" button on the card generates a portrait-format PNG of the recap
(designed to look good as an Instagram story / iMessage attachment). Hands
off to the system share sheet.

**Visual treatment:**

Same dark teal hero block style as the rest of the app, full-bleed image
when shared, with a small app branding watermark in a corner. Match the
"calm, branded, not gamified" tone — no explosive numbers, no
trophy-spam. Just the data, well laid out.

**Empty week:**

If the user logged zero workouts that week, don't generate a recap. Don't
show a "rest week" card either — keep the home tidy.

**Implementation notes:**

- Generation runs on app open: if today is past Sunday and the last recap
  is older than 7 days, generate the new one.
- Past recaps are persisted in their own table so they can be reviewed
  later (and so the data they captured isn't recomputed and possibly
  changed by later edits).

**Open questions:**

- Include the user's name in the shared image, or keep anonymous?
  Recommend opt-in toggle, default off.
- Show a one-line motivational message ("Strong week.")? Recommend no —
  keep tone factual.

---

## Things to work on

### Shrink the hero header once there's data

The hero header takes ~25% of the viewport on every screen and does nothing
functional after the first visit. Shrink it once the user has data — show
streak, last workout, or weekly progress in that space instead.

**Decision: data-driven hero per tab (Hevy/Strava-style).** The dark teal
block stays on every screen (it's the brand), but its *contents* change
based on which tab you're on and what data the user has earned.

This entry overlaps heavily with "A real home dashboard" above — implementing
the Workouts hero below also delivers most of that backlog item. Treat them
as one body of work.

**Cross-tab rules:**

- Empty state still uses the current hero (eyebrow + title + welcome
  subtitle). The data-driven hero only kicks in once the user has earned
  the relevant data. The welcome moment isn't lost — it gracefully retires.
- Eyebrow stays on every tab (small caps label like "TODAY", "LOGBOOK").
  Cheap brand anchor, cheap orientation cue.
- Hero height is flexible per tab, not fixed. Workouts ~200pt, Exercises
  ~110pt is fine.

---

#### Tab 1 — Workouts hero (the home — highest priority)

**Job:** convince the user to start a workout right now, and remind them
they've been doing well.

**Components, in priority order:**

1. **Time-aware greeting eyebrow.** "Morning, Seth" / "Afternoon, Seth" /
   "Evening, Seth" — uses the name from profile. Falls back to "Today" if
   no name set.
2. **Punchline.** One headline-sized line that's the most relevant thing to
   know right now. Three modes, picked by context:
   - Streak headline — "12-day streak. Don't drop it."
   - Smart suggestion — "Last legs day was Tuesday. Ready for legs?" (when
     a muscle group hasn't been hit recently).
   - Comeback prompt — "First workout back. Ease in." (when away >7 days).
3. **Live data sub-line.** Smaller text under the punchline. Examples:
   - "↑ 18% volume vs last week"
   - "3 of 4 weekly target hit"
   - "12.4 t lifted this month"
   Only appears when there's enough history (~2 weeks) to compute it.
4. **Primary CTA inside the hero.** Pill button "Start workout", near
   full-width. Biggest behavioral change: the start button moves *into*
   the hero so the most-used action is the most prominent thing on screen.
5. **Secondary action.** Small, right-aligned text link "Pick template" or
   small icon button. Quiet on purpose so it doesn't compete.

**Sketch:**
```
┌────────────────────────────────────────┐
│ MORNING, SETH                          │
│                                        │
│ 12-day streak. Don't drop it.         │
│ ↑ 18% volume vs last week              │
│                                        │
│ ┌──────────────────┐  Pick template    │
│ │  ⚡ Start workout │                   │
│ └──────────────────┘                   │
└────────────────────────────────────────┘
```

The muscle-group balance ring (separate backlog item) lives *below* the
hero, not inside it. Hero answers "what should I do right now"; the ring
answers "how am I doing this week, in detail." Different time horizons.

---

#### Tab 2 — History hero

**Job:** orient the user in time and let them jump fast to any week.

**Components:**

1. Eyebrow — "LOGBOOK".
2. Title row — current month name on the left ("May"), small streak counter
   on the right ("12 days"). Streak number is the same source of truth as
   the Workouts tab.
3. **Week-strip calendar.** Horizontal strip showing the last 8 weeks as
   columns. Each week is 7 small dots (one per day). Days with a workout
   are filled in teal; rest days are quiet/empty. Today highlighted with
   a ring. Strip is horizontally scrollable — swipe right to walk back
   through history.
4. **Tap behavior** — tapping a week jumps the list below to that week's
   workouts. Tapping a single day filters to that day. Optional but nice.

**Sketch:**
```
┌────────────────────────────────────────┐
│ LOGBOOK                                │
│                                        │
│ May                          12 days   │
│                                        │
│ Apr 8  Apr 15  Apr 22  Apr 29  May 6   │
│ ●○●○●○○ ○●○●○○● ●○○●○●○ ●○●○●○○ ○●○○○○○│
└────────────────────────────────────────┘
```

Turns the History tab from a read-only journal into a navigable timeline.

---

#### Tab 3 — Templates hero

**Job:** start a workout from a template in one tap, without scrolling the
list.

**Components:**

1. Eyebrow — "ROUTINES".
2. Title — drop the static "Templates" title or shrink it; replace with
   something dynamic like "Pick up where you left off".
3. **Quick-start carousel.** Horizontal row of 2–3 most-recently-used
   template chips. Each chip shows: template name, exercise count,
   last-used relative date ("Used 2 days ago"). Tap = start a workout
   from that template *immediately*, no intermediate confirmation.
4. **+ New affordance** — small inline shortcut to create a new template,
   mirrors the existing FAB. Slightly redundant but improves discoverability.

**Sketch:**
```
┌────────────────────────────────────────┐
│ ROUTINES                               │
│                                        │
│ Pick up where you left off             │
│                                        │
│ ┌────────┐ ┌────────┐ ┌────────┐  + New│
│ │  Push  │ │  Pull  │ │  Legs  │       │
│ │ 6 ex.  │ │ 5 ex.  │ │ 7 ex.  │       │
│ │ 2 days │ │ 4 days │ │ 6 days │       │
│ └────────┘ └────────┘ └────────┘       │
└────────────────────────────────────────┘
```

The full template list still lives below — the hero just removes friction
for the 80% case.

---

#### Tab 4 — Exercises hero

**Job:** get to the right exercise fast. The screen is fundamentally about
searching/picking.

**Components:**

1. Eyebrow — "LIBRARY".
2. Title — small "Exercises" heading or drop entirely.
3. **Search field promoted into the hero.** Currently lives below the hero;
   move it inside so the user can start typing the moment the screen loads.
4. **Recent / favorites row.** Small horizontal strip of 4–6 letter-avatar
   chips showing the exercises the user has logged or edited most recently.
   Tap one to jump straight to its history sheet (or to add it to today's
   workout if there's an active workout).

**Sketch:**
```
┌────────────────────────────────────────┐
│ LIBRARY                                │
│                                        │
│ ┌────────────────────────────────────┐ │
│ │ 🔍 Search exercises                │ │
│ └────────────────────────────────────┘ │
│                                        │
│ RECENT                                 │
│  B   D   B   S   I   →                 │
└────────────────────────────────────────┘
```

Simplest hero of the four because the screen's purpose is already focused.

---

#### Implementation order (highest leverage first)

1. **Workouts hero** — biggest perceived-quality win for the entire app.
2. **History hero** — week strip is genuinely novel and people love calendars.
3. **Templates hero** — quick-start chips are useful but lower-frequency.
4. **Exercises hero** — smallest delta from current. Easy to defer.

Each is shippable independently. Each teaches you something about the
pattern before committing to the next.

---

#### Data signals each hero depends on

Calling these out so they're not surprises during implementation. Most
fall out of data the app already collects.

- **Streak** — definition first (daily? weekly? rolling?), then a cached
  value. Shared between Workouts and History heroes.
- **This week's volume vs. last week's** — already partially supported by
  the weekly volume strip.
- **Muscle group last hit** — needed for the smart suggestion
  ("Ready for legs?").
- **Template usage tracking** — count + last-used timestamp per template.
- **Recent exercises** — last N exercises the user logged or edited.

---

#### If only one ships

Just the **Workouts hero**. Replace the static "Stronger than last time."
with the streak headline + sub-line + Start button. Leave the other three
tabs alone. That single change moves perceived value of the app more than
the other three combined.

---

### Quick start vs. Start from template hierarchy

The two buttons on the home are styled almost identically (same height, same
radius, same prominence). One is the primary action, one is secondary — they
should look like it.

**Coordination note:**

This is largely obsoleted by the Workouts hero work — once the hero ships,
the primary "Start workout" button moves INTO the hero, and "Pick template"
becomes a small secondary action right next to it. So the home no longer
has the dueling-buttons problem at all.

**If shipped before the hero (standalone polish):**

- Quick start: keep the current filled dark teal pill button, but make it
  slightly larger and more visually dominant.
- Start from template: convert from same-size outlined button to a smaller,
  quieter text link or outline-only button below it. Roughly half the
  visual weight.

**If shipped alongside the hero:**

Apply the hero spec directly — primary CTA inside the hero, secondary
"Pick template" as a quiet text link to the right. No work needed in the
old location because the buttons move.

---

### Label the intensity slider

The RPE 1–10 slider on the workout summary is decent, but the number alone is
unintuitive for newer lifters. A short label under each value (1 = "Felt
easy", 10 = "Couldn't do another rep") would help adoption without breaking
the no-emojis rule.

**Behavior:**

Below the slider's current value, show a short live-updating label that
describes what the chosen RPE means. Updates as the user drags.

**Suggested copy (standard reps-in-reserve scale, adapted):**

| RPE | Label |
|---|---|
| 1 | Felt easy |
| 2 | Very light |
| 3 | Light |
| 4 | Moderate |
| 5 | Somewhat hard |
| 6 | Hard |
| 7 | Very hard — 3 reps left |
| 8 | Very hard — 2 reps left |
| 9 | Maximal — 1 rep left |
| 10 | All out — couldn't do another |

**Visual:**

- Label sits directly under the slider, smaller secondary text color.
- One line max, ~30 chars, fades cleanly between values.
- Don't add icons or emojis — keep typography-only per brand brief.

**Out of scope:**

- Tooltips on hover (not a touch pattern).
- Half-point increments.
- Showing the table somewhere as a reference legend.

**Open question:**

- Should the label also appear inline on the workout summary list (not
  just on the input)? Recommend not in v1 — keeps the summary clean.

---

### Dark mode

Light-mode-default is fine, but a dark mode for late-night gym sessions is a
small lift and a big perceived-quality win.

**Settings:**

Add a theme picker in Settings:
- Light (default)
- Dark
- Match system

System mode follows the OS / browser preference and switches live when
the preference changes (Material 3 supports this for free).

**Dark theme tuning:**

- Page background: dark navy / charcoal — should complement the existing
  teal, not fight it. Avoid pure black.
- Hero block (currently dark teal): keep as-is — it already works on
  either background, so it stays the same in both themes.
- Card surfaces: slightly lighter than page background, no hard borders.
- Primary text: off-white (not pure white).
- Secondary text: muted slate.
- Accent / interactive: keep the existing teal palette — verify contrast
  passes on dark.

**Things to check screen-by-screen:**

- Active workout — the set row uses a lot of subtle backgrounds; verify
  warm-up amber, drop purple, and failure red still read well.
- History detail — text-heavy, prone to contrast issues.
- Empty-state illustrations — currently designed for light backgrounds,
  may need a dark variant or a tint adjustment.
- Charts (fl_chart) — line / bar colors and axis labels need a dark variant.
- Letter avatars — verify the teal background still reads with white
  letters on a dark card.

**PWA:**

- Manifest theme_color stays the brand teal (#289CB2) — the app icon and
  install chrome should always look "Fitness App teal" regardless of the
  user's theme.
- The status bar / browser chrome adapts based on the active theme via
  meta theme-color — switch live with the theme.

**Out of scope for v1:**

- Per-screen theme overrides.
- AMOLED-black mode (use a soft dark, not pure black).
- High-contrast accessibility mode (separate concern).

**Open question:**

- Should the theme toggle live in Settings only, or also as a quick-access
  toggle in the drawer (next to the existing units toggle)? Recommend
  drawer toggle for fast switching.
