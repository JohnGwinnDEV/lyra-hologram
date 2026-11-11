# Rigged LYRA character study

Status: technical import verified; visual acceptance and final LYRA likeness pending.

## Run and verify

```bash
bash scripts/run_rigged.sh
bash scripts/test.sh
```

The first command opens the separate rigged preview. The original procedural
avatar remains the default: `bash scripts/run.sh`. Both have the same mock
controls. Speech is silent simulation; sensing, Core integration, and real audio
remain inactive.

The current GLB is 14,201,612 bytes with 142,140 triangles, 77,312 exported vertices,
and 12 materials. These are structural counts, not GPU memory or speed estimates.
Four materials beyond the initial eight-material target distinguish coat
fabric, silver jewelry, emissive blue accents, and swept hair locks.
The [portrait pass](portrait-preview.md) adds face/hair smoothing and two eye
joints; its triangle count intentionally exceeds the initial close-up budget.

The imported character has textured skin, blue eyes, silver hair, a silver coat
over a navy outfit, shoes, a blue pendant, and a 55-bone skeleton. Its five facial morphs
are left/right blink, jaw opening, and left/right smile. The wrapper currently
drives blinking and simulated jaw motion; smile controls are exported for later
use. Blink/jaw morphs are also transferred to affected brows, lashes, teeth, and
tongue. Gentle spine/head motion leaves both foot bones planted. Cancellation
resets the mouth immediately without snapping the body's idle pose.

The base was generated from MPFB, not reconstructed from the reference portrait.
The latest pass adds a fitted open-front coat with long sleeves, shaped lapels,
and fine blue piping. Forty-one blue hair filaments are laid onto the hair surface
with small light points. A faceted blue pendant sits inside a silver frame and
chain. All additions are skinned: the coat follows spine/arm bones, hair lights
follow the head, and jewelry follows the chest. Accents dim offline and regain
their configured brightness when ready.

Existing MPFB shape targets define stronger cheekbones, less cheek fullness,
and a narrower, more defined chin/jaw while keeping smooth skin and working
facial controls. Detailed likeness, hair rendering, and tailoring remain visual
refinements. The coat is skinned geometry, not simulated cloth; this pass does
not add hair or fabric physics. Procedural-avatar geometry tests remain attached
to the original scene; the rigged scene has its own asset/mapping/morph/pose tests.

## Provenance and file storage

- [Pinned input versions, source URLs, licenses, and SHA-256 hashes](../assets/lyra-base-provenance.json).
- [Current human preset](../assets/lyra-base-preset.json).
- [CC0 asset license](../assets/licenses/mpfb-assets-CC0.md).
- Runtime: `avatar/assets/lyra/lyra-base.glb`, locally generated and ignored by Git.
- Editable source: `.tools/authoring/lyra-base.blend`, with textures packed.
- Toolchain: Blender 4.5.15 LTS, MPFB 2.0.18, MakeHuman CC0 core pack, and
  Mika Suominen's CC0 `faceunits01` pack. Packages and user preferences stay under
  `.tools/`; no system installation or MakeHuman service is required.

Blender came from the NLUUG distribution mirror after the main download host
returned HTTP 403. Its SHA-256 matched the published release checksum obtained
from that mirror. MPFB was downloaded from its pinned GitHub tag. Both asset
packs were checked against their packaged license metadata before extraction.
The manifest records actual downloaded archive hashes; it does not imply an
independent publisher signature was available for every download.

Expected software/asset fees for this chosen path are **$0**. There is no paid
service, commission, or subscription in the workflow. This is not an estimate
of commissioned art, development time, or any unrelated service billing.

## Rebuild

The installed workspace can regenerate the preview with:

```bash
bash scripts/build_rigged.sh
bash scripts/test_rigged.sh
```

The Blender script is the current source of the preset values; it writes the
JSON preset and provenance on each build. Customize face targets in
`scripts/build_lyra_base.py` and coat/accessory geometry in `scripts/lyra_details.py`
before rebuilding. Eye preparation and hair smoothing are in
`scripts/lyra_portrait.py`. The editable `.blend` provides
a separate manual art workflow; a scripted rebuild overwrites that file, so
save manual work under a different filename.

For a fresh checkout, dependency/download approval is required by `AGENTS.md`.
Download the four exact inputs to `.tools/downloads/` using the filenames and
URLs in the provenance manifest. Then run:

```bash
python3 scripts/prepare_authoring.py
bash scripts/blender.sh --background --factory-startup --python-exit-code 1 --python scripts/setup_authoring.py
bash scripts/build_rigged.sh
bash scripts/test_rigged.sh
```

Preparation verifies hashes and unpacks locally without network access. The
setup script registers MPFB only in isolated preferences. Build generates the
clothed character, bakes its standing arm pose, adds facial targets, saves the
editable source, then cleans helpers/masks on an export copy and imports GLB
into Godot. The authoring tools are unnecessary for running an existing GLB.

The default test runner explicitly skips the rigged suites if the local GLB is
absent. `bash scripts/test_rigged.sh` is strict and fails when the asset is absent.
Generated binary storage remains local; no Git LFS or model commit was added.

## Validation and limits

- Observed failing tests before asset creation and wrapper implementation.
- Actual GLB structure checked for skeleton/weights, nonempty facial morphs,
  embedded dependencies, skinned coat/filaments/pendant, retained emission,
  eye/lash transparency, and matching provenance.
- Godot tests exercised mapping rejection, both eyelids, jaw activation, cancel,
  pose continuity, planted feet, and offline light dimming/restoration.
- Rendered front, three-quarter, side, and back views plus neutral/blink/jaw
  close-ups. These exposed opaque eye/lash polygons; restoring both alpha masks
  fixed the export/material defects and added regression checks. The final
  close-ups visibly show blue irises, closed eyelids, and an open jaw/interior.
- The latest rendered previews used Intel OpenGL following NVIDIA initialization
  failure. RTX behavior, VRAM sharing, p95 frame-time targets, final hair sorting,
  and extended animation/clipping quality are not established by this trial.
- The human-base look is provisional and awaits the user's visual review.

The earlier human-base GLB and editable source were preserved locally under
`.tools/authoring/revisions/` before the styling changes. No new external assets,
dependencies, or paid services were needed for this pass.
