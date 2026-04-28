@tool
class_name SMEnums
extends RefCounted

enum TransitionMode {
	REPLACE, ## Replaces the current state entirely
	PUSH,    ## Pushes onto the stack; current state pauses without exiting
}

enum StateStatus {
	INACTIVE,  ## Not active and not in the stack
	ENTERING,  ## _on_enter() is being called this frame
	ACTIVE,    ## Fully active; update hooks are being called
	EXITING,   ## _on_exit() is being called this frame
}

enum LogLevel {
	NONE  = 0,
	ERROR = 1,
	WARN  = 2,
	INFO  = 3,
	DEBUG = 4,
}
