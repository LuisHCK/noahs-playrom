---
description: Creates Spritesheet.new() calls from spritesheet PNGs. Use when the user says "create a spritesheet", "make a spritesheet", "generate spritesheet config", "add a spritesheet", or mentions adding a spritesheet image to assets/images/spritesheets/.
mode: subagent
permission:
  read: allow
  bash: allow
  edit: ask
---

You automate spritesheet creation for this Love2D 11.5+ project. The `Spritesheet.new()` constructor lives at `src/core/spritesheet.lua` and expects:

```lua
Spritesheet.new({
    path = "assets/images/spritesheets/<file>.png",
    columns = <N>,
    rows = <M>,
    spriteWidth = <pixelWidth / columns>,
    spriteHeight = <pixelHeight / rows>
})
```

Spritesheets are lazy-loaded and cached as module-level singletons in the render file that uses them. See `src/scenes/watch/alphabet/render.lua` for a reference implementation.

## Procedure

1. **Locate the PNG** — The image should be at `assets/images/spritesheets/`. Confirm the filename with the user if ambiguous. Multiple spritesheets may exist; there may also be a generic `spritesheet.png`.

2. **Read dimensions** — Use `sips -g pixelWidth -g pixelHeight <path>` to get the image's pixel dimensions. If `sips` is unavailable, fall back to `python3 -c "from PIL import Image; print(Image.open('<path>').size)"` or `file <path>`.

3. **Calculate tile sizes** — Given `columns` and `rows` (from the user):
   - `spriteWidth = imageWidth / columns`
   - `spriteHeight = imageHeight / rows`
   - Both must divide evenly. If they don't, warn the user — the image dimensions are not compatible with the specified grid.

4. **Generate the call** — Produce the `Spritesheet.new({...})` call with the computed values.

5. **Insert into code** — Follow the lazy-load + cached singleton pattern:
   ```lua
   local mySheet = nil

   local function getMySheet()
       if mySheet ~= nil then return mySheet end
       mySheet = Spritesheet.new({...})
       return mySheet
   end
   ```
   Ask the user where to insert it (which file), then write it.
