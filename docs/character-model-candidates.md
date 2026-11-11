# Free character-model candidates

Reviewed 2026-11-10 against the [model brief](character-model-spec.md).

Follow-up: the approved [MPFB human-base trial](rigged-preview.md) is now built
and tested locally. The comparison below records the selection research before
that trial; its unverified-export caveats describe that earlier review.

## Recommendation

Evaluate **Blender with MPFB 2.0.18** first. It provides an editable human base
and documented rigging/facial-export features, avoiding further anatomy work
with primitive meshes. This is a recommended authoring route, not a downloaded,
finished LYRA model. No paid tools, subscription, commission, or purchase is
planned. Blender and MakeHuman were not found on the current session's PATH.

The comparison below is based on official documentation and asset listings.
No binary was downloaded, installed, imported, or benchmarked for this review.
Engineering effort estimates are judgments, not vendor promises or quotations.

| Candidate | Documented source/license | Fit for LYRA | Remaining work / judgment | Decision |
| --- | --- | --- | --- | --- |
| MPFB-generated human in Blender | Free generator; GPL software, CC0 core graphics assets [1–3] | Adjustable human features, automatic rigs, skin/eye materials; export tooling supports facial shape keys [2–4] | Customize mature face, silver hair, coat, and blue accents; prepare portable materials; verify rig/morph GLB export. Moderate work for the first human-base trial; substantial work for reference likeness | First trial |
| Blender Studio Human Base Meshes | Official demo listing identifies Human Base Meshes v1.4.1 as CC0 [5] | Editable anatomy base with freedom to sculpt LYRA | An asset bundle, not verified here as a clothed, animated Godot character. Confirm contents, then supply missing rig, facial controls, materials, hair, clothing, and clips. More custom authoring expected | Backup if the MPFB face/topology is unsuitable |
| Blender Studio Rain rig, documented v1 | Official character listing identifies the rig as free under CC-BY and specifies credit [6] | Existing human character rig useful as an animation reference | The linked release belongs to a stylized-character workflow. Different face/hair/outfit, and Blender rig controls do not establish GLB compatibility. Significant redesign/export work expected | Do not use as LYRA's base; it works against the requested visual direction |

MakeHuman standalone shares the same community asset ecosystem; it is an
alternative creation workflow rather than a separate visual candidate. MPFB
does not require a separate MakeHuman installation [3].

## Why MPFB first

The official extension listing reports version 2.0.18 and compatibility with
Blender 4.2 LTS or newer [2]. The getting-started guide documents parameter
editing, a standard rig, and fitting hair/clothing after rig creation [3].
The export-copy guide describes facial-animation shape keys and optional
viseme/face-unit packs [4]. These are relevant capabilities, not evidence that
a particular exported character already satisfies our Godot tests.

The community's license page distinguishes GPL MPFB code from CC0 core assets
[1]. Do not generalize CC0 to every community hair, clothing, texture, or morph
download. Read the license shipped with each selected pack and preserve its
provenance before import. No software from the authoring tool needs to be
embedded in the LYRA-Hologram runtime.

## Concrete first trial

1. With dependency/download approval, install a pinned compatible Blender
   release and MPFB 2.0.18 locally under the ignored `.tools/` directory. Record
   download sources, exact versions, hashes, and asset licenses. Do not change
   system packages or connect to a running MakeHuman service.
2. Obtain only the free core assets needed for skin, eyes, teeth, and basic
   clothing, plus the facial pack required for independent blinking and jaw
   opening. Confirm pack availability and licenses before using them; exact
   download sizes and archive contents remain unverified.
3. Create an editable LYRA human preset and a clothed neutral preview. Review
   head/face proportions and the silhouette before detailed hair/coat work.
4. Export a small GLB proof with skeleton, eye blinks, jaw opening, and neutral
   materials. Bake procedural material features into supported textures where
   necessary. Preserve facial controls while resolving modeling shape keys.
5. Verify the GLB in a separate Godot scene before replacing the current avatar.
   Use failing mapping/cancellation/pose tests before writing its wrapper. If
   skin, rig, or morph export fails, report the failure instead of substituting
   a static image or claiming a working character.
6. After the human-base trial passes, develop silver hair, controlled blue
   emission, the coat, and breathing/blink animations toward the reference.

The first success criterion is a working, editable human-base import with
facial controls. It is not a promise of immediate photorealism. Preserve the
current runnable prototype throughout this trial. Runtime resource budgets and
RTX performance remain unverified until measured on the imported asset.

## Official sources

1. [MakeHuman/MPFB split license](https://www.makehumancommunity.org/about/license.html).
2. [MPFB extension, version and compatibility](https://extensions.blender.org/add-ons/mpfb/).
3. [MPFB getting started, prerequisites and rigging](https://static.makehumancommunity.org/mpfb/docs/getting_started.html).
4. [MPFB export copy and facial shape keys](https://www.makehumancommunity.org/mpfb/docs/exporting/export_copy.html).
5. [Blender official demo files and asset bundles](https://www.blender.org/download/demo-files/).
6. [Blender Studio Rain v1, license and credit](https://studio.blender.org/characters/rain/v1/).

Some direct page fetches timed out or were unavailable during this review;
official indexed listings supplied the license/release information in those
cases. Actual archive contents and packaged licenses must be checked at download.
