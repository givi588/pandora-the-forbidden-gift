extends Control
## Owns the portal transition and ending interface for one temple run.

signal play_again
signal main_menu

const DARK := Color("#10191d")
const GOLD := Color("#e6bf85")
const IVORY := Color("#f3e4cc")
const REVEAL_TIME := 1.65

var outcome: Label
var title: Label
var quote: Label
var card: VBoxContainer
var replay_button: Button
var menu_button: Button
var _veil: ColorRect
var _transition: Tween
var _camera: Camera3D
var _light: OmniLight3D
var _normal_fov: float
var _normal_transform: Transform3D
var _normal_energy: float


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil = ColorRect.new()
	_veil.color = DARK
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_veil)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 16)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(card)

	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Times New Roman", "Liberation Serif"])
	title = _label("PANDORA — THE FORBIDDEN GIFT", 39, IVORY)
	title.add_theme_font_override("font", serif)
	var divider := ColorRect.new()
	divider.color = Color("#9e7954")
	divider.custom_minimum_size = Vector2(112, 1)
	divider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(divider)
	quote = _label("“The darkness was released. Hope remained.”", 27, IVORY)
	quote.add_theme_font_override("font", serif)
	_label("THE END", 16, GOLD)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	card.add_child(buttons)
	replay_button = _button("Play Again", buttons)
	menu_button = _button("Main Menu", buttons)
	replay_button.pressed.connect(func() -> void: play_again.emit())
	menu_button.pressed.connect(func() -> void: main_menu.emit())
	_label("R  Play again    •    Esc  Main menu", 15, GOLD)

	# The brief arrival message sits over the scene while the portal is still visible.
	outcome = Label.new()
	outcome.text = "You escaped the temple."
	outcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outcome.add_theme_font_size_override("font_size", 23)
	outcome.add_theme_color_override("font_color", GOLD)
	outcome.add_theme_color_override("font_outline_color", DARK)
	outcome.add_theme_constant_override("outline_size", 6)
	outcome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(outcome)
	outcome.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	outcome.offset_left = -245
	outcome.offset_right = 245
	outcome.offset_top = -136
	outcome.offset_bottom = -96
	reset()


func begin(camera: Camera3D, light: OmniLight3D, portal: Vector3, fade_audio: Callable) -> void:
	if visible:
		return
	_camera = camera
	_light = light
	_normal_fov = camera.fov
	_normal_transform = camera.transform
	_normal_energy = light.light_energy
	show()
	outcome.show()
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_transition = create_tween().set_parallel(true)
	_transition.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var framing := Transform3D(Basis.IDENTITY, portal + Vector3(0, 1.60, 3.4))
	framing = framing.looking_at(portal + Vector3(0, 2.32, 0))
	_transition.tween_property(_camera, "global_transform", framing, 1.25)
	_transition.tween_property(_camera, "fov", _normal_fov - 7.0, 1.28)
	_transition.tween_property(_light, "light_energy", _normal_energy + 1.85, 1.38)
	_transition.tween_method(fade_audio, 0.0, 1.0, 1.85)
	_transition.tween_property(_veil, "modulate:a", 1.0, 1.14).set_delay(0.82)
	_transition.tween_property(outcome, "modulate:a", 0.0, 0.52).set_delay(0.97)
	_transition.tween_callback(_reveal).set_delay(REVEAL_TIME)
	_transition.tween_property(card, "modulate:a", 1.0, 0.52).set_delay(REVEAL_TIME)


func reset() -> void:
	if _transition != null:
		_transition.kill()
		_transition = null
	if is_instance_valid(_camera):
		_camera.fov = _normal_fov
		_camera.transform = _normal_transform
		_camera = null
	if is_instance_valid(_light):
		_light.light_energy = _normal_energy
		_light = null
	_veil.modulate.a = 0.0
	card.modulate.a = 0.0
	card.hide()
	outcome.modulate.a = 1.0
	outcome.hide()
	hide()


func _reveal() -> void:
	card.show()
	replay_button.grab_focus()


func _label(content: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = content
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	card.add_child(label)
	return label


func _button(content: String, buttons: HBoxContainer) -> Button:
	var button := Button.new()
	button.text = content
	button.custom_minimum_size = Vector2(176, 50)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", IVORY)
	button.add_theme_color_override("font_focus_color", GOLD)
	button.add_theme_stylebox_override("normal", _style(Color("#1b282d"), Color("#756047")))
	button.add_theme_stylebox_override("hover", _style(Color("#2b3639"), GOLD))
	button.add_theme_stylebox_override("pressed", _style(Color("#323732"), GOLD))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GOLD))
	buttons.add_child(button)
	return button


func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.border_width_left = 3
	return box
