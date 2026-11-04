# Backrooms game — handoff notes

Paste this file into a new session, or tell it: *"read ~/backrooms-cam/HANDOFF.md first"*.
State as of **2026-11-03** (after the "Level 4 realism" commit on `main`; see `git log`).

---

## What it is

An endless, procedurally generated **Backrooms** game you walk around in, on desktop and in VR (Meta Quest, via WebXR).
Each level is built to match its page on the Backrooms Wikidot wiki (and its photos).

- **The whole game is one file: `~/backrooms-cam/index.html`** (about 2,790 lines).
  World generation, rendering, entities, audio, VR and every level all live in it.
  It started as a fake FaceTime/camcorder cam, which is why the webcam-face and VHS features exist.
- **three.js r0.170.0** is bundled locally under `node_modules/three/...` and loaded through an importmap, so it works offline.
  Only the files actually used are committed; `node_modules/` is in `.gitignore`, so new files need **`git add -f`**.
  Committed so far:
  - `build/three.module.js`
  - `examples/jsm/{objects/Water.js, objects/Sky.js, environments/RoomEnvironment.js, webxr/VRButton.js}`
  - `postprocessing/{EffectComposer, RenderPass, GTAOPass, UnrealBloomPass, OutputPass, ShaderPass, MaskPass, Pass}.js`
  - `shaders/{GTAO, PoissonDenoise, Copy, LuminosityHighPass, Output}Shader.js`
  - `math/SimplexNoise.js`
- **`textures/`** holds photographic CC0 PBR texture sets from **ambientCG** (`<id>_c.jpg` colour, `_n.jpg` normal, `_r.jpg` roughness, 1024 px), about 11 MB.
  Sets: Asphalt033, Bark014, Carpet012, Carpet016, Concrete031, Concrete046, Grass005, Metal021, OfficeCeiling001, PaintedPlaster017, PaintedWood005, Planks037A, Rock058, RoofingTiles013A, Tiles107, Wallpaper001A, WoodSiding008.
  WoodSiding008 and RoofingTiles013A colour maps are greyscale on purpose, so each house can be tinted its own colour.
- `.nojekyll` lets GitHub Pages serve `node_modules`.

## How to run

- **Local (how the user plays):** `~/backrooms-cam/start.command "screen=1&mode=fp"`.
  It starts `python3 -m http.server` on `127.0.0.1:47123`, serving the main checkout, and opens a Chrome app window.
  After a change, hard-reload with **Cmd+Shift+R**.
- **Hosted:** https://danielmew123.github.io/backrooms/ and https://danielmew123.github.io/
- **URL options:**
  - `level=level0|pool|level2|level4|level7|level94`
  - `gfx=fast|medium|ultra` (graphics tier; default `medium`)
  - `mode=fp|tp|selfie`, `screen=1`, `vhs=1`, `ui=1`, `help=1`, `seed=N`, `entity=1`
  - `xrscale=0.4–1` (VR resolution, default 0.7)
  - `debug=1` exposes `window.__bk`, used by the headless screenshot tests (also `buildChunk4`, `props4`, `hash` for finding Level 4 props)

## Controls

- **Desktop:** WASD + Shift to move, mouse or arrow keys to look, click for pointer lock.
  - **P** cycle level (Level 0 → Poolrooms → Pipe Dreams → Level 4 → Level 7 → Level 94)
  - **C** camera (3rd person / selfie / first person), **F** webcam face on the character
  - **E** spawn or remove the entity, **Q** lights fail, **M** fluorescent hum
  - **V** VHS effect, **G** screen-fit mode, **U** hide overlay, **H** help
  - **N** day/night (Level 94 only)
- **VR (Quest):** left stick walk, right stick turn, **Y** cycle level, **A** day/night on Level 94.

## Deploy (git)

- Two remotes, both deploying from `main` via GitHub Pages:
  - `origin` = github.com/danielmew123/backrooms
  - `pages` = github.com/danielmew123/danielmew123.github.io
- Steps: commit, then `git push origin HEAD:main && git push pages HEAD:main`. Fast-forward only; never force-push or merge.
- **Background sessions:** do the work in a git worktree, push from there, then fast-forward the main checkout with `git fetch origin && git merge --ff-only origin/main`. The user plays from the main checkout, so skipping this means they keep seeing the old build.
- The root Pages site sometimes fails a deploy with "in progress deployment". Fix: `gh run rerun <id> -R danielmew123/danielmew123.github.io --failed`.

## How to check visuals without a headset

- Headless Chrome with `--use-angle=swiftshader --enable-unsafe-swift-shader`, driven over the DevTools protocol:
  navigate to `?level=X&debug=1`, wait a few real seconds, then `Page.captureScreenshot`.
  Move the player with `window.__bk.player.pos.set(...)`, `__bk.l7.F` (feet height), `__bk.keys.add('KeyW')`, etc.
  Wrap each evaluated snippet in `{ }`, because DevTools evaluates in global scope and repeated `const` declarations throw.
- Software rendering makes FPS meaningless, but draw-call and triangle counts from `renderer.info` are accurate.
  Comparing old and new builds back-to-back, under the same machine load, is a fair A/B.
- **Always look at screenshots before calling a visual change done.**

---

## Architecture: where things are in `index.html`

| Section (search for the comment) | What's there |
|---|---|
| `// ---------- deterministic hash` | `hash(i,j,k)`: every layout decision is deterministic from the cell coordinates plus `SEED` |
| `const GFX` / `ptex()` / `photo()` | graphics tier (`GFX`, `REAL`, `ULTRA`), `LMat` (MeshStandard vs MeshLambert), the photo-texture loader |
| `// ---------- procedural textures` | canvas textures for Level 0, Poolrooms, Pipe Dreams, Level 7 |
| `// ---------- renderer / scene` | renderer, XR setup, `rig` > `dolly` > `camera`, the two `Water` planes (pool + ocean), `LIGHTS[9]`, `sun`, `applyRenderBudget()` |
| `// ---------- levels` | `LEVELS{}`, `realSurfaces()`, `setLevel(name)` (swaps materials, fog, lights, spawn) |
| `// ---------- level generation` | Level 0 / Pipe Dreams boxes, Poolrooms layout (rooms, pits, stairs, tunnels, spiral rooms, 2 storeys), `cellBoxes()` |
| `// ===== Level 7 world` | sideways entrance room, islands, Fort Surrender, holed concrete ceiling |
| `buildChunk(cx,cz,st)` / `updateChunks()` | chunk streaming: 30 m chunks, 5×5 around the player; the near 3×3 build immediately, the outer ring one per frame |
| `// ---------- audio` / `Level 7 ambience` | all sound is synthesized WebAudio (no audio files) |
| `// ===== Level 94` | terrain `h94()`, roads, `objects94()`, house/car/prop builders, 3D grass, far-hills mesh, sky/clouds/castle, Animations, day/night, cartoon tune |
| `// ===== Level 4` | office layout `office4Boxes()` / `props4()`, `buildChunk4()`, window trap, elevators, stairs |
| `// ---------- photographic materials` | PBR photo sets on level materials, PMREM environments, the `gfx=ultra` composer |
| `// ---------- main loop` → `frame(now)` | input/VR → movement + collision → per-level physics → lights → fog → per-level frame hooks → camera → entity → water mirror pass → render |

**Key conventions**

- `CELL = 5` m, `CHUNK = 6` cells (30 m chunks), `WALL_H = 3`, `VIEW_CHUNKS = 2`.
- `l7.F` is the player's **feet height**, shared by Level 7 (sea), the flooded Poolrooms and the Level 94 terrain.
  `baseY` feeds both the desktop camera and the VR dolly.
- Collision is circle-vs-box on the XZ plane through `cellBoxes(i,j)`. Level 94 uses its own `collide94` against rotated boxes.
- Adding a level: add a `LEVELS.<name>` entry (after any textures it references, to avoid a load-order crash), push it onto `LEVEL_ORDER`, branch in `buildChunk` / `cellBoxes`, and add hooks in `setLevel` and `frame`.

---

## The levels (each built from its wiki page)

1. **Level 0** (`level0`): mono-yellow wallpaper maze, damp carpet, sparse real fluorescent fixtures (point lights pinned to them).
2. **Poolrooms, Level 37 "Sublimity"** (`pool`):
   - Bright white tile, and the **whole floor is flooded** shin-deep (one Water plane follows you).
   - Pits you can fall or swim into; you can't climb a sheer pit wall, so you need stairs or chrome ladders.
   - Arched doorways, round pillars, sourceless daylight patches, a light/dark field (some rooms are pitch black), muted sound with occasional surges.
   - **Round tunnels** (cross-section = the arch).
   - **Open spiral staircases** (matching a user reference screenshot): fat tiled column, smooth white slab steps up through a ceiling hole to a **second storey 6 m up**.
     The upper storey is the same generators evaluated `SOFF = 300` cells away, so it has different rooms.
     It's only drawn near a stair; a curb surrounds the hole upstairs, and there's an invisible handrail.
     Walking up and back down both work.
3. **Pipe Dreams, Level 2** (`level2`): dark concrete tunnels, pipes, rare fixture lights.
4. **Level 4 "Abandoned Office"** (`level4`), matched to the wiki photo:
   - Huge open halls, white plaster walls, blue-grey carpet, drop ceiling with slot vents.
   - Window walls with radiators and orange curtains; most windows are blacked out. **Walking up to a clear one is the trap**: you're thrown far away.
   - Almond Water coolers, vending machines, the odd '90s desk.
   - **Realism pass (made it less cartoonish):**
     - Clear windows use `windowViewMat`, a ShaderMaterial that ray-traces a parallax outdoor view: a lawn 4.5 m down, two tree belts (34 m and 80 m), and cloudy sky. Its colours are linear, so keep them low.
     - Blacked-out windows are glossy glass (`blackGlass4`) with taped black paper behind, reflecting `envIndoor`.
     - Pleated curtains (`curtainGeo4`) hang on a rod; radiators are sectional (`radiator4`).
     - Every cell has a 3D troffer (frame + lens). The point lights sit at `LV.lightY = 2.45` to kill the ceiling hotspot.
     - One decal mesh per chunk (`decalMat4`, atlas `decalTex4`, vertex RGBA colours) carries several things: contact-shadow strips at wall/floor and wall/ceiling joints (`aoBox4`), blob shadows under props, carpet and ceiling water stains, missing ceiling tiles (the fallen tile lies on the carpet), and the troffer lenses. `frame4` dims them with the lights.
     - The carpet is 50 cm quarter-turn tiles composed from the Carpet016 photo (`carpetTiles4`).
     - Swivel office chairs (`chair4`); outlets, light switches, thermostats, sprinklers and smoke detectors; lit vending-machine shelves.
   - **Elevators** go to "another floor" (a far-off part of the level); **STAIRS doors** lead to Level 0 or Level 2.
5. **Level 7 "Thalassophobia"** (`level7`):
   - You spawn in a furnished room built **sideways into the ocean's concrete ceiling**.
   - Walking into the doorway flips gravity and you fall about 4.5 m into an endless dark sea, then swim.
   - Rare rock islands, **Fort Surrender** (furniture and tar), floating debris, underwater murk, synthesized ambience.
6. **Level 94 "Motion"** (`level94`):
   - A 1930s stop-motion town around an Almond Water fountain: detailed houses, picket fences, lamps, stop signs, ALMOND MILK vans.
   - Siren poles play a synthesized cartoon tune.
   - Endless hills with 3D swaying grass, cars, water towers, furniture sets.
   - The castle on a glass mountain on the horizon.
   - Day/night cycle: at night, stop-motion **Animations** hunt you; they lose you if you break line of sight behind a house.
   - Some houses have **red doors that lead to Level 7**.
   - Real sun shadows, re-rendered only when you move 10 m.

The **entity** (E key) works on every level: it stares, creeps toward you, and glitches the screen when it reaches you.

---

## Graphics tiers and performance (important)

- **`gfx=medium` (default):** MeshStandardMaterial with the photo textures, plus image-based lighting (RoomEnvironment indoors, a sky environment on Level 94). Renders straight to the screen.
- **`gfx=ultra`:** adds GTAO ambient occlusion + bloom (EffectComposer) and real cube-map shadows from the two nearest ceiling lights. **Heavy.** The user said it was laggy on their computer, which is why it's opt-in.
  Known artifact: GTAO darkens around the translucent light patches (black blotches in the Poolrooms).
- **`gfx=fast`:** the old Lambert, canvas-texture look; the cheapest.
- **VR performance history:** Quest lag is fill-rate (per-pixel), not geometry.
  - `setPixelRatio` does nothing in VR; the real levers are `renderer.xr.setFramebufferScaleFactor(0.7)` and `setFoveation(1)`.
  - Water mirror reflections render **once per frame before the XR pass**, not per eye.
  - VR keeps at most 4 point lights.
  - Chunks stream in one per frame.
  - **The PBR/photo-texture work has NOT been tested on the Quest.** If VR lags, try `gfx=fast`.
- Approximate draw calls: Level 0 ~35, Poolrooms ~85, Level 4 ~160–250, Level 7 ~40, Level 94 ~225 (the grass adds one instanced mesh per chunk).
- Level 4 is now ~130–180k visible triangles, up from ~50k; most of it is window furniture (radiator sections, curtains) on both faces of each window wall. If the Quest struggles there, the first cuts are the radiator sections and sprinklers in `buildChunk4`.

## Known gaps and ideas not done

- **Level 94:** inside the castle (ball pits, Robo-Men, the Animated King), other night entities, doors to Levels 9 and 53.
- **Level 4:** Hounds/Dullers, the M.E.G. base, cults, basement stairs to Level 71.
- **Level 7:** diving into the deep zones, Tiny / The Thing, underwater exits to Levels 8 and 9.
- **Poolrooms:** no third storey; tunnels don't lead to Level 43.
- **Realism:** geometry is still simple primitives. Further realism would need real 3D models or baked lighting.
- **Level 94 houses** look a bit grey under the photo siding.

## User preferences learned

- Wants each level to **match the Backrooms wiki** (research the wiki and its images first) and the user's own reference screenshots.
  When the user says "check my recent ss", look in `~/Desktop` for the newest `Screenshot *.png`.
- Wants it to look **realistic**, but **lag matters**: it plays on their computer (desktop) as well as the Quest.
- Prefers fast turnarounds; deploy every finished change, and fast-forward the main checkout so `start.command` shows it.
