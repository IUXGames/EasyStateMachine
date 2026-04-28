@tool
extends VBoxContainer

var _state: EasyState
var _editor_plugin: EditorPlugin
var _dialog: EditorFileDialog

func setup(state: EasyState, plugin: EditorPlugin) -> void:
	_state = state
	_editor_plugin = plugin
	_build_ui()

func _build_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)

	var script := _state.get_script() as Script
	var has_custom := script != null and not script.resource_path.ends_with("easy_state.gd")
	if has_custom:
		return

	add_child(HSeparator.new())

	var btn := Button.new()
	btn.text = "Create State Script"
	var base := _editor_plugin.get_editor_interface().get_base_control()
	if base.has_theme_icon("Script", "EditorIcons"):
		btn.icon = base.get_theme_icon("Script", "EditorIcons")
	btn.pressed.connect(_on_create_pressed)
	add_child(btn)

	add_child(HSeparator.new())

func _on_create_pressed() -> void:
	_dialog = EditorFileDialog.new()
	_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_dialog.add_filter("*.gd", "GDScript")
	_dialog.title = "Create State Script"
	_dialog.current_file = _state.name.to_snake_case() + ".gd"
	_dialog.file_selected.connect(_on_file_selected)
	_dialog.canceled.connect(_dialog.queue_free)
	_editor_plugin.get_editor_interface().get_base_control().add_child(_dialog)
	_dialog.popup_centered_ratio(0.5)

func _on_file_selected(path: String) -> void:
	_dialog.queue_free()

	var script := GDScript.new()
	script.source_code = _make_template()
	if ResourceSaver.save(script, path) != OK:
		push_error("EasyStateMachine: no se pudo guardar el script en '%s'." % path)
		return

	_editor_plugin.get_editor_interface().get_resource_filesystem().update_file(path)
	var loaded: Script = load(path)
	if loaded:
		_state.set_script(loaded)
		_editor_plugin.get_editor_interface().edit_resource(loaded)

func _make_template() -> String:
	var class_name_str := _state.name.to_pascal_case()
	var host_line := _detect_host_line()
	return (
		"@tool\nclass_name %s\nextends EasyState\n\n" % class_name_str
		+ host_line + "\n\n"
		+ "func _on_enter(_previous_state: EasyState) -> void:\n\tpass\n\n\n"
		+ "func _on_update(_delta: float) -> void:\n\tpass\n\n\n"
		+ "func _on_exit(_next_state: EasyState) -> void:\n\tpass\n"
	)

func _detect_host_line() -> String:
	var machine := _state.get_parent()
	if not is_instance_valid(machine):
		return "# var host_typed: YourHostType: get: return host as YourHostType"
	var host_node := machine.get_parent()
	if not is_instance_valid(host_node):
		return "# var host_typed: YourHostType: get: return host as YourHostType"
	var host_script := host_node.get_script() as Script
	if host_script == null or host_script.resource_path.is_empty():
		return "# var host_typed: YourHostType: get: return host as YourHostType"
	var script_path := host_script.resource_path
	var host_class := host_script.get_global_name()
	if not host_class.is_empty():
		return "var hostReference: %s:\n\tget: return host as %s" % [host_class, host_class]
	var const_name := host_node.name.to_pascal_case() + "Script"
	return (
		"const %s = preload(\"%s\")\n" % [const_name, script_path]
		+ "var hostReference: %s:\n\tget: return host as %s" % [const_name, const_name]
	)
