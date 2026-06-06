class_name Main
extends Node2D

const FLOATING_DAMAGE_SCENE: PackedScene = preload("res://scenes/floating_damage.tscn")
const ROOM_W: int = 640
const ROOM_H: int = 480
const WALL_THICKNESS: int = 16

@onready var _player: Player = $Player
@onready var _hud: HUD = $HUD

var _total_enemies: int = 0
var _enemies_defeated: int = 0

func _ready() -> void:
	_create_room()
	_setup_navigation()
	_init_player_from_class()
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	call_deferred("_count_enemies")

func _create_room() -> void:
	var floor: Polygon2D = Polygon2D.new()
	floor.color = Color(0.2, 0.25, 0.15, 1.0)
	var hw: float = ROOM_W / 2.0
	var hh: float = ROOM_H / 2.0
	floor.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)
	])
	add_child(floor)

	var wall_color: Color = Color(0.3, 0.25, 0.2, 1.0)
	var wt: int = WALL_THICKNESS
	_create_wall(Vector2(-hw - wt, -hh - wt), ROOM_W + wt * 2, wt, wall_color)
	_create_wall(Vector2(-hw - wt, hh), ROOM_W + wt * 2, wt, wall_color)
	_create_wall(Vector2(-hw - wt, -hh), wt, ROOM_H, wall_color)
	_create_wall(Vector2(hw, -hh), wt, ROOM_H, wall_color)

func _create_wall(pos: Vector2, w: float, h: float, color: Color) -> void:
	var wall: Polygon2D = Polygon2D.new()
	wall.color = color
	wall.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)
	])
	wall.position = pos
	add_child(wall)

func _setup_navigation() -> void:
	var nav_region: NavigationRegion2D = NavigationRegion2D.new()
	var nav_poly: NavigationPolygon = NavigationPolygon.new()
	var margin: int = WALL_THICKNESS + 8
	var hw: float = ROOM_W / 2.0 - margin
	var hh: float = ROOM_H / 2.0 - margin
	nav_poly.add_outline(PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)
	]))
	nav_poly.make_polygons_from_outlines()
	nav_region.navigation_polygon = nav_poly
	add_child(nav_region)

func _init_player_from_class() -> void:
	if not GameState.player_data:
		return
	var pd: PlayerData = GameState.player_data
	if _player and _player.stats:
		_player.stats.character_name = pd.character_class_name
		_player.stats.max_hp = pd.base_max_hp
		_player.stats.hp = pd.base_max_hp
		_player.stats.max_mana = pd.base_mana
		_player.stats.mana = pd.base_mana
		_player.stats.attack = pd.base_attack
		_player.stats.defense = pd.base_defense
		if GameState.selected_class:
			_player.stats.crit_chance = 0.05 + GameState.selected_class.crit_chance_bonus
		_player.update_sprite_set(pd.sprite_set)
		EventBus.player_hp_changed.emit(_player.stats.hp, _player.stats.max_hp)
		EventBus.player_xp_changed.emit(_player.stats.xp, _player.stats.xp_to_next)
		EventBus.player_mana_changed.emit(_player.stats.mana, _player.stats.max_mana)

func _count_enemies() -> void:
	_total_enemies = get_tree().get_nodes_in_group("enemies").size()

func _on_damage_dealt(attacker_name: String, defender_name: String, damage: int, world_position: Vector2, is_crit: bool) -> void:
	EventBus.combat_event.emit(attacker_name + " hit " + defender_name + " for " + str(damage))
	spawn_floating_damage(world_position, damage, is_crit)

func _on_enemy_defeated(enemy_name: String) -> void:
	EventBus.combat_event.emit(enemy_name + " was defeated!")
	_enemies_defeated += 1
	if _enemies_defeated >= _total_enemies and _total_enemies > 0:
		EventBus.all_enemies_defeated.emit()

func spawn_floating_damage(world_position: Vector2, damage: int, is_crit: bool = false) -> void:
	var fd: FloatingDamage = FLOATING_DAMAGE_SCENE.instantiate()
	fd.position = world_position + Vector2(randf_range(-10, 10), -20)
	fd.set_damage_value(damage)
	if is_crit:
		fd.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0, 1.0))
		fd.add_theme_font_size_override("font_size", 22)
	add_child(fd)

