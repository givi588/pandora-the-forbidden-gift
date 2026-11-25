"""Small bevelled solids for the Pandora asset builders."""

import bpy
from mathutils import Vector


def finish(obj, name, material, bevel):
    obj.name = name
    obj.data.name = f"{name}Mesh"
    obj.data.materials.append(material)
    if bevel:
        edges = obj.modifiers.new("Rounded casting edges", "BEVEL")
        edges.width = bevel
        edges.segments = 2
        edges.harden_normals = True
        bpy.ops.object.modifier_apply(modifier=edges.name)
        normals = obj.modifiers.new("Weighted casting normals", "WEIGHTED_NORMAL")
        normals.keep_sharp = True
        bpy.ops.object.modifier_apply(modifier=normals.name)
    return obj


def block(name, position, size, material, bevel=0.002, rotation=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=position)
    obj = bpy.context.object
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if rotation is not None:
        obj.rotation_euler = rotation
    return finish(obj, name, material, bevel)


def cylinder(name, position, radius, depth, material, rotation=None, sides=24):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=sides, radius=radius, depth=depth, location=position
    )
    obj = bpy.context.object
    if rotation is not None:
        obj.rotation_euler = rotation
    return finish(obj, name, material, 0.001)


def bar(name, start, end, width, depth, material):
    start, end = Vector(start), Vector(end)
    direction = end - start
    return block(
        name, (start + end) / 2, (width, depth, direction.length + width),
        material, min(width, depth) * 0.22,
        direction.to_track_quat("Z", "Y").to_euler(),
    )


def combine(name, objects):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    asset = bpy.context.object
    asset.name = name
    asset.data.name = f"{name}Mesh"
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    # Prevent subpixel variation in bevel-generated UVs across Blender runs.
    for layer in asset.data.uv_layers:
        for coordinate in layer.uv:
            coordinate.vector = tuple(round(value * 4096) / 4096 for value in coordinate.vector)
    return asset
