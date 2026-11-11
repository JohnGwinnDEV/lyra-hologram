extends SceneTree

# Load dynamically so a missing implementation is an explicit test failure.
const MACHINE_PATH = "res://src/avatar_state_machine.gd"
var failures: int = 0


class FakeSpeech:

	var stop_calls: int = 0
	var stop_succeeds: bool = true


	func stop() -> bool:
		stop_calls += 1
		return stop_succeeds


func _initialize() -> void:
	_test_lifecycle()
	_test_validation()
	_test_cancellation()
	if failures == 0:
		print("PASS: all three presentation lifecycle tests")
	else:
		printerr("FAIL: %d assertions" % failures)
	quit(1 if failures else 0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)


func _machine(speech: FakeSpeech):
	if not ResourceLoader.exists(MACHINE_PATH):
		_expect(false, "AvatarStateMachine implementation is missing")
		return null
	var script = load(MACHINE_PATH)
	return script.new(speech)


func _event(kind: String, request_id: String = "request-1") -> Dictionary:
	return {"schema_version": 1, "type": kind, "request_id": request_id}


func _test_lifecycle() -> void:
	var machine = _machine(FakeSpeech.new())
	if machine == null:
		return
	var observed: Array = []
	machine.state_changed.connect(func(previous, current): observed.append([previous, current]))
	_expect(machine.state == "OFFLINE", "starts offline")
	for step in [
		["presentation.ready", "IDLE"],
		["request.started", "THINKING"],
		["playback.started", "SPEAKING"],
		["playback.completed", "IDLE"],
	]:
		var result: Dictionary = machine.handle(_event(step[0]))
		_expect(result.get("ok", false), "accept " + step[0])
		_expect(machine.state == step[1], "state after " + step[0])
	_expect(observed == [
		["OFFLINE", "IDLE"], ["IDLE", "THINKING"],
		["THINKING", "SPEAKING"], ["SPEAKING", "IDLE"],
	], "exactly one ordered notification per transition")


func _test_validation() -> void:
	var machine = _machine(FakeSpeech.new())
	if machine == null:
		return
	machine.handle(_event("presentation.ready"))
	var invalid: Dictionary = machine.handle(_event("playback.started"))
	_expect(not invalid.get("ok", true), "reject playback from idle")
	_expect(invalid.get("code") == "invalid_transition", "structured transition rejection")
	_expect(machine.state == "IDLE", "invalid transition preserves state")
	var unsupported = _event("request.started")
	unsupported["schema_version"] = 2
	var version_result: Dictionary = machine.handle(unsupported)
	_expect(not version_result.get("ok", true), "reject unsupported version")
	_expect(version_result.get("code") == "unsupported_version", "structured version rejection")
	_expect(machine.state == "IDLE", "unsupported version preserves state")
	for malformed in [
		{}, {"schema_version": 1, "type": 123},
		{"schema_version": 1, "type": "request.started", "request_id": ""},
	]:
		var malformed_result: Dictionary = machine.handle(malformed)
		_expect(malformed_result.get("code") == "invalid_event", "reject malformed event")
		_expect(machine.state == "IDLE", "malformed event preserves state")
	machine.handle(_event("input.simulated"))
	_expect(machine.state == "LISTENING", "simulated input enters listening")
	machine.handle(_event("input.cancelled"))
	machine.handle(_event("presentation.error"))
	_expect(machine.state == "ERROR", "component failure enters error")
	var reset_result: Dictionary = machine.handle(_event("presentation.reset"))
	_expect(reset_result.get("code") == "not_ready", "reset needs readiness confirmation")
	var reset = _event("presentation.reset")
	reset["ready"] = true
	machine.handle(reset)
	_expect(machine.state == "IDLE", "explicit ready reset recovers")


func _test_cancellation() -> void:
	var speech = FakeSpeech.new()
	var machine = _machine(speech)
	if machine == null:
		return
	machine.handle(_event("presentation.ready"))
	machine.handle(_event("request.started"))
	machine.handle(_event("playback.started"))
	var cancelled: Dictionary = machine.handle(_event("request.cancelled"))
	_expect(cancelled.get("ok", false), "cancel active request")
	_expect(machine.state == "IDLE", "cancel returns to idle")
	machine.handle(_event("request.cancelled"))
	_expect(speech.stop_calls == 1, "repeated cancel stops backend exactly once")
	# A new request must not be affected by callbacks from the cancelled request.
	machine.handle(_event("request.started", "request-2"))
	machine.handle(_event("playback.started"))
	machine.handle(_event("playback.completed"))
	_expect(machine.state == "THINKING", "late callbacks cannot affect new request")
	machine.handle(_event("playback.started", "request-2"))
	_expect(machine.state == "SPEAKING", "new request remains usable")
	speech.stop_succeeds = false
	var failed: Dictionary = machine.handle(_event("request.cancelled", "request-2"))
	_expect(failed.get("code") == "stop_failed", "report unsuccessful stop")
	_expect(machine.state == "ERROR", "unsuccessful stop enters error")
	var reset = _event("presentation.reset")
	reset["ready"] = true
	var unsafe_reset: Dictionary = machine.handle(reset)
	_expect(not unsafe_reset.get("ok", true), "cannot reset while playback stop is unresolved")
	speech.stop_succeeds = true
	machine.handle(_event("presentation.shutdown"))
	_expect(machine.state == "OFFLINE", "shutdown retries stop and goes offline")
	_expect(speech.stop_calls == 3, "failed stop is retried during shutdown")
