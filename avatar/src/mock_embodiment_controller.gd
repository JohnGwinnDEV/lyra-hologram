extends RefCounted

signal presentation_changed(state: String, dialogue: String)

const StateMachine = preload("res://src/avatar_state_machine.gd")
const RESPONSES = [
	"Hello. I'm LYRA's desktop embodiment. This response is scripted.",
	"Ready for the next experiment. My speech animation is simulated and silent.",
	"One step at a time. You can cancel this mock response at any point.",
]


class SilentSpeech:
	extends RefCounted

	func stop() -> bool:
		return true


var machine = StateMachine.new(SilentSpeech.new())
var dialogue := "Choose Run mock dialogue to begin."
var _request_number := 0
var _request_id := ""
var _elapsed := 0.0
var _phase := ""


func _init() -> void:
	machine.state_changed.connect(_on_state_changed)


func _on_state_changed(_previous: String, current: String) -> void:
	presentation_changed.emit(current, dialogue)


func _send(kind: String, extra: Dictionary = {}) -> Dictionary:
	var event := {"schema_version": 1, "type": kind, "request_id": _request_id}
	event.merge(extra, true)
	return machine.handle(event)


func action(name: String) -> void:
	match name:
		"listen":
			if machine.state == "IDLE":
				dialogue = "Simulated input ready. Run the mock, or cancel."
				_send("input.simulated")
		"run":
			if machine.state not in ["IDLE", "LISTENING"]:
				return
			_request_number += 1
			_request_id = "desktop-mock-%d" % _request_number
			_elapsed = 0.0
			_phase = "pending"
			dialogue = "Waiting for a scripted response…"
			_send("request.started")
		"cancel":
			_phase = ""
			if machine.state == "LISTENING":
				dialogue = "Simulated input cancelled."
				_send("input.cancelled")
			elif machine.state in ["THINKING", "SPEAKING"]:
				dialogue = "Mock response cancelled."
				_send("request.cancelled")
		"error":
			if machine.state in ["OFFLINE", "ERROR"]:
				return
			_phase = ""
			dialogue = "Simulated presentation failure. Reset to recover."
			_send("presentation.error")
		"reset":
			if machine.state == "ERROR":
				dialogue = "Presentation ready."
				_send("presentation.reset", {"ready": true})
		"power":
			_phase = ""
			if machine.state == "OFFLINE":
				dialogue = "Presentation ready."
				_send("presentation.ready")
			else:
				dialogue = "Presentation offline."
				_send("presentation.shutdown")


func advance(delta: float) -> void:
	if _phase.is_empty() or delta < 0.0:
		return
	_elapsed += delta
	if _phase == "pending" and _elapsed >= 0.75:
		_elapsed -= 0.75
		_phase = "speaking"
		dialogue = RESPONSES[(_request_number - 1) % RESPONSES.size()]
		_send("playback.started")
	if _phase == "speaking" and _elapsed >= 2.5:
		_phase = ""
		_send("playback.completed")
