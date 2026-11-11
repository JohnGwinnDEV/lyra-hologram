"""Prepare independent eye joints and smoother close-up geometry in Blender."""
import bpy
import bmesh
import math
from mathutils import Vector
from bl_ext.lyra_local.mpfb.services.targetservice import TargetService


def prepare_eyes(rig):
    eyes = next(obj for obj in rig.children_recursive if "high-poly" in obj.name)
    results = []
    for label, sign, bone_name in (("EyeLeft", 1, "eye_l"), ("EyeRight", -1, "eye_r")):
        obj = eyes.copy()
        obj.data = eyes.data.copy()
        obj.name = label
        bpy.context.collection.objects.link(obj)
        mesh = bmesh.new()
        mesh.from_mesh(obj.data)
        bmesh.ops.delete(mesh, geom=[vertex for vertex in mesh.verts if vertex.co.x * sign < 0], context="VERTS")
        mesh.to_mesh(obj.data)
        mesh.free()
        coordinates = [rig.matrix_world.inverted() @ obj.matrix_world @ vertex.co for vertex in obj.data.vertices]
        center = Vector(tuple((min(p[axis] for p in coordinates) + max(p[axis] for p in coordinates)) * .5 for axis in range(3)))
        results.append((obj, bone_name, center))
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for _obj, name, center in results:
        bone = rig.data.edit_bones.new(name)
        bone.head = center
        bone.tail = center + Vector((0, -.02, 0))
        bone.parent = rig.data.edit_bones["head"]
    bpy.ops.object.mode_set(mode="OBJECT")
    for obj, name, _center in results:
        obj.vertex_groups.clear()
        group = obj.vertex_groups.new(name=name)
        group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    bpy.data.objects.remove(eyes, do_unlink=True)


def smooth_hair(rig):
    hair = next(obj for obj in rig.children_recursive if "long01" in obj.name)
    bpy.context.view_layer.objects.active = hair
    bpy.ops.object.select_all(action="DESELECT")
    hair.select_set(True)
    if hair.data.shape_keys:
        TargetService.bake_targets(hair)
    modifier = hair.modifiers.new("Portrait hair smoothing", "SUBSURF")
    modifier.levels = modifier.render_levels = 1
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def style_reference_hair(rig):
    """Give the existing hair volume, waves, and an asymmetric swept crown."""
    hair = next(obj for obj in rig.children_recursive if "long01" in obj.name)
    for vertex in hair.data.vertices:
        point = vertex.co
        height = point.z
        original_x = point.x
        side = 1 if original_x >= 0 else -1
        crown = max(0.0, min(1.0, (height - 1.46) / .15))
        fall = max(0.0, min(1.0, (1.5 - height) / .35))
        # Add volume about the head center; the swept locks provide the part.
        point.x = original_x * (1.22 + .08 * fall)
        point.x += side * .010 * math.sin((height - .9) * 20 + side) * fall
        point.y -= .014 * crown
        point.y += .010 * math.sin(height * 18 + original_x * 8) * fall
        point.z += .032 * crown * max(0, 1 - (original_x / .22) ** 2)
        if point.y < -.025 and abs(original_x) > .075 and height < 1.4:
            point.y -= .04 * fall
    hair.data.update()
