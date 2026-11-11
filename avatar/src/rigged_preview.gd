extends "res://src/desktop.gd"

const RiggedAvatar = preload("res://src/rigged_avatar.gd")


func _ready() -> void:
	super._ready()
	if not avatar.setup_error.is_empty():
		push_error(avatar.setup_error)
		controller.action("error")
		dialogue_label.text = avatar.setup_error
	else:
		dialogue_label.text = "LYRA character study. Silver coat, blue filaments, and a luminous pendant."


func _build_stage() -> void:
	super._build_stage()
	avatar.free()
	avatar = RiggedAvatar.new()
	avatar.position = Vector3(-0.95, 0.06, 0)
	avatar.rotation.y = -0.18
	add_child(avatar)


func _present(state: String, dialogue: String) -> void:
	super._present(state, dialogue)
	if not avatar.setup_error.is_empty():
		# A missing/invalid model cannot be recovered by claiming readiness.
		for action in ["listen", "run", "reset", "error"]:
			buttons[action].disabled = true
		buttons["power"].disabled = state == "OFFLINE"
		dialogue_label.text = avatar.setup_error
