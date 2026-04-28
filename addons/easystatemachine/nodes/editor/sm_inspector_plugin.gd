@tool
extends EditorInspectorPlugin

var _editor_plugin: EditorPlugin

func _init(plugin: EditorPlugin) -> void:
	_editor_plugin = plugin

func _can_handle(object: Object) -> bool:
	return object is EasyStateMachine or object is EasyState

func _parse_begin(object: Object) -> void:
	if object is EasyStateMachine:
		var picker_script := preload("sm_initial_state_picker.gd")
		var picker: Control = picker_script.new()
		picker.setup(object as EasyStateMachine, _editor_plugin)
		add_custom_control(picker)
	elif object is EasyState:
		var state_script := preload("sm_state_inspector.gd")
		var panel: Control = state_script.new()
		panel.setup(object as EasyState, _editor_plugin)
		add_custom_control(panel)
