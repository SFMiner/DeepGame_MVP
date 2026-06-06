class_name StatusEffect
extends Resource

enum EffectType { POISON, SLOW, STUN }

@export var effect_type: EffectType = EffectType.POISON
@export var duration: float = 3.0
@export var damage_per_tick: int = 0
@export var speed_multiplier: float = 1.0
@export var tick_interval: float = 1.0
