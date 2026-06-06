class_name CharacterClass
extends Resource

@export var class_name: String = ""
@export var description: String = ""
@export var hp_per_level: int = 10
@export var attack_per_level: int = 2
@export var defense_per_level: int = 1
@export var mana_per_level: int = 5
@export var available_spells: Array[SpellData] = []
@export var sprite_set: String = "Beastmaster"
@export var crit_chance_bonus: float = 0.0

func get_stat_bonuses() -> Dictionary:
	return {
		"hp": hp_per_level,
		"attack": attack_per_level,
		"defense": defense_per_level,
		"mana": mana_per_level,
	}
