extends Node

signal player_hp_changed(current_hp: int, max_hp: int)
signal player_xp_changed(current_xp: int, xp_to_next: int)
signal player_leveled_up(new_level: int)
signal player_died()
signal combat_event(message: String)
signal damage_dealt(attacker_name: String, defender_name: String, damage: int, world_position: Vector2)
signal item_picked_up(item_name: String)
signal game_message(message: String)
signal enemy_defeated(enemy_name: String)
signal all_enemies_defeated()
