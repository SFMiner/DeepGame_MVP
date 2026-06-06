class_name SkeletonEnemy
extends Enemy

const SKELETON_PATH: String = "res://assets/tilesets_items/"
const DIR_NAMES: Array[String] = ["down", "left", "right", "up"]

@export var skeleton_variant: int = 1

func _setup_animations() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	var prefix: String = "Skeleton 0" + str(skeleton_variant)
	_load_directional(frames, "idle", SKELETON_PATH + prefix + "_idle.png", 4)
	_load_directional(frames, "jump", SKELETON_PATH + prefix + "_walk.png", 4)
	_load_directional(frames, "dash", SKELETON_PATH + prefix + "_walk.png", 4)
	_load_directional(frames, "death", SKELETON_PATH + prefix + "_die.png", 1)
	_sprite.sprite_frames = frames
	_sprite.scale = Vector2(3.0, 3.0)
	_sprite.play("idle")

func _load_directional(frames: SpriteFrames, anim_name: String, path: String, frame_count: int) -> void:
	var sheet: Texture2D = load(path) as Texture2D
	if not sheet:
		return
	var fw: int = int(sheet.get_width() / frame_count)
	var fh: int = int(sheet.get_height() / 4)
	for row: int in range(4):
		var dir_anim: String = anim_name
		if row == 0:
			dir_anim = "idle"
		elif anim_name == "jump":
			dir_anim = "jump"
		elif anim_name == "dash":
			dir_anim = "dash"
		elif anim_name == "death":
			dir_anim = "death"
		if not frames.has_animation(dir_anim):
			frames.add_animation(dir_anim)
			frames.set_animation_speed(dir_anim, 6.0)
		for col: int in range(frame_count):
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(col * fw, row * fh, fw, fh)
			frames.add_frame(dir_anim, atlas)
