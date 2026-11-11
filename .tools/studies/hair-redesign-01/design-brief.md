# Hair redesign 01 — expected behavior

Status: proposed acceptance criteria, awaiting visual approval. This document
does not authorize geometry work, renders, runtime export, or commits.

## Intent

Replace the cap-and-ribbon appearance with a believable layered hairstyle
that preserves the supplied portrait's swept silver hair and woven blue fibers.
The approved face is immutable. The reference portrait is authoritative for
visible features; unseen sides and back remain design interpretations.

## First visual milestone

Review primary masses, root direction, parting, and silhouette in neutral Solid
view before adding fine strands, emission, or polished materials.

- Follow the reference's off-centre frontal sweep; identify directions in the
  reference camera rather than guessing anatomical left/right from the image.
- Roots rise softly from the forehead and turn back into the sweep. Crown
  volume is asymmetric and controlled, with no smooth helmet-shaped dome.
- A gently irregular hairline transitions through small root clumps at the
  forehead and temples. No exposed continuous dark cap strip is acceptable.
- Primary clumps overlap in depth and vary in width and curvature. Avoid
  parallel, equally spaced ribbons and identical wave timing.
- Preserve long flowing hair over and behind the shoulders, with staggered
  tips and selected face-framing strands. Keep eyes, brows, and mouth readable.
- Match reference-angle framing before judging silhouette. Other required
  inspection views: front, both profiles, back, and a slightly elevated crown.
- Back and hidden-side arrangement require user review, not a likeness claim.

## Later surface milestone

Use a concealed scalp foundation, shaped mesh clumps, sparse root/edge/tip
cards, and selected integrated fiber accents. Silver is dominant; slate roots
and underlayers provide depth. Blue follows the same root-to-tip flow and must
not resemble separate cables. Hair must remain readable with emission off.
Avoid bright metallic sheets, uniform glow, dense flyaways, and geometric
light beads where a texture can provide the effect.

## Preservation and technical acceptance

- Check the protected hashes in baseline-manifest.json before and after work.
- Preserve approved body geometry, facial shape-key coordinates and values,
  existing studies, rig, and runtime GLB. Make no LYRA-Core changes.
- Root foundation should stay within 3 mm of its designated scalp region;
  exclude deliberately lifted clumps from that proximity rule.
- Validate root emergence and growth direction visually; proximity alone
  cannot establish believable attachment.
- Check hair/skin/ear/coat clearances in neutral pose and a provisional pose
  envelope: head yaw +/-30 degrees, pitch +/-15 degrees, roll +/-10 degrees.
  These are study checks, not approved runtime motion limits.
- Keep roots attached to the head. Design hanging sections for later explicit
  deformation controls; rigid head weighting alone is not the final solution.
- Initial complete-hair target: 20,000–30,000 triangles and about three material
  surfaces. Reduced version target: 8,000–12,000 triangles. These are proposed
  budgets; measure actual counts and seek review before exceeding them.
- Start textures at 1K. Judge cutout stability, overdraw, and frame time during
  separately approved Godot integration. Do not claim performance from counts.

## Lightweight review constraints

Use one Solid viewport first, no simulation and no live rendered preview.
Only after render approval: small CPU stills, initially 384 x 480 at 8–16
samples with limited threads, one at a time. No GPU stress test is part of
this study. The reported PCIe fault remains unresolved by asset changes.

## Next process gate

Intent and expected behavior are documented. Next establish preservation and
geometry checks, starting with a meaningful failing check where feasible.
Visual quality requires user inspection separately from automated checks.
Implementation follows only after explicit approval of the design plan.
Execute -> Observe -> Verify -> Reflect -> Commit remains the subsequent
sequence; committing requires separate approval.
