"""Reproduce the first CC0 MPFB human-base trial using the isolated toolchain."""
from pathlib import Path
import hashlib
import json
import shutil
import sys

import bpy
from mathutils import Vector
from bl_ext.lyra_local.mpfb.services.humanservice import HumanService
from bl_ext.lyra_local.mpfb.services.targetservice import TargetService
from bl_ext.lyra_local.mpfb.services.rigservice import RigService
from bl_ext.lyra_local.mpfb.services.faceservice import FaceService
from bl_ext.lyra_local.mpfb.services.exportservice import ExportService
from bl_ext.lyra_local.mpfb.services.objectservice import ObjectService
from bl_ext.lyra_local.mpfb.services.locationservice import LocationService

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from lyra_details import build_details
from lyra_portrait import prepare_eyes, smooth_hair, style_reference_hair
OUTPUT = ROOT / "avatar/assets/lyra/lyra-base.glb"
SOURCE = ROOT / ".tools/authoring/lyra-base.blend"
DATA = Path(LocationService.get_user_data())
MORPHS = ["eyeBlinkLeft", "eyeBlinkRight", "jawOpen", "mouthSmileLeft", "mouthSmileRight"]
PRESET = {
    "name": "Lyra", "rig": "game_engine", "proxy": "",
    "phenotype": {
        "gender": 0.0, "age": 0.63, "height": 0.5, "weight": 0.43,
        "muscle": 0.45, "proportions": 0.5, "cupsize": 0.5, "firmness": 0.5,
        "race": {"african": 0.0, "asian": 0.0, "caucasian": 1.0},
    },
    "targets": [
        {"target": "l-cheek-bones-incr", "value": 0.60},
        {"target": "r-cheek-bones-incr", "value": 0.60},
        {"target": "l-cheek-volume-decr", "value": 0.35},
        {"target": "r-cheek-volume-decr", "value": 0.35},
        {"target": "chin-bones-incr", "value": 0.22},
        {"target": "chin-width-decr", "value": 0.18},
        {"target": "head-fat-decr", "value": 0.18},
        {"target": "head-square", "value": 0.14},
        {"target": "head-scale-horiz-decr", "value": 0.10},
        {"target": "nose-scale-horiz-decr", "value": 0.22},
        {"target": "nose-width1-decr", "value": 0.22},
        {"target": "nose-width2-decr", "value": 0.18},
        {"target": "nose-point-width-decr", "value": 0.15},
        {"target": "nose-base-up", "value": 0.05},
        {"target": "mouth-upperlip-volume-incr", "value": 0.50},
        {"target": "mouth-lowerlip-volume-incr", "value": 0.35},
        {"target": "mouth-upperlip-height-incr", "value": 0.18},
        {"target": "mouth-cupidsbow-incr", "value": 0.12},
        {"target": "mouth-angles-up", "value": 0.10},
        {"target": "mouth-scale-horiz-decr", "value": 0.08},
        {"target": "l-eye-height1-decr", "value": 0.12},
        {"target": "r-eye-height1-decr", "value": 0.12},
        {"target": "l-eye-height2-decr", "value": 0.08},
        {"target": "r-eye-height2-decr", "value": 0.08},
        {"target": "l-eye-corner2-up", "value": 0.08},
        {"target": "r-eye-corner2-up", "value": 0.08},
    ], "clothes": ["female_casualsuit01/female_casualsuit01.mhclo", "shoes01/shoes01.mhclo"],
    "eyes": "high-poly/high-poly.mhclo", "eyes_material_type": "MAKESKIN",
    "eyes_material_settings": {}, "eyebrows": "eyebrow003/eyebrow003.mhclo",
    "eyelashes": "eyelashes01/eyelashes01.mhclo", "hair": "long01/long01.mhclo",
    "teeth": "teeth_base/teeth_base.mhclo", "tongue": "tongue01/tongue01.mhclo",
    "skin_mhmat": "middleage_caucasian_female/middleage_caucasian_female.mhmat",
    "skin_material_type": "MAKESKIN", "skin_material_settings": {}, "color_adjustments": {},
}


def portable_material(name, color=(1, 1, 1, 1), image=None, alpha=False, glow=0.0):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    material.diffuse_color = color
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Roughness"].default_value = 0.65
    if glow:
        shader.inputs["Emission Color"].default_value = color
        shader.inputs["Emission Strength"].default_value = glow
    if image:
        texture = material.node_tree.nodes.new("ShaderNodeTexImage")
        texture.image = bpy.data.images.load(str(image), check_existing=True)
        material.node_tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])
        if alpha:
            material.node_tree.links.new(texture.outputs["Alpha"], shader.inputs["Alpha"])
            material.surface_render_method = "DITHERED"
    material.use_backface_culling = not alpha
    return material


def replace_material(obj, material):
    obj.data.materials.clear()
    obj.data.materials.append(material)
    for polygon in obj.data.polygons:
        polygon.material_index = 0
        polygon.use_smooth = True


def set_arm_direction(rig, name, direction):
    bone = rig.pose.bones[name]
    current = (bone.tail - bone.head).normalized()
    rotation = current.rotation_difference(Vector(direction).normalized())
    matrix = rotation.to_matrix().to_4x4() @ bone.matrix
    matrix.translation = bone.matrix.translation.copy()
    bone.matrix = matrix
    bpy.context.view_layer.update()


def build():
    assert bpy.app.version[:2] == (4, 5), bpy.app.version_string
    for pack in ("makehuman_system_assets", "faceunits01"):
        metadata = json.loads((DATA / "packs" / (pack + ".json")).read_text())
        assert {item["license"] for item in metadata.values()} == {"CC0"}
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    settings = HumanService.get_default_deserialization_settings()
    settings.update(subdiv_levels=0, override_skin_model="MAKESKIN", override_eyes_model="MAKESKIN")
    body = HumanService.deserialize_from_dict(PRESET, settings)
    rig = body.parent
    rig.name = "LyraRig"
    for side, sign in (("l", 1), ("r", -1)):
        set_arm_direction(rig, "upperarm_" + side, (sign * 0.16, 0, -1))
        set_arm_direction(rig, "lowerarm_" + side, (sign * 0.02, -0.08, -1))
    # Bake the chosen body shape and standing arm pose before adding facial keys.
    RigService.apply_pose_as_rest_pose(rig)
    for name in MORPHS:
        TargetService.load_target(body, str(DATA / "targets/faceunits" / (name + ".target")), name=name)
    FaceService.interpolate_targets(body)
    prepare_eyes(rig)
    smooth_hair(rig)
    style_reference_hair(rig)
    materials = {
        "Basemesh": portable_material("Skin", image=DATA / "skins/middleage_caucasian_female/middleage_lightskinned_female_diffuse.png"),
        "Clothes": portable_material("NavyOutfit", (0.035, 0.065, 0.11, 1)),
        "Eyes": portable_material("SilverBlueEyes", image=DATA / "eyes/materials/blue_eye.png", alpha=True),
        "Hair": portable_material("SilverHair", (0.58, 0.63, 0.72, 1), DATA / "hair/long01/long01_diffuse.png", alpha=True),
        "Eyebrows": portable_material("Brows", image=DATA / "eyebrows/eyebrow003/eyebrow003.png", alpha=True),
        "Eyelashes": portable_material("Lashes", image=DATA / "eyelashes/eyelashes01/eyelashes01.png", alpha=True),
        "Teeth": portable_material("Teeth", (0.8, 0.77, 0.7, 1)),
        "Tongue": portable_material("MouthInterior", (0.27, 0.085, 0.09, 1)),
    }
    for obj in rig.children_recursive:
        if obj.type != "MESH":
            continue
        kind = ObjectService.get_object_type(obj)
        if kind in materials:
            replace_material(obj, materials[kind])
        if kind == "Clothes":
            obj.name = "Outfit" if "shoes" not in obj.name.lower() else "Boots"
    body.name = "LyraBody"
    body.data.name = "LyraBody_source"
    details = build_details(rig, portable_material)
    for obj in rig.children_recursive:
        if obj.type == "MESH":
            obj.data.name = obj.name + "_source"
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
    (ROOT / "assets/lyra-base-preset.json").write_text(json.dumps(PRESET, indent=2) + "\n")

    # Keep the editable character intact; helper/mask cleanup affects the copy.
    export_rig = ExportService.create_character_copy(body, name_suffix="_export")
    export_body = ObjectService.find_object_of_type_amongst_nearest_relatives(export_rig)
    ExportService.bake_modifiers_remove_helpers(export_body, bake_masks=True, bake_subdiv=False, remove_helpers=True)
    modifier = export_body.modifiers.new("Portrait face smoothing", "SUBSURF")
    modifier.levels = modifier.render_levels = 1
    ExportService._apply_modifiers_keep_shapekeys(export_body, [modifier.name])
    exported = {export_rig, *export_rig.children_recursive}
    bpy.ops.object.select_all(action="DESELECT")
    for obj in exported:
        obj.select_set(True)
        if obj.type == "MESH":
            obj.data.name = obj.name.removesuffix("_export")
            for key in obj.data.shape_keys.key_blocks if obj.data.shape_keys else []:
                key.value = 0.0
    bpy.context.view_layer.objects.active = export_rig
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUTPUT), export_format="GLB", use_selection=True,
        export_animations=False, export_morph=True, export_morph_normal=True,
        export_skins=True, export_def_bones=True, export_apply=False)
    digest = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    inputs = [
        ("blender-4.5.15-linux-x64.tar.xz", "https://ftp.nluug.nl/pub/graphics/blender/release/Blender4.5/blender-4.5.15-linux-x64.tar.xz", "GPL-3.0-or-later"),
        ("mpfb-v2.0.18.zip", "https://github.com/makehumancommunity/mpfb2/archive/refs/tags/v2.0.18.zip", "GPL-3.0-or-later code; CC0-1.0 assets"),
        ("core-assets-alt.zip", "https://files.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip", "CC0-1.0"),
        ("faceunits01.zip", "https://files.makehumancommunity.org/functional/faceunits01.zip", "CC0-1.0"),
    ]
    manifest = {
        "asset_license": "CC0-1.0", "status": "rigged LYRA character study; appearance still provisional",
        "blender_version": bpy.app.version_string, "mpfb_version": "2.0.18",
        "output_sha256": digest(OUTPUT), "output_bytes": OUTPUT.stat().st_size,
        "facial_controls": MORPHS, "bone_count": len(export_rig.data.bones),
        "authored_details": details,
        "inputs": [{"file": name, "url": url, "license": license, "sha256": digest(ROOT / ".tools/downloads" / name)}
                   for name, url, license in inputs],
        "credits": ["MakeHuman Community core assets", "Mika Suominen: faceunits01"],
        "used_assets": [PRESET[key] for key in ("skin_mhmat", "hair", "eyes", "eyebrows", "eyelashes", "teeth", "tongue")] + PRESET["clothes"],
    }
    (ROOT / "assets/lyra-base-provenance.json").write_text(json.dumps(manifest, indent=2) + "\n")
    licenses = ROOT / "assets/licenses"
    licenses.mkdir(exist_ok=True)
    shutil.copyfile(ROOT / ".tools/authoring/mpfb2-2.0.18/LICENSE.ASSETS.md", licenses / "mpfb-assets-CC0.md")
    print("LYRA_GLTF_EXPORT", json.dumps({"bytes": OUTPUT.stat().st_size, "bones": len(export_rig.data.bones), "morphs": MORPHS}))


build()
