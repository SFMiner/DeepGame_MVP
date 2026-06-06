class_name HUD
extends CanvasLayer

var _hp_bar: ProgressBar
var _hp_label: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _level_label: Label
var _defeat_label: Label
var _event_log: RichTextLabel

@export var log_max_lines: int = 6

var _log_messages: Array[String] = []
var _inventory_open: bool = false
var _game_over_panel: Panel
var _game_over_label: Label
var _game_over_restart_button: Button
var _victory_panel: Panel
var _victory_label: Label
var _victory_restart_button: Button
var _inventory_panel: Panel
var _inventory_label: Label

func _ready() -> void:
	_create_ui()

	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.player_xp_changed.connect(_on_player_xp_changed)
	EventBus.player_leveled_up.connect(_on_player_leveled_up)
	EventBus.player_died.connect(_on_player_died)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.game_message.connect(_on_game_message)
	EventBus.all_enemies_defeated.connect(_on_all_enemies_defeated)

func _create_ui() -> void:
	var top_panel: Panel = Panel.new()
	top_panel.position = Vector2(10, 10)
	top_panel.size = Vector2(300, 170)
	top_panel.modulate = Color(0, 0, 0, 0.6)
	add_child(top_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.position = Vector2(16, 16)
	vbox.size = Vector2(288, 158)
	add_child(vbox)

	_level_label = Label.new()
	_level_label.text = "Level: 1"
	_level_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6, 1.0))
	vbox.add_child(_level_label)

	_hp_label = Label.new()
	_hp_label.text = "HP: 100/100"
	_hp_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
	vbox.add_child(_hp_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(0, 20)
	_hp_bar.max_value = 100.0
	_hp_bar.value = 100.0
	_hp_bar.show_percentage = false
	vbox.add_child(_hp_bar)

	_xp_label = Label.new()
	_xp_label.text = "XP: 0/50"
	vbox.add_child(_xp_label)

	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(0, 14)
	_xp_bar.max_value = 50.0
	_xp_bar.value = 0.0
	_xp_bar.show_percentage = false
	vbox.add_child(_xp_bar)

	_defeat_label = Label.new()
	_defeat_label.text = "Defeated: 0"
	vbox.add_child(_defeat_label)

	var bottom_panel: Panel = Panel.new()
	bottom_panel.position = Vector2(10, 340)
	bottom_panel.size = Vector2(400, 130)
	bottom_panel.modulate = Color(0, 0, 0, 0.6)
	add_child(bottom_panel)

	_event_log = RichTextLabel.new()
	_event_log.position = Vector2(16, 346)
	_event_log.size = Vector2(388, 118)
	_event_log.bbcode_enabled = true
	_event_log.fit_content = true
	_event_log.scroll_following = true
	add_child(_event_log)

	var overlay_style: StyleBoxFlat = StyleBoxFlat.new()
	overlay_style.bg_color = Color(0, 0, 0, 0.85)

	_game_over_panel = Panel.new()
	_game_over_panel.size = Vector2(300, 150)
	_game_over_panel.position = Vector2(240, 200)
	_game_over_panel.add_theme_stylebox_override("panel", overlay_style)
	_game_over_panel.visible = false
	add_child(_game_over_panel)

	_game_over_label = Label.new()
	_game_over_label.text = "YOU DIED"
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_label.position = Vector2(0, 20)
	_game_over_label.size = Vector2(300, 40)
	_game_over_label.add_theme_color_override("font_color", Color.RED)
	_game_over_label.add_theme_font_size_override("font_size", 28)
	_game_over_panel.add_child(_game_over_label)

	_game_over_restart_button = Button.new()
	_game_over_restart_button.text = "Restart"
	_game_over_restart_button.position = Vector2(100, 80)
	_game_over_restart_button.size = Vector2(100, 40)
	_game_over_restart_button.pressed.connect(_on_restart_pressed)
	_game_over_panel.add_child(_game_over_restart_button)

	_victory_panel = Panel.new()
	_victory_panel.size = Vector2(300, 150)
	_victory_panel.position = Vector2(240, 200)
	_victory_panel.add_theme_stylebox_override("panel", overlay_style)
	_victory_panel.visible = false
	add_child(_victory_panel)

	_victory_label = Label.new()
	_victory_label.text = "VICTORY"
	_victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_victory_label.position = Vector2(0, 20)
	_victory_label.size = Vector2(300, 40)
	_victory_label.add_theme_color_override("font_color", Color.YELLOW)
	_victory_label.add_theme_font_size_override("font_size", 28)
	_victory_panel.add_child(_victory_label)

	_victory_restart_button = Button.new()
	_victory_restart_button.text = "Play Again"
	_victory_restart_button.position = Vector2(100, 80)
	_victory_restart_button.size = Vector2(100, 40)
	_victory_restart_button.pressed.connect(_on_restart_pressed)
	_victory_panel.add_child(_victory_restart_button)

	_inventory_panel = Panel.new()
	_inventory_panel.position = Vector2(420, 10)
	_inventory_panel.size = Vector2(250, 200)
	_inventory_panel.modulate = Color(0, 0, 0, 0.7)
	_inventory_panel.visible = false
	add_child(_inventory_panel)

	_inventory_label = Label.new()
	_inventory_label.position = Vector2(430, 20)
	_inventory_label.size = Vector2(230, 180)
	_inventory_label.add_theme_color_override("font_color", Color.WHITE)
	_inventory_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_child(_inventory_label)

func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp
	_hp_label.text = "HP: " + str(current_hp) + "/" + str(max_hp)

func _on_player_xp_changed(current_xp: int, xp_to_next: int) -> void:
	_xp_bar.max_value = xp_to_next
	_xp_bar.value = current_xp
	_xp_label.text = "XP: " + str(current_xp) + "/" + str(xp_to_next)

func _on_player_leveled_up(new_level: int) -> void:
	_level_label.text = "Level: " + str(new_level)

func _on_player_died() -> void:
	_add_log_entry("[color=red]YOU DIED[/color]")
	_game_over_panel.visible = true

func _on_damage_dealt(attacker_name: String, defender_name: String, damage: int, _world_position: Vector2, is_crit: bool = false) -> void:
	var crit_str: String = " [CRIT]" if is_crit else ""
	_add_log_entry(attacker_name + " dealt " + str(damage) + " damage to " + defender_name + crit_str)
	_update_defeat_count()

func _on_enemy_defeated(enemy_name: String) -> void:
	_add_log_entry("[color=yellow]Defeated " + enemy_name + "[/color]")
	_update_defeat_count()

func _on_item_picked_up(item_name: String) -> void:
	_add_log_entry("Picked up " + item_name)
	if _inventory_open:
		_refresh_inventory()

func _on_game_message(message: String) -> void:
	_add_log_entry(message)

func _update_defeat_count() -> void:
	_defeat_label.text = "Defeated: " + str(GameState.defeat_count)

func _add_log_entry(text: String) -> void:
	_log_messages.push_front(text)
	if _log_messages.size() > log_max_lines:
		_log_messages.resize(log_max_lines)
	var formatted: String = ""
	for msg: String in _log_messages:
		formatted += msg + "\n"
	_event_log.text = formatted

func _on_all_enemies_defeated() -> void:
	_add_log_entry("[color=yellow]All enemies defeated![/color]")
	_victory_panel.visible = true

func _on_restart_pressed() -> void:
	ResourceLoader.load("res://resources/player_stats.tres", "", ResourceLoader.CACHE_MODE_REPLACE)
	ResourceLoader.load("res://resources/enemy_stats.tres", "", ResourceLoader.CACHE_MODE_REPLACE)
	GameState.reset_all()
	get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		_inventory_open = not _inventory_open
		_inventory_panel.visible = _inventory_open
		_inventory_label.visible = _inventory_open
		if _inventory_open:
			_refresh_inventory()
		return

	if _inventory_open and event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var index: int = event.keycode - KEY_1
			var player: Player = get_tree().get_first_node_in_group("player") as Player
			if player and player.use_item(index):
				_refresh_inventory()

func _refresh_inventory() -> void:
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	var items: Array[ItemData] = player.get_inventory()
	if items.is_empty():
		_inventory_label.text = "Inventory is empty"
		return
	var text: String = ""
	for i: int in range(items.size()):
		var item: ItemData = items[i]
		text += str(i + 1) + ". " + item.item_name + "\n"
		text += "    " + item.item_description + "\n"
	_inventory_label.text = text
