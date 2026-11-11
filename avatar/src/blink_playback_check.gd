extends Node

# Optional observation of normal scene processing: never drives animation.
var avatar: Node3D
var elapsed := 0.0
var peak := 0.0
var frames := 0
var longest_frame := 0.0
var captured := false
var capture_pending := false


func _ready() -> void:
	process_priority = 100
	avatar = get_parent().avatar
	print("Blink check: observing normal playback for 7 seconds; source: ",
		ProjectSettings.globalize_path("res://src/rigged_avatar.gd"))
	if not avatar.setup_error.is_empty():
		printerr("Blink check: " + avatar.setup_error)
		get_tree().quit(1)


func _process(delta: float) -> void:
	elapsed += delta
	frames += 1
	longest_frame = maxf(longest_frame, delta)
	var strength: float = minf(avatar.morph_value("blink_left"), avatar.morph_value("blink_right"))
	peak = maxf(peak, strength)
	if strength > 0.9 and not captured and not capture_pending:
		print("Blink check: both eyelids closed at %.2fs; strength %.3f" % [elapsed, strength])
		if DisplayServer.get_name() == "headless":
			captured = true
		else:
			capture_pending = true
			_capture_frame()
	if elapsed >= 7.0 and not capture_pending:
		print("Blink check: peak %.3f; average %.1f FPS; longest frame %.3fs; %s" %
			[peak, frames / elapsed, longest_frame, "PASS" if captured else "FAIL"])
		get_tree().quit(0 if captured else 1)


func _capture_frame() -> void:
	await RenderingServer.frame_post_draw
	var path := "user://blink-check.png"
	var result := get_viewport().get_texture().get_image().save_png(path)
	captured = result == OK
	capture_pending = false
	if captured:
		print("Blink check: rendered frame saved to ", ProjectSettings.globalize_path(path))
	else:
		printerr("Blink check: failed to save rendered frame: ", result)
