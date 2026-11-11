extends "res://src/rigged_preview.gd"

var camera: Camera3D
var notice: Label


func _ready() -> void:
	super._ready()
	get_window().title = "LYRA — Portrait"
	get_viewport().msaa_3d = Viewport.MSAA_4X
	if avatar.setup_error.is_empty():
		dialogue_label.text = "I'm here. Start a mock conversation when you're ready."
	if "--blink-check" in OS.get_cmdline_user_args():
		add_child(preload("res://src/blink_playback_check.gd").new())


func _build_stage() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("292e32")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("e6e0d8")
	environment.environment.ambient_light_energy = 0.32
	add_child(environment)
	for item in [
		[Vector3(-22, -32, 0), Color("fff0df"), 0.85],
		[Vector3(-10, 45, 0), Color("e0e9f4"), 0.30],
		[Vector3(-25, 150, 0), Color("a9c9e8"), 0.30],
	]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = item[0]
		light.light_color = item[1]
		light.light_energy = item[2]
		add_child(light)
	var catchlight := OmniLight3D.new()
	catchlight.position = Vector3(-0.6, 2.45, 1.0)
	catchlight.light_color = Color("ffede0")
	catchlight.light_energy = 0.08
	catchlight.omni_range = 3.0
	add_child(catchlight)
	_build_room()
	avatar = RiggedAvatar.new()
	avatar.portrait_quality = true
	add_child(avatar)
	camera = Camera3D.new()
	camera.position = Vector3(0, 2.02, 1.35)
	camera.fov = 35
	camera.near = 0.05
	add_child(camera)
	camera.look_at(Vector3(0, 1.84, 0))
	camera.current = true


func _build_room() -> void:
	var wall := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(5, 4, 0.05)
	wall.mesh = box
	wall.position = Vector3(0, 1.6, -0.9)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color("555956")
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.roughness = 1.0
	wall.material_override = paint
	add_child(wall)
	# Soft pools of light suggest a room without distracting high-frequency detail.
	for item in [[Vector3(-1.0, 1.9, -0.85), Color("b9a68a"), Vector3(0.45, 1.4, 0.02)],
		[Vector3(0.85, 1.5, -0.85), Color("46535b"), Vector3(0.4, 1.1, 0.02)]]:
		var panel := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = item[2]
		panel.mesh = mesh
		panel.position = item[0]
		var material := StandardMaterial3D.new()
		material.albedo_color = item[1]
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.roughness = 1.0
		panel.material_override = material
		add_child(panel)


func _build_controls() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var title := _label("LYRA", 24, Color("f4f0e8"))
	title.position = Vector2(30, 22)
	root.add_child(title)
	state_label = _label("IDLE", 13)
	state_label.position = Vector2(32, 58)
	root.add_child(state_label)
	notice = _label("Local portrait · input simulated · silent preview", 13, Color("dedbd3"))
	notice.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	notice.offset_left = -375
	notice.offset_right = -24
	notice.offset_top = 28
	notice.offset_bottom = 56
	root.add_child(notice)
	var tray := PanelContainer.new()
	tray.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	tray.offset_top = -126
	tray.offset_left = 24
	tray.offset_right = -24
	tray.offset_bottom = -24
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.065, 0.075, 0.9)
	style.set_corner_radius_all(18)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	tray.add_theme_stylebox_override("panel", style)
	root.add_child(tray)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	tray.add_child(column)
	dialogue_label = _label("", 17)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(dialogue_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	for item in [["run", "Mock conversation"], ["cancel", "Stop"], ["listen", "Simulate input"],
		["error", "Test error"], ["reset", "Recover"], ["power", "End preview"]]:
		var button := Button.new()
		button.text = item[1]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 40
		button.pressed.connect(controller.action.bind(item[0]))
		button.visible = item[0] in ["run", "cancel", "power"]
		buttons[item[0]] = button
		row.add_child(button)


func _present(state: String, dialogue: String) -> void:
	super._present(state, dialogue)
	buttons["power"].text = "Start preview" if state == "OFFLINE" else "End preview"
