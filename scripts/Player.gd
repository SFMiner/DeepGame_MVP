class_name Player
extends CharacterBody2D

@export var stats: CharacterStats
@export var move_speed: float = 150.0
@export var attack_interval: float = 0.5

var _inventory: Array[ItemData] = []
var _attack_cooldown: float = 0.0
var _is_dead: bool = false
var _nearby_items: Array[ItemPickup] = []
var _last_facing: int = 0
var _sprite_set: String = "Beastmaster"

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_setup_animations()
	add_to_group("player")
	if stats:
		stats = stats.duplicate() as CharacterStats
		stats.hp_changed.connect(_on_stats_hp_changed)
		stats.xp_changed.connect(_on_stats_xp_changed)
		stats.leveled_up.connect(_on_stats_leveled_up)
		stats.died.connect(_on_stats_died)
		EventBus.player_hp_changed.emit(stats.hp, stats.max_hp)
		EventBus.player_xp_changed.emit(stats.xp, stats.xp_to_next)

func _physics_process(delta: float) -> void:
	if _is_dead:
		velocity = Vector2.ZERO
		return

	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	move_and_slide()

	if Input.is_action_just_pressed("interact"):
		_try_pickup_item()

	_update_animation(delta)

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)

	if _attack_cooldown <= 0.0:
		for i: int in range(get_slide_collision_count()):
			var collision: KinematicCollision2D = get_slide_collision(i)
			var collider: Node = collision.get_collider() as Node
			if collider:
				if collider is Enemy:
					_attack_enemy(collider as Enemy)
					_attack_cooldown = attack_interval
					break

func add_item(item: ItemData) -> void:
	_inventory.append(item)
	EventBus.item_picked_up.emit(item.item_name)

func use_item(index: int) -> bool:
	if index < 0 or index >= _inventory.size():
		return false
	var item: ItemData = _inventory[index]
	match item.item_type:
		ItemData.ItemType.CONSUMABLE:
			if item.health_restore > 0:
				if stats:
					stats.heal(item.health_restore)
				EventBus.game_message.emit("Used " + item.item_name + ": restored " + str(item.health_restore) + " HP")
			_inventory.remove_at(index)
			return true
		ItemData.ItemType.WEAPON:
			if stats:
				stats.attack += item.attack_bonus
			EventBus.game_message.emit("Equipped " + item.item_name + ": +" + str(item.attack_bonus) + " ATK")
			return true
		ItemData.ItemType.ARMOR:
			if stats:
				stats.defense += item.defense_bonus
			EventBus.game_message.emit("Equipped " + item.item_name + ": +" + str(item.defense_bonus) + " DEF")
			return true
		ItemData.ItemType.QUEST:
			EventBus.game_message.emit(item.item_name + " has no immediate use")
			return false
	return false

func get_inventory() -> Array[ItemData]:
	return _inventory

func _try_pickup_item() -> void:
	if _nearby_items.is_empty():
		return
	var pickup: ItemPickup = _nearby_items.pop_front()
	add_item(pickup.item_data)
	pickup.queue_free()

func _attack_enemy(enemy: Enemy) -> void:
	if not stats or not enemy.stats:
		return
	var is_crit: bool = randf() < stats.crit_chance
	var damage: int = stats.attack
	var actual: int = enemy.stats.take_damage(damage, is_crit)
	EventBus.damage_dealt.emit(stats.character_name, enemy.stats.character_name, actual, enemy.global_position, is_crit)
	if not enemy.stats.is_alive():
		EventBus.enemy_defeated.emit(enemy.stats.character_name)
		GameState.defeat_count += 1
		_grant_xp_for_enemy(enemy.stats.level)

func _grant_xp_for_enemy(enemy_level: int) -> void:
	if not stats:
		return
	var xp_reward: int = enemy_level * 20
	stats.xp += xp_reward
	EventBus.game_message.emit("Gained " + str(xp_reward) + " XP")

func _on_stats_hp_changed(current_hp: int, _max_hp: int) -> void:
	EventBus.player_hp_changed.emit(current_hp, _max_hp)

func _on_stats_xp_changed(current_xp: int, xp_to_next: int) -> void:
	EventBus.player_xp_changed.emit(current_xp, xp_to_next)

func _on_stats_leveled_up(new_level: int) -> void:
	EventBus.player_leveled_up.emit(new_level)
	EventBus.game_message.emit("Level Up! Now level " + str(new_level))
	EventBus.player_hp_changed.emit(stats.hp, stats.max_hp)

func _on_stats_died() -> void:
	_is_dead = true
	_sprite.play("die_down")
	EventBus.player_died.emit()
	EventBus.game_message.emit("Player has been defeated!")

const CHAR_BASE_PATH: String = "res://assets/spritesheets_player/"
const DIR_NAMES: Array[String] = ["down", "left", "right", "up"]

func update_sprite_set(sprite_set: String) -> void:
	_sprite_set = sprite_set
	_setup_animations()

func get_sprite_set() -> String:
	return _sprite_set

func _setup_animations() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	var char_path: String = CHAR_BASE_PATH + _sprite_set
	_load_spritesheet(frames, "idle", char_path + "_idle.png", 4)
	_load_spritesheet(frames, "walk", char_path + "_walk.png", 4)
	_load_spritesheet(frames, "melee", char_path + "_melee.png", 4)
	_load_spritesheet(frames, "hit", char_path + "_hit.png", 2)
	_load_spritesheet(frames, "die", char_path + "_die.png", 1)
	_sprite.sprite_frames = frames
	_sprite.play("idle_down")

func _load_spritesheet(frames: SpriteFrames, anim_base: String, path: String, frame_count: int) -> void:
	var sheet: Texture2D = load(path)
	var fw: int = int(sheet.get_width() / frame_count)
	var fh: int = int(sheet.get_height() / 4)
	for row: int in range(4):
		var anim_name: String = anim_base + "_" + DIR_NAMES[row]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, 8.0)
		for col: int in range(frame_count):
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(col * fw, row * fh, fw, fh)
			frames.add_frame(anim_name, atlas)

func _get_direction() -> int:
	var inp: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if inp.length() < 0.1:
		return _last_facing
	if abs(inp.x) >= abs(inp.y):
		_last_facing = 1 if inp.x < 0 else 2
	else:
		_last_facing = 3 if inp.y < 0 else 0
	return _last_facing

func _update_animation(_delta: float) -> void:
	var dir_idx: int = _get_direction()
	var base: String = "walk" if velocity.length() > 10.0 else "idle"
	var anim_name: String = base + "_" + DIR_NAMES[dir_idx]
	if _sprite.animation != anim_name:
		_sprite.play(anim_name)
