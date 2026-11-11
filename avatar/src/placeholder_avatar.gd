extends Node3D

# Only the platform light changes color; identity materials remain constant.
const COLORS = {
	"OFFLINE": Color("455366"), "IDLE": Color("72c9f4"),
	"LISTENING": Color("b2e4ff"), "THINKING": Color("859fef"),
	"SPEAKING": Color("68d9ff"), "ERROR": Color("ed968c"),
}

var presentation_state := "OFFLINE"
var body: Node3D
var _mouth: Node3D
var _chest: Node3D
var _head: Node3D
var _hair: Node3D
var _status: StandardMaterial3D
var _fiber: StandardMaterial3D
var _time := 0.0


func _ready() -> void:
	var skin := _material("c49c88", 0.0, 0.68)
	var silver := _material("a9b1c0", 0.22, 0.72)
	var hair := _material("aeb7c7", 0.2, 0.55)
	var shadow := _material("8c94a3", 0.15, 0.65)
	var navy := _material("172b43", 0.12, 0.7)
	var boot := _material("16202e", 0.3, 0.5)
	_fiber = _material("62bbff", 0.1, 0.5, 0.45)
	_status = _material("72c9f4", 0.3, 0.4, 0.7)
	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	_head = Node3D.new()
	_head.name = "Head"
	_head.position.y = 2.0
	_head.scale = Vector3.ONE * 0.75
	body.add_child(_head)
	_hair = Node3D.new()
	_hair.name = "Hair"
	_head.add_child(_hair)
	_build_outfit(navy, silver, boot, skin)
	_build_face(skin)
	_build_hair(hair, shadow)
	# Breath and small upper-body shifts leave the lower body and feet planted.
	_chest = Node3D.new()
	_chest.name = "UpperBody"
	_chest.position.y = 1.3
	body.add_child(_chest)
	for part in body.get_children():
		if part == _chest or part.get_meta("planted", false):
			continue
		part.reparent(_chest, true)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.61
	ring.outer_radius = 0.625
	_piece("StatusRing", ring, Vector3(0, 0.075, 0), self, _status)
	set_presentation("OFFLINE")


func _material(hex: String, metallic: float, roughness: float, glow: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(hex)
	material.metallic = metallic
	material.roughness = roughness
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = Color(hex)
		material.emission_energy_multiplier = glow
	return material


func _piece(label: String, mesh: Mesh, at: Vector3, parent: Node3D, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	if parent == _head or parent == _hair:
		instance.position.y -= 2.1
	if parent == body and (label.begins_with("Leg") or label.begins_with("Boot")):
		instance.set_meta("planted", true)
	parent.add_child(instance, true)
	return instance


func _ellipsoid(label: String, at: Vector3, size: Vector3, parent: Node3D, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 24
	mesh.rings = 16
	var instance := _piece(label, mesh, at, parent, material)
	instance.scale = size
	return instance


# Rings encode (height, half-width, half-depth). Explicit normals smooth the
# procedural silhouette without importing meshes or textures.
func _profile(control_rings: Array[Vector3], sides: int = 40,
		arc_start: float = 0.0, arc_span: float = TAU) -> ArrayMesh:
	var rings: Array[Vector3] = []
	for index in control_rings.size() - 1:
		for step in 5:
			var fraction := step / 5.0
			var ring := control_rings[index].cubic_interpolate(control_rings[index + 1],
				control_rings[maxi(index - 1, 0)], control_rings[mini(index + 2, control_rings.size() - 1)], fraction)
			# Keep height monotonic and radii positive at taper endpoints.
			ring.x = lerpf(control_rings[index].x, control_rings[index + 1].x, fraction)
			ring.y = maxf(ring.y, 0.001)
			ring.z = maxf(ring.z, 0.001)
			rings.append(ring)
	rings.append(control_rings[-1])
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for row in rings.size():
		var ring: Vector3 = rings[row]
		var below: Vector3 = rings[maxi(row - 1, 0)]
		var above: Vector3 = rings[mini(row + 1, rings.size() - 1)]
		var slope := (above - below) / maxf(above.x - below.x, 0.001)
		var columns := sides + 1
		for column in columns:
			var angle := arc_start + arc_span * column / sides
			var c := cos(angle)
			var s := sin(angle)
			vertices.append(Vector3(c * ring.y, ring.x, s * ring.z))
			normals.append(Vector3(ring.z * c,
				-(slope.y * ring.z * c * c + slope.z * ring.y * s * s), ring.y * s).normalized())
			if row < rings.size() - 1 and column < sides:
				var a := row * columns + column
				var b := (row + 1) * columns + column
				var d := row * columns + column + 1
				var next := (row + 1) * columns + column + 1
				indices.append_array([a, b, next, a, next, d])
	return _mesh(vertices, normals, indices)


func _mesh(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> ArrayMesh:
	# Godot's front faces use clockwise winding. Orient each triangle against
	# its outward normals; this also handles the mirrored coat panels.
	for index in range(0, indices.size(), 3):
		var a := indices[index]
		var b := indices[index + 1]
		var c := indices[index + 2]
		var cross := (vertices[b] - vertices[a]).cross(vertices[c] - vertices[a])
		if cross.dot(normals[a] + normals[b] + normals[c]) > 0.0:
			indices[index + 1] = c
			indices[index + 2] = b
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _limb(label: String, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = start.distance_to(end) + radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var instance := _piece(label, mesh, (start + end) * 0.5, body, material)
	instance.quaternion = Quaternion(Vector3.UP, (end - start).normalized())


func _panel(label: String, points: PackedVector3Array, material: Material) -> void:
	var polygon := PackedVector2Array()
	var normals := PackedVector3Array()
	for point in points:
		polygon.append(Vector2(point.x, point.y))
		normals.append(Vector3.BACK)
	_piece(label, _mesh(points, normals, Geometry2D.triangulate_polygon(polygon)), Vector3.ZERO, body, material)


func _build_outfit(navy: Material, silver: Material, boot: Material, skin: Material) -> void:
	_piece("Suit", _profile([
		Vector3(1.02, 0.12, 0.09), Vector3(1.15, 0.215, 0.14),
		Vector3(1.29, 0.17, 0.12), Vector3(1.43, 0.195, 0.135),
		Vector3(1.55, 0.23, 0.15), Vector3(1.68, 0.245, 0.12),
		Vector3(1.76, 0.115, 0.075),
	]), Vector3.ZERO, body, navy)
	_limb("Neck", Vector3(0, 1.75, 0), Vector3(0, 1.85, 0), 0.053, skin)
	# A continuous open-front coat follows the torso and wraps around the back.
	_piece("Coat", _profile([
		Vector3(0.55, 0.32, 0.18), Vector3(0.78, 0.30, 0.19),
		Vector3(1.12, 0.245, 0.17), Vector3(1.29, 0.19, 0.14),
		Vector3(1.44, 0.215, 0.16), Vector3(1.55, 0.25, 0.18),
		Vector3(1.68, 0.27, 0.145), Vector3(1.76, 0.15, 0.095),
	], 48, PI - 1.05, PI + 2.1), Vector3(0, 0, -0.015), body, silver)
	for side in [-1.0, 1.0]:
		_ellipsoid("Shoulder", Vector3(side * 0.25, 1.66, 0), Vector3(0.077, 0.085, 0.08), body, silver)
		_sleeve("UpperSleeve", Vector3(side * 0.25, 1.67, 0), Vector3(side * 0.325, 1.395, 0.01), 0.082, 0.058, silver)
		_sleeve("LowerSleeve", Vector3(side * 0.325, 1.395, 0.01), Vector3(side * 0.315, 1.14, 0.065), 0.06, 0.039, silver)
		_ellipsoid("Elbow", Vector3(side * 0.325, 1.395, 0.01), Vector3(0.058, 0.065, 0.058), body, silver)
		_build_hand(side, skin)
		_piece("Leg", _profile([
			Vector3(0.2, 0.049, 0.06), Vector3(0.38, 0.061, 0.075),
			Vector3(0.52, 0.078, 0.083), Vector3(0.67, 0.067, 0.074),
			Vector3(0.86, 0.088, 0.10), Vector3(1.04, 0.103, 0.11),
			Vector3(1.13, 0.085, 0.10),
		]), Vector3(side * 0.115, 0, 0), body, navy)
		_piece("BootShaft", _profile([
			Vector3(0.11, 0.065, 0.085), Vector3(0.18, 0.063, 0.075),
			Vector3(0.29, 0.058, 0.068), Vector3(0.33, 0.057, 0.065),
		]), Vector3(side * 0.115, 0, 0), body, boot)
		_ellipsoid("Boot", Vector3(side * 0.115, 0.112, 0.055), Vector3(0.071, 0.047, 0.13), body, boot)
		_ellipsoid("BootSole", Vector3(side * 0.115, 0.073, 0.052), Vector3(0.074, 0.014, 0.134), body, boot)
		_panel("Lapel", PackedVector3Array([
			Vector3(side * 0.13, 1.75, 0.085), Vector3(side * 0.23, 1.66, 0.115),
			Vector3(side * 0.15, 1.29, 0.12), Vector3(side * 0.065, 1.50, 0.17),
		]), silver)
		_strand("LapelTrim", PackedVector3Array([
			Vector3(side * 0.13, 1.75, 0.09), Vector3(side * 0.065, 1.50, 0.177),
			Vector3(side * 0.15, 1.29, 0.13),
		]), 0.003, body, _fiber)
	_ellipsoid("Pendant", Vector3(0, 1.62, 0.145), Vector3(0.022, 0.035, 0.013), body, _fiber)
	_strand("Necklace", PackedVector3Array([
		Vector3(-0.065, 1.78, 0.07), Vector3(-0.045, 1.68, 0.13),
		Vector3(0, 1.62, 0.15), Vector3(0.045, 1.68, 0.13), Vector3(0.065, 1.78, 0.07),
	]), 0.003, body, silver)


func _sleeve(label: String, start: Vector3, end: Vector3, shoulder: float, cuff: float, material: Material) -> void:
	var length := start.distance_to(end)
	var mesh := _profile([
		Vector3(0, shoulder * 0.85, shoulder * 0.85),
		Vector3(length * 0.12, shoulder, shoulder),
		Vector3(length * 0.55, lerpf(shoulder, cuff, 0.55), lerpf(shoulder, cuff, 0.55)),
		Vector3(length, cuff, cuff),
	], 24)
	var instance := _piece(label, mesh, start, body, material)
	instance.quaternion = Quaternion(Vector3.UP, (end - start).normalized())


func _build_hand(side: float, skin: Material) -> void:
	var center := Vector3(side * 0.315, 1.085, 0.075)
	_ellipsoid("Palm", center, Vector3(0.035, 0.055, 0.022), body, skin)
	for index in 4:
		var offset := (index - 1.5) * 0.014
		var start := center + Vector3(offset, -0.035, 0.0)
		var end := start + Vector3(side * 0.003, -0.062 + absf(index - 1.5) * 0.009, 0.006)
		_limb("Finger", start, end, 0.006, skin)
	_limb("Thumb", center + Vector3(-side * 0.028, 0.005, 0.008),
		center + Vector3(-side * 0.043, -0.04, 0.018), 0.009, skin)


func _build_face(skin: Material) -> void:
	_piece("Face", _profile([
		Vector3(1.86, 0.035, 0.045), Vector3(1.9, 0.09, 0.085),
		Vector3(1.96, 0.135, 0.125), Vector3(2.02, 0.171, 0.152),
		Vector3(2.10, 0.183, 0.166), Vector3(2.17, 0.181, 0.157),
		Vector3(2.24, 0.174, 0.143), Vector3(2.3, 0.12, 0.10),
		Vector3(2.34, 0.01, 0.01),
	]), Vector3(0, 0, 0.035), _head, skin)
	var whites := _material("d9d7d1", 0, 0.5)
	var iris := _material("679cbe", 0.1, 0.4)
	var dark := _material("253040", 0, 0.7)
	var brow := _material("6f6463", 0, 0.8)
	var glint := _material("d6edff", 0, 0.3, 0.25)
	var lips := _material("916b69", 0, 0.75)
	for side in [-1.0, 1.0]:
		_ellipsoid("Ear", Vector3(side * 0.192, 2.075, 0.015), Vector3(0.028, 0.06, 0.025), _head, skin)
		_ellipsoid("Earring", Vector3(side * 0.2, 2.035, 0.04), Vector3(0.009, 0.018, 0.009), _head, _fiber)
		_ellipsoid("Eye", Vector3(side * 0.075, 2.115, 0.192), Vector3(0.042, 0.016, 0.016), _head, whites)
		_ellipsoid("Iris", Vector3(side * 0.075, 2.115, 0.206), Vector3(0.013, 0.014, 0.007), _head, iris)
		_ellipsoid("Pupil", Vector3(side * 0.075, 2.115, 0.213), Vector3(0.006, 0.009, 0.003), _head, dark)
		_ellipsoid("EyeGlint", Vector3(side * 0.075 - 0.004, 2.121, 0.216), Vector3(0.002, 0.0025, 0.0015), _head, glint)
		_strand("Brow", PackedVector3Array([
			Vector3(side * 0.033, 2.157, 0.19), Vector3(side * 0.075, 2.167, 0.18),
			Vector3(side * 0.117, 2.151, 0.155),
		]), 0.004, _head, brow)
		var eye_x: float = side * 0.075
		_strand("UpperLid", PackedVector3Array([
			Vector3(eye_x - 0.039, 2.115, 0.194), Vector3(eye_x, 2.13, 0.202),
			Vector3(eye_x + 0.039, 2.115, 0.194),
		]), 0.005, _head, skin)
		_strand("LowerLid", PackedVector3Array([
			Vector3(eye_x - 0.039, 2.113, 0.194), Vector3(eye_x, 2.1, 0.202),
			Vector3(eye_x + 0.039, 2.113, 0.194),
		]), 0.004, _head, skin)
	_ellipsoid("NoseBridge", Vector3(0, 2.075, 0.201), Vector3(0.016, 0.044, 0.022), _head, skin)
	_ellipsoid("NoseTip", Vector3(0, 2.042, 0.222), Vector3(0.02, 0.014, 0.018), _head, skin)
	_mouth = Node3D.new()
	_mouth.name = "Mouth"
	_mouth.position = Vector3(0, 1.979 - 2.1, 0.181)
	_head.add_child(_mouth)
	for side in [-1.0, 1.0]:
		var lip := _ellipsoid("UpperLip", Vector3(side * 0.018, 0.003, 0),
			Vector3(0.025, 0.006, 0.008), _mouth, lips)
		lip.rotation.z = side * 0.09
	_ellipsoid("LowerLip", Vector3(0, -0.006, 0.002), Vector3(0.035, 0.006, 0.009), _mouth, lips)
	_strand("LipLine", PackedVector3Array([
		Vector3(-0.04, 0.002, 0.005), Vector3(-0.02, -0.002, 0.009),
		Vector3(0, -0.003, 0.01), Vector3(0.02, -0.002, 0.009), Vector3(0.04, 0.002, 0.005),
	]), 0.0015, _mouth, brow)


func _build_hair(silver: Material, shadow: Material) -> void:
	_ellipsoid("HairCrown", Vector3(0, 2.18, -0.045), Vector3(0.219, 0.205, 0.202), _hair, silver)
	_ellipsoid("HairUnderlayer", Vector3(0, 1.65, -0.11), Vector3(0.23, 0.5, 0.13), _hair, shadow)
	for index in 9:
		var offset := index * 0.009
		_strand("SweptCrown", PackedVector3Array([
			Vector3(-0.2, 2.24 - offset * 0.1, 0.04 + offset),
			Vector3(-0.13, 2.335, 0.035 + offset),
			Vector3(0.015, 2.38, -0.025 + offset),
			Vector3(0.16, 2.315, 0.01 + offset),
			Vector3(0.215, 2.21, 0.025 + offset),
		]), 0.008, _hair, silver)
	# Back and side strands leave the face open.
	for index in 48:
		var angle := PI + PI * index / 47.0
		var x := cos(angle)
		var z := sin(angle)
		var wave := sin(index * 2.4)
		var points := PackedVector3Array([
			Vector3(0.11 * x, 2.35 - 0.025 * absf(x), -0.025 + z * 0.09),
			Vector3(0.205 * x, 2.27, -0.035 + z * 0.18),
			Vector3(0.24 * x, 2.05, -0.04 + z * 0.215),
			Vector3(0.255 * x + wave * 0.015, 1.8, -0.065 + z * 0.21),
			Vector3(0.29 * x - wave * 0.015, 1.52, -0.08 + z * 0.23),
			Vector3(0.32 * x + wave * 0.02, 1.25, -0.065 + z * 0.22),
			Vector3(0.31 * x, 0.82 + 0.09 * wave, -0.055 + z * 0.20),
		])
		_strand("SilverStrand", points, 0.010 if index % 2 == 0 else 0.007, _hair, silver)
		if index % 6 == 0:
			_add_fiber(points, Vector3(x * 0.01, 0, z * 0.012))
	for side in [-1.0, 1.0]:
		for index in 5:
			var offset := index * 0.012
			var points := PackedVector3Array([
				Vector3(side * (0.02 + offset), 2.363 - offset * 0.3, 0.015),
				Vector3(side * (0.18 + offset), 2.28 - offset, 0.115),
				Vector3(side * (0.21 + offset), 2.06, 0.125),
				Vector3(side * (0.235 + offset), 1.86, 0.125),
				Vector3(side * (0.24 + offset), 1.63, 0.12),
				Vector3(side * (0.31 + offset), 1.0 + offset, 0.14),
			])
			_strand("FaceFramingStrand", points, 0.012, _hair, silver)
			if index % 3 == 0:
				_add_fiber(points, Vector3(0, 0, 0.012))


func _add_fiber(points: PackedVector3Array, offset: Vector3) -> void:
	var shifted := PackedVector3Array()
	for point in points:
		shifted.append(point + offset)
	_strand("BlueFiber", shifted, 0.0017, _hair, _fiber)
	for index in [2, 4]:
		_ellipsoid("FiberLight", shifted[index], Vector3.ONE * 0.004, _hair, _fiber)


func _strand(label: String, points: PackedVector3Array, radius: float, parent: Node3D, material: Material) -> void:
	var smooth := PackedVector3Array()
	for index in points.size() - 1:
		for step in 4:
			smooth.append(points[index].cubic_interpolate(points[index + 1],
				points[maxi(0, index - 1)], points[mini(points.size() - 1, index + 2)], step / 4.0))
	smooth.append(points[-1])
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	const SIDES := 6
	for index in smooth.size():
		var tangent := (smooth[mini(index + 1, smooth.size() - 1)] - smooth[maxi(index - 1, 0)]).normalized()
		var right := tangent.cross(Vector3.FORWARD).normalized()
		if right.length_squared() < 0.1:
			right = tangent.cross(Vector3.UP).normalized()
		var up := tangent.cross(right).normalized()
		for side in SIDES:
			var angle := TAU * side / SIDES
			var normal := right * cos(angle) + up * sin(angle)
			vertices.append(smooth[index] + normal * radius)
			normals.append(normal)
			if index < smooth.size() - 1:
				var a := index * SIDES + side
				var b := (index + 1) * SIDES + side
				var c := (index + 1) * SIDES + (side + 1) % SIDES
				var d := index * SIDES + (side + 1) % SIDES
				indices.append_array([a, b, c, a, c, d])
	_piece(label, _mesh(vertices, normals, indices), Vector3.ZERO, parent, material)


func set_presentation(value: String) -> void:
	presentation_state = value
	var tint: Color = COLORS.get(value, COLORS["ERROR"])
	_status.albedo_color = tint
	_status.emission = tint
	_fiber.emission_energy_multiplier = 0.03 if value == "OFFLINE" else 0.45
	_time = 0.0
	body.position.y = 0.0
	body.rotation = Vector3.ZERO
	_chest.position.y = 1.3
	_chest.rotation = Vector3.ZERO
	_head.rotation = Vector3.ZERO
	_hair.rotation = Vector3.ZERO
	_mouth.scale.y = 1.0


func animate(delta: float) -> void:
	if presentation_state == "OFFLINE":
		return
	_time += delta
	_chest.position.y = 1.3 + sin(_time * 1.6) * 0.002
	_chest.rotation.y = sin(_time * 0.55) * 0.012
	_hair.rotation.z = sin(_time * 0.85) * 0.006
	if presentation_state == "THINKING":
		_head.rotation.z = 0.025
	elif presentation_state == "LISTENING":
		_head.rotation.x = -0.015
	_mouth.scale.y = 1.0 + abs(sin(_time * 12.0)) * 0.6 if presentation_state == "SPEAKING" else 1.0
