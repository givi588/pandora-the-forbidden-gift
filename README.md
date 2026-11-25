# Pandora: The Forbidden Gift

A first-person 3D puzzle in a Greek-inspired temple where opening a forbidden chest reshapes the room and every tremor matters.

[Download v1.0.0 for Windows x64](https://github.com/givi588/pandora-the-forbidden-gift/releases/download/v1.0.0/Pandora-The-Forbidden-Gift-v1.0.0-Windows.zip) · [Release notes and SHA-256 checksum](https://github.com/givi588/pandora-the-forbidden-gift/releases/tag/v1.0.0)

![In-game view of Pandora's chest, the suspended slab, and the portal across the chasm](art_previews/release-temple.png)

## Gameplay video

*Gameplay recording pending.* See the [in-game screenshots](art_previews/release-review.png) for views from the Windows release.

## What you play

- Explore one temple chamber and use Pandora's box to change the path across the chasm.
- Read or skip the myth-inspired prologue. Reach the portal to see the cinematic ending, then replay or return to the menu.
- Adjust volume and display mode in Settings. Falls and unsafe crossings reset the puzzle.

## Install and play

Extract the Windows ZIP, run `Pandora.exe`, and select **Play**. The standalone build includes the engine notices.

| Input | Action |
| --- | --- |
| WASD / mouse / Space | Move / look / jump |
| E | Open or close the box when nearby |
| R | Restart the puzzle or replay after victory |
| Esc | Return to the main menu during play or the ending, go back from Settings, or skip the prologue |
| F11 | Toggle fullscreen |
| Left click | Capture the mouse during play |
| Tab or arrow keys / Enter | Navigate menus and the ending / activate the focused control |

## Development case study

**Objective.** Build one complete puzzle around Pandora's box, from the first playable chamber through the prologue, the ceremonial exit, and a standalone Windows release.

**Puzzle design.** Opening the box releases the suspended stone slab but keeps the bridge unsafe while the temple shakes. Closing the lid stops the tremors. The deterministic slab motion and fixed bridge collision let the room reset consistently after a failed crossing.

**Architecture.** The game uses Godot 4.7.2, GDScript, and the Compatibility renderer. [Main menu](main_menu.gd) handles navigation, prologue, and saved settings. [Temple logic](temple.gd) coordinates the puzzle, resets, and transitions, while [geometry](temple_geometry.gd) and [player movement](player.gd) have separate scripts. [Ending presentation](ending_screen.gd) and [audio](temple_audio.gd) handle the camera, interface, and sound cues.

**Procedural art.** Blender 4.5.16 LTS and [Python tools](tools/blender/) generated the chest body, hinged lid, and ceremonial portal. GLB exports bring the models and the portal's limestone texture into Godot. See the [chest](art_previews/pandora_box_studio.png) and [portal](art_previews/temple_exit_studio.png) renders.

**Verification and scope.** Headless regression tests cover menu navigation, the puzzle, resets, and ending transitions. The project owner manually played the final Windows build. The release contains one chamber and targets Windows x64. Cross-GPU and other operating-system compatibility remain unverified.

## Test and build from source

Open [project.godot](project.godot) in **Godot 4.7.2** to play from source. Run the regression suite from the project root with the same engine version. On Windows, use the console executable for terminal output.

```text
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/menu_test.gd
godot --headless --path . --script res://tests/puzzle_test.gd
godot --headless --path . --script res://tests/ending_test.gd
```

Run the menu and ending tests without `--headless` to include display-dependent assertions. The [GitHub Actions workflow](.github/workflows/godot-ci.yml) runs the import and all three headless tests.

For the exact release source, check out [v1.0.0](https://github.com/givi588/pandora-the-forbidden-gift/tree/v1.0.0). Install the matching [Godot 4.7.2 export templates](https://godotengine.org/download/archive/4.7.2-stable/), then use the checked-in Windows x64 preset to build and package the standalone executable from PowerShell:

```powershell
New-Item -ItemType Directory -Path dist/windows -Force | Out-Null
godot --headless --path . --editor --import
godot --headless --path . --export-release "Windows Desktop" dist/windows/Pandora.exe
$notices = Join-Path (Get-Location) 'dist/windows/GODOT-NOTICES.txt'
godot --headless --path . --script res://tools/write_engine_notices.gd -- $notices
Compress-Archive -Path dist/windows/* -DestinationPath dist/Pandora-local-Windows.zip
```

The GLB files are included. To regenerate a model, use a fresh staging directory and run `blender --background --factory-startup --python-exit-code 1 --python tools/blender/build.py -- TempleExit --export-dir <staging-path>`. Use `PandoraBox` to export the chest and lid. The tool also supports `--previews --preview-dir <preview-path>` for reviewing renders before export.

## Credits and licensing

[givi588](https://github.com/givi588) led creative direction, defined the scope and mechanics, reviewed iterations, and manually play-tested the final Windows build. OpenAI Codex assisted with GDScript implementation, automated tests, Blender Python modeling, synthesized audio, and release preparation.

Original source code is under the [MIT License](LICENSE). Original game artwork, models, textures, and audio are all rights reserved. See [asset rights and provenance](ASSET_RIGHTS.md) for details and the Windows ZIP for Godot's bundled third-party notices.
