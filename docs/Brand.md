# Brand

The visual system for the workout app. Everything UI-related references this doc. If a screen looks wrong, this is the source of truth — not the screen.

---

## Style

**M3 Minimalism.** Material 3 defaults, light mode primary, used with restraint.

- Teal as accent only. Not every button, not every label — just the ones that matter (primary action, active state, progress).
- Neutrals do most of the work. Surfaces, text, dividers, borders.
- M3 elevation is subtle — let it be subtle. No custom shadows.
- Rounded corners from M3 defaults (cards ~12px, buttons ~20px). Don't override without reason.
- No gradients. No decorative icons. No illustrations. No mascots.
- Whitespace is a feature. Let things breathe.

The vibe: a serious, clean instrument. Not a game, not a party.

---

## Color — Jelly Bean Palette

Your brand color ramp. `500` is the M3 seed. Other shades are for custom surfaces, charts, and cases where M3's generated scheme doesn't give you what you need.

```
50:  #EFFBFC   ← lightest tint, barely-there backgrounds
100: #D7F3F6
200: #B3E7EE
300: #7FD4E1
400: #44B8CC
500: #289CB2   ← seed / primary brand color
600: #26849D
700: #24667A
800: #255565
900: #234756
950: #122E3A   ← darkest, near-black teal for dark-mode surfaces
```

Use the ramp when you need a specific teal shade (e.g. chart series, subtle accent surfaces). For everything else, let M3's `ColorScheme.fromSeed` generate its own tonal palette and use those roles (`primary`, `onPrimary`, `surface`, etc.).

---

## Theme configuration

### Default mode
**Dark.** Gym lighting is inconsistent, phone is often in low-light, OLED saves battery. Users can still toggle via system settings — M3 honors `ThemeMode.system` — but the app's identity is dark.

### Seed
`#289CB2` (jelly-bean 500).

### Flutter setup

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const seedColor = Color(0xFF289CB2);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final textTheme = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
```

Wire it in `app.dart`:

```dart
MaterialApp.router(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: ThemeMode.dark, // default dark for v1
  routerConfig: router,
);
```

---

## Typography

**Inter** via `google_fonts`. That's it. One typeface, full range of weights.

Use M3's text theme roles — don't hand-pick font sizes per widget:

| Role | Used for |
|---|---|
| `displayLarge` / `displayMedium` | Rare. Onboarding, maybe empty states. |
| `headlineSmall` | Screen titles, section headers. |
| `titleMedium` | Card titles, exercise names in lists. |
| `titleSmall` | Subheaders inside cards. |
| `bodyLarge` | Main body copy. |
| `bodyMedium` | Secondary text, descriptions. |
| `bodySmall` | Timestamps, captions, helper text. |
| `labelLarge` | Button labels. |
| `labelMedium` / `labelSmall` | Chips, badges, tab labels. |

For **numbers** in the set-logging table (weight, reps, distance, time), use Inter with `fontFeatures: [FontFeature.tabularFigures()]` so columns of numbers line up.

```dart
Text(
  '65',
  style: Theme.of(context).textTheme.titleMedium?.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  ),
)
```

No monospace font. Inter's tabular figures are enough and keep the look consistent.

---

## Color usage rules

**Primary (`scheme.primary`, derived from teal)**
- Primary action button on a screen (one per screen, not five).
- Active state on bottom nav.
- Completed set ✅ indicator.
- Focused input underline.

**On-surface variants (`onSurface`, `onSurfaceVariant`)**
- All body text. `onSurface` for important, `onSurfaceVariant` for secondary.

**Surface variants (`surface`, `surfaceContainerLow`, `surfaceContainerHigh`)**
- `surface` — scaffold background.
- `surfaceContainerLow` — cards, list tiles.
- `surfaceContainerHigh` — elevated elements (active workout row, bottom sheets).

**Error (`error`)**
- Destructive buttons (Cancel Workout, Delete Exercise).
- Validation errors on input fields.

**Outline / outlineVariant**
- Dividers. Subtle borders if you need them. Keep at 1px.

### Don't
- Don't use jelly-bean `500` directly for text or backgrounds — use `scheme.primary` (M3 adjusts it for contrast per mode).
- Don't color entire cards teal. Teal is a 5–10% accent, not a wallpaper.
- Don't invent greens, oranges, or "success" colors. M3 has `tertiary` and `error` for a reason.
- Don't use opacity to imply disabled — use `scheme.onSurface.withOpacity(0.38)` which M3 already specifies.

---

## Letter-avatar (exercise fallback thumbnail)

When an exercise has no uploaded image:

- Circle, 40px diameter in lists, 56px in detail views.
- Background: a color picked deterministically from the exercise name (hash the string, map to a fixed set of muted palette options derived from the jelly-bean ramp — e.g. `300`, `500`, `700`, `800`, `900`).
- Letter: first character of the exercise name, uppercase. White or `onPrimary` color depending on background brightness.
- Font: Inter, weight 600, size ~18–22 depending on circle size.

Stable mapping — the same exercise name always produces the same color.

---

## Spacing & sizing

4px grid. Use these values and only these values:

```
4, 8, 12, 16, 20, 24, 32, 40, 48
```

Common patterns:
- Screen horizontal padding: `16`.
- Between sibling cards in a list: `8`.
- Inside a card: `16`.
- Between major sections: `24` or `32`.
- Minimum tap target: `48×48`.

---

## Motion

Use M3 defaults. Don't write custom animation curves.

- Navigation: `go_router` default transitions.
- State changes (checking a set, expanding a section): `AnimatedContainer` / `AnimatedSwitcher` with `duration: 200ms`, default curve.
- Don't animate for decoration. Animation communicates state change; if nothing changed, don't animate.

---

## Icons

Material Symbols via `flutter`'s built-in `Icons`. Outlined weight, not filled — M3 default. Don't mix icon families.

---

## Dark / light parity

Everything must look correct in both modes. When building a screen, toggle between light and dark before merging. If it only looks good in one, it's not done.

---

## Examples of applying this

**A workout card in the history list:**
- `surfaceContainerLow` background
- Title: exercise count + date, `titleMedium`, `onSurface`
- Subtitle: duration + volume, `bodyMedium`, `onSurfaceVariant`
- No border, no shadow, 12px rounded corners
- Tap feedback: M3 default ripple in `primary` at low opacity

**The primary "Start Empty Workout" button:**
- `FilledButton`, full-width, 48px tall
- Background: `primary` (teal)
- Label: `labelLarge`, `onPrimary`
- Icon on the left, text on the right, 8px gap

**An active set row:**
- Horizontal layout, 48px minimum height
- Text fields inline, `bodyLarge`, tabular figures
- ✅ checkbox on the right; when tapped, row background becomes `primary.withOpacity(0.08)` and text goes `onSurfaceVariant`

---

## When in doubt

Look at the Material 3 showcase (m3.material.io) or how Google's own apps handle it (Calendar, Tasks, Clock). Match that level of restraint. If something you're adding would feel out of place in Google Clock, it probably shouldn't be in this app either.