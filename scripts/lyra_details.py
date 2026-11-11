"""Authored LYRA additions using the existing rig and hair surface."""
import math
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree


class MeshBuilder:
    def __init__(self):
        self.vertices = []
        self.faces = []
        self.weights = []

    def vertex(self, point, weights):
        self.vertices.append(tuple(point))
        self.weights.append(weights)
        return len(self.vertices) - 1

    def tube(self, points, radius, weights, sides=6, taper=False, flatten=1.0):
        if len(points) < 2:
            return
        start = len(self.vertices)
        for index, point in enumerate(points):
            tangent = (points[min(index + 1, len(points) - 1)] - points[max(0, index - 1)]).normalized()
            right = tangent.cross(Vector((0, 1, 0)))
            if right.length < 0.01:
                right = tangent.cross(Vector((1, 0, 0)))
            right.normalize()
            up = tangent.cross(right).normalized()
            width = radius
            if taper:
                width *= .15 + .85 * math.sin(math.pi * index / (len(points)-1)) ** .4
            for side in range(sides):
                angle = math.tau * side / sides
                self.vertex(point + width * (right * math.cos(angle) + up * math.sin(angle) * flatten), weights)
            if index:
                for side in range(sides):
                    a = start + (index - 1) * sides + side
                    b = start + (index - 1) * sides + (side + 1) % sides
                    c = start + index * sides + (side + 1) % sides
                    d = start + index * sides + side
                    self.faces.append((a, b, c, d))

    def light_point(self, center, radius, weights):
        start = len(self.vertices)
        for offset in [(radius, 0, 0), (-radius, 0, 0), (0, radius, 0), (0, -radius, 0), (0, 0, radius), (0, 0, -radius)]:
            self.vertex(center + Vector(offset), weights)
        for top in [4, 5]:
            for a, b in [(0, 2), (2, 1), (1, 3), (3, 0)]:
                self.faces.append(tuple(start + index for index in ((top, a, b) if top == 4 else (top, b, a))))

    def object(self, name, rig, material, thickness=0.0, smoothing=0, surface_fit=None):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(self.vertices, [], self.faces)
        mesh.update()
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        obj.parent = rig
        mesh.materials.append(material)
        for polygon in mesh.polygons:
            polygon.use_smooth = True
        groups = {}
        for index, weights in enumerate(self.weights):
            for bone, value in weights.items():
                if value <= 0:
                    continue
                if bone not in groups:
                    assert bone in rig.data.bones, bone
                    groups[bone] = obj.vertex_groups.new(name=bone)
                groups[bone].add([index], value, "REPLACE")
        if smoothing or thickness:
            bpy.ops.object.select_all(action="DESELECT")
            obj.select_set(True)
            bpy.context.view_layer.objects.active = obj
        if smoothing:
            modifier = obj.modifiers.new("Soft tailoring", "SMOOTH")
            modifier.factor = .55
            modifier.iterations = smoothing
            bpy.ops.object.modifier_apply(modifier=modifier.name)
        if surface_fit:
            for vertex in obj.data.vertices:
                vertex.co = surface_fit(vertex.co, self.weights[vertex.index])
            obj.data.update()
        if thickness:
            modifier = obj.modifiers.new("Fabric thickness", "SOLIDIFY")
            modifier.thickness = thickness
            modifier.offset = 0
            bpy.ops.object.modifier_apply(modifier=modifier.name)
        modifier = obj.modifiers.new("Armature", "ARMATURE")
        modifier.object = rig
        return obj


def spine_weights(height):
    anchors = [(0.84, "pelvis"), (0.94, "spine_01"), (1.04, "spine_02"), (1.18, "spine_03")]
    if height <= anchors[0][0]:
        return {anchors[0][1]: 1.0}
    for (low, lower), (high, upper) in zip(anchors, anchors[1:]):
        if height <= high:
            factor = (height - low) / (high - low)
            return {lower: 1 - factor, upper: factor}
    return {"spine_03": 1.0}


def smooth_path(points, steps=3):
    result = []
    for index in range(len(points) - 1):
        a = points[max(index - 1, 0)]
        b = points[index]
        c = points[index + 1]
        d = points[min(index + 2, len(points) - 1)]
        for step in range(steps):
            t = step / steps
            result.append(0.5 * ((2 * b) + (-a + c) * t + (2*a - 5*b + 4*c - d) * t*t + (-a + 3*b - 3*c + d) * t*t*t))
    result.append(points[-1])
    return result


def build_coat(rig, silver, trim):
    coat = MeshBuilder()
    outfit = next(obj for obj in rig.children_recursive if obj.name == "Outfit")
    tree = BVHTree.FromObject(outfit, bpy.context.evaluated_depsgraph_get())
    inverse = outfit.matrix_world.inverted()

    def clear_outfit(point, clearance=.012):
        # Push the shell beyond the actual shirt/trouser surface at each section.
        center = Vector((0, -.025, point.z))
        radial = Vector((point.x, point.y + .025, 0)).normalized()
        origin = center + radial * .48
        direction = (inverse.to_3x3() @ -radial).normalized()
        hit, _normal, _index, _distance = tree.ray_cast(inverse @ origin, direction, .475)
        if hit is not None:
            surface = outfit.matrix_world @ hit
            distance = (surface - center).dot(radial) + clearance
            if distance > (point - center).dot(radial):
                return center + radial * distance
        return point
    # Height, width, front depth, back depth, front opening angle.
    controls = [
        (0.34, 0.245, 0.17, 0.12, 0.72), (0.55, 0.225, 0.17, 0.11, 0.65),
        (0.75, 0.198, 0.16, 0.10, 0.55), (0.89, 0.185, 0.165, 0.09, 0.45),
        (1.00, 0.155, 0.157, 0.06, 0.42), (1.10, 0.167, 0.165, 0.06, 0.42),
        (1.20, 0.188, 0.178, 0.07, 0.43), (1.28, 0.193, 0.135, 0.075, 0.45),
        (1.32, 0.145, 0.10, 0.065, 0.55), (1.35, 0.073, 0.061, 0.043, 0.70),
    ]
    rings = []
    for a, b in zip(controls, controls[1:]):
        for step in range(4):
            t = step / 4
            # Ease the garment profile rather than making straight conical bands.
            eased = t * t * (3 - 2*t)
            rings.append((a[0] * (1-t) + b[0] * t,) +
                         tuple(x * (1-eased) + y * eased for x, y in zip(a[1:], b[1:])))
    rings.append(controls[-1])
    sides = 64
    for row, (height, width, front, back, gap) in enumerate(rings):
        for side in range(sides + 1):
            theta = gap + (math.tau - 2 * gap) * side / sides
            c = math.cos(theta)
            point = Vector((width * math.sin(theta), -(front if c >= 0 else back) * c, height))
            # Very shallow vertical folds keep the long skirt from reading as a cone.
            point.y += math.sin(theta * 7) * 0.002 * max(0, 1.0 - height)
            point = clear_outfit(point)
            coat.vertex(point, spine_weights(height))
            if row and side < sides:
                a = (row - 1) * (sides + 1) + side
                b = a + 1
                d = row * (sides + 1) + side
                coat.faces.append((a, b, d + 1, d))
    for side, sign in (("l", 1), ("r", -1)):
        shoulder = rig.pose.bones["upperarm_" + side].head.copy()
        elbow = rig.pose.bones["lowerarm_" + side].head.copy()
        wrist = rig.pose.bones["hand_" + side].head.copy()
        centers = [shoulder + Vector((-sign*.012, 0, .030)),
                   shoulder + Vector((0, 0, .012)), shoulder + Vector((sign*.004, 0, -.012)),
                   shoulder.lerp(elbow, .3), shoulder.lerp(elbow, .65),
                   elbow, elbow.lerp(wrist, .45), wrist]
        radii = [.030, .052, .063, .058, .050, .045, .040, .032]
        start = len(coat.vertices)
        segments = 20
        for row, (center, radius) in enumerate(zip(centers, radii)):
            tangent = (centers[min(row + 1, len(centers)-1)] - centers[max(0, row-1)]).normalized()
            right = tangent.cross(Vector((0, 1, 0))).normalized()
            up = tangent.cross(right).normalized()
            weights = {"upperarm_" + side: 1.0} if row < 5 else {"lowerarm_" + side: 1.0}
            if row < 2:
                weights = {"spine_03": .65, "upperarm_" + side: .35}
            if row == 5:
                weights = {"upperarm_" + side: .5, "lowerarm_" + side: .5}
            for column in range(segments):
                theta = math.tau * column / segments
                point = center + radius * (right * math.cos(theta) + up * math.sin(theta))
                # Arm rings fit around the arm, not a radial ray from the spine.
                # A spine-centered ray can hit the opposite part of a shoulder
                # and stretch the cap into a point.
                coat.vertex(point, weights)
                if row:
                    a = start + (row-1) * segments + column
                    b = start + (row-1) * segments + (column+1) % segments
                    c = start + row * segments + (column+1) % segments
                    d = start + row * segments + column
                    coat.faces.append((a, b, c, d))
        # Tessellated lapels follow the clothed chest instead of floating out.
        shell_tree = BVHTree.FromPolygons(coat.vertices, coat.faces)

        def fit_lapel(point, clearance=.012):
            point = clear_outfit(point)
            hit, _normal, _face, _distance = shell_tree.ray_cast(
                Vector((point.x, -.5, point.z)), Vector((0, 1, 0)), .7)
            if hit is not None:
                point.y = min(point.y, hit.y - clearance)
            return point

        start = len(coat.vertices)
        corners = [Vector((sign*.052, -.071, 1.342)), Vector((sign*.116, -.11, 1.294)),
                   Vector((sign*.074, -.16, 1.15)), Vector((sign*.038, -.155, 1.23))]
        columns = 5
        rows = 12
        for row in range(rows + 1):
            t = row / rows
            for column in range(columns + 1):
                s = column / columns
                point = corners[0].lerp(corners[1], s).lerp(corners[3].lerp(corners[2], s), t)
                # A shallow rolled fold replaces the flat triangular plate.
                point.y -= .007 * math.sin(math.pi*s) * math.sin(math.pi*t)
                point = fit_lapel(point)
                coat.vertex(point, {"spine_03": 1.0})
                if row and column < columns:
                    a = start + (row-1)*(columns+1) + column
                    b = a + 1
                    d = start + row*(columns+1) + column
                    coat.faces.append((d, d+1, b, a) if sign > 0 else (a, b, d+1, d))
        # Thin seams on the lapel make the tailoring visible at desktop scale.
        path = smooth_path([corners[0], corners[3], corners[2]], steps=8)
        path = [fit_lapel(point, clearance=.014) for point in path]
        trim.tube(path, .0009, {"spine_03": 1.0})
    def fit_tailoring(point, weights):
        if any("arm" in bone for bone in weights):
            return point
        return clear_outfit(point)

    return coat.object("LyraCoat", rig, silver, thickness=.002, smoothing=4, surface_fit=fit_tailoring)


def build_reference_locks(rig, coat, material):
    locks = MeshBuilder()
    paths = []
    coat_tree = BVHTree.FromObject(coat, bpy.context.evaluated_depsgraph_get())
    hair = next(obj for obj in rig.children_recursive if "long01" in obj.name and obj.type == "MESH")
    hair_tree = BVHTree.FromObject(hair, bpy.context.evaluated_depsgraph_get())
    hair_top = max(vertex.co.z for vertex in hair.data.vertices)
    for index in range(12):
        offset = (index - 5.5) * .003
        paths.append([
            Vector((.045 + offset*.25, -.015 + offset, 1.665)),
            Vector((.005, -.08 + offset, 1.66)), Vector((-.075, -.13 + offset, 1.605)),
            Vector((-.133, -.13 + offset, 1.50)), Vector((-.16, -.10 + offset, 1.38)),
            Vector((-.175, -.15 + offset, 1.20)), Vector((-.19, -.18 + offset, 1.03)),
        ])
    for index in range(10):
        offset = (index - 4.5) * .003
        paths.append([
            Vector((.05 + offset, .015, 1.66)), Vector((.14 + offset, -.025, 1.59)),
            Vector((.16 + offset, -.09, 1.48)), Vector((.18 + offset, -.12, 1.36)),
            Vector((.185 + offset, -.16, 1.20)), Vector((.20 + offset, -.19, 1.02)),
        ])
    finished = []
    for index, controls in enumerate(paths):
        # Stagger the ends and flow so locks read as layers rather than cables.
        controls[-1].z += (index % 5) * .018
        points = smooth_path(controls, steps=4)
        for point in points:
            if point.z >= 1.35:
                point.z = min(point.z, hair_top - .002)
                center = Vector((0, -.025, point.z))
                radial = Vector((point.x, point.y + .025, 0)).normalized()
                hit, _normal, _face, _distance = hair_tree.ray_cast(center + radial*.4, -radial, .395)
                if hit is None:
                    hit, _normal, _face, _distance = hair_tree.find_nearest(point)
                if hit is not None:
                    point.x, point.y, point.z = hit + radial*.0015
            else:
                hit, _normal, _face, _distance = coat_tree.ray_cast(Vector((point.x, -.5, point.z)), Vector((0, 1, 0)), .7)
                if hit is not None:
                    point.y = hit.y - .012
                point.x += .004 * math.sin(point.z * 14 + index * .45)
        for _iteration in range(2):
            relaxed = [point.copy() for point in points]
            for sample in range(1, len(points)-1):
                relaxed[sample] = points[sample].lerp((points[sample-1]+points[sample+1])*.5, .5)
            points = relaxed
        radius = (.0025 if index < 12 else .0021) * (1.0 - .07*(index % 3))
        locks.tube(points, radius, {"head": 1.0}, sides=8, taper=True, flatten=.45)
        if index % 3 == 0:
            fine = [point + Vector((.002, -.001, 0)) for point in points]
            locks.tube(fine, .00055, {"head": 1.0}, sides=4, taper=True)
        finished.append(points)
    locks.object("SweptLocks", rig, material)
    return finished


def build_hair_lights(rig, hair, fiber, foreground_paths):
    lights = MeshBuilder()
    graph = bpy.context.evaluated_depsgraph_get()
    tree = BVHTree.FromObject(hair, graph)
    inverse = hair.matrix_world.inverted()
    world_vertices = [hair.matrix_world @ vertex.co for vertex in hair.data.vertices]
    top = max(point.z for point in world_vertices) - .012
    bottom = min(point.z for point in world_vertices) + .025
    strand_count = 0
    for strand in range(30):
        theta = .62 + (math.tau - 1.24) * strand / 29
        radial = Vector((math.sin(theta), -math.cos(theta), 0))
        points = []
        for step in range(24):
            height = top + (bottom - top) * step / 23
            center = Vector((0, -.025, height))
            origin = center + radial * .4
            direction = inverse.to_3x3() @ -radial
            hit, _normal, _index, _distance = tree.ray_cast(inverse @ origin, direction.normalized(), .39)
            if hit is not None:
                point = hair.matrix_world @ hit + radial * .0018
                if points and (point - points[-1]).length > .10:
                    break
                points.append(point)
            elif points:
                break
        if len(points) < 4:
            continue
        lights.tube(smooth_path(points), .0007, {"head": 1.0})
        for index in range(2 + strand % 3, len(points), 6):
            lights.light_point(points[index], .0017, {"head": 1.0})
        strand_count += 1
    assert strand_count >= 10, "Insufficient hair surface coverage for light strands"
    for path in foreground_paths[::2]:
        shifted = [point + Vector((0, -.002, 0)) for point in path]
        lights.tube(shifted, .0004, {"head": 1.0})
        for index in range(3, len(shifted), 6):
            lights.light_point(shifted[index], .0016, {"head": 1.0})
        strand_count += 1
    lights.object("BlueFilaments", rig, fiber)
    return strand_count


def build_pendant(rig, silver, fiber):
    setting = MeshBuilder()
    weights = {"spine_03": 1.0}
    center = Vector((0, -.177, 1.19))
    chain = [Vector((-.046, -.078, 1.335)), Vector((-.053, -.12, 1.29)),
             Vector((-.034, -.169, 1.23)), center + Vector((0, 0, .019)),
             Vector((.034, -.169, 1.23)), Vector((.053, -.12, 1.29)), Vector((.046, -.078, 1.335))]
    setting.tube(smooth_path(chain), .0013, weights)
    outline = [center + Vector((0, 0, .023)), center + Vector((.014, 0, .002)),
               center + Vector((0, 0, -.022)), center + Vector((-.014, 0, .002))]
    setting.tube(smooth_path(outline + [outline[0]], steps=4), .0018, weights, sides=8)
    setting.object("PendantSetting", rig, silver)
    gem = MeshBuilder()
    for point in [center + Vector((0, -.006, .020)), center + Vector((.011, -.006, .001)),
                  center + Vector((0, -.006, -.019)), center + Vector((-.011, -.006, .001)),
                  center + Vector((0, -.012, 0)), center + Vector((0, .003, 0))]:
        gem.vertex(point, weights)
    for a in range(4):
        gem.faces.append((a, 4, (a+1) % 4))
        gem.faces.append((a, (a+1) % 4, 5))
    obj = gem.object("Pendant", rig, fiber)
    for polygon in obj.data.polygons:
        polygon.use_smooth = False


def build_details(rig, portable_material):
    silver = portable_material("SilverCoat", (.46, .50, .58, 1))
    silver.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = .12
    jewelry = portable_material("NecklaceSilver", (.56, .61, .70, 1))
    jewelry.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = .7
    jewelry.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = .3
    fiber = portable_material("FiberBlue", (.018, .16, .72, 1), glow=1.3)
    lock_material = portable_material("SilverLocks", (.46, .50, .58, 1))
    lock_material.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = .12
    lock_material.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = .36
    trim = MeshBuilder()
    coat = build_coat(rig, silver, trim)
    foreground_paths = build_reference_locks(rig, coat, lock_material)
    trim.object("LapelPiping", rig, fiber)
    hair = next(obj for obj in rig.children_recursive if "long01" in obj.name and obj.type == "MESH")
    strand_count = build_hair_lights(rig, hair, fiber, foreground_paths)
    build_pendant(rig, jewelry, fiber)
    return {"hair_filament_count": strand_count, "foreground_lock_count": len(foreground_paths),
            "authored_parts": ["LyraCoat", "BlueFilaments", "Pendant", "PendantSetting", "LapelPiping", "SweptLocks"]}
