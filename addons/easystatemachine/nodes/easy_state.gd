@tool
@icon("res://addons/easystatemachine/icons/icon_easy_state.svg")
class_name EasyState
extends Node

## Base class for all states. Extend this and override the _on_* virtual methods.
##
## Usage:
##   class_name MyIdleState extends EasyState
##   func _on_enter(previous_state): ...
##   func _on_update(delta): ...

## Current lifecycle status. Managed exclusively by EasyStateMachine.
var status: SMEnums.StateStatus = SMEnums.StateStatus.INACTIVE

## Reference to the owning EasyStateMachine. Set automatically on registration.
var _machine: EasyStateMachine = null

## The entity this machine is attached to (the parent of EasyStateMachine).
var host: Node:
	get:
		return _machine.get_parent() if _machine != null else null

# ── Virtual lifecycle hooks ───────────────────────────────────────────────────

## Called when this state becomes active.
## previous_state is null if this is the first state entered.
func _on_enter(_previous_state: EasyState) -> void:
	pass

## Called every process frame while ACTIVE.
func _on_update(_delta: float) -> void:
	pass

## Called every physics frame while ACTIVE.
func _on_physics_update(_delta: float) -> void:
	pass

## Called for unhandled input events while ACTIVE.
func _on_unhandled_input(_event: InputEvent) -> void:
	pass

## Called just before this state becomes inactive.
## next_state is null if the machine is stopping or restarting.
func _on_exit(_next_state: EasyState) -> void:
	pass

# ── Convenience API ───────────────────────────────────────────────────────────

## Replace the current state with another.
func transition_to(state_name: String) -> void:
	if _machine != null:
		_machine.transition_to(state_name)

## Push a state onto the stack (current state pauses without exiting).
func push_state(state_name: String) -> void:
	if _machine != null:
		_machine.push_state(state_name)

## Pop the top state from the stack, resuming the previous one.
func pop_state() -> void:
	if _machine != null:
		_machine.pop_state()
