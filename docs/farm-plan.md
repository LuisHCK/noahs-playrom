# Farm — Implementation Plan

Status: implemented (placeholder art/audio; real assets drop in later)
Module: `farm` ("Farm" / "Granja")
Related: `docs/farm-art-brief.md`, `docs/GDD for Montessori-Inspired App.md` §4.2, `AGENTS.md`

## 1. Goal

Build the Farm as a calm, horizontally scrollable panorama. The child explores a
fixed-height farm world, taps animals to trigger a bounce animation and audio, and
plays two learning modes on top of the same world. Ship gameplay first with
**procedural placeholders**, then drop in real art/audio with no scene-logic
changes (same seam pattern as `numbers`).

The farm **replaces the current `animals` tile** in the main menu, so the shelf
stays a 2x2 grid and no menu pagination is needed.

## 2. Locked decisions

- Module id `farm`, scene key `farm`. Manifest swaps `animals` out for `farm`
  (keeps menu slot 2). Delete `src/modules/animals/`.
- Interim tile art: reuse `assets/images/final/animals.png` via `moduleCardFarm`;
  a dedicated `farm.png` can drop in later.
- World: fixed height, **~4 screens wide** (5120 virtual px at the 1280x720 base).
- **9 animals** (GDD roster): cow, horse, hen, rooster, duck, pig, sheep, dog, cat.
  Each has a themed home/structure:
  - cow -> barn, horse -> stable, hen + rooster -> coop, duck -> pond,
    pig -> mud pen, sheep -> field, dog -> doghouse, cat -> porch.
- **3 parallax layers**: far sky/hills (0.3x), mid trees/fence (0.6x),
  ground/buildings/foreground (1x).
- Input: **drag to scroll** with inertia + edge clamp; **tap vs drag**
  disambiguation (~12px / ~0.35s) so a tap selects an animal and a drag scrolls.
  Desktop niceties: mouse wheel and Left/Right arrows.
- Modes selected by **top-bar icon buttons** (hand / speech bubble / magnifier).
- Modes:
  1. **Explore** — tap animal -> bounce + natural animal sound.
  2. **Learn** — tap animal -> bounce + spoken name (EN/ES).
  3. **Find** — random animal prompt, presented by **sound or written name** at
     random; tap correct -> calm feedback + advance; wrong -> gentle shake, no
     penalty; after all 9 -> quiet celebration, tap to restart.
- Audio seam (dot-path, lang -> common fallback):
  - `farm.common.sound.<key>` — language-independent animal recordings.
  - `farm.common.sfx.<tap|swipe|wrong>` — shared feedback.
  - `farm.<lang>.name.<key>` — spoken animal names.
  - `farm.<lang>.intro|correct|celebrate` — narration/feedback.
  Missing files are silent placeholders.
- Art seam: `scene/art.lua` tries the spritesheet first and falls back to
  procedural drawing when the sheet has no image (same as `numbers`).

## 3. Phasing

- **P0 Scaffold & data seams** — module + manifest swap, `content/config.lua`,
  `content/farm.lua`, locales, `asset_manifest`, `audio_files`, `sprites.lua`,
  delete `animals`.
- **P1 Explore (first playable)** — camera + scroll + inertia, 3-layer parallax,
  world render (ground, structures, animals), procedural art seam, tap -> bounce
  + animal sound, resize-safe. Desktop wheel/arrows.
- **P2 Learn names** — top-bar icon buttons; spoken-name audio on tap.
- **P3 Find-the-animal** — prompt logic (sound|name, random, no immediate
  repeat), correct/wrong feedback, rounds, celebration + tap-to-restart.
- **P4 Docs & verification** — `docs/farm-art-brief.md`, wire the farm harness
  into `scripts/verify.py`, update `AGENTS.md`/`README.md`.

## 4. World & camera

- Content area is the canonical 16:9 `viewport:getContentArea()` (1280x720 at
  base). World is fixed height; only `x` scrolls.
- `worldWidth = 5120`; ground line ~`content.y + 560`.
- Camera: `camera.x` clamped to `[0, worldWidth - content.width]`.
- Pointers are converted to world space with `worldX = virtualX + camera.x`.
- Scroll model: track drag velocity; on release apply friction (exponential
  decay) until velocity ~0, clamped at both ends (small overscroll bounce).
- Top-bar height (~72px) is reserved in the layout for P2/P3.

## 5. Data model

`content/config.lua`:

```lua
return {
  worldWidth = 5120,
  groundY = 560,          -- relative to content top
  tapMaxMove = 12,        -- px before a press becomes a drag
  tapMaxTime = 0.35,      -- seconds
  friction = 4.5,         -- velocity decay per second
  minVelocity = 8,
  parallax = { 0.3, 0.6, 1.0 },
  roundCount = 9          -- Find mode rounds (one per animal)
}
```

`content/farm.lua` — ordered list of structures and animals:

```lua
return {
  structures = {
    { id = "barn",    x = 180,  kind = "barn" },
    { id = "stable",  x = 760,  kind = "stable" },
    -- coop, pond, mudPen, field, doghouse, porch, windmill...
  },
  animals = {
    { key = "cow",     home = "barn",   x = 320,  size = 1.00 },
    { key = "horse",   home = "stable", x = 900,  size = 1.10 },
    -- hen, rooster, duck, pig, sheep, dog, cat...
  }
}
```

Animal display names come from locales (`modules.farm.animals.<key>`), not from
the content table, so EN/ES swaps automatically.

## 6. State machine (Explore + modes)

```
explore (free scroll) --[mode button]--> learn --[mode button]--> find
     ^                                                             |
     +-------------------[mode button / back]----------------------+

find: asking -> (tap) -> [correct] found -> ... -> all found -> celebrating -> (tap) -> new round
                          [wrong]   -> shake -> asking
```

State shape (sketch):

```lua
state = {
  context, layout, config, farm,
  mode = "explore",            -- explore | learn | find
  camera = { x = 0, velocity = 0 },
  pointer = { active=false, id, startX, startY, lastX, lastT, dragging=false },
  animals = { { key, x, y, w, h, animT=0, shakeT=0 }, ... },
  structures = { ... },
  find = { order={}, index=1, target=<animal>, prompt="name"|"sound",
           foundCount=0, celebrateT=0 },
  phase = "playing",           -- playing | celebrating
  viewportSnapshot = { w, h }
}
```

## 7. Modes

- **Explore**: tap an animal -> `animT` bounce + `farm.common.sound.<key>`.
- **Learn**: tap an animal -> bounce + `farm.<lang>.name.<key>`.
- **Find**:
  - Build a shuffled round of all animals (no immediate repeat across rounds).
  - Show a prompt banner: large icon + label; if `prompt == "sound"`, play
    `farm.common.sound.<key>` (and hide the name); if `prompt == "name"`, play
    `farm.<lang>.name.<key>` and show the written name as a fallback.
  - Tap the correct animal -> `farm.<lang>.correct`, calm pulse, advance.
  - Tap any other animal -> `farm.common.sfx.wrong` + gentle horizontal shake.
  - After `roundCount` -> `phase = "celebrating"`; tap restarts a new round.

## 8. File map

```
src/modules/farm/
  module.lua                 enabled = true
  scene/
    init.lua                 lifecycle wiring + mode/round orchestration
    state.lua                camera, animals, pointer, mode/find state
    input.lua                drag-scroll vs tap, mode buttons, find taps
    layout.lua               content/ground, world zones, top bar, banner
    camera.lua               scroll + inertia + clamp helpers
    render.lua               parallax, structures, animals, banner, mode bar
    art.lua                  sprite-or-placeholder drawing (the seam)
    audio.lua                sound/name/correct/wrong/celebrate wrappers
    modes.lua                mode definitions + find-prompt logic
  content/
    config.lua               world/tuning constants
    farm.lua                 structures + animals (positions, homes, sizes)
```

Created: the above. Deleted: `src/modules/animals/`.
Modified: `src/data/modules_manifest.lua`, `src/data/asset_manifest.lua`,
`src/data/audio_files.lua`, `src/data/sprites.lua`,
`src/data/locales/{en,es}.lua`, `main.lua` + `src/core/app.lua` (wheelmoved),
`scripts/verify.py`, `AGENTS.md`, `README.md`, `docs/prototyping-workflow.md`.

## 9. Acceptance

- Main menu tile 2 opens the Farm; back returns to the menu.
- Drag scrolls smoothly and clamps at both ends; inertia feels natural;
  wheel + arrow keys scroll on desktop.
- Tapping an animal bounces it and plays its sound (silent until files exist).
- Learn mode speaks the animal name on tap.
- Find mode asks for the correct animal by sound or name; correct taps advance,
  wrong taps only shake; completing the round shows a quiet celebration.
- Resize keeps the world usable.
- With no art/audio present everything renders/behaves via placeholders; dropping
  files at the declared paths enables real content with no logic changes.

## 10. Verification

- `scripts/tests/farm_harness.lua` (LuaJIT, `love` stubbed): scroll clamp +
  inertia, tap-vs-drag, animal hit-test, bounce trigger, mode switching, find
  correct/wrong + round completion + tap-to-restart, and `render` runs each step.
- `scripts/verify.py logic` runs the farm harness alongside the numbers harness;
  `sprites` auto-validates any new `src/data/sprites.lua` sheets; `syntax` covers
  all new Lua files.
- Manual `love .` pass for scroll feel, parallax depth, and animation timing
  (Love2D not installed in the build environment).
