# Noah's Playroom (Prototype)

Love2D prototype with modular scenes, placeholder visuals, multilingual support, and scenery-based transitions.

## Run

1. Install Love2D 11.5+
2. From project root, run:

```bash
love .
```

Default baseline resolution is 1280x720 (HD 16:9) with letterbox scaling.

## Package .love

Use the packaging script to generate a clean `.love` archive while respecting `.gitignore`.

From project root:

```bash
scripts/pack-love.sh
```

This creates:

- `dist/noahs-playroom.love`

Custom output path:

```bash
scripts/pack-love.sh dist/my-build.love
```

Package a committed snapshot instead of working-tree files:

```bash
scripts/pack-love.sh dist/release.love --ref HEAD
```

How files are selected:

- Default mode uses `git ls-files --cached --others --exclude-standard`
- That includes tracked files plus non-ignored untracked files
- Files and folders ignored by `.gitignore` are excluded from the archive

## Project layout

- `main.lua`, `conf.lua`: app entry and Love config
- `src/core`: app bootstrap, viewport, scenes, i18n, storage, assets, audio
- `src/scenes`: boot, modular main menu, alphabet vertical slice, module placeholders
- `src/ui`: reusable buttons/cards/layout helpers
- `src/data`: locales, content, audio maps, audio files, asset manifest/profiles
- `libs/scenery`: vendored scene manager

## Asset swapping

Active profile is loaded from `settings.lua` or `src/core/config.lua`.

- Prototype: `src/data/asset_profiles/prototype.lua`
- Final: `src/data/asset_profiles/final.lua`

Scenes never use direct asset paths; they request keys through `src/core/assets.lua`.

## Alphabet vertical slice

- All cards render on screen at once
- Tap any card: flip front/back for that card
- Desktop debug: `Space` flips the first card
- Deck sizes: EN 26, ES 27 (includes Ñ)
- Audio uses shared assets in `assets/audio/common/*` (SFX/BGM) and language assets in `assets/audio/en/*` + `assets/audio/es/*`
- Playback routing is key-based via `src/core/audio.lua` and `src/data/audio_files.lua`
- Recommended: BGM as `OGG` (`stream`), SFX/voice as `WAV` or short `OGG` (`static`)

## Language

Languages available: EN and ES.

- Toggle in main menu (top-right)
- Persists in `settings.lua`
- Module content and audio keys are language-aware
