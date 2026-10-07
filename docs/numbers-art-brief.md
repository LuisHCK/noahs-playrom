# Numbers Puzzle — Art Brief (Two Pieces)

Audience: illustrator / sprite artist
Deliverable: **two spritesheets** for the "Numbers — Match & Connect" mini-game.
Please do **not** export one file per element. Everything the game needs from you
is exactly these two sheets.

## 1. What the game is

A calm, Montessori-style matching puzzle for children ages 2–4. Each match is two
pieces: a **number piece** (a small card showing a digit) and a **dots piece** (a
wider card showing that many dots). The child drags a number onto the matching dots
card; correct pairs lock together. When all pairs are matched, a quiet celebration
plays. The look is a "digital woodshop": natural wood, muted pastel palette, soft
light, no cartoon faces, no loud colors.

There are **no objects, fruits, or animals** — quantity is shown with dots only.

## 2. Deliverables — exactly two PNGs

| File | Contents | Grid | Cell | Sheet size |
|------|----------|------|------|------------|
| `numbers-spritesheet.png` | Number pieces, digits **1–10** | **1 × 10**, top to bottom | **115 × 121** | **115 × 1210** |
| `dots-spritesheet.png` | Dots pieces, counts **1–10** | **1 × 10**, top to bottom | **218 × 125** | **218 × 1250** |

Layout:

```
numbers-spritesheet.png (1 x 10)        dots-spritesheet.png (1 x 10)
+--------+                              +------------+
|   1    |                              |     o      |
+--------+                              +------------+
|   2    |                              |   o   o    |
+--------+                              +------------+
|  ...   |                              |    ...     |
+--------+                              +------------+
|   10   |                              |  o o o o o |
+--------+                              |  o o o o o |
                                        +------------+
```

## 3. Sheet 1 — Number pieces

File: `assets/images/spritesheets/numbers-spritesheet.png`

- Frames: **10** (digits 1–10), single column, top to bottom (index 1 = "1",
  index 10 = "10").
- Cell: **115 × 121 px** (near-square).
- Each frame is a **rounded wooden card** with the numeral centered and baked in.
- Keep the card the same size and shape in every frame so the pieces look like a
  set. Only the digit changes. Make "1" and "10" feel equally substantial.
- Numerals: chunky, rounded, hand-painted, consistent stroke weight, high contrast
  against the card, no serifs. Fill roughly 55–65% of the card height.

## 4. Sheet 2 — Dots pieces

File: `assets/images/spritesheets/dots-spritesheet.png`

- Frames: **10** (dot counts 1–10), single column, top to bottom.
- Cell: **218 × 125 px** (wide).
- Each frame is a **wide rounded wooden card** with **N dots**.
- Dots use a **ten-frame layout**: up to **5 per row, 2 rows**, centered in the
  card. 1–5 sit in one row; 6–10 fill a second row.
- All dots are the **same size in every frame**, evenly spaced, clearly countable.
  Use one uniform dot color throughout (do not color-code by number).
- No objects — dots only.

## 5. Style guide

Match the existing art in `assets/images/final/` (for example `menu_background.jpg`
and `alphabet.png`) so everything feels like one toy set. Suggested palette (adjust
to match the existing art):

```
birch light   #E8D9BE
oak mid       #C9A66B
walnut dark   #7A5A3A
sage          #9CAF88
terracotta    #C87B5A
cream         #F5EFE2
ink / outline #3E2C1E
dot           #6E4A2E
```

Rules:

- Wood cards: subtle grain, rounded corners. Keep the border at least ~24 px thick
  (at 256 px) so it scales cleanly.
- Light source: top-left for every frame. Keep shadow direction and softness
  consistent across both sheets.
- Numerals: no serifs, high contrast, clean.
- Dots: solid soft-edged circles with a very subtle highlight; one uniform color.
- No text anywhere except the digits on the number cards.

## 6. Technical requirements

- Format: PNG-32 (RGBA) with **straight (non-premultiplied) alpha**, sRGB.
- Fully transparent background. No white matte and no checkerboard baked in.
- The cell sizes above are already at 2× the on-screen size; keep that resolution.
- Safe area: keep artwork inside the central ~90% of each cell (transparent margin)
  so scaling never bleeds between frames.
- Shadows must not cross cell boundaries.
- No gutters between cells; the uniform grid plus internal margins handle spacing.
- Center every subject in its cell; the game draws by cell, not by content bounds.

## 7. What the game draws itself (not your job)

The game draws the back button, the highlight shown while two pieces are close, the
"locked pair" glow, and the celebration effect. You only provide the two sheets.

## 8. Export checklist

- [ ] Two PNGs only: `numbers-spritesheet.png` and `dots-spritesheet.png`.
- [ ] `numbers-spritesheet.png`: 1 × 10, 115 × 121 cells, 115 × 1210 px, digits
      1–10 on wooden cards.
- [ ] `dots-spritesheet.png`: 1 × 10, 218 × 125 cells, 218 × 1250 px, dot counts
      1–10 in a ten-frame on wooden cards.
- [ ] Frames ordered top to bottom as shown.
- [ ] Straight alpha, no matte, no bleed past the safe margins.
- [ ] Consistent top-left lighting and shadows across both sheets.
- [ ] Dots uniform in size and color; cards consistent in style.
- [ ] Palette matches the existing `assets/images/final/` art.
- [ ] Nice to have: layered source files with grid guides.
