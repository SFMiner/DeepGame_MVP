class_name ClassSelect
extends CanvasLayer

const MAIN_MENU_SCENE: String = "res://scenes/main_menu.tscn"
const GAME_SCENE: String = "res://scenes/main.tscn"
const CHAR_PATH: String = "res://assets/spritesheets_player/"
const DIR_NAMES: Array[String] = ["down", "left", "right", "up"]

var _classes: Array[CharacterClass] = []
var _class_names: Array[String] = []
var _current_index: int = 0
var _sprite: AnimatedSprite2D
var _class_label: Label
var _desc_label: Label
var _stats_label: Label

func _ready() -> void:
	_load_classes()
	_create_ui()
	_update_display()

func _load_classes() -> void:
	var paths: Array[String] = [
		"res://resources/warrior_class.tres",
		"res://resources/ranger_class.tres",
		"res://resources/mage_class.tres",
		"res://resources/rogue_class.tres",
	]
	for path: String in paths:
		var cls: CharacterClass = load(path) as CharacterClass
		if cls:
			_classes.append(cls)

func _create_ui() -> void:
	var bg: Panel = Panel.new()
	bg.size = Vector2(800, 600)
	bg.add_theme_stylebox_override("panel", _make_bg_style(Color(0.05, 0.05, 0.1, 1.0)))
	add_child(bg)

	var title: Label = Label.new()
	title.text = "Choose Your Class"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 30)
	title.size = Vector2(800, 40)
	title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3, 1.0))
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)

	_sprite = AnimatedSprite2D.new()
	_sprite.position = Vector2(300, 200)
	_sprite.scale = Vector2(2.0, 2.0)
	add_child(_sprite)

	var left_btn: Button = Button.new()
	left_btn.text = "<"
	left_btn.position = Vector2(180, 210)
	left_btn.size = Vector2(40, 40)
	left_btn.pressed.connect(_on_prev_class)
	add_child(left_btn)

	var right_btn: Button = Button.new()
	right_btn.text = ">"
	right_btn.position = Vector2(380, 210)
	right_btn.size = Vector2(40, 40)
	right_btn.pressed.connect(_on_next_class)
	add_child(right_btn)

	_class_label = Label.new()
	_class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_class_label.position = Vector2(160, 310)
	_class_label.size = Vector2(280, 30)
	_class_label.add_theme_color_override("font_color", Color.WHITE)
	_class_label.add_theme_font_size_override("font_size", 22)
	add_child(_class_label)

	_desc_label = Label.new()
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.position = Vector2(160, 340)
	_desc_label.size = Vector2(280, 50)
	_desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	_desc_label.add_theme_font_size_override("font_size", 14)
	add_child(_desc_label)

	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.position = Vector2(160, 395)
	_stats_label.size = Vector2(280, 40)
	_stats_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5, 1.0))
	_stats_label.add_theme_font_size_override("font_size", 14)
	add_child(_stats_label)

	var confirm_btn: Button = Button.new()
	confirm_btn.text = "Confirm"
	confirm_btn.position = Vector2(300, 460)
	confirm_btn.size = Vector2(200, 40)
	confirm_btn.pressed.connect(_on_confirm)
	add_child(confirm_btn)

	var back_btn: Button = Button.new()
	back_btn.text = "Back"
	back_btn.position = Vector2(300, 510)
	back_btn.size = Vector2(200, 40)
	back_btn.pressed.connect(_on_back)
	add_child(back_btn)

func _make_bg_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	return style

func _setup_preview_sprite(sprite_set: String) -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	var idle_path: String = CHAR_PATH + sprite_set + "_idle.png"
	_load_spritesheet(frames, "idle", idle_path, 4)
	_sprite.sprite_frames = frames
	_sprite.play("idle_down")

func _load_spritesheet(frames: SpriteFrames, anim_base: String, path: String, frame_count: int) -> void:
	var sheet: Texture2D = load(path) as Texture2D
	if not sheet:
		return
	var fw: int = int(sheet.get_width() / frame_count)
	var fh: int = int(sheet.get_height() / 4)
	for row: int in range(4):
		var anim_name: String = anim_base + "_" + DIR_NAMES[row]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, 8.0)
		for col: int in range(frame_count):
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(col * fw, row * fh, fw, fh)
			frames.add_frame(anim_name, atlas)

func _update_display() -> void:
	if _classes.is_empty():
		return
	var cls: CharacterClass = _classes[_current_index]
	_setup_preview_sprite(cls.sprite_set)
	_class_label.text = cls.class_name
	_desc_label.text = cls.description
	_stats_label.text = "HP/lvl: " + str(cls.hp_per_level) + "  ATK/lvl: " + str(cls.attack_per_level) + "  DEF/lvl: " + str(cls.defense_per_level) + "  Mana/lvl: " + str(cls.mana_per_level)

func _on_prev_class() -> void:
	if _classes.is_empty():
		return
	_current_index = (_current_index - 1 + _classes.size()) % _classes.size()
	_update_display()

func _on_next_class() -> void:
	if _classes.is_empty():
		return
	_current_index = (_current_index + 1) % _classes.size()
	_update_display()

func _on_confirm() -> void:
	if _classes.is_empty():
		return
	var cls: CharacterClass = _classes[_current_index]
	var pd: PlayerData = PlayerData.new()
	pd.player_name = cls.class_name
	pd.character_class_name = cls.class_name
	pd.base_max_hp = 100
	pd.base_attack = 10
	pd.base_defense = 5
	pd.base_mana = 50
	pd.sprite_set = cls.sprite_set
	GameState.selected_class = cls
	GameState.player_data = pd
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_back() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
