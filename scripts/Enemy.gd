class_name Enemy
extends CharacterBody2D

enum Category { PASSIVE, MELEE, RANGED }
enum State { IDLE, WANDERING, CHASING, FLEEING, KITING }

@export var stats: CharacterStats
@export var enemy_category: Category = Category.PASSIVE

@export var wander_speed: float = 50.0
@export var wander_range: float = 60.0
@export var wander_interval: float = 2.0

@export var aggro_range: float = 150.0
@export var chase_speed: float = 80.0
@export var attack_cooldown: float = 1.0
@export var flee_hp_fraction: float = 0.5
@export var flee_distance: float = 100.0

@export var preferred_distance: float = 200.0
@export var projectile_speed: float = 200.0
@export var fire_cooldown: float = 2.0

@export var slime_color: String = "red"

var _current_state: State = State.IDLE
var _origin: Vector2 = Vector2.ZERO
var _wander_direction: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _state_timer: float = 0.0
var _attack_timer: float = 0.0
var _fire_timer: float = 0.0
var _player: Player = null
var _is_dead: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_origin = global_position
	_player = get_tree().get_first_node_in_group("player") as Player
	_setup_animations()
	if stats:
		stats = stats.duplicate() as CharacterStats
		stats.died.connect(_on_stats_died)
		add_to_group("enemies")

func _physics_process(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_fire_timer = maxf(0.0, _fire_timer - delta)

	match _current_state:
		State.IDLE:
			_state_idle(delta)
		State.WANDERING:
			_state_wandering(delta)
		State.CHASING:
			_state_chasing(delta)
		State.FLEEING:
			_state_fleeing(delta)
		State.KITING:
			_state_kiting(delta)

	move_and_slide()
	_update_animation(delta)
	_check_combat_collisions()

func _check_combat_collisions() -> void:
	if enemy_category != Category.MELEE:
		return
	if _attack_timer > 0.0:
		return
	if not _player:
		return
	for i: int in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Node = collision.get_collider() as Node
		if collider == _player:
			_attack_player()
			break

func _attack_player() -> void:
	if not stats or not _player.stats:
		return
	var damage: int = stats.attack
	var actual: int = _player.stats.take_damage(damage)
	_attack_timer = attack_cooldown
	EventBus.damage_dealt.emit(stats.character_name, _player.stats.character_name, actual, _player.global_position)

func _fire_projectile(direction: Vector2) -> void:
	var proj: Projectile = Projectile.new()
	proj.damage = stats.attack
	proj.direction = direction
	proj.speed = projectile_speed
	proj.attacker_name = stats.character_name
	get_parent().add_child(proj)
	proj.global_position = global_position + direction * 16.0

func _state_idle(delta: float) -> void:
	_state_timer += delta
	velocity = Vector2.ZERO
	_check_aggro()
	if _current_state != State.IDLE:
		return
	if _state_timer >= wander_interval:
		_enter_wandering()

func _state_wandering(delta: float) -> void:
	_wander_timer += delta
	_check_aggro()
	if _current_state != State.WANDERING:
		return
	if global_position.distance_to(_origin) > wander_range or _wander_timer >= wander_interval:
		_enter_idle()
		return
	velocity = _wander_direction * wander_speed

func _state_chasing(_delta: float) -> void:
	_check_flee_condition()
	if _current_state != State.CHASING:
		return
	if not _player:
		_enter_idle()
		return
	var direction: Vector2 = global_position.direction_to(_player.global_position)
	velocity = direction * chase_speed
	var dist_to_player: float = global_position.distance_to(_player.global_position)
	if dist_to_player > aggro_range * 2.0:
		_enter_idle()

func _state_fleeing(_delta: float) -> void:
	if not _player:
		_enter_idle()
		return
	var to_player: Vector2 = _player.global_position - global_position
	var distance: float = to_player.length()
	if distance >= flee_distance * 2.0:
		_enter_idle()
		return
	if distance >= flee_distance:
		velocity = Vector2.ZERO
		return
	var direction: Vector2 = -to_player.normalized()
	velocity = direction * chase_speed

func _state_kiting(_delta: float) -> void:
	_check_flee_condition()
	if _current_state != State.KITING:
		return
	if not _player:
		_enter_idle()
		return

	var to_player: Vector2 = _player.global_position - global_position
	var distance: float = to_player.length()
	var dir_to_player: Vector2 = to_player.normalized()

	if distance < preferred_distance * 0.7:
		velocity = -dir_to_player * chase_speed
	elif distance > preferred_distance * 1.3:
		velocity = dir_to_player * chase_speed
	else:
		velocity = Vector2.ZERO
		if _fire_timer <= 0.0:
			_fire_projectile(dir_to_player)
			_fire_timer = fire_cooldown

	if distance > aggro_range * 2.0:
		_enter_idle()

func _check_aggro() -> void:
	if _is_dead:
		return
	if enemy_category == Category.PASSIVE:
		return
	if not _player:
		return
	if global_position.distance_to(_player.global_position) <= aggro_range:
		match enemy_category:
			Category.MELEE:
				_enter_chasing()
			Category.RANGED:
				_enter_kiting()

func _check_flee_condition() -> void:
	if enemy_category == Category.PASSIVE:
		return
	if not stats:
		return
	if float(stats.hp) / float(stats.max_hp) <= flee_hp_fraction:
		_enter_fleeing()

const SLIME_PATH: String = "res://assets/spreitesheets_monster/slimes/"

func _enter_chasing() -> void:
	_current_state = State.CHASING
	_state_timer = 0.0
	_wander_timer = 0.0

func _enter_fleeing() -> void:
	_current_state = State.FLEEING
	_state_timer = 0.0
	_wander_timer = 0.0

func _enter_kiting() -> void:
	_current_state = State.KITING
	_state_timer = 0.0
	_wander_timer = 0.0

func _enter_wandering() -> void:
	_current_state = State.WANDERING
	_state_timer = 0.0
	_wander_timer = 0.0
	var angle: float = randf_range(0.0, TAU)
	_wander_direction = Vector2(cos(angle), sin(angle))

func _enter_idle() -> void:
	_current_state = State.IDLE
	_state_timer = 0.0
	_wander_timer = 0.0
	velocity = Vector2.ZERO

func _on_stats_died() -> void:
	_is_dead = true
	_sprite.play("death")
	set_physics_process(false)
	_collision_shape.set_deferred("disabled", true)
	queue_free()

func _setup_animations() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	var path: String = SLIME_PATH + slime_color
	_load_slime_grid(frames, "idle", path + "_idle.png", 4, 2, 6)
	_load_slime_grid(frames, "jump", path + "_jump.png", 8, 3, 18)
	_load_slime_grid(frames, "dash", path + "_dash_v.png", 4, 3)
	_load_slime_grid(frames, "death", path + "_death.png", 2, 2)
	_sprite.sprite_frames = frames
	_sprite.scale = Vector2(2.0, 2.0)
	_sprite.play("idle")

func _load_slime_grid(frames: SpriteFrames, anim_name: String, path: String, cols: int, rows: int, max_frames: int = -1) -> void:
	var sheet: Texture2D = load(path)
	if not sheet:
		return
	var fw: float = sheet.get_width() / float(cols)
	var fh: float = sheet.get_height() / float(rows)
	var total: int = cols * rows
	var count: int = total if max_frames < 0 else mini(max_frames, total)
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, 8.0)
	for i: int in range(count):
		var row: int = i / cols
		var col: int = i % cols
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(col * fw, row * fh, fw, fh)
		frames.add_frame(anim_name, atlas)

func _update_animation(_delta: float) -> void:
	var anim_name: String = "idle"
	match _current_state:
		State.IDLE:
			anim_name = "idle"
		State.WANDERING:
			anim_name = "jump"
		State.CHASING, State.FLEEING, State.KITING:
			anim_name = "dash"
	if _current_state == State.CHASING or _current_state == State.FLEEING or _current_state == State.KITING:
		_sprite.flip_h = velocity.x > 0
	else:
		_sprite.flip_h = false
	if _sprite.animation != anim_name:
		_sprite.play(anim_name)
