@tool
class_name SMEvents
extends Node

## Internal signal bus. One instance lives as a child of each EasyStateMachine.
## EasyStateMachine re-emits these as its own public signals (facade pattern).

signal state_changed(from_name: String, to_name: String)
signal state_entered(state_name: String)
signal state_exited(state_name: String)
signal stack_pushed(state_name: String)
signal stack_popped(state_name: String)
signal log_requested(level: int, message: String, context: String)
