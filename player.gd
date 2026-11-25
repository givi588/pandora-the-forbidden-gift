extends CharacterBody3D

const WALK_SPEED := 3.4
const JUMP_SPEED := 4.2
const MOUSE_SENSITIVITY := 0.0022

var walking_enabled := true
var jump_requested := false

@onready var head := get_node_or_null("Head") as Node3D
@onready var camera := get_node_or_null("Head/Camera3D") as Camera3D


func _unhandled_input(event: InputEvent) -> void:
	if not walking_enabled:
		return
	if event.is_action_pressed("jump"):
		jump_requested = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotation.x = clampf(
			head.rotation.x - event.relative.y * MOUSE_SENSITIVITY, -1.45, 1.45
		)


func walk(delta: float) -> void:
	var input := Vector2.ZERO
	if walking_enabled:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := transform.basis * Vector3(input.x, 0.0, input.y)
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	if jump_requested and is_on_floor():
		velocity.y = JUMP_SPEED
	elif not is_on_floor():
		velocity += get_gravity() * delta
	jump_requested = false
	move_and_slide()


func respawn(at: Vector3) -> void:
	position = at
	rotation = Vector3.ZERO
	head.rotation = Vector3.ZERO
	velocity = Vector3.ZERO
	jump_requested = false
	walking_enabled = true
	shake(0.0)


func shake(amount: float, elapsed: float = 0.0) -> void:
	camera.position = Vector3(sin(elapsed * 39.0), cos(elapsed * 47.0), 0.0) * amount
	camera.rotation.z = sin(elapsed * 31.0) * amount * 0.5
