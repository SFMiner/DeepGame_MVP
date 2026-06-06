extends Node

var flags: Dictionary = {}
var defeat_count: int = 0
var permadeath_enabled: bool = false
var selected_class: CharacterClass
var player_data: PlayerData

func set_flag(key: String, value: Variant) -> void:
	flags[key] = value

func get_flag(key: String, default: Variant = null) -> Variant:
	return flags.get(key, default)

func has_flag(key: String) -> bool:
	return flags.has(key)

func reset_all() -> void:
	flags.clear()
	defeat_count = 0
	selected_class = null
	player_data = null
