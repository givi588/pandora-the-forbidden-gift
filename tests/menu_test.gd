extends SceneTree

const MENU := preload("res://main_menu.tscn")
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var settings_path := "user://pandora_menu_test_%d.cfg" % OS.get_process_id()
	var menu := MENU.instantiate()
	menu.settings_path = settings_path
	menu.settings.set_value("story", "enabled", true)
	root.add_child(menu)
	current_scene = menu
	await _frames()

	if DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_WINDOWED
		var quit_button: Button = menu.column.get_node("Quit")
		for dimensions: Vector2i in [Vector2i(960, 540), Vector2i(640, 720)]:
			root.size = dimensions
			await _frames()
			_check(root.get_visible_rect().encloses(quit_button.get_global_rect()),
				"Menu buttons fit the %dx%d window" % [root.size.x, root.size.y])

	_check(root.gui_get_focus_owner() == menu.home_button, "Play has keyboard focus on startup")
	await _key(KEY_DOWN)
	_check(root.gui_get_focus_owner() == menu.column.get_node("Settings"), "Down moves focus to Settings")
	await _key(KEY_ENTER)
	_check(menu.page == "settings", "Enter opens Settings")
	var volume: HSlider = menu.column.get_node("MasterVolume")
	await _key(KEY_LEFT)
	_check(volume.value == 75.0, "The volume slider responds to the keyboard")
	var saved := ConfigFile.new()
	_check(saved.load(settings_path) == OK and saved.get_value("audio", "master", 0.0) == 75.0,
		"Master volume is saved")
	var prologue: CheckButton = menu.column.get_node("ShowPrologue")
	await _click(prologue.get_global_rect().get_center())
	_check(not bool(menu.settings.get_value("story", "enabled", true)),
		"The prologue can be disabled with the mouse")
	await _click(prologue.get_global_rect().get_center())
	await _key(KEY_ESCAPE)
	_check(menu.page == "home" and root.gui_get_focus_owner() == menu.home_button,
		"Escape returns from Settings and restores Play focus")

	await _key(KEY_ENTER)
	_check(menu.page == "story" and menu.story_index == 0, "Play opens the prologue")
	await _key(KEY_ENTER)
	_check(menu.story_index == 1, "Continue reveals the second prologue page")
	var skip: Button = menu.column.get_node("SkipPrologue")
	await _click(skip.get_global_rect().get_center())
	_check(current_scene != null and current_scene.scene_file_path == "res://temple.tscn",
		"Clicking Skip prologue enters the temple")

	await _key(KEY_M)
	_check(current_scene != null and current_scene.scene_file_path == "res://temple.tscn",
		"M leaves the player in the temple")
	await _key(KEY_ESCAPE)
	_check(current_scene != null and current_scene.scene_file_path == "res://main_menu.tscn",
		"A single Esc press returns from the temple to the main menu")
	if DisplayServer.get_name() != "headless":
		_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Returning to the menu shows the cursor")
	if current_scene != null and current_scene.scene_file_path == "res://main_menu.tscn":
		menu = current_scene
		menu.settings_path = settings_path
		menu.settings.set_value("story", "enabled", true)
		await _key(KEY_ENTER)
		_check(menu.page == "story", "Play opens the prologue again after returning")
		await _key(KEY_ESCAPE)
		_check(current_scene != null and current_scene.scene_file_path == "res://temple.tscn",
			"Esc skips the prologue without immediately leaving the temple")
		if DisplayServer.get_name() != "headless":
			_check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Returning to gameplay captures the mouse")
			if current_scene != null and current_scene.scene_file_path == "res://temple.tscn":
				var player: CharacterBody3D = current_scene.get_node("Player")
				var yaw := player.rotation.y
				var motion := InputEventMouseMotion.new()
				motion.relative = Vector2(48, 0)
				root.push_input(motion, true)
				_check(not is_equal_approx(player.rotation.y, yaw), "Mouse look works after re-entering gameplay")
		await _key(KEY_ESCAPE)

	if current_scene != null and current_scene.scene_file_path == "res://main_menu.tscn":
		menu = current_scene
		menu.settings_path = settings_path
		menu.settings.set_value("story", "enabled", false)
		await _key(KEY_ENTER)
		_check(current_scene != null and current_scene.scene_file_path == "res://temple.tscn",
			"Play enters the temple directly with the prologue disabled")

	if FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(settings_path)
	if current_scene != null:
		current_scene.queue_free()
	await create_timer(0.10).timeout
	quit(1 if failures else 0)


func _key(key: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.physical_keycode = key
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await _frames()


func _click(at: Vector2) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await _frames()


func _frames() -> void:
	for index in range(4):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
