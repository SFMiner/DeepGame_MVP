class_name Projectile
extends Area2D

var speed: float = 250.0
var damage: int = 0
var direction: Vector2 = Vector2.RIGHT
var attacker_name: String = ""
var lifetime: float = 3.0
var _projectile_data: ProjectileData
var _distance_traveled: float = 0.0
var _pierce_hit: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1

	var shape: CollisionShape2D = CollisionShape2D.new()
	var size: float = 4.0
	if _projectile_data:
		size = _projectile_data.size
		speed = _projectile_data.speed
		damage = _projectile_data.damage
		lifetime = _projectile_data.range / maxf(_projectile_data.speed, 1.0)
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = size
	shape.shape = circle
	add_child(shape)

	if _projectile_data:
		if _projectile_data.sprite_texture:
			var sprite: Sprite2D = Sprite2D.new()
			sprite.texture = _projectile_data.sprite_texture
			sprite.scale = Vector2(size / 16.0, size / 16.0)
			add_child(sprite)
		elif _projectile_data.color != Color.WHITE or size != 4.0:
			var poly: Polygon2D = Polygon2D.new()
			poly.color = _projectile_data.color
			poly.polygon = PackedVector2Array([Vector2(size, 0), Vector2(-size * 0.75, -size * 0.5), Vector2(-size * 0.75, size * 0.5)])
			add_child(poly)
	else:
		var poly: Polygon2D = Polygon2D.new()
		poly.color = Color(0.3, 0.9, 0.3, 1.0)
		poly.polygon = PackedVector2Array([Vector2(4, 0), Vector2(-3, -2), Vector2(-3, 2)])
		add_child(poly)

	rotation = direction.angle()

	body_entered.connect(_on_body_entered)

func set_projectile_data(data: ProjectileData) -> void:
	_projectile_data = data

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_distance_traveled += speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if body.stats:
			var actual: int = body.stats.take_damage(damage)
			EventBus.damage_dealt.emit(attacker_name, body.stats.character_name, actual, body.global_position, false)
		if _projectile_data and _projectile_data.pierce:
			if not _pierce_hit:
				_pierce_hit = true
				return
		queue_free()
