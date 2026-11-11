extends Node3D

const Controller = preload("res://src/mock_embodiment_controller.gd")
const Avatar = preload("res://src/placeholder_avatar.gd")

var controller = Controller.new()
var avatar: Node3D
var state_label: Label
var dialogue_label: Label
var buttons: Dictionary = {}


func _ready() -> void:
	Engine.max_fps = 60
	get_window().min_size = Vector2i(960, 720)
	_build_stage()
	_build_controls()
	controller.presentation_changed.connect(_present)
	controller.action("power")
	get_tree().auto_accept_quit = false


func _process(delta: float) -> void:
	controller.advance(delta)
	avatar.animate(delta)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if controller.machine.state != "OFFLINE":
			controller.action("power")
		get_tree().quit()


func _build_stage() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("09121e")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b1c8de")
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -30, 0)
	light.light_color = Color("fff0e3")
	light.light_energy = 1.1
	add_child(light)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 145, 0)
	rim.light_color = Color("7faee8")
	rim.light_energy = 0.6
	add_child(rim)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, 55, 0)
	fill.light_color = Color("dbe6f5")
	fill.light_energy = 0.35
	add_child(fill)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.45, 5.3)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.05
	add_child(camera)
	camera.look_at(Vector3(0, 1.25, 0))
	camera.current = true
	avatar = Avatar.new()
	avatar.position.x = -0.95
	avatar.rotation.y = -0.18
	add_child(avatar)
	var platform := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.7
	cylinder.bottom_radius = 0.76
	cylinder.height = 0.12
	platform.mesh = cylinder
	platform.position = Vector3(-0.95, 0, 0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("1e3045")
	material.metallic = 0.65
	platform.material_override = material
	add_child(platform)


func _label(text: String, size: int, color: Color = Color("dce8f3")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _build_controls() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var layout := Control.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(layout)
	var heading := VBoxContainer.new()
	heading.position = Vector2(36, 28)
	heading.add_child(_label("L Y R A", 30))
	heading.add_child(_label("EMBODIMENT / SILVER & BLUE", 13, Color("8aa6be")))
	layout.add_child(heading)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.anchor_left = 0.6
	panel.offset_left = 0
	panel.offset_top = 28
	panel.offset_right = -28
	panel.offset_bottom = -28
	var style := StyleBoxFlat.new()
	style.bg_color = Color("112033")
	style.set_corner_radius_all(16)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	layout.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	column.add_child(_label("PRESENTATION STATUS", 13, Color("8aa6be")))
	state_label = _label("OFFLINE", 28)
	column.add_child(state_label)
	var note := _label("Mock dialogue · silent speech animation\nInput is simulated.", 14, Color("9eb4c9"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(note)
	dialogue_label = _label("", 18)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(dialogue_label)
	for item in [
		["listen", "Simulate input"], ["run", "Run mock dialogue"],
		["cancel", "Cancel"], ["error", "Simulate error"],
		["reset", "Reset presentation"], ["power", "Go offline"],
	]:
		var button := Button.new()
		button.text = item[1]
		button.custom_minimum_size.y = 38
		button.pressed.connect(controller.action.bind(item[0]))
		buttons[item[0]] = button
		column.add_child(button)
	var footer := _label("PRESENCE BEFORE BEAUTY\nCharacter study / natural proportions", 13, Color("8aa6be"))
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	footer.offset_left = 36
	footer.offset_top = -66
	footer.offset_right = 450
	footer.offset_bottom = -20
	layout.add_child(footer)


func _present(state: String, dialogue: String) -> void:
	state_label.text = state
	state_label.add_theme_color_override("font_color", Avatar.COLORS[state])
	dialogue_label.text = dialogue
	avatar.set_presentation(state)
	buttons["listen"].disabled = state != "IDLE"
	buttons["run"].disabled = state not in ["IDLE", "LISTENING"]
	buttons["cancel"].disabled = state not in ["LISTENING", "THINKING", "SPEAKING"]
	buttons["error"].disabled = state in ["OFFLINE", "ERROR"]
	buttons["reset"].disabled = state != "ERROR"
	buttons["power"].text = "Start presentation" if state == "OFFLINE" else "Go offline"
