# Modular Game Framework Refactor Plan

Status: implemented (see section 15 for execution notes and deferrals)
Owner: TBD
Related: `AGENTS.md`, `README.md`, `docs/prototyping-workflow.md`

## 1. Purpose

Restructure Noah's Playroom so that adding a new mini-game is a small, predictable
task (a folder plus a manifest line plus content entries) instead of an edit spread
across a dozen files. This document is the step-by-step execution plan. Work through
the phases in order; each phase leaves the game runnable with `love .`.

## 2. Locked decisions

- Full module framework (all phases below).
- Modules are registered through an explicit manifest list (no directory scanning).
- Watch UI is removed entirely: code, docs, `deviceProfile`, and the watch-only
  `ui-buttons` spritesheet.
- Games live under `src/modules/<id>/`.
- `animals`, `numbers`, `universe` stay as placeholders to communicate WIP status.
- No dedicated settings scene; language/profile controls remain in the main menu.
- No new dependencies, no build step, no test framework (manual verification only).

## 3. Definition of done (whole refactor)

1. `love .` boots to the main menu and the four tiles render and navigate.
2. `alphabet` gameplay (grid, flip, audio) works exactly as before.
3. `animals`, `numbers`, `universe` open a WIP placeholder and return to the menu.
4. Adding a module requires only: `src/modules/<id>/module.lua`, a scene file,
   one line in `src/data/modules_manifest.lua`, plus locale/asset/audio entries.
   No edits to `scene_manager.lua`, either menu model, or any order list.
5. `rg "watch"` returns no runtime references (only this plan may mention watch).
6. `AGENTS.md` and `README.md` describe the new layout and "add a module" flow.

## 4. Current friction (why)

Adding one game today touches roughly 12 files:

| # | File | What must change |
|---|------|------------------|
| 1 | `src/data/content/modules.lua` | add entry |
| 2 | `src/scenes/modules/<id>.lua` | add wrapper/scene |
| 3 | `src/core/scene_manager.lua` | add scene path |
| 4 | `src/scenes/main_menu/model.lua` | extend `moduleOrder` |
| 5 | `src/scenes/watch/main_menu/model.lua` | extend `moduleOrder` + `enabled` |
| 6 | `src/scenes/main_menu/render.lua` | add to `moduleAssetKeyById` |
| 7 | `src/data/locales/en.lua` + `es.lua` | add module data (x2) |
| 8 | `src/data/asset_manifest.lua` | add fallback |
| 9 | `src/data/asset_profiles/final.lua` (+ `prototype.lua`) | add asset |
| 10 | `src/data/audio_files.lua` | add audio tree |
| 11 | `src/data/audio_map.lua` | (legacy, mostly dead) |

Additional duplication found:

- `getImage` + `imageCache` implemented 4 times:
  `src/scenes/modules/alphabet_scene/render.lua:53`,
  `src/scenes/main_menu/render.lua:13`,
  `src/ui/placeholder_card.lua:4`, `src/ui/draw_utils.lua:4`.
- `contains(rect,x,y)` implemented 5 times: `src/ui/button.lua:17`,
  `src/scenes/modules/alphabet_scene/input.lua:5`,
  `src/scenes/watch/main_menu/input.lua:7`,
  `src/scenes/watch/alphabet/input.lua:7`,
  `src/scenes/watch/settings/init.lua:6`.
- `spriteIndexByKey` duplicated: `src/scenes/modules/alphabet_scene/state.lua:5`
  and `src/scenes/watch/alphabet/state.lua:7`.
- Module order declared 3 times, asset-key map hardcoded once.
- `main_menu/render.lua:63-68` rebuilds an asset-key table inside the tile loop
  every frame.

## 5. Target architecture

```
src/
  core/
    app.lua               bootstrap + context (shape unchanged)
    scene_manager.lua     builds scenery from the module registry
    modules.lua           registry: loads manifest, exposes list()/get()
    scene_shell.lua       shared chrome: back button, bg, title, resize sync
    placeholder_scene.lua data-driven WIP scene factory
    images.lua            ONE decoded-image cache
    viewport.lua i18n.lua assets.lua audio.lua fonts.lua storage.lua
    spritesheet.lua config.lua
  ui/
    button.lua draw_utils.lua placeholder_card.lua grid.lua
  data/
    modules_manifest.lua  ordered list of module module.lua require paths
    sprites.lua           spriteIndexByKey + spritesheet configs
    locales/ asset_manifest.lua asset_profiles/ audio_files.lua font_files.lua
  modules/
    alphabet/
      module.lua          descriptor
      scene/init.lua state.lua input.lua render.lua audio.lua
      content/decks.lua
    animals/module.lua
    animals/scene.lua     one-line placeholder wiring
    numbers/...
    universe/...
  scenes/
    boot.lua main_menu/...
```

### 5.1 Module descriptor schema

`src/modules/<id>/module.lua` returns a table. Order is the position in the
manifest, so descriptors do not carry an `order` field.

```lua
return {
    id = "alphabet",                 -- required, unique, matches locale key
    enabled = true,                  -- optional, default true (false = WIP toast)
    scene = "alphabet",             -- required, scenery key
    scenePath = "src.modules.alphabet.scene", -- required, require path
    cardAssetKey = "moduleCardAlphabet",      -- optional, default derived from id
    audioPrefix = "alphabet",       -- optional, default id
}
```

Default conventions when optional fields are omitted:

- `cardAssetKey = "moduleCard" .. id:sub(1,1):upper() .. id:sub(2)`
- `audioPrefix = id`

### 5.2 Manifest

`src/data/modules_manifest.lua` is the ONLY place order is declared:

```lua
return {
    "src.modules.alphabet.module",
    "src.modules.animals.module",
    "src.modules.numbers.module",
    "src.modules.universe.module",
}
```

### 5.3 Registry API

`src/core/modules.lua`:

```lua
function modules.list()          -- ordered array of descriptors
function modules.get(id)         -- descriptor or nil
function modules.sceneEntries()  -- array of { path=, key= } for scenery (no boot/menu)
```

The registry asserts each manifest path loads and is a table with `id` and
`scenePath`, and that ids are unique.

### 5.4 Scene contract

A module scene module returns a table with any subset of the existing scenery
lifecycle methods: `load`, `update`, `draw`, `resize`, `mousepressed`,
`mousereleased`, `touchpressed`, `touchreleased`, `touchmoved`, `keypressed`.
This is unchanged from today. `scene_shell` is an optional helper, not a base class.

### 5.5 Placeholder wiring

Each placeholder module has a one-line scene that delegates to the factory:

```lua
-- src/modules/animals/scene.lua
return require("src.core.placeholder_scene").build("animals")
```

`placeholder_scene.build(id)` builds the scene table using that module's descriptor.
It replaces `src/scenes/modules/module_scene.lua` and drops the `audio_map` debug text
in favor of a localized "coming soon"/WIP label.

## 6. Ground rules

- Keep `camelCase` locals, `lowercase_with_underscores` filenames, explicit
  `return <table>`, dot-path requires (see `AGENTS.md`).
- Delete, do not shim, code paths replaced by a phase (except settings migration).
- After every task that changes requires or file locations, run `love .` and click
  through at least: main menu tiles, alphabet flip, placeholder back button.
- Optional syntax gate if `luac` is available:
  `find src -name '*.lua' -exec luac -p {} \;`
- Do not commit `settings.lua`.
- One conventional-commit per logical task, e.g. `refactor: centralize image cache`.

## 7. Phase 0 - Safe de-duplication

No architecture change; pure cleanup. Low risk.

### 0.1 Centralized image cache
- Create `src/core/images.lua`:

  ```lua
  local images = {}
  local cache = {}

  function images.get(path)
      if not path then return nil end
      local hit = cache[path]
      if hit ~= nil then return hit or nil end
      if not love.filesystem.getInfo(path) then cache[path] = false; return nil end
      local ok, img = pcall(love.graphics.newImage, path)
      cache[path] = ok and img or false
      return ok and img or nil
  end

  function images.clear() cache = {} end

  return images
  ```

- Replace local `getImage`/`imageCache` in:
  `src/scenes/modules/alphabet_scene/render.lua`,
  `src/scenes/main_menu/render.lua`,
  `src/ui/placeholder_card.lua`,
  `src/ui/draw_utils.lua` (delegate `drawUtils.getImage = images.get`).
- Verify: images still render in menu and alphabet; no duplicate cache remains
  (`rg "imageCache" src`).

### 0.2 Shared rect hit-test
- Add to `src/ui/draw_utils.lua`:

  ```lua
  function drawUtils.contains(rect, x, y)
      return x >= rect.x and x <= rect.x + rect.width
         and y >= rect.y and y <= rect.y + rect.height
  end
  ```

- Use it in `src/ui/button.lua`, `src/scenes/modules/alphabet_scene/input.lua`.
  (Watch copies are deleted in Phase 3; do not touch them now.)
- Verify: buttons and card taps still work.

### 0.3 Shared sprite data
- Create `src/data/sprites.lua`:

  ```lua
  return {
      indexByKey = { a = 1, b = 2, ... z = 27 }, -- move from alphabet_scene/state.lua
      sheets = {
          alphabet = { path = "assets/images/spritesheets/alphabet-spritesheet.png",
                       columns = 1, rows = 27, spriteWidth = 128, spriteHeight = 130 },
          objectsSpanish = { path = "assets/images/spritesheets/objects-spanish.png",
                       columns = 4, rows = 7, spriteWidth = 125, spriteHeight = 115 },
      },
  }
  ```

- Point `alphabet_scene/state.lua` and `alphabet_scene/render.lua` at it.
- Verify: letter/object sprites still draw, including ES.

### 0.4 Per-frame allocation fix
- In `src/scenes/main_menu/render.lua`, hoist the `moduleAssetKeyById` map out of
  the tile loop (Phase 1 will replace it with registry lookups anyway).
- Verify: menu renders identically.

### 0.5 Remove dead audio map
- Delete `src/data/audio_map.lua`.
- Remove its `require` and debug print from `src/scenes/modules/module_scene.lua`.
- Verify: `rg "audio_map" src` is empty.

Phase 0 acceptance: `love .` runs; `rg "imageCache" src` and `rg "audio_map" src`
return nothing outside `images.lua`.

## 8. Phase 1 - Module registry

Introduce the registry and move module code. Menus and the scene manager stop
maintaining their own lists.

### 1.1 Create the registry and manifest
- Add `src/core/modules.lua` with `list`, `get`, `sceneEntries` per section 5.3.
- Add `src/data/modules_manifest.lua` per section 5.2, pointing at the new module
  paths that will exist after 1.2-1.5. To keep the game runnable mid-phase, create
  all descriptor files first (they may temporarily reference the old scene paths).

### 1.2 Alphabet module folder
- Create `src/modules/alphabet/module.lua` (descriptor).
- Move `src/scenes/modules/alphabet_scene/` -> `src/modules/alphabet/scene/`.
- Move `src/data/content/alphabet_decks.lua` ->
  `src/modules/alphabet/content/decks.lua`.
- Update requires:
  - `src/modules/alphabet/scene/state.lua` -> `src.modules.alphabet.content.decks`
  - `src/data/audio_files.lua` -> the new decks path
- Delete `src/scenes/modules/alphabet.lua` (the pass-through wrapper).
- Verify: alphabet still loads and plays.

### 1.3 Placeholder modules
- For each of `animals`, `numbers`, `universe`:
  - Create `src/modules/<id>/module.lua` with `enabled = false` and
    `scenePath = "src.modules.<id>.scene"`.
  - Create `src/modules/<id>/scene.lua` delegating to the placeholder factory
    (factory is introduced in Phase 2; until then, point `scenePath` at the existing
    `src.scenes.modules.<id>` wrappers and move them in 2.2).
- Keep the current placeholder look for now; Phase 2 rebuilds it.

### 1.4 Scene manager reads the registry
- `src/core/scene_manager.lua`: start from `{ boot, main_menu }` and append
  `modules.sceneEntries()`. Remove the hardcoded module entries.
- Keep the watch branch until Phase 3.
- Verify: all four tiles navigate; no "No such scene" errors.

### 1.5 Menus read the registry
- `src/scenes/main_menu/model.lua`: replace `moduleOrder` with `modules.list()`
  (`enabled == false` still navigates to the placeholder in the default UI).
- `src/scenes/main_menu/render.lua`: derive each tile's asset key from
  `descriptor.cardAssetKey or default`; delete `moduleAssetKeyById`.
- `src/scenes/main_menu/model.lua` continue to use descriptor `scene`.
- Delete `src/data/content/modules.lua` once nothing references it.
- Delete `src/scenes/modules/module_scene.lua` and the
  `src/scenes/modules/{animals,numbers,universe}.lua` wrappers after Phase 2
  replaces them (do not delete yet if they are still the placeholder scenes).

### 1.6 Locale validation
- In `src/core/modules.lua` (or `i18n`), optionally assert each module id has a
  `modules.<id>` entry in every locale; log (not error) missing keys.
- Verify: `rg "moduleOrder" src` and `rg "modulesData" src` are empty.

Phase 1 acceptance: adding a descriptor + manifest line registers a scene and a
tile; both menus and the scene manager require no edits.

## 9. Phase 2 - Module contract + shared scene chrome

### 2.1 Scene shell
- Create `src/core/scene_shell.lua` with:
  - `buildBackButton(context, onClick, opts)` returning a `Button`.
  - `drawBackButton(backButton, i18n)` (extract from alphabet render).
  - `drawBackground(asset, viewport)` (extract from main menu render).
  - `drawTitle(title, subtitle, content)`.
  - `ensureLayout(state, currentSnapshot, buildLayout, applyLayout)` helper for the
    repeated viewport-snapshot/relayout pattern.
- Verify: used by alphabet and placeholder with no visual change.

### 2.2 Placeholder scene factory
- Create `src/core/placeholder_scene.lua` exposing `build(moduleId)` that:
  - reads the module descriptor for id/title/asset,
  - renders background, title/subtitle from `i18n:getModuleData(id)`,
  - renders WIP/"coming soon" label via `i18n:t("comingSoon")`,
  - wires a back button to `main_menu`.
- Refactor `src/scenes/modules/module_scene.lua` into this factory (then delete the
  old file).
- Repoint `src/modules/{animals,numbers,universe}/scene.lua` to
  `require("src.core.placeholder_scene").build(id)`.
- Delete `src/scenes/modules/alphabet.lua`, `animals.lua`, `numbers.lua`,
  `universe.lua`, and `module_scene.lua`.
- Verify: placeholders open/return; alphabet unaffected.

### 2.3 Adopt the shell in alphabet
- Rewrite `src/modules/alphabet/scene/init.lua` to create its back button,
  background, and layout via `scene_shell`.
- Remove duplicate `contains`/resize boilerplate.
- Verify: flip, audio, ES/EN, back button, and window resize all work.

Phase 2 acceptance: no scene hand-rolls a back button, `contains`, or viewport
snapshot; `rg "module_scene" src` is empty.

## 10. Phase 3 - Remove watch mode

### 3.1 Confirm scope
- `rg -n "watch" src main.lua conf.lua` and `rg -n "ui-buttons" src`.
- Expect only `src/scenes/watch/*`, `boot.lua`, `config.deviceProfile`,
  `scene_manager.lua`, and the watch `render.lua` spritesheet reference.

### 3.2 Delete files
- Delete `src/scenes/watch/` (entire tree).
- Delete `assets/images/spritesheets/ui-buttons.png`.
- Delete `docs/watch-mode-plan.md` and `docs/watch-mode-fixes.md`.

### 3.3 De-watch runtime
- `src/core/config.lua`: remove `deviceProfile`.
- `src/core/scene_manager.lua`: remove the `config.deviceProfile` branch.
- `src/scenes/boot.lua`: always `setScene("main_menu", context)`; drop the config
  require if unused.
- Verify: `rg -n "deviceProfile|watch" src` is empty.

### 3.4 Docs
- `README.md`: remove the "Watch mode" section and watch mentions; update layout.
- `AGENTS.md`: remove the watch run command and `deviceProfile` references.
- Verify: `rg -n "watch" README.md AGENTS.md` returns nothing.

Phase 3 acceptance: game boots and all flows work with no watch code present.

## 11. Phase 4 - Polish and optimization

### 4.1 Generic settings persistence
- `src/core/storage.lua`: serialize any flat table of string/number/boolean keys to
  `settings.lua`; keep reading the legacy
  `{ language, assetProfile, volume }` format.
- `src/core/app.lua`: build the persisted table from current service values instead
  of hardcoded fields when possible.
- Verify: change language, quit, relaunch, language persists; old `settings.lua`
  still loads.

### 4.2 Consistent fonts
- Route main menu and alphabet text through `context.fonts` (`fonts:get` /
  `fonts:getForViewport`) instead of Love's default font where a design font is
  intended. Match `src/data/font_files.lua` keys (`cardLetter`, `uiDefault`).
- Verify: no glyph/tofu regressions.

### 4.3 Viewport content-area caching (optional)
- Cache the table returned by `viewport:getContentArea()` and invalidate it in
  `viewport:update`. Only do this after confirming no caller mutates the result
  (`rg "getContentArea"`).
- Verify: gameplay identical across window sizes.

### 4.4 Docs refresh
- `AGENTS.md`: update "Project layout", "Architecture conventions", and add an
  "Adding a module" section.
- `README.md`: update "Project layout" and add the module authoring flow.

Phase 4 acceptance: settings round-trip verified; docs describe the new system.

## 12. Adding a module after the refactor (target workflow)

1. `mkdir -p src/modules/<id>/scene`
2. Write `src/modules/<id>/module.lua` (id, scene, scenePath, optional keys).
3. Write the scene (`scene/init.lua` or a single `scene.lua`; placeholders delegate
   to `placeholder_scene.build(id)`).
4. Add one line to `src/data/modules_manifest.lua`.
5. Add `modules.<id>` to `src/data/locales/en.lua` and `es.lua`.
6. Add asset fallback in `src/data/asset_manifest.lua` and entries in
   `src/data/asset_profiles/{prototype,final}.lua` if it has art.
7. Add audio under `src/data/audio_files.lua` if it has sound.
8. Run `love .`; the tile and scene appear with no core edits.

## 13. Progress tracker

- [x] Phase 0.1 image cache
- [x] Phase 0.2 shared contains
- [x] Phase 0.3 shared sprite data
- [x] Phase 0.4 render allocation fix
- [x] Phase 0.5 remove audio_map
- [x] Phase 1.1 registry + manifest
- [x] Phase 1.2 alphabet module folder
- [x] Phase 1.3 placeholder descriptors
- [x] Phase 1.4 scene manager reads registry
- [x] Phase 1.5 menus read registry
- [ ] Phase 1.6 locale validation (deferred: registry stays decoupled from i18n)
- [x] Phase 2.1 scene shell
- [x] Phase 2.2 placeholder factory
- [x] Phase 2.3 alphabet adopts shell
- [x] Phase 3.1 confirm watch scope
- [x] Phase 3.2 delete watch files
- [x] Phase 3.3 de-watch runtime
- [x] Phase 3.4 docs
- [x] Phase 4.1 generic settings
- [ ] Phase 4.2 consistent fonts (deferred: cannot be visually verified without Love2D installed)
- [x] Phase 4.3 viewport caching (optional)
- [x] Phase 4.4 docs refresh

## 15. Execution notes

- Implemented in order 0 -> 4. Phase 3 (watch removal) landed after Phase 1
  file moves; the three watch files that referenced moved paths were updated
  before deletion so the tree stayed loadable.
- Verification in this environment was done with a LuaJIT harness that stubs
  `love` (Love2D is not installed). It loads every module descriptor and scene,
  builds the scene manager, then drives `app:load/update/draw` through boot, the
  main menu, all four modules, and back navigation. Run it with any LuaJIT:
  `luajit <harness>.lua` from the project root.
- 4.2 (fonts) was intentionally left untouched: applying the design fonts would
  change text sizing/positioning across the default scenes and cannot be visually
  validated here. Do it as a follow-up with `love .` available.
- 1.6 (locale validation) was left out to keep `src/core/modules.lua` free of an
  i18n dependency. Revisit if missing locale keys become a recurring issue.
- Follow-up cleanup (post-plan): the prototype/final asset profile system was
  removed. `src/data/asset_manifest.lua` is now the single asset source,
  `src/core/assets.lua` is a plain key lookup, `src/data/asset_profiles/` and the
  main-menu profile button were deleted. The documented workflow sections that
  referenced `asset_profiles/` in this plan are historical.

## 16. Risks and rollback

- Require-path churn during Phase 1/2 can break loading. Mitigation: move one module
  at a time and run `love .` after each move; keep descriptors pointing at old paths
  until the new scene file exists.
- `settings.lua` compatibility: Phase 4 must read the legacy format before writing
  the generic one.
- Scenery `manualLoad` asserts unique keys and a single default; registry scene keys
  must stay unique (registry validates ids already).
- No automated tests: every task ends with a manual smoke check. Rollback per task
  is `git revert` of that task's commit.
