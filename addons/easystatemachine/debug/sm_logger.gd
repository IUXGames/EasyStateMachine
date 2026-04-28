class_name SMLogger
extends RefCounted

signal log_emitted(
	level: int,
	level_name: String,
	context: String,
	message: String,
	formatted: String,
	timestamp_msec: int
)

var log_level: int = SMEnums.LogLevel.INFO
var _prefix: String = "[ESM] "

func _init(machine_name: String = "") -> void:
	if machine_name != "":
		_prefix = "[ESM|%s] " % machine_name

func set_log_level(level: int) -> void:
	log_level = level

func error(message: String, context: String = "") -> void:
	if log_level < SMEnums.LogLevel.ERROR:
		return
	var formatted := _format_message("ERROR", message, context)
	push_error(formatted)
	_emit_log(SMEnums.LogLevel.ERROR, "ERROR", context, message, formatted)

func warn(message: String, context: String = "") -> void:
	if log_level < SMEnums.LogLevel.WARN:
		return
	var formatted := _format_message("WARN", message, context)
	push_warning(formatted)
	_emit_log(SMEnums.LogLevel.WARN, "WARN", context, message, formatted)

func info(message: String, context: String = "") -> void:
	if log_level < SMEnums.LogLevel.INFO:
		return
	var formatted := _format_message("INFO", message, context)
	print(formatted)
	_emit_log(SMEnums.LogLevel.INFO, "INFO", context, message, formatted)

func debug(message: String, context: String = "") -> void:
	if log_level < SMEnums.LogLevel.DEBUG:
		return
	var formatted := _format_message("DEBUG", message, context)
	print(formatted)
	_emit_log(SMEnums.LogLevel.DEBUG, "DEBUG", context, message, formatted)

func _format_message(level_name: String, message: String, context: String) -> String:
	if context != "":
		return "%s[%s][%s] %s" % [_prefix, level_name, context, message]
	return "%s[%s] %s" % [_prefix, level_name, message]

func _emit_log(level: int, level_name: String, context: String, message: String, formatted: String) -> void:
	log_emitted.emit(level, level_name, context, message, formatted, Time.get_ticks_msec())
