extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)


func _run() -> void:
	if not ResourceLoader.exists("res://scenes/portrait.tscn"):
		_expect(false, "video-call portrait scene is missing")
		quit(1)
		return
	var scene = load("res://scenes/portrait.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	await process_frame
	_expect(scene.avatar.setup_error.is_empty(), "portrait model initializes")
	if not scene.avatar.setup_error.is_empty():
		printerr(scene.avatar.setup_error)
		quit(1)
		return
	var camera: Camera3D = scene.camera
	_expect(camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "portrait uses natural perspective")
	var head: Vector3 = scene.avatar.to_global(Vector3(0, 2.02, 0))
	var projected: Vector2 = camera.unproject_position(head) / Vector2(root.size)
	_expect(projected.x > 0.25 and projected.x < 0.75 and projected.y > 0.1 and projected.y < 0.6,
		"face is framed inside the portrait")
	_expect(scene.notice.text.contains("simulated"), "portrait identifies simulated input")
	var skeleton = scene.avatar.body.find_children("*", "Skeleton3D", true, false)[0]
	var eye_index: int = skeleton.find_bone(scene.avatar.mapping["bones"]["eye_left"])
	var neutral: Quaternion = skeleton.get_bone_pose_rotation(eye_index)
	scene.avatar.animate(3.1)
	_expect(not skeleton.get_bone_pose_rotation(eye_index).is_equal_approx(neutral), "gaze uses real eye bones")
	scene.buttons["run"].pressed.emit()
	scene.controller.advance(0.8)
	scene.avatar.animate(0.2)
	_expect(scene.avatar.morph_value("jaw") > 0.0, "portrait retains mock speaking")
	scene.buttons["cancel"].pressed.emit()
	_expect(is_zero_approx(scene.avatar.morph_value("jaw")), "portrait cancel restores neutral mouth")
	scene.buttons["power"].pressed.emit()
	var offline: Quaternion = skeleton.get_bone_pose_rotation(eye_index)
	scene.avatar.animate(5.0)
	_expect(skeleton.get_bone_pose_rotation(eye_index).is_equal_approx(offline), "offline stops gaze animation")
	scene.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: portrait framing, clear simulation status, eye gaze, speech cancel, and offline")
	quit(1 if failures else 0)
