# Numbers Puzzle — Implementation Plan

Status: implemented (placeholder art; real sprites drop in later)
Module: `numbers` ("Match & Connect")
Related: `docs/numbers-art-brief.md`, `AGENTS.md`

## 1. Goal

Build the Numbers drag-and-drop matching puzzle completely — gameplay, drag/drop,
matching, feedback, and celebration — rendering with **procedural placeholders**.
The final watercolor art (two sheets, see the art brief) can be dropped in later
with no scene-logic changes.

## 2. Locked decisions

- Interaction: single-finger **drag and drop**.
- Pieces: a **number piece** (digit card) and a **dots piece** (a card showing N
  dots). Values 1–10. No objects, fruits, or animals.
- Board: **free placement** — pieces stay where dropped; only a correct pair locks.
- Proximity feedback: while dragging, when a piece's edge is within `highlightGap`
  (~90px) of **any** opposite-type piece (matching or not), both are highlighted to
  show a connection is possible — before they touch. The connection still completes
  only on drop and only within the tighter `connectGap` (~45px).
- Correct pair: **stays joined in place** plus a short positive feedback. The
  connection is only completed **on drop**.
- Completion: after each stage, auto-advance to the next; after the **final** stage
  (all 10 matched): quiet celebration; **wait for a tap**, then restart at stage 1.
- Layout: **staged** — `stageSize` pairs at a time (default 5 → stages 1-5, 6-10).
  One compact column of numbers on the left, one of dots on the right (five slots
  each, ~92px tall, sized to the art aspect), each group shuffled; progress dots at
  the bottom show the current stage.
- Placeholders: digits use Love's default font; dots are uniform colored circles;
  cards drawn procedurally.
- Audio: `pickup`/`place` reuse `assets/audio/common/sfx/flip.wav`; number names,
  `correct`, and `celebrate` are pre-wired to future paths (silent until files exist).

## 3. The swap seam

`src/data/sprites.lua` declares the artist's future sheets now:

```
sheets.numbersCards = assets/images/spritesheets/numbers-spritesheet.png (1x10, 115x121, digits 1-10)
sheets.numbersDots  = assets/images/spritesheets/dots-spritesheet.png    (1x10, 218x125, dots 1-10)
```

Both sheets are delivered; frame index = value (1-10), row-major top to bottom.

`scene/art.lua` tries the sprite first and falls back to procedural drawing when the
sheet has no image (`Spritesheet:drawByIndex` returns `false`). Dropping the real
PNGs at those paths enables real art with no code change.

## 4. File map

```
src/modules/numbers/
  module.lua              enabled = true
  scene/
    init.lua              lifecycle wiring + round/celebrate orchestration
    state.lua             pieces, pairs, drag state, deal/match/complete
    input.lua             begin/move/finish, hit-test, tap-to-continue
    layout.lua            board zones, card sizes, start positions
    render.lua            board, pieces, drag ghost, feedback, celebration
    audio.lua             pickup/place/correct/celebrate/number wrappers
    art.lua               sprite-or-placeholder drawing (the seam)
  content/
    config.lua            values 1-10, stage size, gaps, tunables
```

Modified: `src/data/sprites.lua`, `src/data/audio_files.lua`,
`src/data/locales/{en,es}.lua`. Delete `src/modules/numbers/scene.lua`.

## 5. State machine

```
playing -> stageComplete -> (auto-advance) -> playing -> ... -> celebrating -> (tap) -> restart
```

State shape:

```lua
state = {
  context, layout, phase = "playing",
  stages = { {1,2,3,4,5}, {6,7,8,9,10} }, currentStage = 1,
  pieces = { { id, kind="number"|"dots", value,
               x, y, w, h, paired=false, partner=<piece>, dragging=false } },
  drag = { pointerId, piece, offsetX, offsetY },
  stageCompleted = 0, completedCount = 0,
  celebrateTimer = 0, stageTimer = 0,
  connectCandidate = <piece>|nil,
  viewportSnapshot = { w, h },
}
```

## 6. Tasks

- T1 Data & seams: config, sprites, audio_files, locales.
- T2 Layout: staged — one column of numbers (left) and one of dots (right), one
  row per pair; compact aspect-correct card sizes; progress dots at the bottom;
  resize safe.
- T3 State: deal / match / complete transitions.
- T4 Art seam: `number`, `dots` with sprite-or-placeholder.
- T5 Input: single active pointer drag; drop-match; tap during celebration.
- T6 Render: board, pieces, drag ghost, matched glow/link, confetti.
- T7 Wiring: init/audio lifecycle, delete placeholder `scene.lua`, enable module.
- T8 Verify: LuaJIT stub harness (logic) + manual `love .` pass.

## 7. Acceptance

- Main menu → Numbers opens the playable puzzle; back returns to the menu.
- Dragging a number onto its matching quantity locks the pair with feedback.
- A wrong drop leaves the piece in place (no penalty).
- Pairing all 10 triggers the celebration; a tap deals a new randomized round.
- Window resize keeps the board usable.
- With no art files present, everything renders via placeholders; dropping the two
  PNGs at the declared paths renders real art with no logic changes.

## 8. Verification

- LuaJIT harness with `love` stubbed: deal, drag each number onto its partner,
  assert `completedCount == 10` and `phase == "celebrating"`; wrong drop asserts no
  pair; tap asserts a new round; `render` runs each step without errors.
- Manual `love .` pass for drag feel and celebration timing (Love2D not installed in
  the build environment).
