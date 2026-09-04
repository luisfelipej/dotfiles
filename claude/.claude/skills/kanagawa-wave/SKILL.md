---
name: kanagawa-wave
description: Kanagawa Wave dark palette and type pairing for standalone visuals viewed on a screen — demo pages, internal dashboards, explainers, throwaway HTML, React artifacts, diagrams. Use this whenever building a self-contained visual or UI that has no design system of its own, even if the user doesn't mention colors or theming. Do NOT use for slide decks or anything projected or printed (use kanagawa-paper instead), and do NOT use for client work or any codebase that already has a brand — ask first in those cases.
---

# Kanagawa Wave

The dark default for standalone visuals. Derived from the Neovim colorscheme of the
same name, so it should feel continuous with a terminal-centric setup rather than
like a generic dark mode.

## Tokens

```css
--bg:      #1F1F28;   /* sumiInk3  — page background   */
--surface: #2A2A37;   /* sumiInk4  — cards, code blocks */
--border:  #363646;   /* sumiInk5  — hairlines          */
--text:    #DCD7BA;   /* fujiWhite — all body copy      */
--muted:   #727169;   /* fujiGray  — secondary only     */

--accent:  #7E9CD8;   /* crystalBlue */
--ok:      #98BB6C;   /* springGreen */
--warn:    #E6C384;   /* carpYellow  */
--err:     #E46876;   /* waveRed     */
--alt:     #957FB8;   /* oniViolet   */
```

Every value is from the official palette. Keep the Neovim names in comments — they
make the theme legible to anyone who already knows Kanagawa.

## Typography

Headings and UI: **Space Grotesk**. Code and monospace: **JetBrains Mono**.

Load them explicitly. There is no Tailwind config in an artifact, so a class like
`font-display` does not exist and will silently fall back to the default face:

```html
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
```

In React, inject a `<style>` with the `@import` and set `fontFamily` on the root
element or via a class you define yourself. Do not assume a utility class exists.

Body weight 400 is right here. Light text on a dark background blooms slightly, so
strokes read heavier than they are — going to 500 for body copy makes it muddy.

## Rules

- Dark by default. Do not offer a light toggle unless asked.
- One accent per view. If the title is blue, the highlight and the metric are also
  blue. Cycling through the palette turns a layout into noise.
- Body copy is always `--text`. An accent color on a paragraph is never right.
- `--muted` is for captions, timestamps, and secondary labels. Nothing that matters
  should be in it — it sits near the contrast floor and disappears first on a bad
  display.
- Code blocks sit on `--surface` with at most three syntax colors: one for keywords,
  one for strings, one for comments. Everything else stays `--text`. Reproducing a
  full editor highlight makes a snippet unreadable at a glance.
- No gradients, no glow, no drop shadows. The palette carries the mood; effects
  just make it look like a template.

## When not to use this

If the output is going into a product, a client deliverable, or any repo with an
existing design system, stop and ask before applying any of this. A house style
beats a personal one, and quietly recoloring someone's frontend is worse than
asking a one-line question.
