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
- `src/core`: app bootstrap, viewport, scene manager, module registry, i18n, storage, assets, audio, fonts, scene shell, images
- `src/modules`: game modules (`alphabet`, `farm`, `numbers`, `universe`); each has `module.lua` plus a `scene`
- `src/scenes`: boot and main menu
- `src/ui`: reusable buttons/cards/draw helpers
- `src/data`: module manifest, sprites, locales, audio files, asset manifest
- `libs/scenery`: scene manager

## Adding a module

1. Create `src/modules/<id>/module.lua` with `{ id, enabled, scene, scenePath }`.
2. Create the scene at `scenePath` (a `scene/` folder or a single `scene.lua`; placeholders delegate to `src/core/placeholder_scene.lua`).
3. Add the descriptor path to `src/data/modules_manifest.lua` (list order is display order).
4. Add `modules.<id>` to `src/data/locales/en.lua` and `es.lua`.
5. Add assets to `src/data/asset_manifest.lua` as needed.
6. Add audio to `src/data/audio_files.lua` as needed.

## Assets

Key-to-asset mappings live in `src/data/asset_manifest.lua` (images, colors, or other descriptors). Scenes never use direct asset paths; they request keys through `src/core/assets.lua`.

## Alphabet vertical slice

- All cards render on screen at once
- Tap any card: flip front/back for that card
- Desktop debug: `Space` flips the first card
- Deck sizes: EN 26, ES 27 (includes Ñ)
- Audio uses shared assets in `assets/audio/common/*` (SFX/BGM) and language assets in `assets/audio/en/*` + `assets/audio/es/*`
- Playback routing is key-based via `src/core/audio.lua` and `src/data/audio_files.lua`
- Recommended: BGM as `OGG` (`stream`), SFX/voice as `WAV` or short `OGG` (`static`)

## Farm (horizontal scroll)

- Long fixed-height panorama (~4 screens). Drag to scroll with inertia; mouse wheel and Left/Right arrows on desktop
- 9 animals, each at a themed home (barn, stable, coop, pond, mud pen, field, doghouse, cottage) with a windmill in the distance
- Three modes via the top bar: **Explore** (tap = animal sound), **Names** (tap = spoken name), **Find** (locate the prompted animal)
- Find mode prompts by sound or written name at random; correct taps advance, wrong taps only shake (no penalty); completing the round celebrates, tap to restart
- Placeholder-first: procedural animals/structures/parallax and silent audio until files are added at the declared paths (`assets/images/farm/*`, `assets/images/spritesheets/farm-*.png`, `assets/audio/{common,en,es}/farm/*`)

## Language

Languages available: EN and ES.

- Toggle in main menu (top-right)
- Persists in `settings.lua`
- Module content and audio keys are language-aware
