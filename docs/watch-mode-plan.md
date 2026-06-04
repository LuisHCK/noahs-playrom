# Watch Mode — Implementation Plan

## Overview

Add a second device profile to the game, targeting smartwatch screens (square, small — e.g. Galaxy Watch 5 at 450×450, Apple Watch at 396×484). The existing desktop/tablet scenes are **never modified**. A single config flag switches the entire routing to a parallel set of watch-specific scenes.

---

## Constraints & Guiding Principles

- **Zero impact on existing scenes.** `src/scenes/main_menu/` and `src/scenes/modules/alphabet_scene/` are read-only throughout this plan.
- **No new core systems.** Reuse `viewport`, `audio`, `i18n`, `assets`, `fonts`, and `storage` exactly as-is. Watch layouts read `viewport.width` / `viewport.height` dynamically — they never reference `config.baseWidth` or `config.baseHeight`.
- **`viewport:getContentArea()` is unsafe for watch layouts.** That function returns the 1280×720 safe zone. Watch layouts must build all rects directly from `viewport.width` / `viewport.height`.
- **All input coordinates arrive pre-converted.** `src/core/app.lua` calls `viewport:toVirtual()` before passing coordinates to scenes. Watch input modules receive virtual coordinates; no extra conversion is needed.
- **Folder convention.** All watch scenes live under `src/scenes/watch/`, following the same `init / model / layout / input / render` split used by existing scenes.

---

## Existing Files That Will Be Modified

### 1. `src/core/config.lua`
Add a single new field `deviceProfile`. Two valid values: `"default"` and `"watch"`.

```
deviceProfile = "default"
```

This is the only change needed to switch between the original game and watch mode. When set to `"watch"`, routing and scene registration change; when left as `"default"`, the game behaves exactly as before.

---

### 2. `src/scenes/boot.lua`
Currently always calls `setScene("main_menu", context)`. Change it to read `config.deviceProfile` and branch:

- `"watch"` → `setScene("watch_main_menu", context)`
- anything else → `setScene("main_menu", context)` (unchanged path)

Requires adding `local config = require("src.core.config")` at the top.

---

### 3. `src/core/scene_manager.lua`
Currently registers 6 scene keys. When `config.deviceProfile == "watch"`, additionally register:

- key `"watch_main_menu"` → path `src.scenes.watch.main_menu`
- key `"watch_alphabet"` → path `src.scenes.watch.alphabet`

These registrations must happen **before** `SceneryInit()` is called. The simplest approach: build a table of entries, append the watch entries conditionally, then unpack into `SceneryInit()`.

Requires adding `local config = require("src.core.config")` at the top.

---

## New Files to Create

All ten files below. Create them in order within each section, since later files depend on earlier ones.

---

### Section A — Watch Main Menu

Directory: `src/scenes/watch/main_menu/`

---

#### Step 1 — `model.lua`

Manages the carousel state.

**State fields:**
- `modules` — ordered list of 4 entries, each with `{ key, scene, enabled }`. Only `alphabet` has `enabled = true`. Source the keys and scenes from `src/data/content/modules.lua`. The `enabled` flag is added here; do not modify `modules.lua`.
- `currentIndex` — integer 1–4, which module card is centred. Starts at 1 (Alphabet).
- `swipeAnim` — table `{ active, progress, direction }`. `progress` goes 0→1 over a fixed duration (~0.25 s). `direction` is `1` (swiping to next) or `-1` (swiping to previous).
- `transitionTimer` — same pattern as `src/scenes/main_menu/model.lua`: a countdown delay (0.4 s) before calling `setScene` after tapping an enabled module.
- `queuedScene` — scene key string set when a module is tapped.

**Functions to expose:**
- `model.create(context, setScene)` — builds initial state, stores `setScene` callback.
- `model.navigateTo(state, direction)` — changes `currentIndex` with wrap (1 wraps back to 4, 4 wraps forward to 1), sets `swipeAnim.active = true`.
- `model.tapModule(state)` — if `modules[currentIndex].enabled`, sets `queuedScene` and starts `transitionTimer`. If not enabled, sets a brief `toastTimer` (0.8 s) for a "Coming Soon" label.
- `model.update(state, dt)` — advances `swipeAnim.progress`, clamps to 1 and deactivates when done. Counts down `transitionTimer`; when it reaches 0 and `queuedScene` is set, calls `setScene(queuedScene, context)`. Counts down `toastTimer`.

---

#### Step 2 — `layout.lua`

Computes all rects from the live viewport dimensions. Receives `viewport` (the singleton from `src/core/viewport.lua`).

**Output fields:**
- `cardRect` — the centred card area. Suggested: 80% of `viewport.width` wide, 65% of `viewport.height` tall, centred both axes.
- `titleRect` — a horizontal band at the very top (height ~12% of viewport height) for the app name or a small logo.
- `dotsRect` — a small horizontal band near the bottom (height ~8% of viewport height) for page indicator dots.
- `toastRect` — centred label area used when "Coming Soon" is displayed (centred horizontally, roughly mid-screen vertically).

**Function to expose:**
- `layout.build(viewport)` — returns the layout table. No state; pure computation. Store the last `viewport.width` / `viewport.height` used so that callers can detect resize (same pattern as `src/scenes/main_menu/model.lua`'s `model.ensureLayout`).

---

#### Step 3 — `input.lua`

Detects swipe left/right and taps.

**Constants:**
- `SWIPE_THRESHOLD = 40` — horizontal movement in virtual pixels that classifies a touch as a swipe vs a tap.
- `TAP_MAX_MOVE = 25` — maximum total movement (either axis) still considered a tap.

**State fields needed on the scene state** (added by `model.create`, not by input.lua):
- `activeTouchId` — nil when no touch is active, set to the pointer id on first `begin`.
- `touchStartX`, `touchStartY` — virtual coordinates at touch start.
- `touchCurrentX` — updated every `move` call; used by `render.lua` for drag feedback.

**Functions to expose:**
- `input.begin(state, pointerId, x, y)` — ignores if `activeTouchId` already set or `swipeAnim.active`. Records touch start.
- `input.move(state, pointerId, x, y)` — if correct pointer, updates `touchCurrentX` for drag preview.
- `input.finish(state, pointerId, x, y)` — if correct pointer:
  - compute `deltaX = x - touchStartX`, `deltaY = y - touchStartY`
  - if `|deltaX| >= SWIPE_THRESHOLD` and `|deltaX| > |deltaY|`: call `model.navigateTo(state, direction)` where direction = sign of deltaX (negative = swipe left = next card)
  - else if `|deltaX| < TAP_MAX_MOVE` and `|deltaY| < TAP_MAX_MOVE`: call `model.tapModule(state)`
  - clears `activeTouchId` and `touchCurrentX`
- Block all input while `state.transitionTimer > 0`.

---

#### Step 4 — `render.lua`

Draws the carousel, page dots, title, and toast.

**Carousel drawing logic (pseudo-code):**
```
for offset in { -1, 0, 1 } do
    index = wrap(currentIndex + offset, 1, 4)
    cardX = layout.cardRect.x + offset * viewport.width + slideOffset
    -- slideOffset is derived from swipeAnim.progress * viewport.width * direction
    -- also add (touchCurrentX - touchStartX) if a drag is in progress and not animating
    drawCard(modules[index], cardX, layout.cardRect.y, layout.cardRect.w, layout.cardRect.h)
end
```

**`drawCard` logic:**
- Draw a rounded rectangle background (use the same beige/cream colour palette as existing scenes: `{0.96, 0.93, 0.87, 1}`).
- If the module has a placeholder card image in `assets`, draw it centred (use `assets:get("moduleCard" .. titleCase(module.key))`).
- Draw the module name label below the image using a font from `state.context.fonts`.
- If `not module.enabled`: overlay a semi-transparent dark rectangle (`0,0,0, 0.45`) over the entire card rect.

**Page dots:**
- Draw 4 small circles in `layout.dotsRect`, centred horizontally.
- Active dot: filled, accent colour. Inactive dots: outline only, muted colour.
- Dot radius ~5 virtual px, spacing ~16 virtual px.

**Toast:**
- If `state.toastTimer > 0`, draw a semi-transparent pill-shaped label at `layout.toastRect` with localised "Coming Soon" text. Alpha fades out as `toastTimer` approaches 0.

**Localisation:** "Coming Soon" string must be added to `src/data/locales/en.lua` and `src/data/locales/es.lua` under a new key (e.g. `ui.comingSoon`). Access via `state.context.i18n:t("ui.comingSoon")`.

---

#### Step 5 — `init.lua`

The scene entry point, following the exact pattern of `src/scenes/main_menu/init.lua`.

**`scene:load(context)`:**
1. Store context.
2. Build layout: `self.layout = layoutModule.build(context.viewport)`.
3. Build state: `self.state = model.create(context, self.setScene)`.
4. Store `self.viewportSnapshot = { w = context.viewport.width, h = context.viewport.height }`.
5. Play background music: `context.audio:play("common.bgm.menu")` (same key as current menu).

**`scene:resize()`:**
- Rebuild layout, call `model.applyLayout(state, layout)`.

**`scene:update(dt)`:**
- Check if viewport dimensions changed (compare against snapshot); if so, rebuild layout.
- Call `model.update(state, dt)`.

**`scene:draw()`:** delegates to `render.draw(state, layout)`.

**Input methods** (`mousepressed`, `mousereleased`, `touchpressed`, `touchreleased`, `touchmoved`):
- Map mouse events to `input.begin/finish` using a synthetic pointer id (e.g. `"mouse"`).
- Map touch events directly (pointer id is the touch id from LÖVE).
- `touchmoved` → `input.move`.

---

### Section B — Watch Alphabet Scene

Directory: `src/scenes/watch/alphabet/`

---

#### Step 6 — `state.lua`

Single-card view of the alphabet deck with flip and swipe navigation.

**Key difference from `src/scenes/modules/alphabet_scene/state.lua`:** that file builds a 9×N grid. This file tracks a single `currentIndex` into the deck and one `flip` state object.

**Constants:**
- `FLIP_DURATION = 0.45` — same as the existing scene.
- `SWIPE_ANIM_DURATION = 0.25` — card slide animation duration.
- `spriteIndexByKey` — copy the same table from the existing `state.lua` (a→1 through z→27 plus ntilde→15). Do not require the existing state module; duplicate the table here.

**State fields:**
- `deck` — array of card objects loaded from `src/data/content/alphabet_decks`, using `context.i18n:getLanguage()`. Each card: `{ letter, object, key, audio, spriteIndex, isFront }`.
- `currentIndex` — starts at 1.
- `flip` — `{ active, time, duration, swapped, targetIsFront }`. Mirrors the flip table in the existing state.
- `isFlipLocked` — boolean; prevents flipping while animation is in progress.
- `swipeAnim` — `{ active, progress, direction }`. Same structure as the menu's swipe anim.
- `pendingAudio` — `{ card, delay }` or nil. Used to play letter/object audio after a short delay post-flip.
- `language` — string, stored from context at creation time.
- `activeTouchId` — nil or pointer id, for multi-touch guard.
- `touchStartX`, `touchStartY`, `touchCurrentX` — for drag feedback and swipe detection.

**Functions to expose:**
- `state.create(context)` — initialise all fields above.
- `state.currentCard(s)` — returns `s.deck[s.currentIndex]`.
- `state.navigate(s, direction)` — advance `currentIndex` by direction (+1 or -1) with wrap. Starts `swipeAnim`. Does nothing if `isFlipLocked` or `swipeAnim.active`.
- `state.flipCurrent(s)` — same logic as `state.flipCard` in the existing state: start flip animation if not locked.
- `state.update(s, dt)` — advance `flip.time`; at 50% mark swap `isFront`; at 100% mark complete and unlock. Advance `swipeAnim.progress`. Count down `pendingAudio.delay`; when it reaches 0 return the pending card so the caller can play audio.

---

#### Step 7 — `layout.lua`

All rects computed from `viewport.width` / `viewport.height`.

**Output fields:**
- `backButton` — small square in the top-left corner. Suggested: 44×44 virtual px, offset 10 px from the top-left corner.
- `cardRect` — the large area below the top bar. Suggested: full width minus 16 px horizontal padding, from `backButton.y + backButton.height + 8` down to `viewport.height - indicatorHeight - 8`.
- `indicatorRect` — a small strip at the bottom (`height ≈ 20 virtual px`) for the `"N / 27"` counter.

**Function to expose:**
- `layout.build(viewport)` — pure computation, returns the layout table.

---

#### Step 8 — `input.lua`

Swipe left/right to navigate, tap anywhere on `cardRect` to flip, tap `backButton` to go back.

**Constants:**
- `SWIPE_THRESHOLD = 40`
- `TAP_MAX_MOVE = 25`

**Functions to expose:**
- `input.begin(state, layout, pointerId, x, y)` — guard on `activeTouchId`; guard on `isFlipLocked` and `swipeAnim.active` (only for navigation, not for back button). Record touch start.
- `input.move(state, pointerId, x, y)` — update `touchCurrentX`.
- `input.finish(state, layout, pointerId, x, y)` — on release:
  - If `|deltaX| >= SWIPE_THRESHOLD` and horizontal > vertical: `state.navigate(state, direction)` and return `"swipe"`.
  - Else if movement < `TAP_MAX_MOVE`:
    - If point is inside `layout.backButton`: return `"back"`.
    - If point is inside `layout.cardRect` and not `isFlipLocked`: `state.flipCurrent(state)` and return `"flip"`.
  - Clear `activeTouchId`.

---

#### Step 9 — `render.lua`

**Back button:**
- Small rounded rectangle at `layout.backButton`. Draw a left-arrow character (`←`) centred inside it.
- Use the same colour palette as the existing back button in `src/scenes/modules/alphabet_scene/render.lua`: fill `{0.9, 0.85, 0.75, 1}`, border `{0.1, 0.1, 0.1, 1}`.

**Card:**
- The card area is `layout.cardRect` displaced horizontally by `touchCurrentX - touchStartX` (drag feedback) or by `swipeAnim.progress * viewport.width * direction` (snap animation). Only one of these is active at a time.
- Draw the card at its displaced position. Also draw the adjacent card (index ± 1 with wrap) offset by ±`viewport.width` from the current card position, for a peek effect during swipe.

**Flip animation:**
- Compute `xScale = abs(cos(flip.time / flip.duration * π))` — gives a 1 → 0 → 1 cosine curve.
- Apply `love.graphics.scale(xScale, 1)` around the horizontal centre of `cardRect` using push/pop + translate.
- When `card.isFront`: draw the letter sprite from `assets/images/spritesheets/alphabet-spritesheet.png` (1 col × 27 rows, 128×130 px each). Use `src/core/spritesheet.lua` (`Spritesheet.new`, `sheet:getQuad(1, spriteIndex)`). Fall back to drawing `card.letter` as large text if spritesheet fails.
- When `not card.isFront`: draw the object sprite from `assets/images/spritesheets/objects-spanish.png` (4 cols × 7 rows, 125×115 px each) using the card's `spriteIndex` to compute column/row. Fall back to drawing `card.object` as text. Use `insetRect` (same 18% inset pattern from the existing render) for visual balance.

**Indicator:**
- At `layout.indicatorRect`, draw `currentIndex .. " / " .. #deck` centred.

**Spritesheets are module-level variables** (lazy-loaded and cached), same as `src/scenes/modules/alphabet_scene/render.lua`.

---

#### Step 10 — `init.lua`

**`scene:load(context)`:**
1. Store context.
2. Build state: `self.state = stateModule.create(context)`.
3. Build layout: `self.layout = layoutModule.build(context.viewport)`.
4. Store viewport snapshot.
5. Play intro audio: `audio.playIntro(self.state)` (reuse `src/scenes/modules/alphabet_scene/audio.lua` directly — require it here; it is not tied to the grid scene in any way).

**`scene:update(dt)`:**
1. Check viewport snapshot for resize; rebuild layout if needed.
2. Call `stateModule.update(state, dt)` — it returns completed cards. For each completed card, queue `pendingAudio` (delay 0.18 s, same as existing scene). When `pendingAudio.delay` reaches 0, call `audio.playCurrentLetter` or `audio.playCurrentObject` depending on `card.isFront`.

**`scene:draw()`:** delegates to `render.draw(state, layout)`.

**Input — `handleAction(action)`:**
- `"flip"` → `audio.playFlip(state)`.
- `"swipe"` → `audio.playSwipe(state)`.
- `"back"` → `self.setScene("watch_main_menu", context)`.

**Input methods** (`mousepressed`, `mousereleased`, `touchpressed`, `touchreleased`, `touchmoved`):
- Same mouse→pointer-id mapping as the menu's init.
- All calls pass `self.state` and `self.layout` to `input.begin/move/finish`.
- `handleAction` is called with the return value of `input.finish`.

---

## Verification Checklist

Work through these in order after implementation.

1. **Default profile untouched** — set `deviceProfile = "default"` in `src/core/config.lua`, run the game. It must boot to `main_menu` as before; none of the existing scenes should change behaviour.
2. **Watch routing** — set `deviceProfile = "watch"`. The game must boot to `watch_main_menu`. Confirm in the LÖVE window console that neither `src/scenes/main_menu/init.lua` nor `src/scenes/modules/alphabet_scene/init.lua` is ever `require`d.
3. **Carousel wraps** — on `watch_main_menu`, swipe left past module 4 and confirm it wraps to module 1. Swipe right from module 1 and confirm it wraps to module 4.
4. **Coming Soon** — tap Animals, Numbers, or Universe. Confirm the "Coming Soon" toast appears and fades. Confirm no scene transition occurs.
5. **Launch Alphabet** — tap the Alphabet card. Confirm transition to `watch_alphabet`.
6. **Watch Alphabet — navigation** — swipe left and right through all 27 (Spanish) or 26 (English) cards. Confirm wrap at both ends.
7. **Watch Alphabet — flip** — tap any card. Confirm the flip animation plays, card face changes, and letter/object audio fires after ~0.18 s. Confirm only one flip at a time.
8. **Watch Alphabet — back** — tap the back button. Confirm return to `watch_main_menu`.
9. **Resize square** — resize the LÖVE window to 450×450. Confirm watch layouts fill the area correctly with no overflow or 1280/720 assumptions.
10. **Audio keys** — all audio calls use existing keys from `src/data/audio_map.lua`. If any are missing, add them to the map; do not add raw file paths in scene code.
11. **Localisation** — add `ui.comingSoon` to both `src/data/locales/en.lua` and `src/data/locales/es.lua` before touching `render.lua`. Confirm the correct string appears for each language.

---

## Assets Referenced

| Asset | Path | Used By |
|---|---|---|
| Alphabet letter sprites | `assets/images/spritesheets/alphabet-spritesheet.png` | `watch/alphabet/render.lua` |
| Spanish object sprites | `assets/images/spritesheets/objects-spanish.png` | `watch/alphabet/render.lua` |
| Menu background | `assets/images/backgrounds/background-2.jpg` (or whichever is current) | `watch/main_menu/render.lua` |
| Module card images | loaded via `assets:get("moduleCardAlphabet")` etc. | `watch/main_menu/render.lua` |
| Flip SFX | `common.sfx.flip` key in `src/data/audio_map.lua` | `watch/alphabet/init.lua` |
| Swipe SFX | `common.sfx.swipe` key in `src/data/audio_map.lua` | `watch/alphabet/init.lua` |
| Menu BGM | `common.bgm.menu` key in `src/data/audio_map.lua` | `watch/main_menu/init.lua` |
| Letter audio | `alphabet.<lang>.letters.<key>` pattern | `watch/alphabet/init.lua` via `audio.lua` |
| Object audio | `alphabet.<lang>.objects.<key>` pattern | `watch/alphabet/init.lua` via `audio.lua` |

---

## Key Existing Files to Read Before Coding Each Step

| Step | Read These First |
|---|---|
| Steps 1–3 (config/boot/scenemanager) | `src/core/config.lua`, `src/scenes/boot.lua`, `src/core/scene_manager.lua` |
| Steps 4–5 (menu model/layout) | `src/scenes/main_menu/model.lua`, `src/scenes/main_menu/layout.lua`, `src/data/content/modules.lua` |
| Steps 6–7 (menu input/render) | `src/scenes/main_menu/input.lua`, `src/scenes/main_menu/render.lua`, `src/ui/placeholder_card.lua` |
| Step 8 (menu init) | `src/scenes/main_menu/init.lua` |
| Step 9 (alphabet state) | `src/scenes/modules/alphabet_scene/state.lua` |
| Step 10 (alphabet layout) | `src/scenes/modules/alphabet_scene/state.lua` (grid geometry for reference) |
| Step 11 (alphabet input) | `src/scenes/modules/alphabet_scene/input.lua` |
| Step 12 (alphabet render) | `src/scenes/modules/alphabet_scene/render.lua`, `src/core/spritesheet.lua` |
| Step 13 (alphabet init) | `src/scenes/modules/alphabet_scene/init.lua`, `src/scenes/modules/alphabet_scene/audio.lua` |
