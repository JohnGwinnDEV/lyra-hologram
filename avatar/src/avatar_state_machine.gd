extends RefCounted

signal state_changed(previous: String, current: String)

const TRANSITIONS = {
	"presentation.ready": {"OFFLINE": "IDLE"},
	"input.simulated": {"IDLE": "LISTENING"},
	"input.cancelled": {"LISTENING": "IDLE"},
	"request.started": {"IDLE": "THINKING", "LISTENING": "THINKING"},
	"request.completed": {"THINKING": "IDLE"},
	"playback.started": {"THINKING": "SPEAKING"},
	"playback.completed": {"SPEAKING": "IDLE"},
	"presentation.reset": {"ERROR": "IDLE"},
}
const REQUEST_EVENTS = [
	"request.started", "request.completed", "request.cancelled",
	"playback.started", "playback.completed",
]

var state: String = "OFFLINE":
	get:
		return _state
var _state: String = "OFFLINE"
var _active_request: String = ""
# Request IDs cannot be reused during a session; this also guards late callbacks.
var _seen_requests: Dictionary = {}
var _speech: RefCounted


func _init(speech: RefCounted) -> void:
	_speech = speech


func handle(event: Dictionary) -> Dictionary:
	if typeof(event.get("schema_version")) != TYPE_INT:
		return _reject("invalid_event")
	if event["schema_version"] != 1:
		return _reject("unsupported_version")
	if typeof(event.get("type")) != TYPE_STRING:
		return _reject("invalid_event")
	var kind: String = event["type"]
	if kind not in TRANSITIONS and kind not in [
		"request.cancelled", "presentation.error", "presentation.shutdown"
	]:
		return _reject("unknown_event")
	var request_id: String = ""
	if kind in REQUEST_EVENTS:
		if typeof(event.get("request_id")) != TYPE_STRING or event["request_id"].strip_edges().is_empty():
			return _reject("invalid_event")
		request_id = event["request_id"]
		if kind == "request.started":
			if _seen_requests.has(request_id):
				return _reject("duplicate_request")
		elif request_id != _active_request:
			if _seen_requests.has(request_id):
				return {"ok": true, "ignored": true}
			return _reject("invalid_transition")
	if kind == "presentation.reset":
		if event.get("ready") != true or not _active_request.is_empty():
			return _reject("not_ready")
	if kind in ["request.cancelled", "presentation.error", "presentation.shutdown"]:
		if kind == "presentation.error" and _state == "OFFLINE":
			return _reject("invalid_transition")
		# stop() is synchronous: true confirms playback has stopped.
		if not _active_request.is_empty():
			if not _speech.stop():
				_change_state("ERROR")
				return _reject("stop_failed")
			_active_request = ""
		var destination = "IDLE"
		if kind == "presentation.error":
			destination = "ERROR"
		elif kind == "presentation.shutdown":
			destination = "OFFLINE"
		_change_state(destination)
		return {"ok": true}
	var allowed: Dictionary = TRANSITIONS[kind]
	if not allowed.has(_state):
		return _reject("invalid_transition")
	if kind == "request.started":
		_active_request = request_id
		_seen_requests[request_id] = true
	elif kind in ["request.completed", "playback.completed"]:
		_active_request = ""
	_change_state(allowed[_state])
	return {"ok": true}


func _change_state(next: String) -> void:
	if next == _state:
		return
	var previous = _state
	_state = next
	state_changed.emit(previous, _state)


func _reject(code: String) -> Dictionary:
	return {"ok": false, "code": code}
