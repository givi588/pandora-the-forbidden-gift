extends Node3D

const BOX_BODY := preload("res://assets/models/pandora_box_body.glb")
const BOX_LID := preload("res://assets/models/pandora_box_lid.glb")
const EXIT_PORTAL := preload("res://assets/models/temple_exit.glb")
const PIT_HALF_LENGTH := 3.0
const BOX_POSITION := Vector3(-1.72, 0.94, 5.85)
const SLAB_RAISED := Vector3(0.0, 4.6, 0.0)
const SLAB_LANDED := Vector3(0.0, -0.30, 0.0)

var lid: Node3D
var slab: Node3D
var bridge: CollisionShape3D
var bridge_inlay: StandardMaterial3D
var exit_portal: Node3D
var exit_light: OmniLight3D
var _seal_light: OmniLight3D
var _impact_dust: CPUParticles3D
var _chasm_light: OmniLight3D

var _stone := _material(Color("#535752"))
var _marble := _material(Color("#77786d"))
var _trim := _material(Color("#72766a"))
var _bronze := _material(Color("#ae7944"))
var _dark := _material(Color("#242e31"))
var _amber := _material(Color("#f8ac57"), 0.8)
var _teal := _material(Color("#74ccd0"), 0.95)
var _tiles := [
	_material(Color("#414947")), _material(Color("#4a514a")), _material(Color("#444c49")),
]
var _column_mesh: ArrayMesh


func _ready() -> void:
	var atmosphere := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#0b151b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#a6b9be")
	environment.ambient_light_energy = 0.48
	environment.fog_enabled = true
	environment.fog_light_color = Color("#445a5e")
	environment.fog_density = 0.012
	atmosphere.environment = environment
	add_child(atmosphere)
	_column_mesh = _fluted_column()
	var tile_centers: Array[PackedVector3Array] = [
		PackedVector3Array(), PackedVector3Array(), PackedVector3Array(),
	]
	var frieze_centers: Array[PackedVector3Array] = [
		PackedVector3Array(), PackedVector3Array(), PackedVector3Array(),
	]

	for side: float in [-1.0, 1.0]:
		_solid(Vector3(0, -0.52, side * 7.5), Vector3(10, 1.04, 9), _stone)
		_block(self, Vector3(0, -0.76, side * 3.05), Vector3(9.96, 0.19, 0.18), _trim)
		for row in range(9):
			for column in range(-4, 5):
				var offset := Vector3(column * 1.08, 0.002, side * (3.46 + row * 0.98))
				tile_centers[posmod(row * 13 + column * 7, _tiles.size())].append(offset)
		for x: float in [-2.05, 2.05]:
			_block(self, Vector3(x, 0.016, side * 3.16), Vector3(1.44, 0.025, 0.075), _bronze)
		_solid(Vector3(0, 2.9, side * 12.2), Vector3(10.5, 6.5, 0.4), _dark)

	for side: float in [-1.0, 1.0]:
		_solid(Vector3(side * 5.2, 0.3, 0), Vector3(0.4, 12, 24.8), _dark)
		for z: float in [-10.0, -5.0, 0.0, 5.0, 10.0]:
			_column(Vector3(side * 4.56, 0, z))
			if z != 0.0:
				_block(self, Vector3(side * 4.11, 2.57, z), Vector3(0.12, 0.26, 0.21), _amber)
				_block(self, Vector3(side * 4.18, 2.35, z), Vector3(0.20, 0.14, 0.35), _bronze)
				_light(Vector3(side * 3.94, 2.57, z), Color("#efad69"), 0.77, 4.0)
		_block(self, Vector3(side * 4.76, 5.00, 0), Vector3(0.54, 0.45, 23.8), _stone)
		for y: float in [4.74, 5.25]:
			_block(self, Vector3(side * 4.72, y, 0), Vector3(0.58, 0.075, 23.8), _bronze)
		for index in range(-14, 15):
			var center := Vector3(side * 4.48, 5.0, index * 0.79)
			frieze_centers[0].append(center + Vector3(0, 0.12, 0))
			frieze_centers[1].append(center + Vector3(0, 0.02, 0.30 * side))
			frieze_centers[2].append(center + Vector3(0, -0.08, 0.08 * side))

	for index in range(_tiles.size()):
		_batch_blocks(tile_centers[index], Vector3(1.065, 0.015, 0.965), _tiles[index])
	_batch_blocks(frieze_centers[0], Vector3(0.026, 0.038, 0.64), _bronze)
	_batch_blocks(frieze_centers[1], Vector3(0.026, 0.22, 0.038), _bronze)
	_batch_blocks(frieze_centers[2], Vector3(0.026, 0.038, 0.48), _bronze)

	_block(self, Vector3(0, 6.15, 0), Vector3(10.4, 0.35, 24.5), _dark)
	_block(self, Vector3(0, -5.0, 0), Vector3(10, 0.3, 6), _dark)
	for x: float in [-3.8, 3.8]:
		_block(self, Vector3(x, -3.05, 0), Vector3(0.12, 0.12, 5.7), _teal)
	_light(Vector3(0.0, 4.6, 7.6), Color("#edc08a"), 1.7, 10.0)
	_light(Vector3(0.0, 3.1, -8.4), Color("#92cedb"), 2.3, 10.0)
	_light(Vector3(0.0, 2.5, 0.0), Color("#82bcc2"), 1.15, 8.0)
	_chasm_light = _light(Vector3(0.0, -3.3, 0.0), Color("#4d9199"), 1.9, 7.0)
	_build_box()
	_build_slab()
	_build_exit()
	_build_atmosphere()


func _column(at: Vector3) -> void:
	var shaft := MeshInstance3D.new()
	shaft.mesh = _column_mesh
	shaft.material_override = _marble
	shaft.position = at + Vector3(0, 0.28, 0)
	add_child(shaft)
	_block(self, at + Vector3(0, 0.14, 0), Vector3(1.02, 0.28, 1.02), _trim)
	_block(self, at + Vector3(0, 0.30, 0), Vector3(0.89, 0.09, 0.89), _stone)
	_block(self, at + Vector3(0, 4.55, 0), Vector3(0.82, 0.17, 0.82), _marble)
	_block(self, at + Vector3(0, 4.68, 0), Vector3(1.03, 0.13, 1.03), _trim)


func _fluted_column() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SIDES := 96
	for index in range(SIDES):
		var a := TAU * float(index) / SIDES
		var b := TAU * float(index + 1) / SIDES
		var edge_a := Vector3(cos(a), 0, sin(a)) * (0.385 + 0.023 * cos(a * 16))
		var edge_b := Vector3(cos(b), 0, sin(b)) * (0.385 + 0.023 * cos(b * 16))
		var top_a := edge_a * 0.85 + Vector3(0, 4.24, 0)
		var top_b := edge_b * 0.85 + Vector3(0, 4.24, 0)
		for vertex: Vector3 in [edge_a, top_b, top_a, edge_a, edge_b, top_b]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()


func _build_box() -> void:
	_solid(BOX_POSITION + Vector3(0, -0.52, 0), Vector3(0.82, 0.84, 0.78), _stone)
	_block(self, BOX_POSITION + Vector3(0, -0.82, 0), Vector3(1.02, 0.23, 0.99), _trim)
	_block(self, BOX_POSITION + Vector3(0, -0.13, 0), Vector3(1.02, 0.18, 0.99), _trim)
	var body := BOX_BODY.instantiate() as Node3D
	body.name = "PandoraBoxBodyModel"
	body.position = BOX_POSITION
	add_child(body)

	lid = Node3D.new()
	lid.name = "BoxLid"
	lid.position = BOX_POSITION + Vector3(0, 0.20, -0.23)
	add_child(lid)
	var cover := BOX_LID.instantiate() as Node3D
	cover.name = "PandoraBoxLidModel"
	lid.add_child(cover)
	_light(BOX_POSITION + Vector3(0, 1.15, 0.64), Color("#f3c78a"), 2.0, 3.7)
	_seal_light = _light(BOX_POSITION + Vector3(0, 0.31, 0.12), Color("#ffb259"), 0.0, 2.9)


func _build_slab() -> void:
	slab = Node3D.new()
	slab.name = "SuspendedSlab"
	slab.position = SLAB_RAISED
	add_child(slab)
	_block(slab, Vector3.ZERO, Vector3(2.55, 0.6, 6.0), _trim)
	bridge_inlay = _material(Color("#e9a85d"), 0.95)
	for x: float in [-1.09, 1.09]:
		_block(slab, Vector3(x, 0.295, 0), Vector3(0.085, 0.012, 5.85), bridge_inlay)
		_block(slab, Vector3(x, -0.29, 0), Vector3(0.085, 0.025, 5.85), bridge_inlay)
	for z: float in [-2.9, -1.95, -0.98, 0.0, 0.98, 1.95, 2.9]:
		_block(slab, Vector3(0, 0.296, z), Vector3(1.9, 0.008, 0.04), _dark)
	for z: float in [-2.55, 2.55]:
		_block(self, Vector3(0, 5.55, z), Vector3(0.16, 1.05, 0.16), _bronze)

	var bridge_body := StaticBody3D.new()
	bridge_body.name = "BridgeBody"
	bridge_body.position = SLAB_LANDED
	add_child(bridge_body)
	bridge = _collision(bridge_body, Vector3(2.55, 0.6, 6.0))
	bridge.disabled = true


func _build_exit() -> void:
	exit_portal = EXIT_PORTAL.instantiate() as Node3D
	exit_portal.name = "ExitPortalModel"
	exit_portal.position = Vector3(0, 0, -11.62)
	add_child(exit_portal)
	exit_light = _light(exit_portal.position + Vector3(0, 3.85, 1.1), Color("#e6c298"), 0.85, 3.6)
	_light(exit_portal.position + Vector3(0, 0.32, 0.15), Color("#75b9b4"), 0.50, 2.8)


func _material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material


func _block(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visible_block := MeshInstance3D.new()
	visible_block.mesh = mesh
	visible_block.material_override = material
	visible_block.position = at
	parent.add_child(visible_block)
	return visible_block


func _batch_blocks(centers: PackedVector3Array, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = centers.size()
	for index in range(centers.size()):
		batch.set_instance_transform(index, Transform3D(Basis.IDENTITY, centers[index]))
	var geometry := MultiMeshInstance3D.new()
	geometry.multimesh = batch
	add_child(geometry)


func _solid(at: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.position = at
	add_child(body)
	_collision(body, size)
	_block(body, Vector3.ZERO, size, material)


func _collision(body: StaticBody3D, size: Vector3) -> CollisionShape3D:
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	return collision


func _light(at: Vector3, color: Color, energy: float, light_range: float) -> OmniLight3D:
	var lamp := OmniLight3D.new()
	lamp.position = at
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.omni_range = light_range
	add_child(lamp)
	return lamp


func _build_atmosphere() -> void:
	var haze := _dust(Vector3(0, 2.6, 0), Vector3(4, 2.4, 10), 72, 8.0, 0.023)
	haze.gravity = Vector3(0.0, -0.018, 0.0)
	haze.initial_velocity_max = 0.09
	haze.preprocess = 8.0
	haze.emitting = true

	_impact_dust = _dust(Vector3(0, 0.12, 0), Vector3(1.13, 0.06, 2.83), 55, 1.0, 0.11)
	_impact_dust.one_shot = true
	_impact_dust.explosiveness = 0.90
	_impact_dust.initial_velocity_min = 0.35
	_impact_dust.initial_velocity_max = 0.78
	_impact_dust.gravity = Vector3(0, 0.35, 0)


func _dust(at: Vector3, extents: Vector3, count: int, lifetime: float, size: float) -> CPUParticles3D:
	var dust := CPUParticles3D.new()
	dust.emitting = false
	dust.position = at
	dust.amount = count
	dust.lifetime = lifetime
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = extents
	dust.scale_amount_min = 0.40
	dust.scale_amount_max = 1.0
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.20, 1.0])
	colors.colors = PackedColorArray([Color("#dcc3a300"), Color("#dcc3a38c"), Color("#dcc3a300")])
	dust.color_ramp = colors
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	quad.material = material
	dust.mesh = quad
	add_child(dust)
	return dust


func update_tremors(open: bool, elapsed: float, delta: float) -> void:
	var glow := 1.35 + sin(elapsed * 14.0) * 0.40 if open else 0.0
	_seal_light.light_energy = move_toward(_seal_light.light_energy, glow, delta * 8.0)
	_chasm_light.light_color = Color("#b17856") if open else Color("#4d9199")


func show_slab_impact() -> void:
	_impact_dust.restart()


func reset_effects() -> void:
	_impact_dust.emitting = false
	_seal_light.light_energy = 0.0
	_chasm_light.light_color = Color("#4d9199")
