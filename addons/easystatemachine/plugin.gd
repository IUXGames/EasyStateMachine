@tool
extends EditorPlugin

var _inspector_plugin: EditorInspectorPlugin

func _enter_tree() -> void:
	var plugin_script := preload("nodes/editor/sm_inspector_plugin.gd")
	_inspector_plugin = plugin_script.new(self)
	add_inspector_plugin(_inspector_plugin)

func _exit_tree() -> void:
	if _inspector_plugin != null:
		remove_inspector_plugin(_inspector_plugin)
		_inspector_plugin = null

func _enable_plugin() -> void:
	print("Plugin enabled.")

func _disable_plugin() -> void:
	print("Plugin disabled.")
