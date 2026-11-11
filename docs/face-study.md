# Separate face likeness study

This is the first Blender face blockout toward the supplied LYRA portrait.
It is a review milestone, not a finished replica or an approved facial likeness.
The existing Godot model and editable prototype source are preserved: the study
builder checks their SHA-256 hashes before and after its run and never exports
to `avatar/assets/lyra/`.

## Build and review

Use the already installed Blender toolchain:

```bash
bash scripts/blender.sh --background --python-exit-code 1 --python scripts/build_likeness_study.py
```

The builder uses the original verified reference at `/tmp/lyra-reference.png`,
or the existing local study copy if the temporary file has expired. It verifies SHA-256
`9dd93e24ace6f61419534d4b795b0a4ff0bdc330bc61add487bbb38feee2b4fb`.
This is the supplied GitHub `LYRAIMage.png`, not an invented reverse view.
The original is copied and embedded only in the local ignored study directory.
The reference is not repainted, projected onto the face, or redistributed.

Local outputs under `.tools/studies/likeness/`:

- `lyra-face-study.blend`: editable mesh with seven `Study_` shape keys.
- `review.html`: reference face crop, starting face, study, and an interactive
  before/after wipe. Open the file in a browser; no server/dependency is needed.
- `baseline-angle.png` and `study-angle.png`: identical camera, materials,
  lighting and render seed; only the study's geometry controls differ.
- `study-front-clay.png`: frontal contour review without hair/skin coloring.
- `study.json`: input hashes, camera settings, sculpt controls and render setup.

Open the `.blend` with the installed Blender, select `LyraBody_export`, and
find `Study_` controls in Object Data Properties → Shape Keys. Each is set to
1 in the saved study; set all seven to 0 for the starting face. Existing blink,
jaw and smile keys remain available. Camera `ReferenceAngle` also contains a
disabled reference background for optional manual sculpt comparison.

## What this iteration actually does

It starts from the current mesh and adds small, editable vertex deformations
for cheek hollow/crest, nose tip/base, lip volume, mouth corners, and jaw contour.
These are an initial sculpt blockout authored through Blender Python, not
image-to-3D reconstruction, an artist's completed sculpt, new topology, or a
photographic texture capture. Hair and clothing are inherited context assets.
The study uses Cycles CPU with area lights and skin shading, independently of
Godot. Render timing and appearance are not Godot performance measurements.

The camera angle and focal length are estimates. The full original portrait is
embedded for reference, but no recovered camera calibration or automatic
likeness score is claimed. Single-image depth, unseen face contours and other
angles remain uncertain.

## Review before integration

Compare eye spacing/shape, nose bridge/tip, mouth width/volume, cheeks, chin,
and resting expression against the portrait, in that order. Camera/framing
differences should be resolved before treating a silhouette difference as a
sculpt error. Front clay is a diagnostic view; there is no supplied front view
to certify that angle as correct.

The next sculpt should follow specific differences identified in this review.
Keep the study separate until the face is accepted. Detailed skin, custom hair,
garment rebuilding and facial rig refinement are later character-art work;
they are not fulfilled by these initial shape keys. Nothing is committed,
installed or connected to LYRA-Core by this workflow.

## Verification recorded

The study build and `bash scripts/test.sh` completed successfully. A separate
saved-file inspection reloads the `.blend`, checks seven nonempty bounded
facial controls, unchanged lower-body vertices, preserved original face morphs,
reference/prototype hashes, matching render dimensions, and required outputs:

```bash
bash scripts/blender.sh --background --python-exit-code 1 --python scripts/verify_likeness_study.py
```

That inspection passed. The original and study stills differ; no image
similarity score or test assertion establishes likeness. This visual iteration
uses matched-render review rather than a fabricated failing appearance test.
The first light setup was too pale and was revised before the final comparison.
The resulting face remains visibly different from the reference and needs
further sculpt review. Rendering alone does not complete the replica.
