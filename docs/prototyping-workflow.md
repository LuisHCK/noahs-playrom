# Prototyping Workflow

## Keep files modular

- Put scene logic in small files (`layout`, `model`, `input`, `render`, `init`)
- Keep reusable UI code in `src/ui`
- Keep translatable content in locale files only
- Keep font mapping in `src/data/font_files.lua` and load via `src/core/fonts.lua`

## Swap to final assets

1. Add final files under `assets/images/final`
2. Update key mappings in `src/data/asset_profiles/final.lua`
3. Set `defaultAssetProfile = "final"` in `src/core/config.lua` (or saved setting)

## Audio placeholders and swap

1. Keep key-to-file mapping in `src/data/audio_files.lua`
2. Play audio only through `src/core/audio.lua`
3. Put shared SFX/BGM in `assets/audio/common/`
4. Keep language-specific speech in `assets/audio/<lang>/<module>/`
5. Replace placeholder files with final recordings without changing scene code
6. Prefer `OGG` for long BGM (`stream`) and `WAV`/short `OGG` for SFX/voice (`static`)

## Alphabet vertical slice behavior

- All cards are visible in a grid
- `Tap` any card to flip that card
- Single touch is enforced (one active touch id)

## Add a new module

1. Add localized content in `src/data/locales/en.lua` and `src/data/locales/es.lua`
2. Add optional audio keys in `src/data/audio_map.lua`
3. Add scene entry in `src/core/scene_manager.lua`
4. Add menu module metadata in `src/data/content/modules.lua`
