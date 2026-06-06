extends Node

var flags: Dictionary = {}
var defeat_count: int = 0

func set_flag(key: String, value: Variant) -> void:
	flags[key] = value

func get_flag(key: String, default: Variant = null) -> Variant:
	return flags.get(key, default)

func has_flag(key: String) -> bool:
	return flags.has(key)

func reset_all() -> void:
	flags.clear()
	defeat_count = 0
