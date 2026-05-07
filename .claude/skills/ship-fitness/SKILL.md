---
name: ship-fitness
description: Commit, push to main, and deploy the Fitness App to production on Vercel. Use when the user wants to "ship", "deploy", "push to prod", "release", or otherwise publish changes from this repo. Bundles git commit + push origin main + the deploy-web-vercel.ps1 script into one flow. Project-scoped — only loads in C:\Dev\FitnessApp.
---

# Ship the Fitness App

End-to-end flow for committing local changes, pushing them to `main`, and deploying the web build to production on Vercel.

## When to invoke

Trigger when the user says any of:
- "ship", "ship it", "ship the app"
- "deploy", "push to prod", "release", "go live"
- "run the deploy script" (in this repo's context)

Do NOT trigger for a plain `git commit` or `git push` with no deploy intent — those don't need this skill.

## Preconditions

- CWD is the FitnessApp repo root (the one containing `deploy-web-vercel.ps1` and `pubspec.yaml`).
- `flutter` and `vercel` are on PATH (the deploy script asserts this).
- Current branch is `main`. This skill ships **direct-to-main**; PR review is intentionally bypassed for this single-developer repo.

## Steps

### 1. Inspect the working tree
- `git status` and `git diff --stat` to see what's about to be shipped.
- If multiple unrelated changes are dirty, surface them to the user and ask which belong in this ship — never `git add -A` blindly.

### 2. Run guardrails
Before committing run, in parallel:
- `flutter analyze lib` — must finish with **No issues found**.
- `flutter test` — must finish with **All tests passed!**.

If either fails, stop and report. Do not commit a broken main.

### 3. Stage + commit
- `git add` only the files the user agreed on.
- Draft a commit message from the actual diff: short imperative subject, blank line, body explaining the *why* (the diff already shows the what). Match repo style — `git log --oneline` shows the existing tone (short titles like "Major Push", "Image Uploads"; longer descriptive subjects are also fine).
- Always use a HEREDOC for the message body and include the trailer:
  ```
  Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
  ```
- Never `--amend`; always create a new commit.

### 4. Push to main — REQUIRES EXPLICIT CONFIRMATION
Pushing to `main` triggers production. Even in auto mode, **confirm with the user** before running `git push origin main`. Show them the commit SHA + subject and ask: *"push directly to main?"*. The harness may block the first attempt with a "default-branch push" warning; if it does, ask the user to confirm explicitly ("yes, push to main") and retry **once**.

### 5. Run the deploy script
From the repo root, run:

```
powershell -ExecutionPolicy Bypass -File .\deploy-web-vercel.ps1
```

The script:
1. `flutter build web --release` → `build/web`
2. Writes a SPA-rewrite `vercel.json` into the build output.
3. `vercel link --yes --project seth-fitness-app --scope sethsotiralis-gmailcoms-projects`
4. `vercel deploy --prod --yes`

Use a **10-minute** Bash/PowerShell timeout — the Flutter build alone is ~70–90s, plus another ~15s for upload + deploy.

### 6. Verify
In the JSON the script prints, look for:
- `"readyState": "READY"`
- `"target": "production"`
- An `Aliased: https://seth-fitness-app.vercel.app` line above it.

Report the production URL back to the user. Done.

## Failure modes & remedies

- **Push blocked with "default-branch" message** → confirm with user, retry once. If still blocked, the user's settings may need a Bash permission rule.
- **`flutter` or `vercel` not on PATH** → script fails fast with `Required command 'X' was not found`. Tell the user to install / add to PATH; do not try to work around it.
- **Vercel build fails** → script throws and exits non-zero. Read the deploy URL's `Inspect:` link from the output — that's the build log on Vercel.
- **Live site boots with a SQLite "duplicate column" or "table already exists" error post-deploy** → schema migration regression. Check `lib/data/db/app_database.dart`'s `onUpgrade` is still using the `addColumnIfMissing` / `createTableIfMissing` guards. The site uses Drift over IndexedDB; users with stale browser DBs are the canaries.

## Out of scope

- The phone PWA — it picks up the new code on its own reload, but its IndexedDB is a separate store from the desktop browser's. This skill does not push to mobile stores.
- Preview deploys / non-prod aliases. Add a `--preview` switch later if needed.
