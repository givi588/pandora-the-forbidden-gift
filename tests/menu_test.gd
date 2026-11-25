extends SceneTree

const MENU := preload("res://main_menu.tscn")
const TEMPLE := preload("res://temple.tscn")
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
		root.mode = Window.MODE_MAXIMIZED
		await _wait_for_window_mode(Window.MODE_MAXIMIZED)
		_check(root.mode == Window.MODE_MAXIMIZED, "The menu test can maximize the window")
		await _key(KEY_F11)
		await _wait_for_window_mode(Window.MODE_FULLSCREEN)
		_check(root.mode == Window.MODE_FULLSCREEN, "One F11 press enters fullscreen from a maximized menu")
		root.mode = Window.MODE_WINDOWED
		await _wait_for_window_mode(Window.MODE_WINDOWED)

	_check(root.gui_get_focus_owner() == menu.home_button, "Play has keyboard focus on startup")
	await _key(KEY_DOWN)
	_check(root.gui_get_focus_owner() == menu.column.get_node("Settings"), "Down moves focus to Settings")
	await _key(KEY_ENTER)
	_check(menu.page == "settings", "Enter opens Settings")
	if DisplayServer.get_name() != "headless":
		var fullscreen: CheckButton = menu.column.get_node("Fullscreen")
		fullscreen.grab_focus()
		await _key(KEY_F11)
		await _wait_for_window_mode(Window.MODE_FULLSCREEN)
		_check(root.gui_get_focus_owner() == fullscreen and fullscreen.button_pressed,
			"F11 in Settings updates the fullscreen checkbox without losing focus")
		await _key(KEY_F11)
		await _wait_for_window_mode(Window.MODE_WINDOWED)
		var display_settings := ConfigFile.new()
		_check(display_settings.load(settings_path) == OK
			and display_settings.get_value("display", "fullscreen", true) == false
			and not fullscreen.button_pressed,
			"F11 back to windowed mode updates and saves the preference")
	var volume: HSlider = menu.column.get_node("MasterVolume")
	volume.grab_focus()
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

	if current_scene != null:
		current_scene.queue_free()
		await process_frame
		await process_frame
	await _check_invalid_settings(settings_path)
	await _check_incomplete_temple()
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


func _check_invalid_settings(path: String) -> void:
	var fixture := ConfigFile.new()
	fixture.set_value("audio", "master", ["invalid"])
	fixture.set_value("story", "enabled", 0)
	var error := fixture.save(path)
	_check(error == OK, "The invalid-settings fixture can be saved")
	if error != OK:
		return
	var menu := MENU.instantiate()
	menu.settings_path = path
	root.add_child(menu)
	_check(is_equal_approx(AudioServer.get_bus_volume_db(0), linear_to_db(0.8)),
		"A non-numeric saved volume uses the default")
	menu._show_settings()
	var volume: HSlider = menu.column.get_node("MasterVolume")
	var prologue: CheckButton = menu.column.get_node("ShowPrologue")
	_check(volume.value == 80.0 and prologue.button_pressed,
		"Invalid saved option types show safe defaults")
	menu.queue_free()
	DirAccess.remove_absolute(path)
	await _frames()


func _check_incomplete_temple() -> void:
	var scene := TEMPLE.instantiate()
	scene.get_node("Player/Head/Camera3D").free()
	root.add_child(scene)
	current_scene = scene
	await _frames()
	_check(current_scene != null and current_scene.scene_file_path == MENU.resource_path,
		"A temple without a camera returns to the main menu")


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


func _wait_for_window_mode(mode: Window.Mode) -> void:
	var deadline := Time.get_ticks_msec() + 1000
	while root.mode != mode and Time.get_ticks_msec() < deadline:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
