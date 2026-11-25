extends SceneTree
## Writes the notices for the version of Godot used to make a release build.


func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 1:
		push_error("Pass an absolute destination path for the notices.")
		quit(1)
		return

	var file := FileAccess.open(arguments[0], FileAccess.WRITE)
	if file == null:
		push_error("Could not open the Godot notices file.")
		quit(1)
		return

	file.store_line("Godot Engine and bundled third-party notices")
	file.store_line("")
	file.store_line(Engine.get_license_text())
	for component: Dictionary in Engine.get_copyright_info():
		file.store_line("\n" + str(component["name"]))
		for part: Dictionary in component["parts"]:
			for owner: String in part["copyright"]:
				file.store_line(owner)
			file.store_line("License: " + str(part["license"]))
	for license_name: String in Engine.get_license_info():
		file.store_line("\n--- " + license_name + " ---")
		file.store_line(Engine.get_license_info()[license_name])
	file.close()
	quit()
