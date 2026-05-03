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

### Personal records

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

---

### Notes per workout and per exercise

Free-text notes at both levels (e.g. "left shoulder felt tight"). We already
have workout name + intensity — one more field is small effort, big payoff.

---

### Search and filter on history

Today it's a flat reverse-chronological list. Users want "find every leg day"
or "find when I last benched 100 kg".

---

### Charts beyond bodyweight

We already have the data for estimated 1RM and weekly volume per muscle.
Surface it. A "show me my bench over the last 3 months" chart is the single
most-asked-for feature on every lifting app's subreddit.

---

### A real home dashboard

> I like this idea of making a better home page, but need to discuss some
> better ideas.

Right now Workouts is the home and the only personal data is an empty weekly
volume strip. After a month of training, the home should show streak, last
workout, this week's volume vs. last week's, next muscle group due. Make the
home screen earn its keep.

---

### "Auto-deload" nudge

We're already collecting RPE per session. After a few high-RPE weeks, suggest
a lighter week. This is the kind of thing only paid coaching apps do, and it
falls out naturally from data we already have.

---

### Muscle-group balance ring

> Good solution to add to the home page.
> we already have something like this, the weekly muscle group (weekly_volume_strip_bar.dart). But we can maybe look at adding this to the progression page

A simple visual on the home that fills in as you hit each muscle group's
weekly set goal — like Apple's activity rings, but for legs/back/chest/etc.
Turns existing weekly target data into a glanceable habit loop.

---

### Quick-log mode for cardio

A single-screen logger for "I went on a 5 km run, 28 min" without going
through the full active-workout flow. Right now logging cardio takes the same
number of taps as a full lifting session.

---

### Weekly recap card

Every Sunday, generate a one-screen summary ("3 workouts, 9.2 t volume,
1 PR on deadlift, intensity avg 7.4"). Shareable. Even if we never ship
social, this is the kind of thing people screenshot and post themselves.

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

---

### Label the intensity slider

The RPE 1–10 slider on the workout summary is decent, but the number alone is
unintuitive for newer lifters. A short label under each value (1 = "Felt
easy", 10 = "Couldn't do another rep") would help adoption without breaking
the no-emojis rule.

---

### Dark mode

Light-mode-default is fine, but a dark mode for late-night gym sessions is a
small lift and a big perceived-quality win.
