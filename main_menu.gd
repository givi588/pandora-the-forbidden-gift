extends Control

const Geometry := preload("res://temple_geometry.gd")
const TEMPLE := "res://temple.tscn"
const KEY_ART := "res://assets/pandora_key_art.png"
const SETTINGS_PATH := "user://pandora_settings.cfg"
const GOLD := Color("#edca95")
const IVORY := Color("#f5e8d3")
const MUTED := Color("#b9c0ba")
const PROLOGUE := [
	"The gods placed a sealed gift in Pandora's hands. They spoke of everything it might offer, and gave her only one command: never raise the lid.",
	"Years later, a tremor still answers from beneath the temple. The old hymns say that even there, a little hope waits to be heard.",
]

var page := "home"
var story_index := 0
var settings := ConfigFile.new()
var settings_path := SETTINGS_PATH
var column: VBoxContainer
var heading_font := SystemFont.new()
var home_button: Button


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	settings.load(settings_path)
	_set_volume(float(settings.get_value("audio", "master", 80.0)))
	if not get_tree().has_meta("pandora_display_initialized"):
		get_tree().set_meta("pandora_display_initialized", true)
		if settings.has_section_key("display", "fullscreen"):
			_apply_fullscreen(bool(settings.get_value("display", "fullscreen")))
	heading_font.font_names = PackedStringArray(["Georgia", "Times New Roman", "Liberation Serif"])
	_build_background()
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 68)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 34)
	var rows := HBoxContainer.new()
	margin.add_child(rows)
	var alignment := VBoxContainer.new()
	alignment.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.add_child(alignment)
	column = VBoxContainer.new()
	column.custom_minimum_size.x = 360
	column.add_theme_constant_override("separation", 12)
	alignment.add_child(column)
	_show_home()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		match page:
			"settings": _show_home()
			"story": _enter_temple()
	elif event.is_action_pressed("toggle_fullscreen") and DisplayServer.get_name() != "headless":
		var fullscreen := get_window().mode == Window.MODE_WINDOWED
		_save_option("display", "fullscreen", fullscreen)
		_apply_fullscreen(fullscreen)
		if page == "settings":
			_show_settings()


func _build_background() -> void:
	if ResourceLoader.exists(KEY_ART, "Texture2D"):
		var art := TextureRect.new()
		art.texture = load(KEY_ART)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		var world := Geometry.new()
		add_child(world)
		var camera := Camera3D.new()
		world.add_child(camera)
		camera.position = Vector3(-3.55, 1.66, 8.25)
		camera.look_at(Vector3(-2.46, 1.48, 5.49))
		camera.fov = 57
		camera.current = true

	var shade := ColorRect.new()
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	float left = 1.0 - smoothstep(0.22, 0.76, UV.x);
	float edges = smoothstep(0.30, 0.72, distance(UV, vec2(0.58, 0.48)));
	COLOR = vec4(0.029, 0.046, 0.055, min(0.94, 0.19 + left * 0.68 + edges * 0.24));
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	shade.material = material
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _show_home() -> void:
	_clear("home")
	_label("PANDORA", 67, IVORY, true)
	_label("The Forbidden Gift", 28, GOLD, true)
	_gap(15)
	home_button = _button("Play", _play)
	_button("Settings", _show_settings)
	_button("Quit", func() -> void: get_tree().quit())
	home_button.grab_focus()


func _show_settings() -> void:
	_clear("settings")
	_label("Settings", 50, IVORY, true)
	var volume := HSlider.new()
	volume.name = "MasterVolume"
	volume.min_value = 0
	volume.max_value = 100
	volume.step = 5
	var current := float(settings.get_value("audio", "master", 80.0))
	var volume_label := _label("Master volume · %d%%" % current, 19, GOLD)
	volume.value = current
	volume.custom_minimum_size = Vector2(0, 36)
	volume.value_changed.connect(func(value: float) -> void:
		volume_label.text = "Master volume · %d%%" % value
		_set_volume(value)
		_save_option("audio", "master", value)
	)
	column.add_child(volume)
	var fullscreen := bool(settings.get_value("display", "fullscreen", true))
	if DisplayServer.get_name() != "headless":
		fullscreen = get_window().mode == Window.MODE_FULLSCREEN
	_checkbox("Fullscreen", fullscreen, func(value: bool) -> void:
		_save_option("display", "fullscreen", value)
		_apply_fullscreen(value)
	)
	_checkbox("Show prologue", bool(settings.get_value("story", "enabled", true)), func(value: bool) -> void:
		_save_option("story", "enabled", value)
	)
	_gap(8)
	_button("Back", _show_home)
	volume.grab_focus()


func _play() -> void:
	if bool(settings.get_value("story", "enabled", true)):
		story_index = 0
		_show_story()
	else:
		_enter_temple()


func _show_story() -> void:
	_clear("story")
	_label("The forbidden gift", 40, GOLD, true)
	var story := _label(PROLOGUE[story_index], 22, IVORY, true)
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.custom_minimum_size.x = 360
	_gap(10)
	var next: Button
	if story_index == 0:
		next = _button("Continue", func() -> void:
			story_index += 1
			_show_story()
		)
	else:
		next = _button("Enter temple", _enter_temple)
	_button("Skip prologue", _enter_temple)
	next.grab_focus()


func _enter_temple() -> void:
	var error := get_tree().change_scene_to_file(TEMPLE)
	if error != OK:
		_show_home()
		_label("Could not open the temple.", 18, GOLD)
		push_error("Could not load the temple: %s" % error_string(error))


func _clear(next_page: String) -> void:
	page = next_page
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()


func _label(content: String, size: int, color: Color, serif: bool = false) -> Label:
	var label := Label.new()
	label.text = content
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if serif:
		label.add_theme_font_override("font", heading_font)
	column.add_child(label)
	return label


func _button(content: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = content.to_pascal_case()
	button.text = content
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 51)
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", IVORY)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", GOLD)
	button.add_theme_stylebox_override("normal", _button_box(Color("#131e22"), Color("#5d5547")))
	button.add_theme_stylebox_override("hover", _button_box(Color("#293335"), GOLD))
	button.add_theme_stylebox_override("pressed", _button_box(Color("#343c37"), GOLD))
	button.add_theme_stylebox_override("focus", _button_box(Color.TRANSPARENT, GOLD))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	column.add_child(button)
	return button


func _checkbox(content: String, checked: bool, action: Callable) -> void:
	var option := CheckButton.new()
	option.name = content.to_pascal_case()
	option.text = content
	option.button_pressed = checked
	option.custom_minimum_size.y = 41
	option.add_theme_color_override("font_color", IVORY)
	option.add_theme_font_size_override("font_size", 19)
	option.toggled.connect(action)
	column.add_child(option)


func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.border_width_left = 3
	box.content_margin_left = 18
	return box


func _gap(height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	column.add_child(spacer)


func _set_volume(value: float) -> void:
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master, value <= 0.0)
	AudioServer.set_bus_volume_db(master, linear_to_db(maxf(0.001, value / 100.0)))


func _apply_fullscreen(enabled: bool) -> void:
	if DisplayServer.get_name() != "headless":
		get_window().mode = Window.MODE_FULLSCREEN if enabled else Window.MODE_WINDOWED


func _save_option(section: String, key: String, value: Variant) -> void:
	settings.set_value(section, key, value)
	var error := settings.save(settings_path)
	if error != OK:
		push_warning("Pandora could not save settings: %s" % error_string(error))
