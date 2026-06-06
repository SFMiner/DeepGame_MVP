class_name ItemData
extends Resource

enum ItemType { CONSUMABLE, WEAPON, ARMOR, QUEST }

@export var item_name: String = ""
@export var item_description: String = ""
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var health_restore: int = 0
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var value: int = 0
