class_name MainMenu
extends CanvasLayer

const CLASS_SELECT_SCENE: String = "res://scenes/class_select.tscn"

func _ready() -> void:
	var panel: Panel = Panel.new()
	panel.size = Vector2(800, 600)
	panel.add_theme_stylebox_override("panel", _make_bg_style(Color(0.05, 0.05, 0.1, 1.0)))
	add_child(panel)

	var title: Label = Label.new()
	title.text = "BASIC RPG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 80)
	title.size = Vector2(800, 60)
	title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3, 1.0))
	title.add_theme_font_size_override("font_size", 36)
	add_child(title)

	_add_button("New Game", 180, _on_new_game)
	_add_button("Load Game", 240, _on_load_game)
	_add_button("Settings", 300, _on_settings)
	_add_button("Quit", 360, _on_quit)

func _make_bg_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	return style

func _add_button(text: String, y: float, callback: Callable) -> void:
	var btn: Button = Button.new()
	btn.text = text
	btn.position = Vector2(300, y)
	btn.size = Vector2(200, 40)
	btn.pressed.connect(callback)
	add_child(btn)

func _on_new_game() -> void:
	get_tree().change_scene_to_file(CLASS_SELECT_SCENE)

func _on_load_game() -> void:
	EventBus.game_message.emit("Load Game not yet implemented")

func _on_settings() -> void:
	EventBus.game_message.emit("Settings not yet implemented")

func _on_quit() -> void:
	get_tree().quit()
