# Frontend Context for Claude

This file is the frontend-specific brief.

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
