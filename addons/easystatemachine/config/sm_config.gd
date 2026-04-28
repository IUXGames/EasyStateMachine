@tool
class_name SMConfig
extends Resource

## Name of the state to enter when the machine starts.
## Set via the inspector dropdown in EasyStateMachine.
@export var initial_state: String = ""

## Maximum entries kept in the state history ring buffer.
@export_range(1, 200) var history_max_size: int = 20

## Maximum stack depth for push_state / pop_state.
@export_range(1, 32) var max_stack_depth: int = 8

## Enable debug logging for this machine instance.
@export var debug_enabled: bool = false

## Log verbosity level (maps to SMEnums.LogLevel).
@export_range(0, 4) var log_level: int = SMEnums.LogLevel.INFO
