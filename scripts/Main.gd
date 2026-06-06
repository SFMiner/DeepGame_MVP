class_name Main
extends Node2D

const FLOATING_DAMAGE_SCENE: PackedScene = preload("res://scenes/floating_damage.tscn")

@onready var _player: Player = $Player
@onready var _hud: HUD = $HUD

var _total_enemies: int = 0
var _enemies_defeated: int = 0

func _ready() -> void:
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	call_deferred("_count_enemies")

func _count_enemies() -> void:
	_total_enemies = get_tree().get_nodes_in_group("enemies").size()

func _on_damage_dealt(attacker_name: String, defender_name: String, damage: int, world_position: Vector2) -> void:
	EventBus.combat_event.emit(attacker_name + " hit " + defender_name + " for " + str(damage))
	spawn_floating_damage(world_position, damage)

func _on_enemy_defeated(enemy_name: String) -> void:
	EventBus.combat_event.emit(enemy_name + " was defeated!")
	_enemies_defeated += 1
	if _enemies_defeated >= _total_enemies and _total_enemies > 0:
		EventBus.all_enemies_defeated.emit()

func spawn_floating_damage(world_position: Vector2, damage: int) -> void:
	var fd: FloatingDamage = FLOATING_DAMAGE_SCENE.instantiate()
	fd.position = world_position + Vector2(randf_range(-10, 10), -20)
	fd.set_damage_value(damage)
	add_child(fd)
