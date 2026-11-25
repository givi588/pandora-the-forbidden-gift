"""Deterministically generate and review Pandora's game models."""

import argparse
import sys
from pathlib import Path

import bpy

TOOL_DIR = Path(__file__).resolve().parent
PROJECT_DIR = TOOL_DIR.parents[1]
sys.path.insert(0, str(TOOL_DIR))

from pandora_box import build_pandora_box
from render_previews import render_box, render_exit
from temple_exit import build_temple_exit


def export_glb(obj, destination):
    if destination.exists():
        raise FileExistsError(f"Refusing to overwrite {destination}. Export to a staging directory instead.")
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=str(destination), export_format="GLB", use_selection=True,
        export_yup=True, export_animations=False, export_cameras=False, export_lights=False,
    )


def run():
    parser = argparse.ArgumentParser()
    parser.add_argument("asset", choices=["PandoraBox", "TempleExit"])
    parser.add_argument("--previews", action="store_true")
    parser.add_argument("--preview-dir", type=Path)
    parser.add_argument("--export-dir", type=Path)
    parser.add_argument("--engine", choices=["BLENDER_EEVEE_NEXT", "CYCLES"], default="BLENDER_EEVEE_NEXT")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    if not args.previews and args.export_dir is None:
        parser.error("Choose --previews, --export-dir, or both.")
    default_preview = PROJECT_DIR / "art_previews" / "pandora_box"
    if args.asset == "TempleExit":
        default_preview = PROJECT_DIR / ".godot" / "art-scratch" / "temple_exit"
    preview_dir = (args.preview_dir or default_preview).resolve()
    export_dir = args.export_dir.resolve() if args.export_dir else None
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if args.asset == "PandoraBox":
        body, lid = build_pandora_box()
        models = [(body, "pandora_box_body.glb"), (lid, "pandora_box_lid.glb")]
        if args.previews:
            render_box(lid, preview_dir, args.engine)
    else:
        models = [(build_temple_exit(), "temple_exit.glb")]
        if args.previews:
            render_exit(preview_dir, args.engine)
    for obj, _ in models:
        obj.data.calc_loop_triangles()
        print(f"{obj.name}: {len(obj.data.loop_triangles)} triangles, {len(obj.data.materials)} materials")
    if export_dir is not None:
        export_dir.mkdir(parents=True, exist_ok=True)
        for obj, filename in models:
            export_glb(obj, export_dir / filename)


if __name__ == "__main__":
    run()
