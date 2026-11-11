extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)


func _run() -> void:
	if not ResourceLoader.exists("res://scenes/rigged_preview.tscn"):
		_expect(false, "rigged preview scene is missing")
		quit(1)
		return
	var scene = load("res://scenes/rigged_preview.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	await process_frame
	var avatar = scene.avatar
	_expect(avatar.setup_error.is_empty(), "imported model resolves required mappings")
	if not avatar.setup_error.is_empty():
		printerr(avatar.setup_error)
		scene.queue_free()
		quit(1)
		return
	var filaments = avatar.body.find_child("BlueFilaments_export", true, false)
	_expect(filaments != null, "blue filaments import into the rigged scene")
	if filaments == null:
		scene.queue_free()
		quit(1)
		return
	var fiber_material = filaments.get_active_material(0)
	var active_glow: float = fiber_material.emission_energy_multiplier
	var white_hair = avatar.body.find_child("Lyra_long01_export", true, false).get_active_material(0)
	var invalid: Dictionary = avatar.mapping.duplicate(true)
	invalid["morphs"]["jaw"] = "missing_jaw"
	var validation: Dictionary = avatar.validate_mapping(invalid)
	_expect(not validation["ok"], "missing facial mapping is rejected explicitly")
	_expect(validation["error"].contains("missing_jaw"), "mapping rejection identifies missing control")
	invalid = avatar.mapping.duplicate(true)
	invalid["bones"]["foot_left"] = "missing_foot"
	validation = avatar.validate_mapping(invalid)
	_expect(not validation["ok"], "missing bone mapping is rejected explicitly")
	var foot_before: Array = avatar.foot_poses()
	avatar.animate(0.5)
	var foot_after: Array = avatar.foot_poses()
	_expect(foot_before.size() == 2, "both imported foot bones resolve")
	for index in foot_before.size():
		_expect(foot_before[index].is_equal_approx(foot_after[index]), "idle preserves imported foot pose")
	scene.buttons["run"].pressed.emit()
	scene.controller.advance(0.8)
	avatar.animate(0.2)
	_expect(avatar.morph_value("jaw") > 0.0, "speaking drives real imported jaw morph")
	var skeleton = avatar.body.find_children("*", "Skeleton3D", true, false)[0]
	var chest: int = skeleton.find_bone(avatar.mapping["bones"]["chest"])
	var speaking_pose: Quaternion = skeleton.get_bone_pose_rotation(chest)
	scene.buttons["cancel"].pressed.emit()
	_expect(is_zero_approx(avatar.morph_value("jaw")), "cancel neutralizes jaw immediately")
	_expect(skeleton.get_bone_pose_rotation(chest).is_equal_approx(speaking_pose), "cancel does not snap body pose")
	scene.controller.advance(10.0)
	_expect(avatar.presentation_state == "IDLE", "cancel suppresses pending imported speech cues")
	# Presentation changes must not postpone autonomous blinking indefinitely.
	avatar.set_presentation("OFFLINE")
	avatar.set_presentation("IDLE")
	var strongest_blink := 0.0
	for frame in 288:
		if frame % 45 == 0:
			avatar.set_presentation("SPEAKING" if frame % 90 == 0 else "IDLE")
		avatar.animate(1.0 / 60.0)
		strongest_blink = maxf(strongest_blink, avatar.morph_value("blink_left"))
	_expect(strongest_blink > 0.9, "blinking continues through frequent dialogue state changes")
	_expect(avatar.morph_value("blink_left") > 0.5, "idle blink reaches left eyelid morph")
	_expect(avatar.morph_value("blink_right") > 0.5, "idle blink reaches right eyelid morph")
	avatar.set_presentation("IDLE")
	_expect(avatar.morph_value("blink_left") > 0.5, "state transition preserves an ongoing blink")
	scene.buttons["power"].pressed.emit()
	var offline_poses: Array = avatar.foot_poses()
	avatar.animate(10.0)
	_expect(avatar.presentation_state == "OFFLINE", "power stops imported presentation")
	_expect(is_zero_approx(avatar.morph_value("jaw")), "offline mouth neutral")
	_expect(is_zero_approx(avatar.morph_value("blink_left")), "offline eyelids neutral")
	_expect(fiber_material.emission_energy_multiplier < active_glow, "offline dims hair filaments")
	var white_glow = white_hair.get_shader_parameter("fiber_brightness")
	_expect(white_glow != null and is_equal_approx(float(white_glow), 0.06), "offline dims white fiber glow")
	_expect(avatar.foot_poses() == offline_poses, "offline does not move skeleton")
	scene.buttons["power"].pressed.emit()
	_expect(is_equal_approx(fiber_material.emission_energy_multiplier, active_glow), "ready restores filament brightness")
	white_glow = white_hair.get_shader_parameter("fiber_brightness")
	_expect(white_glow != null and is_equal_approx(float(white_glow), 1.0), "ready restores white fiber glow")
	scene.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: imported mappings, planted feet, real jaw/blink morphs, cancellation, and offline")
	quit(1 if failures else 0)
