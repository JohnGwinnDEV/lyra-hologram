# LYRA-Hologram

LYRA's replaceable presentation adapter. LYRA-Core remains an independent
repository and process responsible for cognition and identity.

The desktop prototype displays a stylized procedural LYRA character with idle
motion, state lighting, simulated mouth motion, and scripted dialogue controls.
The state machine remains independent of rendering. No real audio, sensing,
or Core integration is active. The design specification is still missing;
the kickoff prompt v0.2 is the provisional scope.

## Desktop preview

```bash
bash scripts/run.sh
```

Use **Run mock dialogue** to advance from request pending to a silent simulated
speech animation, then back to idle. **Simulate input** demonstrates LISTENING
without opening a microphone. Cancel, simulate error, reset, and power controls
exercise recovery and shutdown. Buttons are enabled only in valid states.

Mock timing is 0.75 seconds pending and 2.5 seconds simulated speech; it is not
audio playback or lip synchronization. The avatar consists of code-created
meshes with no imported character assets. Her silver hair has blue light
filaments, and her silver coat, navy outfit, silver-blue eyes, and pendant
follow the supplied [visual reference](assets/README.md). The current pass uses
adult head/body proportions, smooth facial contours with eyelids and shaped
lips, tapered limbs, individual fingers, a curved coat, and softer fabric
materials. Breathing moves the upper body while both feet remain planted.
This remains a procedural character study; a close, realistic likeness will
require an authored character mesh, textures, and a facial rig.
Skin, hair, and clothing retain their colors across states; the pedestal light
and subtle pose changes distinguish presentation states. The window targets
1120 × 760 with scaled UI on resize and a 60 FPS cap.

The current scene was captured and visually inspected using the Intel OpenGL
renderer. NVIDIA initialization failed in that preview, so RTX performance
remains unverified. Headless tests exercise scene creation, controls, and
identity palette stability, head/body proportions, and planted feet, not pixel
rendering.

## Tests

Run from this repository:

```bash
bash scripts/test.sh
```

The runner uses the locally installed Godot 4.7.2 standard Linux x86_64 binary
under `.tools/godot-4.7.2/`. That directory is ignored by Git; a fresh checkout
requires a separately approved engine installation. No global PATH or system
packages were changed. Runtime data stays under `.tools/runtime/`.
The suite includes lifecycle tests and desktop scene/control integration tests.
When the local rigged GLB is present, it also runs the actual asset handoff and
rigged-scene tests. Missing rigged assets are reported as an explicit skip.

The portable engine came from the official `godotengine/godot-builds` GitHub
release `4.7.2-stable`; the archive's SHA-512 matched that release's
`SHA512-SUMS.txt` before extraction. Engine licensing:
https://godotengine.org/license/

See [the local event contract](docs/contracts/v1.md) and [agent instructions](AGENTS.md).

The next asset is described in the proposed
[character-model specification](docs/character-model-spec.md), covering visual
direction, rigging, Godot delivery, resource targets, and import acceptance.
The [free candidate comparison](docs/character-model-candidates.md) explains the
selection of an MPFB-generated human base for the first import trial.

The [rigged LYRA character study](docs/rigged-preview.md) is built locally.
Run `bash scripts/run_rigged.sh` to inspect it. Blender/MPFB are isolated under
`.tools/`; the existing procedural scene remains the default. The rigged base
has textured skin, silver hair with 41 blue light strands, a fitted silver coat,
a blue pendant and silver chain, and sharper cheek/jaw contours. Blink/jaw
controls remain functional. The accents dim offline. Facial likeness and fine
material/tailoring work remain refinements.

For the closer [video-call portrait view](docs/portrait-preview.md), run
`bash scripts/run_portrait.sh`. It adds eye-level perspective, quieter controls,
smoother geometry, independent eye gaze, and skin/hair/eye surface improvements.
It remains a local, silent 3D simulation with a visible CG appearance.

The latest [likeness pass](docs/likeness-review.md) focuses on the supplied
portrait's narrower nose, fuller lips, shaped brows, warmer skin, and fuller
swept silver hair with foreground locks. The visual match remains provisional.

A separate [Blender face study](docs/face-study.md) preserves the working
prototype and compares editable facial controls with the supplied portrait.
Its local review page is `.tools/studies/likeness/review.html`; it is not yet
integrated into the Godot avatar.

## What is stored in Git

The repository contains code, shaders, tests, documentation, build scripts,
and asset provenance. Installed tools, generated GLB/Blender models, extracted
textures, renders, and the supplied reference image remain local and ignored.
A fresh clone does not include the rigged portrait or face-study binaries;
use the documented [authoring workflow](docs/rigged-preview.md) and
[face-study workflow](docs/face-study.md) to recreate them after setting up
the required local tools and reference.
