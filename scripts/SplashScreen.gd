class_name SplashScreen
extends CanvasLayer

const MAIN_MENU_SCENE: String = "res://scenes/main_menu.tscn"

func _ready() -> void:
	var panel: Panel = Panel.new()
	panel.size = Vector2(800, 600)
	panel.add_theme_stylebox_override("panel", _make_bg_style(Color(0.05, 0.05, 0.1, 1.0)))
	add_child(panel)

	var title: Label = Label.new()
	title.text = "BASIC RPG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 180)
	title.size = Vector2(800, 60)
	title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3, 1.0))
	title.add_theme_font_size_override("font_size", 42)
	add_child(title)

	var prompt: Label = Label.new()
	prompt.text = "Press any key..."
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.position = Vector2(0, 350)
	prompt.size = Vector2(800, 30)
	prompt.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
	prompt.add_theme_font_size_override("font_size", 16)
	add_child(prompt)

	_blink_label(prompt)

func _make_bg_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	return style

func _blink_label(label: Label) -> void:
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_property(label, "modulate:a", 0.1, 0.6)
	tween.tween_property(label, "modulate:a", 1.0, 0.6)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	if event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
