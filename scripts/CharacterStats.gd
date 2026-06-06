class_name CharacterStats
extends Resource

signal hp_changed(current_hp: int, max_hp: int)
signal xp_changed(current_xp: int, xp_to_next: int)
signal leveled_up(new_level: int)
signal died()

@export var character_name: String = "Character"
@export var max_hp: int = 100
@export var hp: int = 100:
	set(value):
		hp = clampi(value, 0, max_hp)
		hp_changed.emit(hp, max_hp)
		if hp <= 0:
			died.emit()
@export var attack: int = 10
@export var defense: int = 5
@export var level: int = 1
@export var xp: int = 0:
	set(value):
		xp = value
		while xp >= xp_to_next:
			xp -= xp_to_next
			level_up()
		xp_changed.emit(xp, xp_to_next)
@export var xp_to_next: int = 50

func take_damage(amount: int) -> int:
	var actual_damage: int = maxi(1, amount - defense)
	hp -= actual_damage
	return actual_damage

func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)

func is_alive() -> bool:
	return hp > 0

func level_up() -> void:
	level += 1
	max_hp += 10
	hp = max_hp
	attack += 2
	defense += 1
	xp_to_next = int(xp_to_next * 1.5)
	leveled_up.emit(level)
