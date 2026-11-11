extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)


func _run() -> void:
	if not ResourceLoader.exists("res://scenes/desktop.tscn"):
		_expect(false, "desktop scene is missing")
		quit(1)
		return
	var scene = load("res://scenes/desktop.tscn").instantiate()
	root.add_child(scene)
	if scene.avatar == null:
		_expect(false, "avatar initializes without script errors")
		scene.queue_free()
		quit(1)
		return
	scene.set_process(false)
	await process_frame
	_expect(scene.controller.machine.state == "IDLE", "desktop starts ready")
	_test_visual_identity(scene.avatar)
	_test_human_proportions(scene.avatar)
	_expect(scene.state_label.text.contains("IDLE"), "visible status matches state")
	_expect(scene.buttons["cancel"].disabled, "cancel unavailable while idle")
	scene.buttons["listen"].pressed.emit()
	_expect(scene.controller.machine.state == "LISTENING", "simulated listening control")
	scene.buttons["run"].pressed.emit()
	_expect(scene.controller.machine.state == "THINKING", "mock starts pending")
	_expect(scene.buttons["run"].disabled, "cannot overlap mock requests")
	scene.controller.advance(0.8)
	_expect(scene.controller.machine.state == "SPEAKING", "mock response starts simulated speech")
	_expect(not scene.dialogue_label.text.is_empty(), "scripted response is visible")
	_expect(scene.avatar.presentation_state == "SPEAKING", "renderer receives speaking state")
	scene.buttons["cancel"].pressed.emit()
	scene.controller.advance(10.0)
	_expect(scene.controller.machine.state == "IDLE", "cancel suppresses delayed playback")
	_expect(scene.avatar.presentation_state == "IDLE", "cancel resets rendered state")
	scene.buttons["run"].pressed.emit()
	scene.controller.advance(0.8)
	scene.controller.advance(3.0)
	_expect(scene.controller.machine.state == "IDLE", "mock automatically completes")
	scene.buttons["run"].pressed.emit()
	scene.buttons["error"].pressed.emit()
	scene.controller.advance(10.0)
	_expect(scene.controller.machine.state == "ERROR", "error stops pending mock")
	scene.buttons["reset"].pressed.emit()
	_expect(scene.controller.machine.state == "IDLE", "reset restores ready scene")
	var suit = scene.avatar.find_child("Suit", true, false)
	var initial: Transform3D = suit.global_transform
	var boots: Array = scene.avatar.body.find_children("Boot*", "MeshInstance3D", true, false)
	var planted_feet: Array[Transform3D] = []
	for boot in boots:
		planted_feet.append(boot.global_transform)
	scene.avatar.animate(0.25)
	_expect(not suit.global_transform.is_equal_approx(initial), "breathing changes upper-body pose")
	_expect(boots.size() >= 2, "both feet available for planted pose check")
	for index in boots.size():
		_expect(boots[index].global_transform.is_equal_approx(planted_feet[index]), "breathing leaves feet planted")
	scene.buttons["power"].pressed.emit()
	_expect(scene.controller.machine.state == "OFFLINE", "power shuts down")
	_expect(scene.buttons["run"].disabled, "mock unavailable while offline")
	scene.buttons["power"].pressed.emit()
	_expect(scene.controller.machine.state == "IDLE", "power restores readiness")
	scene.buttons["run"].pressed.emit()
	scene.buttons["power"].pressed.emit()
	scene.controller.advance(10.0)
	_expect(scene.controller.machine.state == "OFFLINE", "shutdown clears pending mock work")
	var offline_pose: Transform3D = scene.avatar.body.transform
	scene.avatar.animate(1.0)
	_expect(scene.avatar.body.transform == offline_pose, "offline avatar is stationary")
	scene.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: desktop controls, mocked lifecycle, cancellation, recovery, and idle motion")
	quit(1 if failures else 0)


func _test_visual_identity(avatar: Node3D) -> void:
	# Presentation status must not recolor LYRA's face, hair, or clothing.
	var surfaces: Array = []
	for surface in ["Face", "HairCrown", "Suit"]:
		var part = avatar.find_child(surface, true, false)
		_expect(part != null, "stylized avatar provides " + surface)
		if part == null:
			return
		surfaces.append(part)
	var identity_colors: Array = []
	for surface in surfaces:
		identity_colors.append(surface.material_override.albedo_color)
	for state in ["LISTENING", "THINKING", "SPEAKING", "ERROR", "OFFLINE", "IDLE"]:
		avatar.set_presentation(state)
		for index in surfaces.size():
			_expect(surfaces[index].material_override.albedo_color == identity_colors[index],
				"identity palette survives " + state)


func _test_human_proportions(avatar: Node3D) -> void:
	var face = avatar.find_child("Face", true, false)
	if face == null:
		_expect(false, "face available for proportion check")
		return
	var face_bounds: AABB = face.global_transform * face.get_aabb()
	var bounds: AABB = face_bounds
	for mesh in avatar.body.find_children("*", "MeshInstance3D", true, false):
		bounds = bounds.merge(mesh.global_transform * mesh.get_aabb())
	var head_ratio := face_bounds.size.y / bounds.size.y
	_expect(head_ratio >= 0.11 and head_ratio <= 0.17,
		"head has adult proportions rather than oversized toy proportions")
