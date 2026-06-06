class_name ItemData
extends Resource

enum ItemType { CONSUMABLE, WEAPON, ARMOR, QUEST, BOW, STAFF, SHIELD, ACCESSORY }

@export var item_name: String = ""
@export var item_description: String = ""
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var health_restore: int = 0
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var value: int = 0
@export var equip_slot: String = ""
@export var block_chance: float = 0.0
@export var mana_bonus: int = 0
@export var max_hp_bonus: int = 0
