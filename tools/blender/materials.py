"""Shared glTF-compatible materials. Colors are authored in sRGB."""

import bpy


def linear_channel(value):
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def physical_material(name, hex_color, roughness, metallic=0.0, emission=0.0):
    srgb = [int(hex_color[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    color = (*map(linear_channel, srgb), 1.0)
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    material.diffuse_color = color
    shader = next(node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    if emission:
        shader.inputs["Emission Color"].default_value = color
        shader.inputs["Emission Strength"].default_value = emission
    return material


def box_palette():
    return {
        "bronze": physical_material("Aged cast bronze", "725038", 0.38, 0.56),
        "gold": physical_material("Worn gilt edges", "C29658", 0.30, 0.48),
        "patina": physical_material("Deep green enamel", "233E3B", 0.44, 0.25),
        "dark": physical_material("Oxidized bronze", "302B2A", 0.52, 0.32),
        "ember": physical_material("Amber seal", "F9AC53", 0.37, 0.15, 0.65),
    }
