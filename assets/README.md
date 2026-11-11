# LYRA visual reference

User-supplied design reference:
[LYRAIMage.png](https://github.com/JohnGwinnDEV/rixinteractive-site/blob/main/LYRAIMage.png).

The image was viewed as direction for the procedural character: approachable
human proportions, silver hair with blue fiber-optic strands, silver-blue eyes,
silver/navy clothing, a blue pendant, and a calm presence. The silver coat is
the initial outfit; the other illustrated outfits remain future possibilities.

The current procedural study moves toward natural adult proportions and softer
facial features. A curved coat, tapered limbs, shaped hands, and planted feet
reduce the original toy-like appearance. The reference's silver/blue identity
is preserved, but no photorealistic likeness or facial rig is implemented.

The reference image is not redistributed in this repository. No image license
has been established here. The default avatar uses GDScript-created geometry.
The separate rigged trial uses licensed MakeHuman graphics and facial targets;
its source URLs, archive hashes, and license records are linked below.

This reference governs appearance only. It does not move identity, reasoning,
or other LYRA-Core responsibilities into the embodiment adapter. The original
design specification is still missing and remains a separate required input.

See the proposed [character-model specification](../docs/character-model-spec.md)
for the requirements and acceptance checks for replacing this procedural study
with a more lifelike, rigged asset.

The separate [rigged human-base trial](../docs/rigged-preview.md) now uses CC0
MakeHuman core graphics and facial targets. See its
[provenance manifest](lyra-base-provenance.json), [preset](lyra-base-preset.json),
and [asset license](licenses/mpfb-assets-CC0.md). The trial imports an actual
skinned GLB generated locally; the procedural avatar remains the default.

The current rigged study also includes code-authored coat, lapels, sleeves,
hair filaments, pendant, and chain from `scripts/lyra_details.py`. Face-shaping
targets come from the existing CC0 MPFB bundle. No additional external artwork
was downloaded for those additions; their generated meshes are recorded in
the provenance manifest.
