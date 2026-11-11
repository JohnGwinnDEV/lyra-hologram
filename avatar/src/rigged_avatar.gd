extends Node3D

const MODEL_PATH := "res://assets/lyra/lyra-base.glb"
const MAP_PATH := "res://assets/lyra/rigged-map.json"
const STATUS_COLORS = preload("res://src/placeholder_avatar.gd").COLORS

var presentation_state := "OFFLINE"
var setup_error := ""
var mapping: Dictionary = {}
var body: Node3D
var _skeleton: Skeleton3D
var _meshes: Array[MeshInstance3D] = []
var _face: MeshInstance3D
var _neutral_rotations: Dictionary = {}
var _status: StandardMaterial3D
var _time := 0.0
var _expression_time := 0.0
var _accent_materials: Array[StandardMaterial3D] = []
var _accent_energies: Array[float] = []
var _white_fiber_materials: Array[ShaderMaterial] = []
var _gaze := Vector2.ZERO
var _gaze_axes: Dictionary = {}
@export var portrait_quality := false


func _ready() -> void:
	if not ResourceLoader.exists(MODEL_PATH):
		setup_error = "Rigged LYRA asset missing. Run the documented authoring build and import."
		return
	body = load(MODEL_PATH).instantiate()
	add_child(body)
	var skeletons := body.find_children("*", "Skeleton3D", true, false)
	if skeletons.size() != 1:
		setup_error = "Expected exactly one imported skeleton."
		return
	_skeleton = skeletons[0]
	for node in body.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(node)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	if not parsed is Dictionary:
		setup_error = "Invalid rigged-avatar mapping file."
		return
	mapping = parsed
	var validation := validate_mapping(mapping)
	if not validation["ok"]:
		setup_error = validation["error"]
		return
	_face = body.find_child(mapping["body_node"], true, false)
	for semantic in ["head", "chest", "eye_left", "eye_right"]:
		var index := _skeleton.find_bone(mapping["bones"][semantic])
		_neutral_rotations[index] = _skeleton.get_bone_pose_rotation(index)
		if semantic.begins_with("eye"):
			var inverse := _skeleton.get_bone_global_rest(index).basis.inverse()
			_gaze_axes[index] = [inverse * Vector3.UP, inverse * Vector3.RIGHT]
	# Normalize the preview onto the existing platform, leaving asset meters intact.
	var bounds: AABB = _meshes[0].get_aabb()
	for mesh in _meshes:
		bounds = bounds.merge(mesh.transform * mesh.get_aabb())
	body.scale = Vector3.ONE * 1.35
	body.position.y = -bounds.position.y * body.scale.y
	_prepare_cutout_materials()
	_prepare_accents()
	_prepare_surface_materials()
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.61
	torus.outer_radius = 0.625
	ring.mesh = torus
	ring.position.y = 0.015
	_status = StandardMaterial3D.new()
	_status.emission_enabled = true
	_status.emission_energy_multiplier = 0.7
	ring.material_override = _status
	add_child(ring)
	set_presentation("OFFLINE")


func validate_mapping(candidate: Dictionary) -> Dictionary:
	if candidate.get("schema_version") != 1:
		return {"ok": false, "error": "Unsupported model mapping version."}
	var face = body.find_child(str(candidate.get("body_node", "")), true, false)
	if not face is MeshInstance3D:
		return {"ok": false, "error": "Mapped body mesh is missing."}
	if not candidate.get("bones") is Dictionary or not candidate.get("morphs") is Dictionary:
		return {"ok": false, "error": "Bone and morph mappings must be dictionaries."}
	for semantic in ["head", "chest", "foot_left", "foot_right", "eye_left", "eye_right"]:
		var name := str(candidate["bones"].get(semantic, ""))
		if _skeleton.find_bone(name) < 0:
			return {"ok": false, "error": "Missing bone mapping: " + semantic + " = " + name}
	for semantic in ["blink_left", "blink_right", "jaw"]:
		var name := str(candidate["morphs"].get(semantic, ""))
		if face.find_blend_shape_by_name(name) < 0:
			return {"ok": false, "error": "Missing morph mapping: " + semantic + " = " + name}
	return {"ok": true}


func _prepare_cutout_materials() -> void:
	for mesh in _meshes:
		for surface in mesh.mesh.get_surface_count():
			var material = mesh.get_active_material(surface)
			if material is StandardMaterial3D and material.resource_name in ["SilverHair", "Brows", "Lashes", "SilverBlueEyes"]:
				material = material.duplicate()
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				material.alpha_scissor_threshold = 0.35
				material.cull_mode = BaseMaterial3D.CULL_DISABLED
				mesh.set_surface_override_material(surface, material)


func _prepare_surface_materials() -> void:
	for mesh in _meshes:
		for surface in mesh.mesh.get_surface_count():
			var material = mesh.get_active_material(surface)
			if not material is StandardMaterial3D:
				continue
			if material.resource_name == "SilverHair":
				var hair := ShaderMaterial.new()
				hair.shader = preload("res://shaders/silver_hair.gdshader")
				hair.set_shader_parameter("strand_texture", material.albedo_texture)
				_white_fiber_materials.append(hair)
				mesh.set_surface_override_material(surface, hair)
			elif material.resource_name == "SilverLocks":
				var locks := ShaderMaterial.new()
				locks.shader = preload("res://shaders/silver_locks.gdshader")
				_white_fiber_materials.append(locks)
				mesh.set_surface_override_material(surface, locks)
			elif material.resource_name == "Skin":
				var skin := ShaderMaterial.new()
				skin.shader = preload("res://shaders/portrait_skin.gdshader")
				skin.set_shader_parameter("skin_texture", material.albedo_texture)
				mesh.set_surface_override_material(surface, skin)
			elif material.resource_name == "Brows":
				var brows := ShaderMaterial.new()
				brows.shader = preload("res://shaders/soft_brows.gdshader")
				brows.set_shader_parameter("brow_texture", material.albedo_texture)
				mesh.set_surface_override_material(surface, brows)
			elif material.resource_name == "SilverBlueEyes":
				material = material.duplicate()
				material.roughness = 0.16
				material.metallic_specular = 0.5
				material.clearcoat_enabled = true
				material.clearcoat = 0.7
				material.clearcoat_roughness = 0.08
				material.albedo_color = Color(0.82, 0.87, 0.92)
				mesh.set_surface_override_material(surface, material)


func _set_morph(semantic: String, value: float) -> void:
	var name: String = mapping["morphs"][semantic]
	# Eyelashes, teeth, and tongue carry interpolated copies of relevant morphs.
	for mesh in _meshes:
		var index := mesh.find_blend_shape_by_name(name)
		if index >= 0:
			mesh.set_blend_shape_value(index, value)


func _prepare_accents() -> void:
	for mesh in _meshes:
		for surface in mesh.mesh.get_surface_count():
			var material = mesh.get_active_material(surface)
			if material is StandardMaterial3D and material.resource_name == "FiberBlue":
				material = material.duplicate()
				mesh.set_surface_override_material(surface, material)
				_accent_materials.append(material)
				_accent_energies.append(material.emission_energy_multiplier)


func morph_value(semantic: String) -> float:
	return _face.get_blend_shape_value(_face.find_blend_shape_by_name(mapping["morphs"][semantic]))


func foot_poses() -> Array:
	var result := []
	for semantic in ["foot_left", "foot_right"]:
		result.append(_skeleton.get_bone_global_pose(_skeleton.find_bone(mapping["bones"][semantic])))
	return result


func set_presentation(value: String) -> void:
	presentation_state = value
	if not setup_error.is_empty():
		return
	_expression_time = 0.0
	for semantic in mapping["morphs"]:
		if value != "OFFLINE" and semantic in ["blink_left", "blink_right"]:
			continue
		_set_morph(semantic, 0.0)
	if value == "OFFLINE":
		_time = 0.0
		_gaze = Vector2.ZERO
		for index in _neutral_rotations:
			_skeleton.set_bone_pose_rotation(index, _neutral_rotations[index])
	var tint: Color = STATUS_COLORS.get(value, STATUS_COLORS["ERROR"])
	_status.albedo_color = tint
	_status.emission = tint
	for index in _accent_materials.size():
		_accent_materials[index].emission_energy_multiplier = _accent_energies[index] * (0.06 if value == "OFFLINE" else 1.0)
	for material in _white_fiber_materials:
		material.set_shader_parameter("fiber_brightness", 0.06 if value == "OFFLINE" else 1.0)


func animate(delta: float) -> void:
	if not setup_error.is_empty() or presentation_state == "OFFLINE":
		return
	_time += maxf(delta, 0.0)
	_expression_time += maxf(delta, 0.0)
	var chest: int = _skeleton.find_bone(mapping["bones"]["chest"])
	var head: int = _skeleton.find_bone(mapping["bones"]["head"])
	_skeleton.set_bone_pose_rotation(chest, _neutral_rotations[chest] * Quaternion(Vector3.RIGHT, sin(_time * 1.6) * 0.004))
	_skeleton.set_bone_pose_rotation(head, _neutral_rotations[head] * Quaternion(Vector3.UP, sin(_time * 0.6) * 0.012))
	var gaze_phase := fmod(_time, 7.0)
	var target := Vector2(0.015, -0.008) if gaze_phase > 3.0 and gaze_phase < 3.3 else Vector2.ZERO
	_gaze = _gaze.lerp(target, 1.0 - exp(-35.0 * maxf(delta, 0.0)))
	for index in _gaze_axes:
		var axes: Array = _gaze_axes[index]
		var convergence := 0.0
		if portrait_quality:
			convergence = -0.025 if index == _skeleton.find_bone(mapping["bones"]["eye_left"]) else 0.025
		_skeleton.set_bone_pose_rotation(index, _neutral_rotations[index] * Quaternion(axes[0], _gaze.x + convergence) * Quaternion(axes[1], _gaze.y))
	# Blinking follows the continuous active clock, independently of speech cues.
	var phase := fmod(_time, 5.0)
	var blink := clampf((0.18 - absf(phase - 4.8)) / 0.12, 0.0, 1.0)
	_set_morph("blink_left", blink)
	_set_morph("blink_right", blink)
	_set_morph("jaw", 0.12 + abs(sin(_expression_time * 10.0)) * 0.3 if presentation_state == "SPEAKING" else 0.0)
