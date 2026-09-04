---
name: kanagawa-paper
description: Kanagawa Lotus light palette ("papel" variant) with contrast-corrected accents, for slide decks, presentations, and anything projected or printed. Use this whenever building a deck, slides, a talk, a printable one-pager, or any visual the user says is for a bright room or a projector — and whenever they ask for a light or clear theme. Prefer kanagawa-wave for on-screen work like dashboards and demos. Do NOT use for client work or any codebase with an existing brand — ask first.
---

# Kanagawa Paper

The light counterpart to kanagawa-wave, built on Kanagawa Lotus. Lotus straight out
of the box is too soft for projection, so this variant keeps the paper and darkens
the accents.

## Tokens

```css
--bg:      #faf7ef;   /* near-neutral paper — the cream only hints */
--surface: #f0ebdc;   /* cards, code blocks                        */
--border:  #d5cea3;   /* lotusWhite0 — hairlines                   */
--text:    #43436c;   /* lotusInk2                                 */
--muted:   #716e61;   /* lotusGray2 — secondary only               */

--accent:  #496393;   /* blue   */
--ok:      #55693c;   /* green  */
--warn:    #975100;   /* orange */
--err:     #b33345;   /* red    */
--alt:     #624c83;   /* lotusViolet4 */
```

`--border`, `--text`, `--muted`, and `--alt` are official Lotus values. The other
four accents are darkened from their Lotus originals to hold roughly 5:1 against the
background. The originals (`#4d699b`, `#6f894e`, `#cc6d00`, `#c84053`) sit at
3.0–4.6, which is fine on a laptop and falls apart on a projector.

If the user wants to stay strictly canonical, use the original accents but restrict
them to text at 32pt and up, where the 3:1 large-text threshold applies.

## Typography

Headings and UI: **Space Grotesk**. Code and monospace: **JetBrains Mono**.

```html
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
```

In React, inject a `<style>` with the `@import` and set `fontFamily` on the root
element. Tailwind font utility classes do not exist in an artifact.

Body weight is **500**, not 400. Dark text on a light background reads thinner than
the same weight inverted, so carrying 400 over from the dark theme leaves the copy
looking anemic on screen and worse on a projector.

## Rules

- One accent per slide. If the section number is blue, the highlight and the metric
  are blue too.
- Body copy is always `--text`. Never an accent.
- `--muted` for footnotes and source lines only.
- Code blocks on `--surface`, at most three syntax colors: keywords, strings,
  comments. Everything else stays `--text`. A snippet on a slide is there to be
  recognized, not read.
- Minimum sizes for anything projected: body 24pt, code 20pt. Below that the
  contrast math stops mattering because nobody can resolve the glyphs anyway.
- No gradients, no glow, no drop shadows.

## Pairing with the dark theme

When a deck needs both modes, expose the tokens as CSS variables under a
`[data-theme]` selector and swap the block — the names map one-to-one onto
kanagawa-wave, so nothing else in the markup has to change.

## When not to use this

If the deck is for a client, or the repo already has a brand or template, ask before
applying any of it.
