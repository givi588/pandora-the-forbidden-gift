extends Node3D

const Geometry := preload("res://temple_geometry.gd")
const TempleAudio := preload("res://temple_audio.gd")
const EndingScreen := preload("res://ending_screen.gd")
const TemplePlayer := preload("res://player.gd")
const MENU := "res://main_menu.tscn"
const SPAWN := Vector3(0, 0.02, 9)
const FALL_DURATION := 0.85
const INTERACT_DISTANCE := 2.30
const UNSAFE_CROSSING_Z := Geometry.PIT_HALF_LENGTH - 0.22
const FALL_RESET_Y := -3.4
const EXIT_TRIGGER_Z := -11.12
const EXIT_HALF_WIDTH := 1.05
const NOTICE_DURATION := 3.0
const AMBER := Color("#ffd095")
const TEAL := Color("#a8f3dd")

var lid_open := false
var released := false
var landed := false
var completed := false
var returning_to_menu := false
var fall_time := 0.0
var shake_time := 0.0
var notice_text := ""
var notice_time := 0.0
var interact_requested := false
var restart_requested := false

var status: Label
var prompt: Label
var prompt_card: CenterContainer
var completion: Label
var sound: TempleAudio
var ending: EndingScreen

@onready var room := get_node_or_null("Architecture") as Geometry
@onready var player := get_node_or_null("Player") as TemplePlayer
@onready var overlay := get_node_or_null("HUD/Overlay") as Control


func _ready() -> void:
	var collider := get_node_or_null("Player/CollisionShape3D") as CollisionShape3D
	if (room == null or overlay == null or player == null or player.head == null
		or player.camera == null or collider == null or collider.shape == null):
		set_physics_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		if player != null:
			player.walking_enabled = false
		push_warning("The temple scene is incomplete. Returning to the main menu.")
		_return_to_menu.call_deferred()
		return

	sound = TempleAudio.new()
	ending = EndingScreen.new()
	add_child(sound)
	_create_hud()
	overlay.add_sibling(ending)
	completion = ending.outcome
	ending.play_again.connect(func() -> void: restart_requested = true)
	ending.main_menu.connect(_return_to_menu)
	_reset()
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_requested = true
	elif event.is_action_pressed("interact") and not completed:
		interact_requested = true
	elif event.is_action_pressed("toggle_fullscreen") and DisplayServer.get_name() != "headless":
		var window := get_window()
		if window.mode == Window.MODE_FULLSCREEN or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
			window.mode = Window.MODE_WINDOWED
		else:
			window.mode = Window.MODE_FULLSCREEN


func _return_to_menu() -> void:
	if not returning_to_menu:
		returning_to_menu = get_tree().change_scene_to_file(MENU) == OK


func _physics_process(delta: float) -> void:
	if returning_to_menu:
		return
	if restart_requested:
		_reset("Puzzle restarted.")
		return
	if completed:
		return

	if interact_requested:
		interact_requested = false
		_interact_with_box()

	_update_slab(delta)
	var lid_angle := -1.30 if lid_open else 0.0
	room.lid.rotation.x = move_toward(room.lid.rotation.x, lid_angle, 7.0 * delta)
	shake_time = shake_time + delta if lid_open else 0.0
	player.shake(0.055 if lid_open else 0.0, shake_time)
	room.update_tremors(lid_open, shake_time, delta)
	room.bridge_inlay.emission = TEAL if landed and not lid_open else AMBER

	player.walk(delta)
	var at: Vector3 = player.position
	if lid_open and at.z < UNSAFE_CROSSING_Z:
		_reset("The tremors knocked you back. Close the lid before crossing.")
		return
	if at.y < FALL_RESET_Y:
		_reset("You fell into the chasm. The room has reset.")
		return
	if at.z < EXIT_TRIGGER_Z and absf(at.x) < EXIT_HALF_WIDTH:
		_reach_exit()
		return

	notice_time = maxf(notice_time - delta, 0.0)
	_update_hud()


func _interact_with_box() -> void:
	if not _near_box():
		if not released and notice_time == 0.0:
			_show_notice("Move closer to Pandora’s box to open it.")
		return

	lid_open = not lid_open
	released = true
	notice_time = 0.0
	sound.set_lid(lid_open)


func _update_slab(delta: float) -> void:
	if not released or landed:
		return

	fall_time = minf(fall_time + delta, FALL_DURATION)
	var progress := fall_time / FALL_DURATION
	room.slab.position = Geometry.SLAB_RAISED.lerp(Geometry.SLAB_LANDED, progress * progress)
	if fall_time >= FALL_DURATION:
		landed = true
		room.bridge.set_deferred("disabled", false)
		room.show_slab_impact()
		sound.slab_impact()


func _reach_exit() -> void:
	completed = true
	player.walking_enabled = false
	player.velocity = Vector3.ZERO
	player.jump_requested = false
	notice_time = 0.0
	overlay.hide()
	sound.reached_exit()
	ending.begin(player.camera, room.exit_light, room.exit_portal.global_position, sound.set_ending_blend)


func _near_box() -> bool:
	var offset: Vector3 = player.position - Geometry.BOX_POSITION
	return Vector2(offset.x, offset.z).length() <= INTERACT_DISTANCE and absf(offset.y) <= 1.5


func _reset(message: String = "") -> void:
	var was_completed := completed
	interact_requested = false
	restart_requested = false
	lid_open = false
	released = false
	landed = false
	completed = false
	fall_time = 0.0
	shake_time = 0.0
	room.lid.rotation.x = 0.0
	room.slab.position = Geometry.SLAB_RAISED
	room.bridge.set_deferred("disabled", true)
	room.bridge_inlay.emission = AMBER
	room.reset_effects()
	ending.reset()
	sound.reset()
	player.respawn(SPAWN)
	overlay.show()
	if was_completed and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_show_notice(message)
	_update_hud()


func _show_notice(message: String) -> void:
	notice_text = message
	notice_time = NOTICE_DURATION if not message.is_empty() else 0.0


func _update_hud() -> void:
	status.modulate = AMBER if lid_open or notice_time > 0.0 else TEAL
	if completed:
		status.text = ""
	elif lid_open:
		status.text = "The slab has landed. Close the lid before crossing." if landed else "Tremors! Close the lid before crossing."
	elif notice_time > 0.0:
		status.text = notice_text
	elif landed:
		status.text = "The bridge is safe. Cross to the exit."
	elif released:
		status.text = "The slab is falling. Wait for it to settle."
	elif _near_box():
		status.text = ""
	else:
		status.text = "Approach Pandora’s box."

	prompt.text = ""
	var can_interact := not completed and _near_box()
	prompt_card.visible = can_interact
	if can_interact:
		prompt.text = "Close the lid" if lid_open else "Open Pandora’s box"


func _create_hud() -> void:
	var title := _label("P A N D O R A", 19)
	title.modulate = AMBER
	title.position = Vector2(28, 23)

	var controls := _label(
		"WASD  Move    •    Mouse  Look    •    Space  Jump    •    R  Restart    •    Esc  Menu    •    F11  Fullscreen",
		16
	)
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	controls.position += Vector2(28, -47)

	status = _label("", 23)
	status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	status.offset_left = -390
	status.offset_right = 390
	status.offset_top = -126
	status.offset_bottom = -79
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var reticle := _label("·", 28)
	reticle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	reticle.offset_left = -12
	reticle.offset_right = 12
	reticle.offset_top = -18
	reticle.offset_bottom = 18
	reticle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	prompt_card = CenterContainer.new()
	prompt_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(prompt_card)
	prompt_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	prompt_card.offset_left = -195
	prompt_card.offset_right = 195
	prompt_card.offset_top = 27
	prompt_card.offset_bottom = 74
	var plate := PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color("#132027ee")
	backing.border_color = Color("#a48765")
	backing.set_border_width_all(1)
	backing.content_margin_left = 13
	backing.content_margin_right = 13
	backing.content_margin_top = 6
	backing.content_margin_bottom = 6
	plate.add_theme_stylebox_override("panel", backing)
	prompt_card.add_child(plate)
	var prompt_row := HBoxContainer.new()
	prompt_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_row.add_theme_constant_override("separation", 13)
	plate.add_child(prompt_row)
	var key := _label("E", 21)
	key.modulate = TEAL
	key.reparent(prompt_row, false)
	prompt = _label("", 21)
	prompt.modulate = AMBER
	prompt.reparent(prompt_row, false)

func _label(content: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = content
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color("#0e191e"))
	label.add_theme_constant_override("outline_size", 8)
	overlay.add_child(label)
	return label
