# LYRA-Hologram — Agent Instructions

## Scope and authority
- Build LYRA's replaceable embodiment/input/output adapter.
- LYRA-Core owns identity, reasoning, memory, planning, ethics, and decisions.
- Keep both repositories and processes independent.
- Inspect LYRA-Core interfaces only with permission; never modify its files
  without separately approved scope.
- Use mocked LYRA responses for the first MVP.
- Treat the kickoff prompt v0.2 as provisional scope until the design
  specification is supplied. Report conflicts rather than inventing details.

## Architecture
- LYRAIMage.png supplied by the user is the appearance/likeness target. Match
  the face and swept silver fiber-optic hair, not only the palette and props.
  See docs/likeness-review.md; passing tests does not establish visual likeness.
- Keep state logic deterministic and independent of rendering and devices.
- Use small, explicit, versioned contracts and validate boundary inputs.
- THINKING means request pending; LISTENING must not imply an active microphone.
- Make rendering, speech, and hardware backends replaceable where useful.
- Prefer offline operation and avoid speculative abstractions.
- Reject invalid transitions without mutation.
- Make cancellation idempotent and ignore callbacks from cancelled work.
- Surface failures explicitly; recover only after readiness checks.

## Repository conventions
- Proposed layout: avatar/, avatar/tests/, docs/, assets/.
- Document event contracts in docs/contracts/v1.md.
- Keep changes focused, reversible, and within approved scope.
- Record asset provenance and licenses before adding assets.
- Do not add credentials, generated caches, or large generated assets.

## Mandatory iteration protocol
Intent → Expected Behavior → Test → Implementation → Execute →
Observe → Verify → Reflect → Commit

- Start with the smallest failing automated test wherever feasible.
- Use deterministic fakes for clocks, adapters, and audio in logic tests.
- Report commands, actual results, deviations, and unresolved questions.
- Never claim tests passed unless executed.
- Commit is approval-gated, even after verification.

## Testing
- Godot 4.7.2 is installed locally in the ignored .tools/ directory.
- Run the verified headless suite from the repository root:
  bash scripts/test.sh
- The script keeps runtime data, configuration, and caches inside .tools/.
- The suite includes state-machine tests and desktop scene/control integration.
- Launch the desktop preview with: bash scripts/run.sh
- Launch the separate rigged human-base trial with: bash scripts/run_rigged.sh
- Launch the local video-call portrait with: bash scripts/run_portrait.sh
- Run strict asset/import tests with: bash scripts/test_rigged.sh
- Approved authoring tools are isolated under .tools/: Blender 4.5.15 LTS,
  MPFB 2.0.18, CC0 core assets, and faceunits01. Rebuild instructions and
  remaining visual/performance limits are in docs/rigged-preview.md.
- Keep generated GLB binaries local and ignored until storage is agreed.
- The close-up model has 55 bones including independent eyes. Runtime hair
  recoloring and portrait skin detail use repository shaders. See
  docs/portrait-preview.md for limits and the recorded geometry-budget exception.
- Verify visual rendering and physical audio separately from headless logic.

## Approval and safety
- Do not commit, push, install dependencies, create large generated assets,
  or modify LYRA-Core without explicit approval.
- Do not install Godot or Unity without approval.
- Do not activate microphones, cameras, or robotic motion in MVP 1.
- Future sensing or motion requires explicit permission, visible status,
  and independent safety controls.
- Provide reliable audio stop/cancel behavior.
- Plan device selection and playback timing without prematurely adding
  TTS, echo cancellation, or hardware control.
- Assume other processes may compete for GPU, CPU, and RAM.
- Do not assume control of another Codex session or repository.
- Treat tabletop optics as hardware-dependent; do not promise life-sized,
  omnidirectional, free-floating projection.
