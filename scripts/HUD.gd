class_name HUD
extends CanvasLayer

var _hp_bar: ProgressBar
var _hp_label: Label
var _mana_bar: ProgressBar
var _mana_label: Label
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
var _equip_panel: Panel
var _inventory_grid: GridContainer
var _equip_slot_buttons: Dictionary = {}
var _tooltip_label: Label
var _inventory_buttons: Array[Button] = []
var _spell_bar_panel: Panel
var _spell_labels: Array[Label] = []

func _ready() -> void:
	_create_ui()

	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.player_xp_changed.connect(_on_player_xp_changed)
	EventBus.player_leveled_up.connect(_on_player_leveled_up)
	EventBus.player_mana_changed.connect(_on_player_mana_changed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.game_message.connect(_on_game_message)
	EventBus.all_enemies_defeated.connect(_on_all_enemies_defeated)

func _create_ui() -> void:
	var top_panel: Panel = Panel.new()
	top_panel.position = Vector2(10, 10)
	top_panel.size = Vector2(300, 210)
	top_panel.modulate = Color(0, 0, 0, 0.6)
	add_child(top_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.position = Vector2(16, 16)
	vbox.size = Vector2(288, 198)
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

	_mana_label = Label.new()
	_mana_label.text = "Mana: 50/50"
	_mana_label.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0, 1.0))
	vbox.add_child(_mana_label)

	_mana_bar = ProgressBar.new()
	_mana_bar.custom_minimum_size = Vector2(0, 16)
	_mana_bar.max_value = 50.0
	_mana_bar.value = 50.0
	_mana_bar.show_percentage = false
	vbox.add_child(_mana_bar)

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
	_inventory_panel.position = Vector2(320, 10)
	_inventory_panel.size = Vector2(450, 320)
	_inventory_panel.modulate = Color(0, 0, 0, 0.7)
	_inventory_panel.visible = false
	add_child(_inventory_panel)

	_create_equip_panel()
	_create_inventory_grid()
	_create_spell_bar()
	_create_tooltip()

func _create_equip_panel() -> void:
	_equip_panel = Panel.new()
	_equip_panel.position = Vector2(330, 20)
	_equip_panel.size = Vector2(160, 280)
	_equip_panel.modulate = Color(0.1, 0.1, 0.1, 0.8)
	add_child(_equip_panel)

	var title: Label = Label.new()
	title.text = "Equipment"
	title.position = Vector2(340, 22)
	title.add_theme_color_override("font_color", Color.YELLOW)
	title.add_theme_font_size_override("font_size", 14)
	add_child(title)

	var slots: Array[Dictionary] = [
		{"slot": "weapon", "label": "Weapon", "y": 50, "types": "WEAPON/BOW/STAFF"},
		{"slot": "armor", "label": "Armor", "y": 140, "types": "ARMOR/SHIELD"},
		{"slot": "accessory", "label": "Accessory", "y": 230, "types": "ACCESSORY"},
	]
	for slot_info: Dictionary in slots:
		var slot_label: Label = Label.new()
		slot_label.text = slot_info["label"]
		slot_label.position = Vector2(340, slot_info["y"])
		slot_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		slot_label.add_theme_font_size_override("font_size", 12)
		add_child(slot_label)

		var btn: Button = Button.new()
		btn.text = "(empty)"
		btn.position = Vector2(340, slot_info["y"] + 18)
		btn.size = Vector2(140, 50)
		btn.pressed.connect(_on_equip_slot_clicked.bind(slot_info["slot"]))
		btn.mouse_entered.connect(_on_equip_slot_hover.bind(slot_info["slot"]))
		btn.mouse_exited.connect(_on_tooltip_hide)
		add_child(btn)
		_equip_slot_buttons[slot_info["slot"]] = btn

func _create_inventory_grid() -> void:
	_inventory_grid = GridContainer.new()
	_inventory_grid.position = Vector2(500, 20)
	_inventory_grid.size = Vector2(260, 260)
	_inventory_grid.columns = 4
	add_child(_inventory_grid)

func _create_spell_bar() -> void:
	_spell_bar_panel = Panel.new()
	_spell_bar_panel.position = Vector2(330, 310)
	_spell_bar_panel.size = Vector2(430, 16)
	_spell_bar_panel.modulate = Color(0.05, 0.05, 0.15, 0.8)
	add_child(_spell_bar_panel)

	for i: int in range(3):
		var label: Label = Label.new()
		label.text = "Spell " + str(i + 1) + ": -"
		label.position = Vector2(335 + i * 140, 311)
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.8, 1.0))
		label.add_theme_font_size_override("font_size", 11)
		add_child(label)
		_spell_labels.append(label)

func _create_tooltip() -> void:
	_tooltip_label = Label.new()
	_tooltip_label.position = Vector2(330, 270)
	_tooltip_label.size = Vector2(430, 36)
	_tooltip_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.7, 1.0))
	_tooltip_label.add_theme_font_size_override("font_size", 11)
	_tooltip_label.visible = false
	add_child(_tooltip_label)

func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp
	_hp_label.text = "HP: " + str(current_hp) + "/" + str(max_hp)

func _on_player_mana_changed(current_mana: int, max_mana: int) -> void:
	_mana_bar.max_value = max_mana
	_mana_bar.value = current_mana
	_mana_label.text = "Mana: " + str(current_mana) + "/" + str(max_mana)

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
		_refresh_equip_slots()

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
		_equip_panel.visible = _inventory_open
		_tooltip_label.visible = false
		for label: Label in _spell_labels:
			label.visible = _inventory_open
		_spell_bar_panel.visible = _inventory_open
		for btn: Button in _inventory_buttons:
			btn.visible = _inventory_open
		if _inventory_open:
			_refresh_inventory()
			_refresh_equip_slots()
		return

	if _inventory_open and event is InputEventKey and event.pressed and event.keycode == KEY_X:
		_try_drop_selected()

func _refresh_inventory() -> void:
	for btn: Button in _inventory_buttons:
		btn.queue_free()
	_inventory_buttons.clear()
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	var items: Array[ItemData] = player.get_inventory()
	for i: int in range(items.size()):
		var item: ItemData = items[i]
		var btn: Button = Button.new()
		btn.text = item.item_name
		btn.size = Vector2(62, 62)
		btn.mouse_entered.connect(_on_item_hover.bind(item))
		btn.mouse_exited.connect(_on_tooltip_hide)
		btn.pressed.connect(_on_item_clicked.bind(i))
		_inventory_grid.add_child(btn)
		_inventory_buttons.append(btn)

func _refresh_equip_slots() -> void:
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	var eq: Dictionary = player.get_equipment()
	for slot: String in _equip_slot_buttons:
		var btn: Button = _equip_slot_buttons[slot]
		var item: ItemData = eq.get(slot)
		if item:
			btn.text = item.item_name
		else:
			btn.text = "(empty)"

func _on_item_clicked(index: int) -> void:
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if player:
		player.use_item(index)
		_refresh_inventory()
		_refresh_equip_slots()

func _on_equip_slot_clicked(slot: String) -> void:
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if player:
		player.unequip_item(slot)
		_refresh_inventory()
		_refresh_equip_slots()

func _on_item_hover(item: ItemData) -> void:
	if _tooltip_label:
		_tooltip_label.text = item.item_name + ": " + item.item_description
		_tooltip_label.visible = true

func _on_equip_slot_hover(slot: String) -> void:
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	var eq: Dictionary = player.get_equipment()
	var item: ItemData = eq.get(slot)
	if item:
		_tooltip_label.text = "[Equipped] " + item.item_name + ": " + item.item_description
	else:
		_tooltip_label.text = slot.capitalize() + " slot (empty)"
	_tooltip_label.visible = true

func _on_tooltip_hide() -> void:
	if _tooltip_label:
		_tooltip_label.visible = false

func _try_drop_selected() -> void:
	pass
