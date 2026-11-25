"""Render the review views of Pandora's procedural assets."""

from math import radians

import bpy

from lighting import look_at, studio
from pandora_box import HINGE


def preview_camera(engine, width, height):
    scene = bpy.context.scene
    scene.render.engine = engine
    if engine == "CYCLES":
        scene.cycles.samples = 20
        scene.cycles.use_denoising = True
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"

    camera_data = bpy.data.cameras.new("PreviewCamera")
    camera_data.type = "ORTHO"
    camera = bpy.data.objects.new("PreviewCamera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    return scene, camera


def render_box(lid, output, engine):
    studio()
    scene, camera = preview_camera(engine, 704, 512)
    lid.location = HINGE
    output.mkdir(parents=True, exist_ok=True)
    views = [
        ("front_three_quarter", (1.05, -1.48, 0.96), (0, 0, 0.12), 1.03, 0),
        ("right_side", (1.9, 0, 0.17), (0, 0, 0.13), 0.88, 0),
        ("top", (0, -0.0001, 2.1), (0, 0, 0.10), 0.95, 0),
        ("open_three_quarter", (0.88, -1.54, 1.78), (0, 0, 0.27), 1.46, -74.5),
    ]
    try:
        for name, position, target, scale, angle in views:
            lid.rotation_euler.x = radians(angle)
            camera.location = position
            camera.data.ortho_scale = scale
            look_at(camera, target)
            scene.render.filepath = str(output / f"{name}.png")
            bpy.ops.render.render(write_still=True)
    finally:
        lid.location = (0, 0, 0)
        lid.rotation_euler.x = 0


def render_exit(output, engine):
    studio(scale=5.5, floor_height=-0.002)
    scene, camera = preview_camera(engine, 768, 672)
    output.mkdir(parents=True, exist_ok=True)
    views = [
        ("front_three_quarter", (5, -8, 4.2), (0, 0, 2.22), 5.9),
        ("right_side", (9, -0.03, 2.4), (0, -0.14, 2.22), 6.15),
        ("top", (0, -0.0001, 10), (0, -0.14, 0), 5.45),
        ("player_eye", (0, -8.55, 1.55), (0, -0.15, 2.16), None),
    ]
    for name, position, target, scale in views:
        camera.location = position
        look_at(camera, target)
        if scale is None:
            camera.data.type = "PERSP"
            camera.data.lens = 47
        else:
            camera.data.type = "ORTHO"
            camera.data.ortho_scale = scale
        scene.render.filepath = str(output / f"{name}.png")
        bpy.ops.render.render(write_still=True)
