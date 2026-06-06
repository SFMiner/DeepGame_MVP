class_name Projectile
extends Area2D

var speed: float = 250.0
var damage: int = 0
var direction: Vector2 = Vector2.RIGHT
var attacker_name: String = ""
var lifetime: float = 3.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1

	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)

	var poly: Polygon2D = Polygon2D.new()
	poly.color = Color(0.3, 0.9, 0.3, 1.0)
	poly.polygon = PackedVector2Array([Vector2(4, 0), Vector2(-3, -2), Vector2(-3, 2)])
	add_child(poly)

	rotation = direction.angle()

	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if body.stats:
			var actual: int = body.stats.take_damage(damage)
			EventBus.damage_dealt.emit(attacker_name, body.stats.character_name, actual, body.global_position)
		queue_free()
