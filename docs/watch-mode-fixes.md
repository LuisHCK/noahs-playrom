# Watch Mode Fixes — Implementation Plan

## Problem 1: Card images stretched (aspect ratio not preserved)

### Root cause

The watch main menu's `drawCardFill` (`src/scenes/watch/main_menu/render.lua:34-44`) draws card images by setting scale factors directly from the card rect dimensions:

```lua
love.graphics.draw(image, rect.x, rect.y, 0, rect.width / image:getWidth(), rect.height / image:getHeight())
```

This stretches the image to **exactly** fill the card rectangle, ignoring the image's native aspect ratio. The images in the asset profiles (e.g. `moduleCardAlphabet`) have their own intrinsic dimensions (likely landscape/16:9-oriented), but the card rect computed in `src/scenes/watch/main_menu/layout.lua` uses:

```lua
cardW = w * 0.8   -- 1024 in a 1280-wide virtual canvas
cardH = h * 0.65  -- 832 in a 1280-tall virtual canvas
```

This creates a card aspect ratio of ~1.23:1, which does not match the source images.

By contrast, the watch alphabet scene **already does it right** — it uses `fitSizeInRect()` in its `drawAssetToRect` helper (`src/scenes/watch/alphabet/render.lua:43-46`) which preserves the content aspect ratio.

### Fix

Replace `drawCardFill` in the watch main menu with a function that preserves aspect ratio (akin to `drawAssetToRect` in the alphabet render). The card rectangle should serve as a **bounding box**, not a fill target.

## Problem 2: Text too tiny / unreadable

### Root cause

All watch-mode render files render text through `love.graphics.printf()` **without ever setting a custom font or font size**. This means Love2D's default 12px bitmap font is used.

The viewport scaling chain for a 450×450 window:

| Step | Value |
|------|-------|
| Window size | 450 × 450 |
| windowAspect = 450/450 | 1.0 |
| targetAspect = 1280/720 | 1.777… |
| Since 1.0 < 1.777, branch: | `scale = 450 / 1280` |
| **viewport.scale** | **0.3515625** |
| Virtual font size (12pt) | 12 |
| **Rendered physical size** | **12 × 0.352 ≈ 4.2 px** |

The default 12px font in virtual space becomes ~4px physical pixels — impossible to read.

The standard HD mode (1280×720 window) has `viewport.scale = 1.0`, so 12px virtual = 12px physical, which is marginally readable.

No watch scene calls `fonts:get()` or `love.graphics.setFont()`, despite the `fonts` service being available in the context object passed to every scene at load.

### Fix

Watch scene renders must set a font size proportional to the viewport dimensions. Since the viewport's virtual canvas can vary (1280×1280 for a square window), font sizes should be derived from `viewport.height` (or `viewport.width`).

For example: `fonts:get("uiDefault", math.floor(viewport.height * 0.045))` would give ~57pt in the 1280-tall virtual space, which renders at 57 × 0.352 ≈ 20 physical pixels.

A helper function should be added (or used from the font module) to compute a readable font size from a viewport-relative fraction.

## Additional observations

1. **`drawCardFill` vs `drawAssetToRect` inconsistency** — The watch main menu and watch alphabet scenes have duplicate `drawCardFill`/`drawAssetToRect`/`fitSizeInRect` helpers. These should be extracted into a shared utility module.

2. **Font helper gap** — The `fonts` service (`src/core/fonts.lua`) supports `fonts:get(name, size)` but has no concept of viewport-aware sizing. The caller must compute size manually.

3. **Watch main menu card layout** — The current `cardW = w * 0.8, cardH = h * 0.65` is arbitrary and doesn't match source image ratios. Consider making the card aspect ratio configurable or computed from the active asset profile's image dimensions.

## Implementation steps

### Step 1: Extract shared rendering utilities

Move `fitSizeInRect`, `drawAssetToRect`, and `colorFrom` into a shared module (e.g. `src/ui/draw_utils.lua`):

- `draw_utils.fitSizeInRect(contentW, contentH, rectW, rectH)` → `offsetX, offsetY, drawW, drawH`
- `draw_utils.drawAssetToRect(asset, rect)` — draws image or color fill preserving aspect ratio
- `draw_utils.colorFrom(asset)` — extract color from asset entry with fallback

### Step 2: Fix card image stretching in watch main menu

- Replace `drawCardFill` in `src/scenes/watch/main_menu/render.lua` with `draw_utils.drawAssetToRect`
- This single change makes card images respect their native aspect ratio within the card bounding box

### Step 3: Make watch text viewport-aware

Add a helper in `src/core/fonts.lua` (or a new `src/ui/text_utils.lua`):

```lua
-- Returns a font sized proportionally to the viewport height.
-- fraction: what fraction of viewport height the font should occupy (e.g. 0.045)
function fonts:getForViewport(viewport, name, fraction)
    local size = math.floor(viewport.height * fraction)
    size = math.max(10, math.min(size, 120))  -- clamp
    return self:get(name, size)
end
```

### Step 4: Apply font sizing to all watch scene renders

| File | Elements | Suggested fraction |
|------|----------|-------------------|
| `src/scenes/watch/main_menu/render.lua` | Title, module name, toast text, settings icon indicator | Title: 0.05, Module name: 0.04, Toast: 0.035 |
| `src/scenes/watch/alphabet/render.lua` | Letter text (fallback spriteless), indicator, back button | Indicator: 0.04, Letter text fallback: 0.06, Back: 0.035 |
| `src/scenes/watch/settings/render.lua` | Title, back button, volume label | Title: 0.05, Volume label: 0.045, Back: 0.035 |
| `src/scenes/modules/module_scene.lua` | Title, subtitle, card labels, back button | Uses viewport.getContentArea() (16:9). Not a watch scene, but should also be checked. |

### Step 5: Clean up duplicate code

- Remove `imageCache`, `colorFrom`, `drawCardFill` from `src/scenes/watch/main_menu/render.lua` in favor of shared utils
- Remove local `fitSizeInRect`, `drawAssetToRect`, `colorFrom`, `imageCache` from `src/scenes/watch/alphabet/render.lua` in favor of shared utils
- The `src/scenes/main_menu/render.lua` and `src/ui/placeholder_card.lua` also have similar `imageCache` / `colorFrom` patterns; share selectively where it reduces duplication

### Step 6: Verify

1. Set `deviceProfile = "watch"` in `src/core/config.lua`
2. Run `love . --window-width 450 --window-height 450`
3. Visually verify:
   - Main menu card images are no longer stretched (aspect ratio preserved within bounding box)
   - All text is readable at native resolution
   - Alphabet scene card flip/swipe still works
   - Settings scene back button and volume label are readable
4. Also verify with a non-square watch-like resolution: `--window-width 400 --window-height 500` to test viewport adaptation
5. Run `love .` (standard HD) to ensure no regressions to the HD main menu or module scenes

## Files to modify

| File | Change |
|------|--------|
| `src/ui/draw_utils.lua` | **New** — shared `fitSizeInRect`, `drawAssetToRect`, `colorFrom` |
| `src/core/fonts.lua` | Add `getForViewport(viewport, name, fraction)` helper |
| `src/scenes/watch/main_menu/render.lua` | Use shared draw utils; set viewport-aware fonts |
| `src/scenes/watch/alphabet/render.lua` | Use shared draw utils; set viewport-aware fonts |
| `src/scenes/watch/settings/render.lua` | Set viewport-aware fonts |
| `src/scenes/watch/alphabet/init.lua` | Pass `fonts` context to state if needed (already in context) |
