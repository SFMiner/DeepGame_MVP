class_name CharacterStats
extends Resource

signal hp_changed(current_hp: int, max_hp: int)
signal xp_changed(current_xp: int, xp_to_next: int)
signal leveled_up(new_level: int)
signal died()
signal mana_changed(current_mana: int, max_mana: int)

@export var character_name: String = "Character"
@export var max_hp: int = 100
@export var hp: int = 100:
	set(value):
		hp = clampi(value, 0, max_hp)
		hp_changed.emit(hp, max_hp)
		if hp <= 0:
			died.emit()
@export var max_mana: int = 50
@export var mana: int = 50:
	set(value):
		mana = clampi(value, 0, max_mana)
		mana_changed.emit(mana, max_mana)
@export var attack: int = 10
@export var defense: int = 5
@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 2.0
@export var level: int = 1
@export var xp: int = 0:
	set(value):
		xp = value
		while xp >= xp_to_next:
			xp -= xp_to_next
			level_up()
		xp_changed.emit(xp, xp_to_next)
@export var xp_to_next: int = 50

func take_damage(amount: int, is_crit: bool = false) -> int:
	var raw_damage: int = amount * int(crit_multiplier) if is_crit else amount
	var actual_damage: int = maxi(1, raw_damage - defense)
	hp -= actual_damage
	return actual_damage

func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)

func use_mana(cost: int) -> bool:
	if mana < cost:
		return false
	mana -= cost
	return true

func restore_mana(amount: int) -> void:
	mana = mini(mana + amount, max_mana)

func is_alive() -> bool:
	return hp > 0

func level_up(stat_bonuses: Dictionary = {}) -> void:
	level += 1
	max_hp += stat_bonuses.get("hp", 10)
	attack += stat_bonuses.get("attack", 2)
	defense += stat_bonuses.get("defense", 1)
	max_mana += stat_bonuses.get("mana", 5)
	hp = max_hp
	mana = max_mana
	xp_to_next = int(xp_to_next * 1.5)
	leveled_up.emit(level)
