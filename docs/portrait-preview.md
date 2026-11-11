# Video-call portrait view

```bash
bash scripts/run_portrait.sh
```

To check blinking through the same launcher, without forcing animation:

```bash
bash scripts/run_portrait.sh -- --blink-check
```

This optional seven-second check reports both eyelid strengths and frame timing,
saves a closed-eyelid render as `user://blink-check.png` (prints its absolute path),
and exits with success only if a full blink was observed and the render saved.
In headless mode it verifies morph motion only. Normal launches do not enable
the observer. From the scripts directory, use `./run_portrait.sh -- --blink-check`.
An exact-launcher check observed closure at 4.74 seconds, peak strength 1.0,
and approximately 57 FPS on Intel. The same NVIDIA/cookie warnings appeared;
they did not prevent blinking in that run. The user's missing-blink report
remains unreproduced; do not claim those warnings explain it or that this
diagnostic itself fixes it.

This local portrait places LYRA at eye level with perspective head-and-shoulders
framing, soft key/fill/rim lighting, eye highlights, a neutral procedural room
backdrop, and compact conversation controls. The notice explicitly identifies
simulated input and silent playback. No network call, webcam, microphone, or
user tracking is activated.

The model has smoother face and hair geometry and 55 bones, including two new
eye joints. Each eyeball is a separately skinned mesh. Programmed gaze changes
briefly around the three-second point of a seven-second cycle; the eyes converge
slightly toward the portrait lens. This is deterministic animation, not sensing.
Blinking, small head movements, and upper-body breathing continue. Offline resets
the eye pose and stops animation; cancellation neutralizes the mouth while
preserving body-pose continuity.

Portrait skin shading adds restrained roughness variation and fine procedural
normal variation over the existing skin image. Hair shading retains the original
strand image's tonal detail and recolors it silver at runtime. The original
bitmap is unchanged. Eye materials use lower roughness and a clear-coat layer
for highlights. These effects use the pinned Compatibility renderer; they do
not implement subsurface scattering, photographic capture, or facial tracking.

The coat, pendant, blue filaments, and five facial morphs are retained. The
full-body study is still available with `bash scripts/run_rigged.sh`, and the
procedural avatar remains `bash scripts/run.sh`.

## Build and verification

Rebuild using `bash scripts/build_rigged.sh`; this also updates the model used by
the full-body view. `scripts/lyra_portrait.py` splits the eye mesh, adds the eye
bones, and smooths the hair. The export script smooths the body on the export
copy while preserving all five facial morphs. The earlier styled model/source
were preserved under `.tools/authoring/revisions/styled-before-portrait.*`.

Run `bash scripts/test.sh` for all available suites or
`bash scripts/test_rigged.sh` for strict asset, full-body, and portrait tests.
The portrait suite checks perspective framing, simulation status, real eye-bone
movement, speaking/cancel behavior, and frozen offline gaze. Asset tests verify
the two eye joints and separate eye meshes alongside skinning/morph checks.
Rendered idle, speaking, and blink views were inspected using Intel OpenGL.

The GLB contains 142,140 triangles, 77,312 exported vertices, 55 bones, and 12
materials, totaling 14,201,612 bytes. Smoothing and swept locks exceed the initial
100,000-triangle target for this close-up trial, while staying below the
150,000-triangle review threshold. Four-sample antialiasing is enabled for the
portrait viewport. GPU memory, p95 frame time, RTX behavior, and concurrent
LYRA-Core performance remain unverified. The 60 FPS cap is not a benchmark.

## Remaining realism gap

This is a live 3D portrait built from the current human base. It still has a
visible CG appearance, especially in hair, eyes, expression, and tailoring.
Near-photographic video-call realism needs higher-quality authored/scanned skin
and hair, a more expressive facial rig, and speech-timed facial animation. This
iteration improves framing, surface detail, and presence; it does not establish
that the photographic target has been reached.

The subsequent [reference-focused likeness pass](likeness-review.md) refines
the face targets, brow, eye/skin tone, and swept hair volume, adding 22 foreground
locks and bringing the filament count to 41. Matching that reference remains
the visual acceptance criterion.

No new dependencies, external art downloads, paid services, or purchases were
introduced. Existing license/provenance records cover the reused base assets;
the portrait geometry preparation, shaders, and scene are repository code.
