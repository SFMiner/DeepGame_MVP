class_name ItemPickup
extends Area2D

@export var item_data: ItemData

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player)._nearby_items.append(self)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		(body as Player)._nearby_items.erase(self)
