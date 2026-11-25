"""Ceremonial portal modeled in meters, facing Blender -Y from a floor-level origin."""

from math import atan2, cos, hypot, pi, sin, tau
from random import Random

import bpy

from materials import linear_channel, physical_material
from shapes import bar, block, combine, cylinder, finish


def stone_grain(material):
    """Pack a small, seeded stone texture that can travel with the GLB."""
    size = 192
    random = Random(765)
    grids = [[random.random() for _ in range(n * n)] for n in (8, 24, 64)]

    def noise(x, y, n, grid):
        u, v = x * n / size, y * n / size
        ix, iy = int(u), int(v)
        a, b = u - ix, v - iy
        a, b = a * a * (3 - 2 * a), b * b * (3 - 2 * b)
        row = iy * n
        next_row = ((iy + 1) % n) * n
        right = (ix + 1) % n
        lower = grid[row + ix] * (1 - a) + grid[row + right] * a
        upper = grid[next_row + ix] * (1 - a) + grid[next_row + right] * a
        return lower * (1 - b) + upper * b

    image = bpy.data.images.new("Portal limestone grain", width=size, height=size, alpha=False)
    pixels = []
    for y in range(size):
        for x in range(size):
            grain = sum(weight * (noise(x, y, n, grid) - 0.5)
                        for n, grid, weight in zip((8, 24, 64), grids, (0.16, 0.11, 0.067)))
            grain += (random.random() - 0.5) * 0.045
            pixels.extend((*(linear_channel(channel + grain) for channel in (0.48, 0.49, 0.46)), 1.0))
    image.pixels.foreach_set(pixels)
    image.pack()
    nodes = material.node_tree.nodes
    shader = next(node for node in nodes if node.type == "BSDF_PRINCIPLED")
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = image
    material.node_tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])


def portal_palette():
    materials = {
        "stone": physical_material("Weathered portal limestone", "7a7d75", 0.87),
        "trim": physical_material("Honed limestone edges", "747a70", 0.79),
        "shadow": physical_material("Portal shadow stone", "454e4e", 0.91),
        "recess": physical_material("Inner recess", "162729", 0.95),
        "bronze": physical_material("Oxidized portal bronze", "705239", 0.51, 0.48),
        "gold": physical_material("Worn portal gold", "bd965f", 0.45, 0.38),
        "teal": physical_material("Teal threshold inlay", "729e94", 0.52, emission=1.22),
    }
    stone_grain(materials["stone"])
    return materials


def prism(name, outline, front, back, material, bevel):
    count = len(outline)
    points = [(x, depth, height) for depth in (front, back) for x, height in outline]
    faces = [tuple(range(count)), tuple(reversed(range(count, 2 * count)))]
    for a in range(count):
        b = (a + 1) % count
        faces.append((b, a, a + count, b + count))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(points, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    return finish(obj, name, material, bevel)


def rake(name, start, end, thickness, front, back, material):
    start, end = sorted((start, end))
    dx, dz = end[0] - start[0], end[1] - start[1]
    half_width = thickness / (2 * hypot(dx, dz))
    offset_x, offset_z = -dz * half_width, dx * half_width
    outline = [
        (start[0] - offset_x, start[1] - offset_z), (end[0] - offset_x, end[1] - offset_z),
        (end[0] + offset_x, end[1] + offset_z), (start[0] + offset_x, start[1] + offset_z),
    ]
    return prism(name, outline, front, back, material, thickness * 0.12)


def pilaster(parts, x, label, m):
    for tier, height, width, depth, thick, material in (
        ("Plinth", 0.13, 0.68, 0.84, 0.25, "trim"),
        ("Footing", 0.29, 0.62, 0.75, 0.11, "shadow"),
        ("Abacus", 3.17, 0.70, 0.79, 0.15, "trim"),
    ):
        parts.append(block(f"{label}{tier}", (x, -0.21, height), (width, depth, thick),
                           m[material], min(0.028, thick / 5)))
    parts.append(block(f"{label}Ashlar", (x, -0.07, 1.73), (0.55, 0.72, 2.85), m["stone"], 0.036))
    shaft = cylinder(f"{label}ColumnShaft", (x, -0.40, 1.72), 0.247, 2.68, m["trim"], sides=64)
    for vertex in shaft.data.vertices:
        height = (vertex.co.z + 1.34) / 2.68
        angle = atan2(vertex.co.y, vertex.co.x)
        taper = 1.0 - height * 0.10
        radius = taper * (0.96 + 0.035 * cos(angle * 16))
        vertex.co.x *= radius
        vertex.co.y *= radius
    parts.append(shaft)
    for suffix, radius, depth, height, material in (
        ("ShaftBase", 0.269, 0.17, 0.40, "trim"),
        ("Neck", 0.236, 0.09, 2.95, "bronze"),
        ("Echinus", 0.274, 0.15, 3.04, "trim"),
    ):
        parts.append(cylinder(f"{label}{suffix}", (x, -0.39, height), radius, depth, m[material]))


def frieze(parts, materials):
    design = [(-0.17, -0.060), (-0.17, 0.061), (0.17, 0.061), (0.17, -0.060),
              (-0.052, -0.060), (-0.052, 0.013), (0.085, 0.013)]
    for index in range(7):
        x = (index - 3) * 0.465
        for segment, (a, b) in enumerate(zip(design, design[1:])):
            parts.append(bar(f"FriezeKey{index:02}_{segment}", (x+a[0], -0.580, 3.49+a[1]),
                             (x+b[0], -0.580, 3.49+b[1]), 0.022, 0.027, materials["gold"]))


def build_temple_exit():
    m = portal_palette()
    pieces = [
        block("RecessBackdrop", (0, 0.342, 1.67), (2.26, 0.025, 3.34), m["recess"], 0.008),
        block("Lintel", (0, -0.15, 3.31), (3.70, 0.80, 0.20), m["stone"], 0.025),
        block("FriezeBed", (0, -0.17, 3.49), (3.80, 0.80, 0.225), m["bronze"], 0.018),
        block("Cornice", (0, -0.15, 3.66), (3.98, 0.90, 0.15), m["trim"], 0.022),
        prism("PedimentTympanum", [(-1.90, 3.72), (1.90, 3.72), (0, 4.44)],
              -0.49, 0.20, m["shadow"], 0.018),
        block("CeremonialSill", (0, -0.22, 0.018), (2.29, 1.10, 0.038), m["shadow"], 0.008),
        block("ThresholdBronzeStrip", (0, -0.73, 0.042), (2.27, 0.09, 0.014), m["bronze"], 0.003),
        block("ThresholdLightStrip", (0, -0.751, 0.05), (2.18, 0.023, 0.006), m["teal"], 0.001),
    ]
    for side, label in ((-1, "Left"), (1, "Right")):
        pilaster(pieces, side * 1.51, label, m)
        pieces.append(block(f"{label}JambFooting", (side * 1.19, -0.01, 0.15),
                            (0.25, 0.70, 0.30), m["shadow"], 0.016))
        for index in range(6):
            z = 0.50 + 0.44 * index
            pieces.append(block(f"{label}ChamberJamb{index:02}", (side * 1.19, -0.01, z),
                                (0.24, 0.70, 0.422), m["stone"], 0.022))
        pieces.extend([
            block(f"{label}InlayChannel", (side * 1.115, -0.413, 1.52), (0.13, 0.09, 2.37), m["bronze"], 0.015),
            block(f"{label}Inlay", (side * 1.115, -0.462, 1.52), (0.048, 0.018, 2.22), m["teal"], 0.006),
            rake(f"{label}RakingCornice", (side * 1.95, 3.74), (0, 4.48),
                 0.16, -0.65, -0.30, m["trim"]),
            rake(f"{label}GiltPediment", (side * 1.76, 3.81), (0, 4.48),
                 0.025, -0.663, -0.641, m["gold"]),
        ])
    frieze(pieces, m)
    pieces.append(cylinder("PedimentSunBoss", (0, -0.52, 4.02), 0.105, 0.065,
                           m["gold"], (pi / 2, 0, 0)))
    for index in range(12):
        angle = tau * index / 12
        start = (0.13 * cos(angle), -0.526, 4.02 + 0.13 * sin(angle))
        end = (0.212 * cos(angle), -0.526, 4.02 + 0.212 * sin(angle))
        pieces.append(bar(f"SunRay{index:02}", start, end, 0.026, 0.022, m["bronze"]))
    return combine("TempleExit", pieces)
