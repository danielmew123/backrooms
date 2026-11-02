# Backrooms

An endless, procedurally generated Backrooms you walk around in. Four levels — Level 0 (yellow
rooms), the Poolrooms, Level 2 "Pipe Dreams", and Level 7 "Thalassophobia" (the ocean). Everything
is generated in code; the only external assets are the three.js engine (CDN) and a pixel font.

## Play in your browser / VR headset
Hosted here: **https://danielmew123.github.io/backrooms/**

**In VR (Quest etc.):** open that link in the headset browser and tap **ENTER VR**.
- Left thumbstick = walk (where you look) · Right thumbstick = turn · move your head to look around.
- No keyboard in VR, so pick a level with a URL param: add `?level=pool`, `?level=level2` or
  `?level=level7` (default is Level 0), e.g. `.../backrooms/?level=level7`.

## Open it locally (desktop)
Double-click **`start.command`** (or run `~/backrooms-cam/start.command` in Terminal).
It starts a local server and opens a 1280×720 Chrome window titled "Backrooms".
It opens straight into first-person with no overlay. Click the window to take control.

First time, if macOS blocks it: right-click `start.command` → **Open** → **Open** again.
To quit: close the window, then run `pkill -f "http.server 47123"` in Terminal.

## Controls (click the window first)
| Key | |
|---|---|
| W A S D / Shift | walk / run |
| Mouse (or ← →) | look |
| C | camera: 1st person → 3rd person → selfie |
| F | put your real webcam face on the character |
| E | spawn the entity down a hallway. It stares, creeps toward you, and glitches out when it reaches you. Press again to remove it |
| Q | the lights fail |
| P | cycle level: Level 0 (yellow rooms) → Poolrooms (tiled pools) → Level 2 "Pipe Dreams" (dark concrete pipe tunnels) → Level 7 "Thalassophobia" (endless ocean) |
| M | fluorescent hum |
| V | VHS / glitch camcorder effect on/off (off by default — clean render) |
| U | show/hide the REC overlay (hidden by default) |
| H | show/hide the controls panel |
| G | brighter mode with no dark edges |
| Esc | free the mouse |

URL options (pass as an argument: `./start.command "seed=42&mode=tp"`): `seed=` gives a different
maze, `mode=fp|tp|selfie` sets the starting camera, `level=pool`, `level=level2` or `level=level7` picks the starting level,
`vhs=1` turns the VHS/glitch effect on (off by default), `ui=1` shows the overlay on start.

Files: `index.html` (everything), `node_modules/three` (bundled three.js, so it works offline).
Uses port 47123.
