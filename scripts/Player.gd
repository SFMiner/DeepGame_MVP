class_name Player
extends CharacterBody2D

enum AtkState { IDLE, WINDUP, STRIKE, RECOVERY }

@export var stats: CharacterStats
@export var move_speed: float = 150.0
@export var attack_interval: float = 0.5
@export var windup_duration: float = 0.2
@export var strike_duration: float = 0.15
@export var recovery_duration: float = 0.3
@export var melee_range: float = 80.0
@export var knockback_strength: float = 200.0
@export var knockback_decay: float = 5.0

var _inventory: Array[ItemData] = []
var _equipment: Dictionary = {}
var _equipped_spells: Array[SpellData] = []
var _spell_cooldowns: Array[float] = []
var _attack_cooldown: float = 0.0
var _is_dead: bool = false
var _nearby_items: Array[ItemPickup] = []
var _last_facing: int = 0
var _sprite_set: String = "Beastmaster"
var _atk_state: AtkState = AtkState.IDLE
var _atk_state_timer: float = 0.0
var _active_statuses: Array[StatusEffect] = []
var _status_timers: Array[float] = []
var _knockback_velocity: Vector2 = Vector2.ZERO
var _melee_hitbox: Area2D
var _input_direction: Vector2 = Vector2.ZERO

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_setup_animations()
	_setup_melee_hitbox()
	add_to_group("player")
	if stats:
		stats = stats.duplicate() as CharacterStats
		stats.hp_changed.connect(_on_stats_hp_changed)
		stats.xp_changed.connect(_on_stats_xp_changed)
		stats.leveled_up.connect(_on_stats_leveled_up)
		stats.died.connect(_on_stats_died)
		stats.mana_changed.connect(_on_stats_mana_changed)
		EventBus.player_hp_changed.emit(stats.hp, stats.max_hp)
		EventBus.player_xp_changed.emit(stats.xp, stats.xp_to_next)
		EventBus.player_mana_changed.emit(stats.mana, stats.max_mana)
	_equip_spells_from_data()

func _setup_melee_hitbox() -> void:
	_melee_hitbox = Area2D.new()
	_melee_hitbox.collision_layer = 0
	_melee_hitbox.collision_mask = 1
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(melee_range, 40)
	shape.shape = rect
	shape.position = Vector2(melee_range / 2.0, 0)
	_melee_hitbox.add_child(shape)
	_melee_hitbox.monitoring = false
	call_deferred("add_child", _melee_hitbox)

func _input(event: InputEvent) -> void:
	if event.is_action("move_left"):
		_input_direction.x = -1.0 if event.is_pressed() else (0.0 if _input_direction.x < 0 else _input_direction.x)
	elif event.is_action("move_right"):
		_input_direction.x = 1.0 if event.is_pressed() else (0.0 if _input_direction.x > 0 else _input_direction.x)
	elif event.is_action("move_up"):
		_input_direction.y = -1.0 if event.is_pressed() else (0.0 if _input_direction.y < 0 else _input_direction.y)
	elif event.is_action("move_down"):
		_input_direction.y = 1.0 if event.is_pressed() else (0.0 if _input_direction.y > 0 else _input_direction.y)

func _physics_process(delta: float) -> void:
	if _is_dead:
		velocity = Vector2.ZERO
		return

	_process_statuses(delta)
	_process_knockback(delta)
	_process_attack_state(delta)
	_process_spell_cooldowns(delta)

	if _atk_state == AtkState.IDLE or _atk_state == AtkState.STRIKE:
		velocity = _input_direction * get_effective_speed()
	else:
		velocity = Vector2.ZERO

	velocity += _knockback_velocity
	move_and_slide()

	if Input.is_action_just_pressed("interact"):
		_try_pickup_item()

	_check_attack_input()
	_update_animation(delta)

func _process_attack_state(delta: float) -> void:
	match _atk_state:
		AtkState.WINDUP:
			_atk_state_timer -= delta
			if _atk_state_timer <= 0.0:
				_do_strike()
		AtkState.STRIKE:
			_atk_state_timer -= delta
			if _atk_state_timer <= 0.0:
				_do_recovery()
		AtkState.RECOVERY:
			_atk_state_timer -= delta
			if _atk_state_timer <= 0.0:
				_atk_state = AtkState.IDLE

func _check_attack_input() -> void:
	if get_tree().paused:
		return
	if _atk_state != AtkState.IDLE:
		return
	if Input.is_action_just_pressed("attack_melee"):
		_start_melee_attack()
	elif Input.is_action_just_pressed("attack_ranged"):
		_start_ranged_attack()
	elif Input.is_action_just_pressed("spell_1"):
		cast_spell(0)
	elif Input.is_action_just_pressed("spell_2"):
		cast_spell(1)
	elif Input.is_action_just_pressed("spell_3"):
		cast_spell(2)

func _start_melee_attack() -> void:
	_atk_state = AtkState.WINDUP
	_atk_state_timer = windup_duration

func _do_strike() -> void:
	_atk_state = AtkState.STRIKE
	_atk_state_timer = strike_duration
	_melee_hitbox.monitoring = true
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for enemy: Node in enemies:
		if enemy is Enemy:
			var e: Enemy = enemy as Enemy
			if e.stats and e.stats.is_alive():
				var to_enemy: Vector2 = e.global_position - global_position
				if to_enemy.length() <= melee_range:
					_deal_damage_to_enemy(e)

func _do_recovery() -> void:
	_atk_state = AtkState.RECOVERY
	_atk_state_timer = recovery_duration
	_melee_hitbox.monitoring = false

func _start_ranged_attack() -> void:
	pass

func cast_spell(index: int) -> void:
	if index < 0 or index >= _equipped_spells.size():
		return
	var spell: SpellData = _equipped_spells[index]
	if not spell:
		return
	if index < _spell_cooldowns.size() and _spell_cooldowns[index] > 0.0:
		EventBus.game_message.emit("Spell on cooldown")
		return
	var has_staff: bool = false
	var weapon: ItemData = _equipment.get("weapon")
	if weapon and weapon.item_type == ItemData.ItemType.STAFF:
		has_staff = true
	if not has_staff:
		EventBus.game_message.emit("Staff required to cast spells")
		return
	if not stats or not stats.use_mana(spell.mana_cost):
		EventBus.game_message.emit("Not enough mana")
		return
	EventBus.game_message.emit("Cast " + spell.spell_name + "!")
	var proj: Projectile = Projectile.new()
	proj.set_projectile_data(spell.projectile_data)
	proj.attacker_name = stats.character_name
	var dir: Vector2 = Vector2.DOWN
	match _last_facing:
		0: dir = Vector2.DOWN
		1: dir = Vector2.LEFT
		2: dir = Vector2.RIGHT
		3: dir = Vector2.UP
	proj.direction = dir
	proj._projectile_data = spell.projectile_data
	get_parent().add_child(proj)
	proj.global_position = global_position + dir * 20.0
	if spell.status_effect:
		proj._status_effect_on_hit = spell.status_effect
	while _spell_cooldowns.size() <= index:
		_spell_cooldowns.append(0.0)
	_spell_cooldowns[index] = spell.cooldown
	_equip_spells_from_data()

func _process_spell_cooldowns(delta: float) -> void:
	for i: int in range(_spell_cooldowns.size()):
		_spell_cooldowns[i] = maxf(0.0, _spell_cooldowns[i] - delta)

func _equip_spells_from_data() -> void:
	if GameState.player_data:
		for spell: SpellData in GameState.player_data.equipped_spells:
			if not _equipped_spells.has(spell):
				_equipped_spells.append(spell)
		GameState.player_data.equipped_spells = _equipped_spells.duplicate()

func _deal_damage_to_enemy(enemy: Enemy) -> void:
	if not stats or not enemy.stats:
		return
	var is_crit: bool = randf() < stats.crit_chance
	var damage: int = stats.attack
	var actual: int = enemy.stats.take_damage(damage, is_crit)
	EventBus.damage_dealt.emit(stats.character_name, enemy.stats.character_name, actual, enemy.global_position, is_crit)
	enemy.apply_knockback(global_position, knockback_strength)
	if not enemy.stats.is_alive():
		EventBus.enemy_defeated.emit(enemy.stats.character_name)
		GameState.defeat_count += 1
		_grant_xp_for_enemy(enemy.stats.level)

func apply_knockback(from_position: Vector2, strength: float) -> void:
	var direction: Vector2 = global_position.direction_to(from_position)
	_knockback_velocity = direction * strength

func _process_knockback(delta: float) -> void:
	if _knockback_velocity.length() < 1.0:
		_knockback_velocity = Vector2.ZERO
		return
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * _knockback_velocity.length() * delta)

func apply_status_effect(effect: StatusEffect) -> void:
	_active_statuses.append(effect)
	_status_timers.append(effect.duration)
	EventBus.status_applied.emit(stats.character_name if stats else "Player", effect.effect_type)

func _process_statuses(delta: float) -> void:
	if _active_statuses.is_empty():
		return
	for i: int in range(_active_statuses.size() - 1, -1, -1):
		var effect: StatusEffect = _active_statuses[i]
		_status_timers[i] -= delta
		if effect.effect_type == StatusEffect.EffectType.POISON:
			if fmod(effect.duration - _status_timers[i], effect.tick_interval) < delta:
				stats.take_damage(effect.damage_per_tick)
		if _status_timers[i] <= 0.0:
			_active_statuses.remove_at(i)
			_status_timers.remove_at(i)

func take_damage_from_enemy(damage: int, is_crit: bool = false, attacker_pos: Vector2 = Vector2.ZERO) -> void:
	if not stats:
		return
	if _atk_state == AtkState.STRIKE:
		return
	if _atk_state == AtkState.WINDUP:
		_atk_state = AtkState.IDLE
		_atk_state_timer = 0.0
		_melee_hitbox.monitoring = false
	stats.take_damage(damage, is_crit)
	if attacker_pos != Vector2.ZERO:
		apply_knockback(attacker_pos, knockback_strength * 0.7)

func get_effective_speed() -> float:
	for effect: StatusEffect in _active_statuses:
		if effect.effect_type == StatusEffect.EffectType.SLOW:
			return move_speed * effect.speed_multiplier
		if effect.effect_type == StatusEffect.EffectType.STUN:
			return 0.0
	return move_speed

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
		ItemData.ItemType.WEAPON, ItemData.ItemType.BOW, ItemData.ItemType.STAFF:
			return equip_item(index)
		ItemData.ItemType.ARMOR, ItemData.ItemType.SHIELD:
			return equip_item(index)
		ItemData.ItemType.ACCESSORY:
			return equip_item(index)
		ItemData.ItemType.QUEST:
			EventBus.game_message.emit(item.item_name + " has no immediate use")
			return false
	return false

func equip_item(index: int) -> bool:
	if index < 0 or index >= _inventory.size():
		return false
	var item: ItemData = _inventory[index]
	var slot: String = item.equip_slot
	if slot.is_empty():
		return false
	var old_item: ItemData = _equipment.get(slot)
	if old_item:
		_inventory.append(old_item)
	_equipment[slot] = item
	_inventory.remove_at(index)
	_recalc_stats()
	if old_item:
		EventBus.game_message.emit("Swapped " + item.item_name + " for " + old_item.item_name)
	else:
		EventBus.game_message.emit("Equipped " + item.item_name)
	return true

func unequip_item(slot: String) -> void:
	var item: ItemData = _equipment.get(slot)
	if not item:
		return
	_inventory.append(item)
	_equipment.erase(slot)
	_recalc_stats()
	EventBus.game_message.emit("Unequipped " + item.item_name)

func drop_item(source: Variant) -> void:
	var item: ItemData = null
	if source is int:
		var index: int = source as int
		if index < 0 or index >= _inventory.size():
			return
		item = _inventory[index]
		_inventory.remove_at(index)
	elif source is String:
		var slot: String = source as String
		item = _equipment.get(slot)
		if not item:
			return
		_equipment.erase(slot)
		_recalc_stats()
	else:
		return
	var pickup: PackedScene = load("res://scenes/item_pickup.tscn") as PackedScene
	var ip: ItemPickup = pickup.instantiate()
	ip.item_data = item
	get_parent().add_child(ip)
	ip.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	EventBus.game_message.emit("Dropped " + item.item_name)

func _recalc_stats() -> void:
	if not stats:
		return
	if GameState.player_data:
		var pd: PlayerData = GameState.player_data
		stats.max_hp = pd.base_max_hp
		stats.attack = pd.base_attack
		stats.defense = pd.base_defense
		stats.max_mana = pd.base_mana
	for slot: String in _equipment:
		var item: ItemData = _equipment[slot]
		if not item:
			continue
		stats.attack += item.attack_bonus
		stats.defense += item.defense_bonus
		stats.max_hp += item.max_hp_bonus
		stats.max_mana += item.mana_bonus
	stats.hp = mini(stats.hp, stats.max_hp)
	stats.mana = mini(stats.mana, stats.max_mana)
	EventBus.player_hp_changed.emit(stats.hp, stats.max_hp)
	EventBus.player_mana_changed.emit(stats.mana, stats.max_mana)

func get_equipment() -> Dictionary:
	return _equipment

func get_equipped_spells() -> Array[SpellData]:
	return _equipped_spells

func get_inventory() -> Array[ItemData]:
	return _inventory

func _try_pickup_item() -> void:
	if _nearby_items.is_empty():
		return
	var pickup: ItemPickup = _nearby_items.pop_front()
	add_item(pickup.item_data)
	pickup.queue_free()

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

func _on_stats_mana_changed(current_mana: int, max_mana: int) -> void:
	EventBus.player_mana_changed.emit(current_mana, max_mana)

func _on_stats_leveled_up(new_level: int) -> void:
	EventBus.player_leveled_up.emit(new_level)
	EventBus.game_message.emit("Level Up! Now level " + str(new_level))
	EventBus.player_hp_changed.emit(stats.hp, stats.max_hp)
	EventBus.player_mana_changed.emit(stats.mana, stats.max_mana)

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
	var inp: Vector2 = _input_direction
	if inp.length() < 0.1:
		return _last_facing
	if abs(inp.x) >= abs(inp.y):
		_last_facing = 1 if inp.x < 0 else 2
	else:
		_last_facing = 3 if inp.y < 0 else 0
	return _last_facing

func _update_animation(_delta: float) -> void:
	var dir_idx: int = _get_direction()
	var base: String = "idle"
	match _atk_state:
		AtkState.WINDUP, AtkState.STRIKE:
			base = "melee"
		_:
			base = "walk" if velocity.length() > 10.0 else "idle"
	var anim_name: String = base + "_" + DIR_NAMES[dir_idx]
	if _sprite.animation != anim_name:
		_sprite.play(anim_name)
