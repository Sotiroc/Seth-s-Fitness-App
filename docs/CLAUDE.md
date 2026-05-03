# Frontend Context for Claude

This file is the frontend-specific brief.

## How to talk to me (read this first)

This is a **vibe-coded project**. I am not reading the code, the files, or the diffs. I direct from intent — you handle everything below the surface.

When you give me a plan, a status update, or a summary, include:

- **Your understanding of what I'm asking for** — restate it back so I can catch misunderstandings early.
- **The goal** — what we're actually trying to achieve and why it matters.
- **The approach at a high level** — the shape of the solution in plain language. Think product conversation, not engineering ticket.

Do **not** include:

- File names, paths, or directory references
- Function, class, or variable names
- Code snippets or pseudocode
- Step-by-step technical edits ("modify X to call Y")
- Library/framework jargon used as a stand-in for a plain explanation

One exception: if I explicitly ask for technical detail (e.g. "show me the code", "what file?", "explain how it works under the hood"), then go ahead and give it. Otherwise, default to plain English and high-level only.

This rule applies to **all** communication with me — plan mode, regular replies, end-of-turn summaries, everything.

## Primary goal

Ship a **working web-first PWA by the end of today**.

The app should:
- run in the browser
- work on iPhone via Safari "Add to Home Screen"
- persist data locally in the browser

Do **not** optimize for native mobile/store release right now.

## Frontend assumptions you must follow

- Runtime is **browser / PWA**
- Persistence is **local browser storage**
- Native filesystem behavior is **not available**
- Exercise thumbnails are **deferred**
- Letter avatars are the default visual treatment for exercises
- Speed and simplicity matter more than complete polish

## Do not assume

- `dart:io`
- device file paths
- app-documents storage
- native image picker flows
- iOS/Android-specific UI behavior

## UI priorities

- clean exercise list and forms
- empty/loading/error states
- touch-friendly layout on iPhone Safari
- PWA-friendly layout and spacing
- fast, simple flows for one user

## Coordination note

- Claude owns frontend/UI implementation
- Codex owns data/runtime/storage/backend logic unless explicitly reassigned

Build the frontend against the current web-first runtime, not against future native ambitions.
