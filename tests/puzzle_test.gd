extends SceneTree

const TEMPLE := preload("res://temple.tscn")

var temple
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	temple = TEMPLE.instantiate()
	root.add_child(temple)
	await _frames(4)

	var portal := temple.room.get_node_or_null("ExitPortalModel") as Node3D
	_check(portal != null, "The imported exit portal is present")
	if portal != null:
		_check(not portal.find_children("*", "MeshInstance3D", true, false).is_empty(),
			"The imported exit portal contains visible geometry")
		_check(not portal is CollisionObject3D
			and portal.find_children("*", "CollisionObject3D", true, false).is_empty()
			and portal.find_children("*", "CollisionShape3D", true, false).is_empty(),
			"The decorative exit portal has no blocking collision")

	if DisplayServer.get_name() != "headless":
		_check(root.mode == Window.MODE_FULLSCREEN, "The game starts in fullscreen")
		await _tap(KEY_F11)
		await _wait_for_window_mode(Window.MODE_WINDOWED)
		_check(root.mode == Window.MODE_WINDOWED, "F11 switches to windowed mode")
		await _tap(KEY_F11)
		await _wait_for_window_mode(Window.MODE_FULLSCREEN)
		_check(root.mode == Window.MODE_FULLSCREEN, "F11 restores fullscreen")
		var motion := InputEventMouseMotion.new()
		motion.relative = Vector2(48, -32)
		Input.parse_input_event(motion)
		Input.flush_buffered_events()
		_check(temple.player.rotation.y < 0.0 and temple.player.head.rotation.x > 0.0,
			"Mouse movement turns and tilts the first-person camera")
		await _tap(KEY_R)

	await _tap(KEY_E)
	_check(not temple.released, "E has no effect out of reach")
	await _tap(KEY_SPACE)
	_check(temple.player.position.y > 0.08, "Space jumps from the floor")
	var upward_speed: float = temple.player.velocity.y
	await _tap(KEY_SPACE)
	_check(temple.player.velocity.y < upward_speed, "Space cannot jump again in midair")
	await _frames(60)
	_check(temple.player.is_on_floor(), "The player lands after jumping")
	await _walk(170)
	_check(temple.reset_notice.contains("chasm"), "The gap blocks progress and falling resets the room")
	_check(not temple.released and temple.room.bridge.disabled, "The bridge starts absent after a fall")

	await _tap(KEY_R)
	await _walk(99)
	await _tap(KEY_SPACE)
	await _walk(130)
	_check(temple.reset_notice.contains("chasm"), "Jumping cannot bypass the gap before the slab falls")

	await _tap(KEY_R)
	await _walk(52)
	_check(temple.prompt.text.contains("Open"), "The box is reachable from the starting side")
	await _tap(KEY_E)
	await _frames(54)
	_check(temple.lid_open and temple.landed, "Opening the box releases and settles the slab")
	var lid_model := temple.room.lid.get_node_or_null("PandoraBoxLidModel") as Node3D
	_check(lid_model != null and lid_model.global_rotation.x < -1.2,
		"The imported lid opens around the existing hinge")
	_check(temple.status.text.contains("Close the lid"), "Tremor cue tells the player to close the lid")
	_check(temple.player.camera.position.length() > 0.0, "The camera shakes while the lid is open")

	await _walk(44)
	await _tap(KEY_SPACE)
	await _walk(18)
	_check(temple.reset_notice.contains("tremors"), "Entering the gap with the lid open resets the room")
	_check(not temple.lid_open and not temple.landed and temple.room.bridge.disabled,
		"Tremor reset restores the lid, slab, and collision")
	_check(lid_model != null and is_zero_approx(lid_model.global_rotation.x),
		"Reset closes the imported lid")

	await _tap(KEY_R)
	await _walk(52)
	await _tap(KEY_E)
	await _tap(KEY_E)
	_check(not temple.lid_open and not temple.landed, "The lid can close while the slab is falling")
	_check(temple.player.camera.position == Vector3.ZERO, "Closing the lid stops the shaking")
	await _frames(54)
	_check(not temple.room.bridge.disabled and temple.status.text.contains("safe"),
		"The settled bridge has collision and a safe crossing cue")

	await _tap(KEY_E)
	_check(temple.lid_open and temple.landed, "Reopening the box leaves the bridge seated")
	await _tap(KEY_E)
	_check(not temple.lid_open and temple.status.text.contains("safe"),
		"Closing the box after the slab has landed makes the crossing safe")

	await _walk(360)
	_check(temple.completed and temple.completion.visible, "Walking across the bridge reaches the exit")
	_check(temple.completion.text.begins_with("You escaped the temple.") and temple.completion.visible,
		"The victory message is visible at the portal")
	var exit_position: Vector3 = temple.player.position
	_check(exit_position.z < -11.12 and absf(exit_position.x) < 1.05,
		"The player can enter the original victory region")
	await _tap(KEY_R)
	_check(not temple.completed and not temple.completion.visible and temple.player.position.z == 9.0,
		"R restarts the puzzle after completion")
	_check(temple.room.slab.position.y > 4.0 and temple.room.bridge.disabled,
		"R restores the suspended slab and removes bridge collision")
	_check(portal != null and portal.is_inside_tree() and not temple.lid_open and not temple.released,
		"R keeps the portal in place and restores the box and puzzle state")
	temple.queue_free()
	await create_timer(0.10).timeout
	quit(1 if failures else 0)


func _tap(key: Key) -> void:
	_send_key(key, true)
	_send_key(key, false)
	Input.flush_buffered_events()
	await _frames(4)


func _walk(frame_count: int) -> void:
	_send_key(KEY_W, true)
	await _frames(frame_count)
	_send_key(KEY_W, false)
	await _frames(2)


func _send_key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame


func _wait_for_window_mode(mode: Window.Mode) -> void:
	var deadline := Time.get_ticks_msec() + 1000
	while root.mode != mode and Time.get_ticks_msec() < deadline:
		await process_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)
