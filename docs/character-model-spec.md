# LYRA character model specification

Version 0.2 · Asset-selection brief · 2026-11-10

## Intent and scope

Replace the procedural character with a more lifelike, rigged desktop avatar
while preserving the existing mock lifecycle and controls. The user's latest
direction is natural human appearance rather than a cute figure.

The supplied [visual reference](../assets/README.md) guides appearance. The
missing `LYRA_Embodiment_Design_v0.1.docx` remains an outstanding input. Unseen
angles, outfit construction, and numerical budgets below are proposals, not
claims about that document. No imported model or artist is selected by this brief.
LYRA-Core retains all identity and cognitive responsibilities.

## Acquisition scope

Use free tools and assets for the next evaluation. No purchase, subscription,
commission, or paid service is planned. Earlier references to monetary cost
described optional acquisition routes, not a project charge or requirement.
Track license terms and the engineering effort separately from financial cost.

## Visual brief

| Element | Required direction |
| --- | --- |
| Overall | Adult woman with natural proportions and the mature, calm, approachable presence shown in the reference |
| Face | Sculpted cheeks, jaw, nose, lips, ears, and eyelids; subtle asymmetry and relaxed resting expression |
| Eyes | Silver-blue irises, restrained highlights, and eyelids that meet the eyeballs without gaps |
| Skin | Natural tonal variation and restrained surface detail rather than uniform plastic shading |
| Hair | Long silver hair with layered volume, a swept part, and sparse blue light filaments; keep the face readable |
| Clothing | One silver-gray tailored coat over a navy outfit, dark practical boots, and a blue pendant |
| Materials | Fabric reads as fabric and hair as hair; reserve bright emission for fine filaments and the pendant |
| Motion | Planted feet, gentle breathing, occasional blinking, and small head/gaze adjustments; no exaggerated bobbing |

Preserve skin, hair, and outfit colors through state changes. Communicate status
through the platform light and subtle motion. Avoid oversized eyes/head, rigid
tubular limbs, mitten hands, glowing skin, and permanent smiles. Review face and
silhouette before adding outfit variants.

## Asset delivery

- One full-body character, outfit, and hairstyle, including finished side/back
  geometry. Supply front, three-quarter, side, and back preview images.
- Godot-ready glTF 2.0 binary (`.glb`) containing textures, skeleton, skin weights,
  facial morph targets, and animation clips. Retain editable source files and
  the exporter/version record when their license permits delivery.
- Use meters, Y-up, character facing +Z, and an origin on the floor between the
  feet. Proposed height: approximately 1.70 m. Adapt stage scale in the wrapper;
  the tabletop apparent-size target remains a separate display concern.
- Supply a documented neutral A- or T-pose and bone-name mapping for root, hips,
  spine, neck/head, arms, hands/fingers, legs, and feet. Verify shoulder, elbow,
  wrist, knee, and ankle deformation in the exported asset.
- Minimum facial controls: independent left/right blink, jaw opening, and a
  gentle smile. Map asset-specific morph names explicitly. An open jaw must
  reveal a finished mouth interior. Additional speech mouth shapes are preferred;
  exact visemes will follow the chosen speech backend.
- Minimum motion: seamless standing idle/breathing, blink, and a subtle attentive
  head movement. Morphs may drive blinking instead of a clip. No locomotion or
  root-motion animation is needed in this iteration.
- Use portable PBR materials with base color, normals, roughness/metallic, and
  optional occlusion/emission maps. Verify them in the Compatibility renderer.
  Hair must remain readable on a dark background without transparency sorting
  artifacts; prefer opaque geometry or alpha-cutout cards initially.
- Bake required motion and export supported material properties. Runtime must
  not require authoring-tool constraints, hair grooms, plugins, network services,
  or an installed authoring application.

Godot recommends [glTF 2.0 for scene imports](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html).
Follow its [export conventions](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/model_export_considerations.html)
for orientation, transforms, rest pose, and triangulation. Direct `.blend`
import requires Blender; the proposed runtime handoff is an exported GLB.

## Proposed resource targets

These are starting budgets, not measured capability. Count the complete clothed
character, including hair, and record exceptions rather than silently exceeding
the budgets.

| Resource | Initial target |
| --- | --- |
| Triangles | 60,000–100,000 total; review above 150,000 |
| Materials | At most 8 initially; account for hair passes and transparent surfaces |
| Textures | Mostly 2K; allow a 4K face map only if useful at the actual display size |
| GPU memory | Aim below 512 MiB incremental avatar usage; measure actual usage |
| Frame time | Target 60 FPS at 1920 × 1080, with p95 frame time at or below 16.7 ms on the intended renderer/hardware |

Measure frame times, memory, import/startup time, and hair overdraw against the
current scene. Repeat with representative concurrent LYRA-Core load only after
permission to inspect or run that system. The last preview used Intel graphics
after NVIDIA initialization failed; RTX 3060 performance remains unverified.
Headless tests or an FPS cap cannot establish that a hardware target passed.

## Integration boundary

Keep the procedural avatar as a fallback and comparison. Place an approved
imported asset under `avatar/assets/lyra/` and wrap it in a separate scene. Keep
source/license records under `assets/`. Resolve large-file storage before adding
model binaries to Git.

Preserve `set_presentation(state)` and `animate(delta)` so the desktop controller
and state machine remain unchanged. Map bone, clip, and morph names explicitly.
Motion stays local to the character; stage position and feet remain stable.

| State | Presentation only |
| --- | --- |
| OFFLINE | Stable neutral pose, no scheduled facial/mouth motion, dim light accents |
| IDLE | Breathing and infrequent blinking |
| LISTENING | Slight attentive pose; input remains simulated |
| THINKING | Small waiting pose reflecting a pending mock request |
| SPEAKING | Current silent mouth simulation until actual audio timing is implemented |
| ERROR | Stop speaking cues; use the existing UI/platform light to show failure |

Cancellation restores neutral mouth controls and stops pending speech cues without
discontinuous body movement. Missing required asset mappings produce a clear
diagnostic; an explicitly supported fallback must not hide import failures.

## Acceptance for the import iteration

1. Record source/version/hash, author, license, attribution, modification rights,
   and runtime redistribution terms before import. Include all hair, clothing,
   textures, rig, and animation licenses.
2. Import offline in pinned Godot 4.7.2. Confirm materials, normals, skeleton,
   morphs, clips, and dependencies survive export.
3. Review the face close-up and the full body in neutral lighting from all four
   preview angles. The user approves the likeness and visual direction.
4. Run existing lifecycle tests. Before implementing the model wrapper, add
   failing integration tests for required mapping validation, cancellation
   resetting speech morphs, and planted-foot continuity. Procedural geometry
   checks cannot substitute for imported-model tests or visual approval.
5. Exercise every state, cancel during speech, recover from error, and toggle
   offline/online. Inspect eyelids, teeth, hair/coat clipping, and loop seams.
6. Record performance separately from functional acceptance; report unverified
   hardware budgets explicitly and distinguish Intel results from RTX results.

## Selection and outstanding decisions

Prefer an editable, licensed human base with verified Godot export and facial
controls, then customize LYRA's face, hair, and outfit. Compare candidates in
this order: license/delivery compatibility, facial quality, rig/morph support,
hair quality, required customization, and measured runtime cost.

See the [free candidate comparison](character-model-candidates.md). Recommend an
MPFB-generated base as the first technical trial; no imported asset is accepted
until the delivery and acceptance checks above pass. Before installing authoring
tools, downloading large assets, or adding model binaries, obtain the approvals
required by `AGENTS.md`. Revisit any paid route only if the user requests it.
