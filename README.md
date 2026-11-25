# Pandora — The Forbidden Gift

An original first-person 3D puzzle inspired by Greek mythology.

## About the game

Enter a deserted temple and discover what the gods left behind. Pandora's box can change the room, but opening it comes at a cost. The complete game takes place in one chamber and ends at the ceremonial portal.

## Gameplay features

- Explore in first person, examine Pandora's box, and manipulate the room to cross the chasm.
- Find a safe path through the tremors. Falls and unsafe crossings reset the puzzle.
- Read or skip the optional prologue. After the cinematic ending, replay or return to the main menu.
- Adjust volume and display mode in Settings.

## Screenshots

![The temple, Pandora's box, and the distant exit](art_previews/release-temple.png)

[Godot gameplay and ending review](art_previews/release-review.png) · [Pandora's box model](art_previews/pandora_box_studio.png) · [Temple exit model](art_previews/temple_exit_studio.png)

## Controls

| Input | Action |
| --- | --- |
| WASD | Move |
| Mouse | Look around |
| Space | Jump |
| E | Open or close Pandora's box when nearby |
| R | Restart the puzzle or replay after victory |
| Esc | Return to the main menu during gameplay and the ending |
| F11 | Switch between fullscreen and windowed mode |
| Left click | Capture the mouse during play |
| Tab or arrow keys | Navigate menus and the ending |
| Enter | Activate the focused control |

## Technologies used

Godot 4.7.2 with the Compatibility renderer, GDScript, Blender 4.5.16 LTS, Python, and glTF 2.0/GLB.

## How to play

Extract the Windows ZIP and run `Pandora.exe`. Choose **Play** and read or skip the prologue. Approach the box and use **E**. Read the warnings before crossing the chasm. Reach the far portal to finish the game.

## Windows download

The standalone archive is named `Pandora-The-Forbidden-Gift-v1.0.0-Windows.zip`. It is prepared locally in `dist/`. When published, it will be attached to the [GitHub release](https://github.com/givi588/pandora-the-forbidden-gift/releases/tag/v1.0.0).

## Development and architecture

- `main_menu.tscn` and `main_menu.gd` manage the menu, prologue, and persisted settings. The menu uses a live temple view and supports optional original key art at `assets/pandora_key_art.png`.
- `temple.tscn`, `temple.gd`, `player.gd`, and `temple_geometry.gd` own the temple, movement, physics, and puzzle.
- `ending_screen.gd` manages the victory camera framing, golden light, screen fade, and ending controls. `temple_audio.gd` handles gameplay cues and the ambience fade.
- `assets/models/` contains the chest body, hinged lid, ceremonial portal, and its imported limestone texture. The decorative portal sits at `(0, 0, -11.62)`. Victory is triggered by the existing region `z < -11.12`, `abs(x) < 1.05`.

## Testing

Run these from the project root using Godot 4.7.2. On Windows, use the console executable to retain command output.

```powershell
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/menu_test.gd
godot --headless --path . --script res://tests/puzzle_test.gd
godot --headless --path . --script res://tests/ending_test.gd
godot --path . --script res://tests/menu_test.gd
godot --path . --script res://tests/puzzle_test.gd
godot --path . --script res://tests/ending_test.gd
```

For a manual pass, launch the Windows build, try Settings, enter the temple, open and close the box, cross the bridge, watch the ending, select **Play Again**, and complete another run. Check **Main Menu**, **R**, **Esc**, and **F11**. In Settings, **Esc** goes back to the main menu. During the prologue, **Esc** skips to the temple.

## Building from source

Open `project.godot` in Godot 4.7.2 and choose **Run Project**. For a release build, install the matching [Godot export templates](https://godotengine.org/download/archive/4.7.2-stable/). The **Windows Desktop** preset targets x86_64 and embeds the game data into the executable.

```powershell
New-Item -ItemType Directory -Path dist/windows -Force | Out-Null
godot --headless --path . --editor --import
godot --headless --path . --export-release "Windows Desktop" dist/windows/Pandora.exe
$notices = Join-Path (Get-Location) 'dist/windows/GODOT-NOTICES.txt'
godot --headless --path . --script res://tools/write_engine_notices.gd -- $notices
Compress-Archive -Path dist/windows/* -DestinationPath dist/Pandora-The-Forbidden-Gift-v1.0.0-Windows.zip
```

Build and run the executable before packaging. Build output and editor caches belong outside source commits.

## Blender asset generation

`tools/blender/build.py` generates `PandoraBox` (body and lid) and `TempleExit` (ceremonial portal). One Blender unit equals one meter. Models face Blender −Y, exported as Godot +Z. The lid mesh origin is its rear hinge. The portal origin is on the floor at the opening's centerline.

Use Blender 4.5.16 LTS (build `3f6797307da5`) and set the executable path for your installation. Run the preview command first, inspect the rendered images, then export to a fresh staging directory. Replace game assets only after review and run the Godot tests again.

```powershell
$blender = 'path/to/blender.exe'
$asset = 'TempleExit' # Or PandoraBox
$scratch = Join-Path (Get-Location) '.godot/art-scratch'
$env:BLENDER_USER_RESOURCES = Join-Path $scratch 'blender-profile'
$views = Join-Path $scratch "$asset-review"
$staged = Join-Path $scratch "$asset-staged"
& $blender --background --factory-startup --python-exit-code 1 --python tools/blender/build.py -- $asset --previews --preview-dir $views
& $blender --background --factory-startup --python-exit-code 1 --python tools/blender/build.py -- $asset --export-dir $staged
```

## Credits and asset provenance

Pandora was directed by [givi588](https://github.com/givi588), who defined the game concept and scope, gave feedback, and play-tested the early prototype. Codex assisted with implementation, testing, Blender Python modeling, original synthesized sound effects, and release preparation. The chest, portal, and limestone grain come from the project's original procedural workflow. The game uses system fonts and Godot's built-in fallback. The Windows archive includes Godot's engine and bundled third-party notices.

The project's original source code is available under the [MIT License](LICENSE). All rights are reserved for the original game artwork, models, textures, and audio. See the [asset rights and provenance notice](ASSET_RIGHTS.md) for the full scope.

## Known limitations

The release targets Windows x86_64 and contains one temple puzzle. Cross-GPU and other operating-system compatibility have not been verified.
