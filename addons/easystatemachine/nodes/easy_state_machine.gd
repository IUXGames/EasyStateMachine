@tool
@icon("res://addons/easystatemachine/icons/icon_easy_state_machine.svg")
class_name EasyStateMachine
extends Node

# ── Public signals ────────────────────────────────────────────────────────────

## Emitted on every REPLACE transition (not push/pop).
signal state_changed(from_name: String, to_name: String)
## Emitted when any state's _on_enter begins.
signal state_entered(state_name: String)
## Emitted when any state's _on_exit completes.
signal state_exited(state_name: String)
## Emitted when push_state() pushes a new state onto the stack.
signal stack_pushed(state_name: String)
## Emitted when pop_state() resumes the previous state.
signal stack_popped(state_name: String)

# ── Exported config ───────────────────────────────────────────────────────────

@export var config: SMConfig

# ── Private state ─────────────────────────────────────────────────────────────

var _states: Dictionary = {}              # String → EasyState
var _current_state: EasyState = null
var _previous_state_name: String = ""
var _state_stack: Array[EasyState] = []   # index 0 = deepest; last = top
var _history: Array[String] = []          # ring buffer
var _events: SMEvents = null
var _logger: SMLogger = null
var _initialized: bool = false

# ── Initialization ────────────────────────────────────────────────────────────

func _ready() -> void:
	if config == null:
		config = SMConfig.new()

	_logger = SMLogger.new(name)
	var effective_level := config.log_level if config.debug_enabled else SMEnums.LogLevel.NONE
	_logger.set_log_level(effective_level)

	_events = SMEvents.new()
	_events.name = "__SMEvents"
	add_child(_events)
	_events.state_changed.connect(func(f, t): state_changed.emit(f, t))
	_events.state_entered.connect(func(s): state_entered.emit(s))
	_events.state_exited.connect(func(s): state_exited.emit(s))
	_events.stack_pushed.connect(func(s): stack_pushed.emit(s))
	_events.stack_popped.connect(func(s): stack_popped.emit(s))

	_auto_discover_states()

	# Editor only needs state discovery (for the inspector dropdown).
	if Engine.is_editor_hint():
		return

	var initial_name := config.initial_state
	if initial_name == "" or not _states.has(initial_name):
		if _states.size() > 0:
			initial_name = _states.keys()[0]
			if config.initial_state != "":
				_logger.warn("initial_state '%s' not found, falling back to '%s'" % [config.initial_state, initial_name])
			else:
				_logger.warn("initial_state not set, defaulting to first child state: '%s'" % initial_name)
		else:
			_logger.warn("No EasyState children found — machine will not start automatically.")
			return

	# Defer so the host's @onready vars are initialized before the first state fires.
	call_deferred("_start", initial_name)

func _start(initial_name: String) -> void:
	_enter_state(_states[initial_name], null)
	_initialized = true

# ── Process loop ──────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _current_state == null:
		return
	_current_state._on_update(delta)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _current_state == null:
		return
	_current_state._on_physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or _current_state == null:
		return
	_current_state._on_unhandled_input(event)

# ── State registration ────────────────────────────────────────────────────────

func _auto_discover_states() -> void:
	for child in get_children():
		if child is EasyState:
			register_state(child)

## Register a state with this machine. Called automatically for child EasyState
## nodes in _ready(). Can also be called at runtime for dynamically added states.
func register_state(state: EasyState) -> void:
	var key := state.name
	if _states.has(key):
		_logger.warn("register_state: duplicate name '%s', skipping." % key)
		return
	state._machine = self
	_states[key] = state
	_logger.debug("Registered state: %s" % key)

## Remove a state from the registry. The state must not be the currently active one.
func unregister_state(state_name: String) -> void:
	if not _states.has(state_name):
		_logger.warn("unregister_state: '%s' not found." % state_name)
		return
	if _current_state != null and _current_state.name == state_name:
		_logger.error("Cannot unregister the currently active state '%s'." % state_name)
		return
	var state: EasyState = _states[state_name]
	state._machine = null
	_states.erase(state_name)
	_logger.debug("Unregistered state: %s" % state_name)

# ── Internal lifecycle ────────────────────────────────────────────────────────

func _enter_state(next_state: EasyState, prev_state: EasyState) -> void:
	_current_state = next_state
	next_state.status = SMEnums.StateStatus.ENTERING
	next_state._on_enter(prev_state)
	next_state.status = SMEnums.StateStatus.ACTIVE
	_events.state_entered.emit(next_state.name)
	_push_history(next_state.name)
	_logger.debug("Entered state: %s" % next_state.name)

func _exit_state(current_state: EasyState, next_state: EasyState) -> void:
	current_state.status = SMEnums.StateStatus.EXITING
	current_state._on_exit(next_state)
	current_state.status = SMEnums.StateStatus.INACTIVE
	_events.state_exited.emit(current_state.name)
	_logger.debug("Exited state: %s" % current_state.name)

func _push_history(state_name: String) -> void:
	_history.append(state_name)
	while _history.size() > config.history_max_size:
		_history.pop_front()

# ── Public transition API ─────────────────────────────────────────────────────

## Replace the current state with another. Calls _on_exit on the old state
## and _on_enter on the new one. Emits state_changed.
func transition_to(state_name: String) -> void:
	if not _states.has(state_name):
		_logger.error("transition_to: unknown state '%s'." % state_name)
		return
	var next: EasyState = _states[state_name]
	if next == _current_state:
		return

	var prev := _current_state
	var prev_name := ""
	if prev != null:
		prev_name = prev.name
		_exit_state(prev, next)

	_previous_state_name = prev_name
	_enter_state(next, prev)
	_events.state_changed.emit(prev_name, state_name)

## Push a new state on top of the stack. The current state is paused (status →
## INACTIVE) without calling _on_exit. Emits stack_pushed.
func push_state(state_name: String) -> void:
	if not _states.has(state_name):
		_logger.error("push_state: unknown state '%s'." % state_name)
		return
	if _state_stack.size() >= config.max_stack_depth:
		_logger.error("push_state: max stack depth (%d) reached." % config.max_stack_depth)
		return

	if _current_state != null:
		_current_state.status = SMEnums.StateStatus.INACTIVE
		_state_stack.push_back(_current_state)
		_logger.debug("Paused state on stack: %s" % _current_state.name)

	var next: EasyState = _states[state_name]
	_enter_state(next, _current_state)
	_events.stack_pushed.emit(state_name)

## Pop the current state from the stack and resume the previous one.
## The popped state gets _on_exit called. The resumed state does NOT get
## _on_enter called — it simply resumes from where it paused.
func pop_state() -> void:
	if _state_stack.is_empty():
		_logger.warn("pop_state: stack is empty.")
		return

	var prev := _current_state
	if prev != null:
		_exit_state(prev, null)

	var resumed: EasyState = _state_stack.pop_back()
	resumed.status = SMEnums.StateStatus.ACTIVE
	_current_state = resumed
	_events.stack_popped.emit(resumed.name)
	_logger.debug("Resumed state from stack: %s" % resumed.name)

## Exit current state, clear the stack and history, then re-enter the initial state.
func restart() -> void:
	if _current_state != null:
		_exit_state(_current_state, null)
		_current_state = null

	for s: EasyState in _state_stack:
		s.status = SMEnums.StateStatus.INACTIVE
	_state_stack.clear()
	_history.clear()

	var initial_name := config.initial_state
	if initial_name != "" and _states.has(initial_name):
		_enter_state(_states[initial_name], null)
	elif _states.size() > 0:
		_enter_state(_states.values()[0], null)

# ── Getters ───────────────────────────────────────────────────────────────────

## Returns the currently active EasyState node, or null if none.
func get_current_state() -> EasyState:
	return _current_state

## Returns the name of the currently active state, or "" if none.
func get_current_state_name() -> String:
	return _current_state.name if _current_state != null else ""

## Returns the name of the state that was active before the last transition_to call.
func get_previous_state_name() -> String:
	return _previous_state_name

## Returns the EasyState node registered under the given name, or null.
func get_state(state_name: String) -> EasyState:
	return _states.get(state_name, null)

## Returns a copy of the internal state registry (name → EasyState).
func get_all_states() -> Dictionary:
	return _states.duplicate()

## Returns a copy of the state history ring buffer (array of state names).
func get_state_history() -> Array[String]:
	var copy: Array[String] = []
	copy.assign(_history)
	return copy

## Returns how many states are currently on the stack (0 when no push is active).
func get_stack_depth() -> int:
	return _state_stack.size()

# ── Setters ───────────────────────────────────────────────────────────────────

## Sets the name of the state the machine will enter on start or restart().
func set_initial_state(state_name: String) -> void:
	config.initial_state = state_name

## Enables or disables debug logging. When disabled, log_level is set to NONE.
func set_debug_enabled(enabled: bool) -> void:
	config.debug_enabled = enabled
	_logger.set_log_level(config.log_level if enabled else SMEnums.LogLevel.NONE)

## Sets how many entries to keep in the history ring buffer.
func set_history_max_size(size: int) -> void:
	config.history_max_size = maxi(1, size)

# ── Utility ───────────────────────────────────────────────────────────────────

## Returns true if a state with the given name is registered.
func has_state(state_name: String) -> bool:
	return _states.has(state_name)

## Returns true if the machine is currently in the given state.
func is_in_state(state_name: String) -> bool:
	return _current_state != null and _current_state.name == state_name

## Clears the state history ring buffer.
func clear_history() -> void:
	_history.clear()
