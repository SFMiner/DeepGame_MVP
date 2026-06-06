class_name PlayerData
extends Resource

@export var player_name: String = "Hero"
@export var character_class_name: String = ""
@export var level: int = 1
@export var xp: int = 0
@export var xp_to_next: int = 50
@export var base_max_hp: int = 100
@export var base_attack: int = 10
@export var base_defense: int = 5
@export var base_mana: int = 50
@export var gold: int = 0
@export var equipment: Dictionary = {}
@export var inventory: Array[ItemData] = []
@export var equipped_spells: Array[SpellData] = []
@export var dungeon_depth: int = 1
@export var flags: Dictionary = {}

func serialize() -> Dictionary:
	var data: Dictionary = {
		"player_name": player_name,
		"character_class_name": character_class_name,
		"level": level,
		"xp": xp,
		"xp_to_next": xp_to_next,
		"base_max_hp": base_max_hp,
		"base_attack": base_attack,
		"base_defense": base_defense,
		"base_mana": base_mana,
		"gold": gold,
		"dungeon_depth": dungeon_depth,
		"flags": flags,
	}
	var eq: Dictionary = {}
	for slot: String in equipment:
		var item: ItemData = equipment[slot] as ItemData
		if item:
			eq[slot] = item.resource_path
		else:
			eq[slot] = ""
	data["equipment"] = eq
	var inv: Array[String] = []
	for item: ItemData in inventory:
		inv.append(item.resource_path)
	data["inventory"] = inv
	var spells: Array[String] = []
	for spell: SpellData in equipped_spells:
		spells.append(spell.resource_path)
	data["equipped_spells"] = spells
	return data

static func deserialize(data: Dictionary) -> PlayerData:
	var pd: PlayerData = PlayerData.new()
	pd.player_name = data.get("player_name", "Hero")
	pd.character_class_name = data.get("character_class_name", "")
	pd.level = data.get("level", 1)
	pd.xp = data.get("xp", 0)
	pd.xp_to_next = data.get("xp_to_next", 50)
	pd.base_max_hp = data.get("base_max_hp", 100)
	pd.base_attack = data.get("base_attack", 10)
	pd.base_defense = data.get("base_defense", 5)
	pd.base_mana = data.get("base_mana", 50)
	pd.gold = data.get("gold", 0)
	pd.dungeon_depth = data.get("dungeon_depth", 1)
	pd.flags = data.get("flags", {})
	var eq: Dictionary = data.get("equipment", {})
	pd.equipment = {}
	for slot: String in eq:
		var path: String = eq[slot]
		if path != "":
			pd.equipment[slot] = load(path) as ItemData
		else:
			pd.equipment[slot] = null
	var inv: Array[String] = data.get("inventory", [])
	pd.inventory.clear()
	for path: String in inv:
		pd.inventory.append(load(path) as ItemData)
	var spells: Array[String] = data.get("equipped_spells", [])
	pd.equipped_spells.clear()
	for path: String in spells:
		pd.equipped_spells.append(load(path) as SpellData)
	return pd
