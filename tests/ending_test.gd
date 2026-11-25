extends SceneTree

const TEMPLE := preload("res://temple.tscn")
const MENU_PATH := "res://main_menu.tscn"
const SPAWN := Vector3(0, 0.02, 9)

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var temple := _start_temple()
	await _physics_frames(4)
	var normal_fov: float = temple.player.camera.fov
	var normal_light: float = temple.room.exit_light.light_energy
	await _reach_exit(temple)
	var ending = temple.ending
	_check(temple.completed and ending.visible and ending.outcome.visible,
		"Entering the original exit region starts the ending")
	var frozen: Vector3 = temple.player.position
	var rotation: Vector3 = temple.player.rotation
	_key(KEY_W, true)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(140, -60)
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	await _physics_frames(8)
	_key(KEY_W, false)
	_check(temple.player.position == frozen and temple.player.rotation == rotation
		and temple.player.velocity == Vector3.ZERO and not temple.player.walking_enabled,
		"Movement and mouse look leave the player stationary during the ending")
	await create_timer(2.24).timeout
	_check(ending.card.is_visible_in_tree() and ending.card.modulate.a > 0.99
		and ending.title.text == "PANDORA — THE FORBIDDEN GIFT"
		and ending.quote.text == "“The darkness was released. Hope remained.”",
		"The title, quote, and final screen are fully visible")
	_check(root.gui_get_focus_owner() == ending.replay_button
		and ending.menu_button.is_visible_in_tree(), "Both ending options are available")
	_key(KEY_TAB, true)
	_key(KEY_TAB, false)
	await _physics_frames(2)
	_check(root.gui_get_focus_owner() == ending.menu_button, "Tab reaches Main Menu")
	await create_timer(0.15).timeout
	_check(root.gui_get_focus_owner() == ending.menu_button
		and is_equal_approx(temple.player.camera.fov, normal_fov - 7.0)
		and is_equal_approx(temple.room.exit_light.light_energy, normal_light + 1.85),
		"Remaining in the victory region does not start the sequence again")
	if DisplayServer.get_name() != "headless":
		_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not temple.sound._ambient.playing,
			"The ending releases the cursor and finishes fading the room audio")
		root.mode = Window.MODE_WINDOWED
		for dimensions: Vector2i in [Vector2i(960, 540), Vector2i(800, 600)]:
			root.size = dimensions
			await _physics_frames(8)
			_check(root.get_visible_rect().encloses(ending.card.get_global_rect()),
				"The ending fits the %dx%d window" % [root.size.x, root.size.y])

	await _click(ending.replay_button)
	_check(_restored(temple, normal_fov, normal_light), "Clicking Play Again resets the room, camera, and light")
	if DisplayServer.get_name() != "headless":
		_check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and temple.sound._ambient.playing,
			"Replay recaptures the mouse and resumes ambience")

	await _reach_exit(temple)
	await _tap(KEY_R)
	await create_timer(2.24).timeout
	_check(_restored(temple, normal_fov, normal_light),
		"R interrupts the ending and its tween cannot affect the restarted run")

	await _reach_exit(temple)
	await create_timer(2.24).timeout
	await _tap(KEY_RIGHT)
	_check(root.gui_get_focus_owner() == ending.menu_button, "Right arrow focuses Main Menu")
	await _tap(KEY_ENTER)
	_check(_at_main_menu(), "Enter on Main Menu loads the existing main menu")

	if _at_main_menu():
		current_scene.queue_free()
		await process_frame
		await process_frame
		temple = _start_temple()
		await _physics_frames(4)
		await _reach_exit(temple)
		await _tap(KEY_M)
		_check(current_scene == temple and temple.ending.visible, "M leaves the ending open")
		await _tap(KEY_ESCAPE)
		_check(_at_main_menu(), "A single Esc press returns to the menu during the ending transition")

	if _at_main_menu():
		current_scene.queue_free()
		await process_frame
		await process_frame
		temple = _start_temple()
		await _physics_frames(4)
		await _reach_exit(temple)
		await create_timer(2.24).timeout
		_check(root.gui_get_focus_owner() == temple.ending.replay_button,
			"The final ending screen has a focused button before Esc")
		await _tap(KEY_ESCAPE)
		_check(_at_main_menu(), "A single Esc press returns to the menu after the ending")
		if DisplayServer.get_name() != "headless":
			_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Esc leaves the ending with a visible cursor")

	if current_scene != null:
		current_scene.queue_free()
	await create_timer(0.15).timeout
	quit(1 if failures else 0)


func _start_temple() -> Node3D:
	var scene := TEMPLE.instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	return scene


func _reach_exit(temple) -> void:
	# Exercise the actual position trigger. The puzzle regression also reaches it on foot.
	temple.player.position = Vector3(0.0, 0.02, -11.20)
	await _physics_frames(3)


func _restored(temple, normal_fov: float, normal_light: float) -> bool:
	return (not temple.completed and not temple.ending.visible and not temple.ending.card.visible
		and temple.player.walking_enabled and absf(temple.player.position.y - SPAWN.y) < 0.03
		and temple.player.position.z == SPAWN.z and temple.player.rotation == Vector3.ZERO
		and temple.player.head.rotation == Vector3.ZERO and temple.player.camera.position == Vector3.ZERO
		and is_equal_approx(temple.player.camera.fov, normal_fov)
		and is_equal_approx(temple.room.exit_light.light_energy, normal_light)
		and temple.overlay.visible and not temple.lid_open and not temple.released
		and temple.room.bridge.disabled)


func _at_main_menu() -> bool:
	return current_scene != null and current_scene.scene_file_path == MENU_PATH


func _click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await _physics_frames(3)


func _tap(key: Key) -> void:
	_key(key, true)
	_key(key, false)
	await _physics_frames(5)


func _key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _physics_frames(count: int) -> void:
	for index in range(count):
		await physics_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)
