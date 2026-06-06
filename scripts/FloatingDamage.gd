class_name FloatingDamage
extends Label

@export var float_speed: float = 60.0
@export var fade_duration: float = 1.0
@export var gravity: float = 0.0

var _velocity: Vector2 = Vector2(0, -float_speed)
var _elapsed: float = 0.0

func _ready() -> void:
	modulate = Color.WHITE

func _process(delta: float) -> void:
	_elapsed += delta
	var alpha: float = 1.0 - (_elapsed / fade_duration)
	modulate = Color(1.0, 1.0, 1.0, alpha)
	_velocity.y -= gravity * delta
	position += _velocity * delta

	if _elapsed >= fade_duration:
		queue_free()

func set_damage_value(damage: int) -> void:
	text = str(damage)
	if damage <= 0:
		text = "Miss"
		add_theme_color_override("font_color", Color.GRAY)
	elif damage >= 20:
		add_theme_color_override("font_color", Color.RED)
		add_theme_font_size_override("font_size", 20)
