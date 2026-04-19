# Fitness App - Execution Plan

Current product target: **ship a usable web-first PWA today**.

This plan is now centered on browser use first. Native store release is deferred.

---

## Phase 0 - Locked decisions

- [x] Flutter + Material 3
- [x] Inter via `google_fonts`
- [x] Riverpod + `go_router`
- [x] UUID ids
- [x] kg / km only
- [x] exercise types: `weighted`, `bodyweight`, `cardio`
- [x] jelly-bean seed color `#289CB2`
- [x] light mode default
- [x] one-user local-first product direction

---

## Phase W1 - Web-first runtime conversion

Goal: make the app run as a browser-based PWA with local browser persistence.

**Codex backend**
- [x] Remove native-only runtime APIs from app code
- [x] Replace native DB bootstrap with browser-safe local persistence
- [x] Add the required web database assets/config
- [x] Confirm `flutter build web` works
- [ ] Confirm `flutter run -d chrome` works in a live browser session
- [ ] Confirm seeded data persists after refresh in manual browser testing

**Claude frontend**
- [ ] Review current web shell in browser and flag any frontend blockers caused by the runtime conversion

**Order**
- Run Codex first for this phase.
- Claude can review and refine UI only after the web runtime is stable enough to load in the browser.

---

## Phase W2 - PWA usability on iPhone

Goal: make the web build usable from Safari home screen.

**Codex backend**
- [ ] Deploy behind HTTPS
- [ ] Confirm data persists after relaunch

**Claude frontend**
- [x] Validate manifest, icons, title, theme color
- [ ] Test Safari open -> Add to Home Screen -> launch
- [ ] Fix any layout issues specific to iPhone Safari

**Order**
- These can run mostly in parallel.
- Codex should handle hosting/deployment and persistence checks.
- Claude should handle install flow validation and Safari layout fixes once a live HTTPS URL exists.

---

## Phase W3 - Exercise management for web

Goal: working exercise CRUD in the browser.

**Codex backend**
- [x] Keep thumbnails deferred for now
- [x] Support exercise CRUD through repositories/controllers

**Claude frontend**
- [x] Exercise list screen
- [x] Search/filter
- [x] Create/edit form
- [x] Delete with confirm
- [x] Letter-avatar fallback

**Order**
- These can run in parallel.
- If there is a dependency conflict, default to Codex and let Claude wire UI after the backend surface is stable.

---

## Phase W4 - Workout logging core loop

Goal: the app becomes practically useful for real workouts.

**Codex backend**
- [x] Start empty workout
- [x] Add exercises to workout
- [x] Add sets
- [x] Support weighted/bodyweight/cardio set entry
- [x] Persist every change immediately
- [x] Finish and cancel workout flows
- [x] Expose `activeWorkoutDetailProvider` for reading the active workout state
- [x] Expose `workoutExerciseOptionsProvider` for the add-exercise flow
- [x] Expose `workoutSessionControllerProvider` for workout mutations

**Claude frontend**
- [ ] Active workout screen
- [ ] Add-exercise UI flow
- [ ] Set-entry UI for weighted/bodyweight/cardio rows
- [ ] Finish/cancel dialogs
- [ ] Summary after finish

**Order**
- Codex backend for W4 is now in place.
- Claude should work next against the new workout providers/controllers instead of touching Drift directly.
- Further W4 backend work should only happen if Claude hits a missing contract.

---

## Phase W5 - History and templates

**Codex backend**
- [ ] Workout history queries
- [ ] Workout detail data assembly
- [ ] Template create/edit/delete logic
- [ ] Start workout from template

**Claude frontend**
- [ ] Workout history list
- [ ] Workout detail view
- [ ] Template list/create/edit screens

**Order**
- Start with Codex for history/template data contracts.
- Claude can begin layout work in parallel if the screen structure is obvious, but real integration should follow Codex.
- If split is unclear, default to Codex.

---

## Deferred until later

- Native Android/iOS support
- App Store / Play Store release
- Supabase sync
- Authentication
- Exercise thumbnails
- Graphs/polish/export

---

## Working rules

1. Web-first decisions win over native assumptions.
2. Simplicity wins over architecture polish.
3. Ship a working one-user model before adding extra features.
4. Keep docs aligned with the web-first goal.
5. Claude owns frontend/UI tasks by default.
6. Codex owns backend/runtime/storage/tasks by default.
7. When a task is hard to split cleanly, default ownership to Codex.
