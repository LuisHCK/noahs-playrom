# Noah's Playroom (Prototype)

Love2D prototype with modular scenes, placeholder visuals, multilingual support, and scenery-based transitions.

## Run

1. Install Love2D 11.5+
2. From project root, run:

```bash
love .
```

Default baseline resolution is 1280x720 (HD 16:9) with letterbox scaling.

### Watch mode (desktop test)

A parallel watch-optimized UI can be tested on desktop without a smartwatch:

1. Set `deviceProfile = "watch"` in `src/core/config.lua`
2. Launch with a small square resolution to simulate a watch screen:

```bash
love . --window-width 450 --window-height 450
```

3. Or resize the window manually after launch — layouts adapt dynamically.

Watch scenes use `viewport.width` / `viewport.height` directly (not the 16:9 safe zone), so shrinking the window to any small size gives an accurate preview of the watch layout.

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

## Android (debug/dev)

This project uses the official love-android template as a git submodule at `android/`.

Add the submodule (first-time setup):

```bash
git submodule add https://github.com/love2d/love-android android
git submodule update --init --recursive
```

After cloning the repo, initialize submodules:

```bash
git submodule update --init --recursive
```

Package and install the game into the Android template:

```bash
scripts/setup-android.sh
```

Then open `android/` in Android Studio and run the app. Configuration notes:

- The setup script writes `app.application_id` and `app.orientation` in `android/gradle.properties`
- You can adjust them later in `android/gradle.properties`

## Project layout

- `main.lua`, `conf.lua`: app entry and Love config
- `src/core`: app bootstrap, viewport, scenes, i18n, storage, assets, audio
- `src/scenes`: boot, modular main menu, alphabet vertical slice, module placeholders
- `src/ui`: reusable buttons/cards/layout helpers
- `src/data`: locales, content, audio maps, audio files, asset manifest/profiles
- `libs/scenery`: scene manager

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
