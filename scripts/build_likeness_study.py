"""Create an isolated, reversible Blender face blockout and matched stills.

This is a first sculpt study, not an automatic portrait reconstruction.
Uses the installed Blender toolchain; never exports into the runtime model.
"""
from pathlib import Path
import hashlib
import json
import math
import shutil

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / ".tools/studies/likeness"
MODEL = ROOT / "avatar/assets/lyra/lyra-base.glb"
REFERENCE = Path("/tmp/lyra-reference.png")
if not REFERENCE.is_file():
    REFERENCE = OUT / "reference.png"
REFERENCE_HASH = "9dd93e24ace6f61419534d4b795b0a4ff0bdc330bc61add487bbb38feee2b4fb"

# Centers, radii and displacement are in world meters. Each entry becomes its
# own editable shape key. Bilateral edits use symmetric centers/displacements.
FEATURES = [
    ("Study_CheekHollow", (.047, -.116, 1.438), (.021, .027, .024), (0, .003, 0)),
    ("Study_CheekCrest", (.050, -.112, 1.478), (.022, .027, .016), (.0005, -.0015, .001)),
    ("Study_NoseTip", (0, -.158, 1.450), (.014, .019, .015), (0, -.0025, .0015)),
    ("Study_NoseBase", (.012, -.148, 1.442), (.009, .018, .009), (-.001, 0, 0)),
    ("Study_LipVolume", (0, -.149, 1.419), (.024, .018, .009), (0, -.0018, .0004)),
    ("Study_MouthCorners", (.026, -.132, 1.416), (.010, .020, .011), (0, 0, .0015)),
    ("Study_JawContour", (.046, -.066, 1.391), (.020, .044, .022), (-.0015, 0, 0)),
]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def point_at(obj, point):
    obj.rotation_euler = (Vector(point) - obj.location).to_track_quat("-Z", "Y").to_euler()


def area(name, position, power, size, color):
    light = bpy.data.lights.new(name, "AREA")
    light.energy, light.shape, light.size, light.color = power, "DISK", size, color
    obj = bpy.data.objects.new(name, light)
    bpy.context.collection.objects.link(obj)
    obj.location = position
    point_at(obj, (0, -.04, 1.47))


def add_study_keys(body):
    inverse = body.matrix_world.to_3x3().inverted()
    base = body.data.shape_keys.key_blocks["Basis"]
    coordinates = [body.matrix_world @ v.co for v in base.data]
    affected = {}
    for name, center, radii, movement in FEATURES:
        key = body.shape_key_add(name=name, from_mix=False)
        count = 0
        for index, point in enumerate(coordinates):
            displacement = Vector((0, 0, 0))
            for sign in ((1, -1) if center[0] else (1,)):
                mirrored = Vector((center[0]*sign, center[1], center[2]))
                distance = sum(((point[a]-mirrored[a])/radii[a])**2 for a in range(3))
                if distance > 9:
                    continue
                weight = math.exp(-2.0 * distance)
                displacement += Vector((movement[0]*sign, movement[1], movement[2])) * weight
            key.data[index].co = base.data[index].co + inverse @ displacement
            count += displacement.length > .00001
        key.value = 0
        assert count > 0, f"Study control does not affect the mesh: {name}"
        affected[name] = count
    return affected


def prepare_materials():
    for material in bpy.data.materials:
        if not material.use_nodes:
            continue
        shader = next((n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if shader is None:
            continue
        if material.name.startswith("Skin"):
            shader.inputs["Roughness"].default_value = .53
            shader.inputs["Subsurface Weight"].default_value = .06
            shader.inputs["Subsurface Scale"].default_value = .003
            source = shader.inputs["Base Color"].links[0].from_socket if shader.inputs["Base Color"].is_linked else None
            if source:
                tint = material.node_tree.nodes.new("ShaderNodeMixRGB")
                tint.blend_type = "MULTIPLY"
                tint.inputs[0].default_value = 1
                tint.inputs[2].default_value = (.80, .68, .59, 1)
                material.node_tree.links.new(source, tint.inputs[1])
                material.node_tree.links.new(tint.outputs[0], shader.inputs["Base Color"])
        if material.name.startswith(("SilverHair", "Brows")):
            texture = next((n for n in material.node_tree.nodes if n.type == "TEX_IMAGE"), None)
            if texture is None:
                continue
            ramp = material.node_tree.nodes.new("ShaderNodeValToRGB")
            if material.name.startswith("Brows"):
                ramp.color_ramp.elements[0].color = (.12, .10, .085, 1)
                ramp.color_ramp.elements[1].color = (.28, .24, .20, 1)
            else:
                ramp.color_ramp.elements[0].position = .015
                ramp.color_ramp.elements[0].color = (.045, .055, .075, 1)
                ramp.color_ramp.elements[1].position = .30
                ramp.color_ramp.elements[1].color = (.80, .83, .89, 1)
                ramp.color_ramp.elements.new(.12).color = (.32, .36, .43, 1)
            material.node_tree.links.new(texture.outputs["Color"], ramp.inputs["Fac"])
            material.node_tree.links.new(ramp.outputs["Color"], shader.inputs["Base Color"])


def render(scene, name):
    scene.render.filepath = str(OUT / name)
    bpy.ops.render.render(write_still=True)


def main():
    assert digest(REFERENCE) == REFERENCE_HASH, "Original reference is missing or differs"
    OUT.mkdir(parents=True, exist_ok=True)
    before = {path: digest(path) for path in (MODEL, ROOT / ".tools/authoring/lyra-base.blend")}
    if REFERENCE.resolve() != (OUT / "reference.png").resolve():
        shutil.copyfile(REFERENCE, OUT / "reference.png")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(MODEL))
    body = bpy.data.objects["LyraBody_export"]
    affected = add_study_keys(body)
    prepare_materials()
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 64
    scene.cycles.use_denoising = True
    scene.cycles.seed = 7
    scene.cycles.max_bounces = 5
    scene.render.threads_mode = "FIXED"
    scene.render.threads = 4
    scene.render.resolution_x, scene.render.resolution_y = 768, 960
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "AgX"
    world = bpy.data.worlds.new("StudyWorld")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (.025, .033, .045, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = .12
    scene.world = world
    area("Key", (-.65, -.8, 2.15), 30, .7, (1, .87, .75))
    area("Fill", (.7, -.5, 1.7), 7, .85, (.72, .83, 1))
    area("Rim", (.4, .4, 1.95), 25, .55, (.68, .81, 1))
    camera = bpy.data.objects.new("ReferenceAngle", bpy.data.cameras.new("ReferenceAngle"))
    bpy.context.collection.objects.link(camera)
    camera.location = (-.43, -1.12, 1.53)
    camera.data.lens = 85
    camera.data.clip_start = .01
    point_at(camera, (0, -.045, 1.475))
    scene.camera = camera
    # Reference is embedded for camera-background/manual sculpt review, not
    # projected onto the mesh or included in the rendered character.
    image = bpy.data.images.load(str(OUT / "reference.png"))
    image.pack()
    camera.data.show_background_images = True
    bg = camera.data.background_images.new()
    bg.image, bg.alpha = image, .25
    bg.show_background_image = False
    render(scene, "baseline-angle.png")
    for name, *_ in FEATURES:
        body.data.shape_keys.key_blocks[name].value = 1
    render(scene, "study-angle.png")
    # Additional neutral front view reveals contours without hair or skin color.
    front = camera.copy()
    front.data = camera.data.copy()
    front.name = "FrontContours"
    bpy.context.collection.objects.link(front)
    front.location = (0, -1.20, 1.51)
    point_at(front, (0, -.045, 1.475))
    scene.camera = front
    clay = bpy.data.materials.new("ContourClay")
    clay.diffuse_color = (.35, .35, .35, 1)
    scene.view_layers[0].material_override = clay
    hidden = [o for o in bpy.data.objects if o.type == "MESH" and any(
        token in o.name for token in ("long01", "SweptLocks", "BlueFilaments"))]
    for obj in hidden:
        obj.hide_render = True
    render(scene, "study-front-clay.png")
    for obj in hidden:
        obj.hide_render = False
    scene.view_layers[0].material_override = None
    scene.camera = camera
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    body.active_shape_key_index = len(body.data.shape_keys.key_blocks)-1
    for screen in bpy.data.screens:
        for area_view in screen.areas:
            if area_view.type == "VIEW_3D":
                area_view.spaces.active.region_3d.view_perspective = "CAMERA"
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "lyra-face-study.blend"))
    manifest = {
        "status": "first reversible face blockout; likeness not approved",
        "runtime_model_sha256": before[MODEL], "reference_sha256": REFERENCE_HASH,
        "reference_url": "https://github.com/JohnGwinnDEV/rixinteractive-site/blob/main/LYRAIMage.png",
        "camera": {"location": list(camera.location), "lens_mm": camera.data.lens,
                   "target": [0, -.045, 1.475], "note": "estimated from portrait; not recovered calibration"},
        "controls": [{"name": n, "center_m": c, "radii_m": r, "displacement_m": m,
                      "affected_vertices": affected[n]} for n, c, r, m in FEATURES],
        "render": {"engine": "Cycles CPU", "samples": 64, "seed": 7, "resolution": [768, 960]},
    }
    (OUT / "study.json").write_text(json.dumps(manifest, indent=2)+"\n")
    shutil.copyfile(ROOT / "scripts/likeness_review.html", OUT / "review.html")
    for path, original in before.items():
        assert digest(path) == original, f"Runtime prototype changed: {path}"
    print("STUDY COMPLETE: isolated Blender source and three renders; runtime files unchanged.")


if __name__ == "__main__":
    main()
