# LYRA likeness target and current review

The supplied [LYRAIMage.png](https://github.com/JohnGwinnDEV/rixinteractive-site/blob/main/LYRAIMage.png)
defines the intended character's appearance. The central portrait is the primary
face/hair reference; the lower panels show outfit variants. The target is the
same recognizable character, not just a person wearing silver and blue.

Reference bytes viewed in this workspace have SHA-256
`9dd93e24ace6f61419534d4b795b0a4ff0bdc330bc61add487bbb38feee2b4fb`.
The image is not redistributed in the repository. The separate original design
specification is still missing.

## Visual priorities

1. Face: mature, defined cheek/jaw structure, a narrower straight nose, fuller
   lips, shaped brows, silver-blue eyes, and a calm resting expression.
2. Hair: swept side part, volume above and around the head, layered silver waves,
   foreground locks over the shoulders, and fine blue light strands/points.
3. Clothing: silver outerwear over navy with a blue pendant and a thin silver
   chain. Outfit details may adapt, but should support the reference's presence.

The reference is primarily a three-quarter portrait; unseen geometry is an
approximation. Review the actual face in front and three-quarter renders before
accepting further presentation features as a likeness improvement.

## Current reference-focused pass

- Sculpt parameters narrow the nose/face, increase lip volume, refine eyelid
  shape and outer corners, and retain the stronger cheek/jaw contours.
- A shaped brow asset from the already installed CC0 pack replaces the initial
  generic brow. Blue irises are moderated toward silver-blue; skin shading is
  warmer and hair shading brighter silver.
- The existing hair mesh gains volume, a raised crown, and waves. Twenty-two
  tapered foreground locks are added, projected to the hair/coat surfaces and
  skinned to the head. Extra strands and light points bring the filament count
  to 41. This remains mesh-based hair without strand simulation.
- The coat, chain, pendant, facial morphs, independent eyes, and mock controls
  remain. The previous portrait model/source were saved under
  `.tools/authoring/revisions/portrait-before-likeness.*` before the rebuild.

Run `bash scripts/run_portrait.sh` to review the latest model, or
`bash scripts/run_rigged.sh` for the full body. Face/hairstyle geometry is authored
in `scripts/build_lyra_base.py`, `scripts/lyra_portrait.py`, and
`scripts/lyra_details.py`; runtime surface treatment is in the repository shaders.

## Surface refinement after the likeness review

The user described the latest face/hairstyle as "a lot closer" and approved
refining skin, hair, and facial shading. That model remains the geometry
baseline: this pass changes runtime materials and the portrait rim light only.

- Skin keeps its existing diffuse texture, with smoothly interpolated,
  distance-filtered pore detail and gentler roughness variation.
- Silver hair uses bounded albedo and broader, less intense highlights to
  retain texture under the portrait lights. The rim light is reduced.
- Foreground locks use a separate shader with subtle, filtered streaks attached
  to their local coordinates. These suggest finer fibers; they are not new
  individual hair strands or a physical hair simulation.
- Sharp facial features, coat, pendant, blue filaments, rig and morphs remain.

Visual comparison uses front, three-quarter, blinking and speaking captures.
The initial material trial made the hair too gray; the final balance restores
silver while reducing glare. The headless suite checks retained behavior;
it does not judge realism. No new automated test was added for these reversible
visual adjustments; rendered review is the relevant appearance check.

The preview still has broad hair locks and a procedural garment. Surface
refinement does not resolve those geometry limitations or establish photorealism.
No model rebuild, new binary asset, dependency, purchase or commit is required.

## Acceptance and remaining gap

### Pronounced white fiber-optic strands

User review requested white filaments through the silver hair, then more
pronounced cable-like strands. The hair and foreground-lock shaders now add
continuous, brighter white threads with restrained emission, alongside the
existing blue filaments and darker undertones. Their contrast is filtered at
distance. This is surface shading, without new strand geometry or a model
rebuild. White emission follows the existing offline dim/ready restore behavior.

A regression check for white glow dimming/restoration failed before the state
hook was added. Visual checks use front/angled and live dialogue renders.

### Eyebrow and hair tone correction

User review requested lighter eyebrows and darker undertones beneath the silver
hair. Brows now use a soft ash-brown shader that preserves the original fiber
alpha mask and shape. The main hair shader retains slate undertones from its
existing darker texture values; foreground locks gain restrained darker layer
variation. Silver highlights and blue emissive filaments remain.

This is a runtime material change with no geometry or source bitmap edits and
no model rebuild. The existing `bash scripts/test.sh` suite passed; rendered
front/angled and live dialogue checks cover appearance and retained blinking.
No new automated appearance test was added for this reversible color adjustment.

### Hair layering and coat tailoring

The next approved visual iteration keeps the current face as the baseline.
Foreground locks are thinner, flattened, tapered, and staggered in length;
eight fine companion strands break up the broad parallel bundles. The main
silver hairstyle remains mesh based. Blue strands, pendant and necklace remain.

The coat has lower, rounder sleeve caps, an eased torso profile, narrower
lapels with shallow rolled folds, and smoothing before fabric thickness is
applied. Lapels fit over the coat shell; sleeve rings follow the arm rather
than using spine-centered fitting rays that can stretch the shoulder cap.
No new asset pack, dependency or service is used. Source and model backups are
stored locally as `before-hair-coat*` in the authoring revisions directory.

This is a visual iteration: no new automated appearance test is claimed.
The existing functional/asset suite and front/angled/live dialogue renders
are the relevant checks. A direct comparison of exported body position and
facial morph buffers confirmed that the face was preserved. This pass does
not add audio playback or change speech timing.

Verification: `bash scripts/build_rigged.sh`, `bash scripts/test.sh`, and
`python3 -m py_compile scripts/lyra_details.py` completed successfully.
Front and three-quarter renders were inspected; the live dialogue capture
reached blink strength 1.0. Intermediate shoulder-fitting attempts produced
visible overlap/pointing and were corrected before retaining the final build.
The final model has 142,140 triangles, remaining below the 150,000 review
threshold. GPU memory and concurrent RTX performance remain unmeasured.

### Blink and hair alignment correction

User playback review found no visible blink and an off-center hairstyle.
The blink used the speech clock, which restarted with each presentation state.
A regression test reproduced starvation with state changes every 0.75 seconds.
Blinking now follows continuous active time, retains an ongoing blink across
state changes, and uses a 0.36-second close/hold/open envelope every five seconds.
Offline still clears the eyelids and stops animation; jaw timing remains separate.

The authoring pass removes the 0.025-meter lateral crown shift while retaining
volume, the raised crown, and swept locks. Hair, foreground locks and filaments
were regenerated together using the already installed tools. The prior model
and Blender source are saved locally as `before-centered-crown.*` in the
authoring revisions directory. Provenance was refreshed for the rebuilt GLB.

The new regression failed before the fix and passed afterward. The full
`bash scripts/test.sh` suite passed. A live six-second rendered dialogue run
reached blink strength 1.0 and captured closed eyelids while the mouth was
speaking. Front and angled captures were checked for hair placement.

The render is still a parameterized human-base approximation. It is not a
reconstructed or approved likeness of the supplied portrait. A closer facial
match needs further dedicated sculpt/texture work, and the hair still needs
more convincing strand detail and material response. The coat remains a
procedural garment. Do not report that the likeness target has been reached
based on passing software tests.

Asset tests verify the new swept-lock geometry is skinned, not that it looks
correct. Functional checks cover the retained rig, eyelids, jaw, gaze,
cancellation, offline behavior, and planted feet. Front, three-quarter, blink,
and speaking renders were inspected separately. User visual review is the
acceptance step for likeness; no automatic similarity score is claimed.

This pass uses only previously installed tools/assets and authored geometry.
No new dependencies, external art downloads, purchases, or services were added.
Appearance work does not move LYRA-Core identity or reasoning into this adapter.
