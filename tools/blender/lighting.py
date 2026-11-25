"""Studio fixtures used to compare Pandora assets under consistent lighting."""

import bpy
from mathutils import Vector
from materials import physical_material


def look_at(obj, target):
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def area(name, position, target, energy, size, color):
    light = bpy.data.lights.new(name, "AREA")
    light.energy = energy
    light.shape = "DISK"
    light.size = size
    light.color = color
    fixture = bpy.data.objects.new(name, light)
    bpy.context.scene.collection.objects.link(fixture)
    fixture.location = position
    look_at(fixture, target)


def studio(scale=1.0, floor_height=-0.050):
    scene = bpy.context.scene
    scene.world = bpy.data.worlds.new("StudioWorld")
    scene.world.use_nodes = True
    background = next(node for node in scene.world.node_tree.nodes if node.type == "BACKGROUND")
    background.inputs["Color"].default_value = (0.24, 0.26, 0.30, 1.0)
    background.inputs["Strength"].default_value = 0.28

    bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, floor_height))
    bpy.context.object.name = "StudioBackdrop"
    bpy.context.object.data.materials.append(physical_material("Studio slate", "44494D", 0.8))

    target = (0, 0, 0.14 * scale)
    for name, position, energy, size, color in (
        ("Key", (-1.45, -1.2, 1.65), 155, 1.35, (1.0, 0.87, 0.72)),
        ("Fill", (1.1, -0.65, 0.9), 63, 1.20, (0.69, 0.82, 1.0)),
        ("Rim", (0.28, 1.5, 1.3), 175, 1.0, (1.0, 0.91, 0.79)),
    ):
        area(name, Vector(position) * scale, target, energy * scale ** 2, size * scale, color)
