# Farm — Art Brief (v1 · Static)

Audience: illustrator / sprite artist
Scope: the **static art** for the "Farm" mini-game (module `farm`).
Related: `docs/farm-plan.md`, `docs/GDD for Montessori-Inspired App.md` §4.2

> **Version 1 has NO animation.** Every asset is a **single static pose/illustration**.
> We are locking the **style, palette, and dimensions** first; animation frames will be
> requested in a later pass once this set is approved. Do **not** deliver idle/walk/hop
> frames now.

The game is currently running on procedural placeholders. Each file below drops in at
the exact path/size listed with **no code changes**, so dimensions and grids must match
precisely.

---

## 0. Read this first — Consistency is the priority

This set only works if every asset looks like it belongs to **one toy set**. Please keep
these constant across **all four sections**:

1. **One palette** — use the shared palette in §5. No asset may introduce a new hue
   family. (Adjust the palette values once to match `assets/images/final/` and then use
   only those.)
2. **One light source** — soft light from the **top-left**, on every asset, in every
   section. Highlight top-left, shadow bottom-right.
3. **One outline treatment** — soft, hand-painted edges with the same "ink" line weight.
   No hard vector strokes, no pure black outlines.
4. **One render density** — same level of detail everywhere. Don't make animals highly
   detailed and buildings flat (or vice-versa).
5. **Exact dimensions** — every sheet uses the cell sizes given here. Cells are uniform;
   do not crop, rotate, or trim cells to content. The game draws **by cell**, not by the
   subject's bounding box.
6. **Safe area** — keep subjects inside the central ~90% of each cell (transparent
   margin), so scaling/positioning never clips them or bleeds into a neighbor.
7. **Consistent scale logic** — within a section, sizes read relative to each other
   (e.g. a cat is smaller than a horse). Across sections, buildings/animals share the
   same "real world" scale implied by the ground line.

If anything in this brief conflicts with the existing `assets/images/final/` style,
**match the existing style** and note the deviation.

## 1. World facts (needed for Background & placement)

- Base resolution **1280 × 720**. The farm is **fixed height** and scrolls
  **horizontally only**. Total world width is **5120** (~4 screens).
- A single **ground line sits at y = 560** (of 720). **Buildings and animals stand on
  this line** (their base is at the bottom of their cell).
- Style: "Digital Woodshop" — watercolor, pastel, soft light, no cartoon faces, no loud
  colors, calm and gentle (ages 2–4).

---

## 2. Section A — UI Elements

Small interface pieces used by the Farm screen and the main menu.

| # | File | Size | Notes |
|---|------|------|-------|
| A1 | `assets/images/final/farm.png` | **600 × 300** (2:1) | Main-menu tile. Must match the style/size of `alphabet.png`, `numbers.png`, `universe.png`. Replaces the interim `animals.png`. |
| A2 | `assets/images/spritesheets/farm-mode-icons.png` | **3 × 1**, cell **128 × 128** → sheet **384 × 128** | Three mode icons, transparent background, **glyphs only** (no plates, no text — the game draws the button plate and the label). |
| A3 | `assets/images/final/ui-banner.png` | **640 × 120** | The prompt plate behind Find-mode text. Soft rounded wooden panel; the game prints the question on top. Keep the center area clear/low-contrast so dark text stays readable. |

**A2 icon order (index 1 → 3):**

1. **Explore** — an open child's hand / tap gesture (means "tap an animal to hear it").
   May include a small sound-wave accent.
2. **Names** — a speech bubble (means "the animal says its name").
3. **Find** — a magnifying glass (means "find the animal").

Icon rules: bold, readable at small size, consistent stroke weight, **transparent
background**, centered in the cell, ~10% inner margin.

> Back/Home button and language toggle are shared UI already used by other screens — do
> not redesign them here. If you want to restyle them, do it globally, not in this set.

---

## 3. Section B — Background (parallax layers)

The farm is drawn as **3 horizontally tileable strips** (plus the sky). The game tiles
each strip left↔right across the world at **native scale** (no stretching) and anchors it
vertically. Each strip should be a wide band (~2 screens wide) so it repeats at a gentle
rate.

| # | File | Parallax | Vertical anchor | Contents |
|---|------|----------|-----------------|----------|
| B1 | `assets/images/final/farm-sky.png` | static (0×) | top of screen | Sky, soft clouds, distant haze. **Opaque.** Delivered: ~2661 × 285 |
| B2 | `assets/images/final/farm-far.png` | 0.3× | **bottom on the ground line (y = 560)** | Distant hills / far treeline (includes trees/bushes). **Transparent above the art.** Delivered: ~2751 × 271 |
| B3 | `assets/images/final/farm-ground.png` | 1.0× | **bottom of the screen (y = 720)** | Grass/earth band (path, flowers, stones). **Transparent above the grass.** Delivered: ~2752 × 304 |

> There is **no separate "mid" layer** — the far strip already carries the trees/bushes, so
> the set is sky + far + ground.

**B1–B3 rules:**

- Wide strips at native resolution (the delivered sizes in the table are the target);
  PNG-32, sRGB.
- **Must tile seamlessly**: the **left edge must match the right edge** exactly (test by
  placing two copies side by side).
- **Export with TRUE transparency (straight alpha) above the art.** Do **not** export the
  painter's transparency checkerboard (the light-gray/white squares) into the pixels — that
  bakes an opaque checkerboard that then shows in-game. The delivered `ui-banner` is the
  reference for correct real transparency.
- **Do not draw buildings or animals into these layers** — they are separate sections
  (C and D) drawn on top.
- Keep the horizon consistent between B2 and B3 so the depth reads.

---

## 4. Section C — Buildings (structures)

One spritesheet, one building per cell.

| File | Grid | Cell | Sheet size |
|------|------|------|------------|
| `assets/images/spritesheets/farm-structures.png` | **1 × 9**, top → bottom | **320 × 320** | **320 × 2880** |

**Frame order (index 1 → 9):**

| Index | Structure | Notes |
|-------|-----------|-------|
| 1 | **Barn** | Cow's home. Red barn, big door. |
| 2 | **Stable** | Horse's home. Open stall, wooden. |
| 3 | **Coop** | Hen's & rooster's home. Small house + ramp. |
| 4 | **Pond** | Duck's spot. Flat water patch hugging the cell bottom. |
| 5 | **Mud pen** | Pig's spot. Flat muddy patch, fence posts. |
| 6 | **Field / meadow** | Sheep's spot. Flat grassy patch, maybe hay. |
| 7 | **Doghouse** | Dog's home. Small, with an arched opening. |
| 8 | **Cottage** | Cat's porch/home. Cosy, with a doorway. |
| 9 | **Windmill** | Far-right landmark. The tallest structure. |

Rules:

- **Base every structure at the bottom of its cell** (they sit on the ground line).
- Flat items (pond, mud pen, field) are **top-down-ish patches** that still hug the
  bottom so they sit correctly on the ground.
- Keep the **windmill tall** and iconic; it anchors the end of the world.
- Same light, outline, and palette as everything else.

---

## 5. Section D — Animals

One spritesheet, one animal per cell.

| File | Grid | Cell | Sheet size |
|------|------|------|------------|
| `assets/images/spritesheets/farm-animals.png` | **1 × 9**, top → bottom | **220 × 220** | **220 × 1980** |

**Frame order (index 1 → 9):**

| Index | Animal | Index | Animal |
|-------|--------|-------|--------|
| 1 | **Cow** | 6 | **Pig** |
| 2 | **Horse** | 7 | **Sheep** |
| 3 | **Hen** | 8 | **Dog** |
| 4 | **Rooster** | 9 | **Cat** |
| 5 | **Duck** | | |

Rules:

- One animal per cell, **centered horizontally**, **feet at the bottom** of the cell.
- Transparent background; ~10% inner margin.
- Single static pose, calm and friendly (no cartoon faces needed — soft, natural shapes).
- Keep internal proportions consistent: a cat is clearly smaller than a horse; hen and
  rooster share scale; duck sits low.
- These are matched to their homes in Section C (cow→barn, horse→stable, hen+rooster→
  coop, duck→pond, pig→mud pen, sheep→field, dog→doghouse, cat→cottage).

---

## 6. Shared palette (adjust once to match `assets/images/final/`)

```
birch light   #E8D9BE
oak mid       #C9A66B
walnut dark   #7A5A3A
sage          #9CAF88
terracotta    #C87B5A
cream         #F5EFE2
sky           #A9CFE6
grass         #8FB562
pond          #79B7D8
ink / outline #3E2C1E
```

Rules: no text baked into any art (names are spoken, not written); no pure black; keep
saturation gentle.

---

## 7. Global technical requirements (all sections)

- Format: **PNG-32 (RGBA)**, **straight (non-premultiplied) alpha**, sRGB.
- Fully transparent backgrounds where specified; **no white matte**, no checkerboard,
  no background baked in.
- **No gutters between cells**; the uniform grid plus inner margins handle spacing.
- **No bleed between cells** — shadows/subjects must stay inside their cell's safe area.
- Sheet sizes must match the tables exactly (cell × grid).
- Sheets are drawn scaled by the game, so export at the stated size (already generous for
  retina) and keep edges clean.

---

## 8. Export checklist

**UI**
- [ ] `assets/images/final/farm.png` — 600 × 300, matches other menu tiles.
- [ ] `assets/images/spritesheets/farm-mode-icons.png` — 3 × 1, 128 × 128 cells (384 × 128), glyphs only, transparent.
- [ ] `assets/images/final/ui-banner.png` — 640 × 120, clear center for text.

**Background**
- [ ] `assets/images/final/farm-sky.png`, `farm-far.png`, `farm-ground.png` — wide strips, **seamlessly tileable** left↔right.
- [ ] **Real transparency** above the art (no baked checkerboard/matte) on far and ground; sky is opaque.
- [ ] No buildings/animals painted into the layers.

**Buildings**
- [ ] `farm-structures.png` — 1 × 9, 320 × 320 cells (320 × 2880), order barn→windmill, based at cell bottom.

**Animals**
- [ ] `farm-animals.png` — 1 × 9, 220 × 220 cells (220 × 1980), order cow→cat, centered, feet at cell bottom.

**Consistency & format**
- [ ] One palette, one top-left light, one outline weight across **all** sections.
- [ ] Straight alpha, sRGB, transparent where specified, no matte, no cell bleed.
- [ ] **No animation frames** in v1 — static poses only.
- [ ] Sheets match the exact dimensions above.
- [ ] Nice to have: layered source files with grid guides.
