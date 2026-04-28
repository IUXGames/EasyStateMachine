@tool
extends VBoxContainer

var _machine: EasyStateMachine
var _editor_plugin: EditorPlugin
var _undo_redo: EditorUndoRedoManager
var _option_btn: OptionButton
var _current_label: Label
var _no_states_label: Label

func setup(machine: EasyStateMachine, plugin: EditorPlugin) -> void:
	_machine = machine
	_editor_plugin = plugin
	_undo_redo = plugin.get_undo_redo()
	_build_ui()

func _build_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)

	# Section header
	var header := Label.new()
	header.text = "EasyStateMachine"
	header.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	add_child(header)

	# Separator
	var sep := HSeparator.new()
	add_child(sep)

	# Initial state row
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)

	var lbl := Label.new()
	lbl.text = "Initial State"
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	_option_btn = OptionButton.new()
	_option_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_option_btn.item_selected.connect(_on_initial_state_selected)
	row.add_child(_option_btn)

	# "No states" hint
	_no_states_label = Label.new()
	_no_states_label.text = "Add EasyState child nodes to define states."
	_no_states_label.add_theme_color_override("font_color", Color(0.9, 0.65, 0.2))
	_no_states_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_no_states_label.visible = false
	add_child(_no_states_label)

	# Live state label (shown only while game runs inside editor)
	_current_label = Label.new()
	_current_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	_current_label.visible = false
	add_child(_current_label)

	# Bottom separator
	var sep2 := HSeparator.new()
	add_child(sep2)

func _ready() -> void:
	if not is_instance_valid(_machine):
		return
	_refresh()
	if not _machine.child_order_changed.is_connected(_refresh):
		_machine.child_order_changed.connect(_refresh)

func _process(_delta: float) -> void:
	if not is_instance_valid(_machine):
		return
	# Show active state label only while the game is running inside the editor
	var is_running := not Engine.is_editor_hint()
	if is_running and _machine._initialized:
		_current_label.visible = true
		_current_label.text = "Active: " + _machine.get_current_state_name()
	else:
		_current_label.visible = false

func _refresh() -> void:
	if not is_instance_valid(_option_btn) or not is_instance_valid(_machine):
		return
	_option_btn.clear()
	var names := _collect_state_names()
	_no_states_label.visible = names.is_empty()
	_option_btn.visible = not names.is_empty()
	for n in names:
		_option_btn.add_item(n)
	# Re-select the stored value
	var current_initial := ""
	if _machine.config != null:
		current_initial = _machine.config.initial_state
	var idx := names.find(current_initial)
	if idx >= 0:
		_option_btn.select(idx)
	elif not names.is_empty():
		_option_btn.select(0)

func _collect_state_names() -> Array[String]:
	var names: Array[String] = []
	if not is_instance_valid(_machine):
		return names
	for child in _machine.get_children():
		if child is EasyState:
			names.append(child.name)
	return names

func _on_initial_state_selected(index: int) -> void:
	if not is_instance_valid(_machine) or _machine.config == null:
		return
	var new_val: String = _option_btn.get_item_text(index)
	var old_val: String = _machine.config.initial_state
	if old_val == new_val:
		return
	_undo_redo.create_action("Set EasyStateMachine Initial State")
	_undo_redo.add_do_property(_machine.config, "initial_state", new_val)
	_undo_redo.add_undo_property(_machine.config, "initial_state", old_val)
	_undo_redo.add_do_method(_machine, "notify_property_list_changed")
	_undo_redo.add_undo_method(_machine, "notify_property_list_changed")
	_undo_redo.commit_action()
