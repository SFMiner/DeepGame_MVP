extends Node

const BATTLE_MUSIC: String = "res://assets/sounds/music/rpg_battle_music_1.ogg"
const EXPLORE_MUSIC: String = "res://assets/sounds/music/rpg_funky_theme_1.ogg"
const SFX_HURT_MALE: String = "res://assets/sounds/sfx/hurt_male_grunt.ogg"
const SFX_HURT_FEMALE: String = "res://assets/sounds/sfx/hurt_fmale_grunt.ogg"
const SFX_SWORD: String = "res://assets/sounds/sfx/sword_strike_flesh.ogg"
const SFX_COIN: String = "res://assets/sounds/sfx/get_coin.ogg"
const SFX_SLIME: String = "res://assets/sounds/sfx/slime.ogg"

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _current_music: String = ""
var _is_crossfading: bool = false
var _crossfade_tween: Tween

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "SFX"
	add_child(_sfx_player)
	EventBus.enemy_aggro_changed.connect(_on_enemy_aggro_changed)
	EventBus.all_enemies_defeated.connect(_on_all_enemies_defeated)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.gold_collected.connect(_on_gold_collected)
	EventBus.player_died.connect(_on_player_died)
	play_music(EXPLORE_MUSIC)

func play_music(path: String) -> void:
	if _current_music == path and _music_player.playing:
		return
	_current_music = path
	var stream: AudioStream = load(path) as AudioStream
	if not stream:
		return
	_music_player.stream = stream
	_music_player.play()

func play_sfx(path: String) -> void:
	var stream: AudioStream = load(path) as AudioStream
	if not stream:
		return
	_sfx_player.stream = stream
	_sfx_player.play()

func crossfade_to(path: String, duration: float = 1.0) -> void:
	if _current_music == path:
		return
	if _is_crossfading:
		return
	_is_crossfading = true
	var new_player: AudioStreamPlayer = AudioStreamPlayer.new()
	new_player.bus = "Music"
	new_player.stream = load(path) as AudioStream
	if not new_player.stream:
		new_player.queue_free()
		_is_crossfading = false
		return
	new_player.volume_db = -40.0
	add_child(new_player)
	new_player.play()
	var old_player: AudioStreamPlayer = _music_player
	_current_music = path
	_music_player = new_player
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(old_player, "volume_db", -40.0, duration)
	tween.tween_property(new_player, "volume_db", 0.0, duration)
	tween.tween_callback(_on_crossfade_done.bind(old_player))

func _on_crossfade_done(old_player: AudioStreamPlayer) -> void:
	_is_crossfading = false
	old_player.stop()
	old_player.queue_free()

func _on_enemy_aggro_changed(in_combat: bool) -> void:
	if in_combat:
		crossfade_to(BATTLE_MUSIC)
	else:
		crossfade_to(EXPLORE_MUSIC)

func _on_all_enemies_defeated() -> void:
	crossfade_to(EXPLORE_MUSIC)

func _on_damage_dealt(_attacker_name: String, defender_name: String, _damage: int, _world_position: Vector2, _is_crit: bool) -> void:
	play_sfx(SFX_SWORD)
	var player_node: Player = get_tree().get_first_node_in_group("player") as Player
	if player_node and defender_name == player_node.stats.character_name:
		var sprite_set: String = ""
		if player_node.has_method("get_sprite_set"):
			sprite_set = player_node.get_sprite_set()
		if sprite_set.begins_with("Sorcerer") or sprite_set.begins_with("Swashbuckler") or sprite_set.begins_with("Fox"):
			play_sfx(SFX_HURT_FEMALE)
		else:
			play_sfx(SFX_HURT_MALE)

func _on_item_picked_up(_item_name: String) -> void:
	play_sfx(SFX_COIN)

func _on_gold_collected(_amount: int) -> void:
	play_sfx(SFX_COIN)

func _on_player_died() -> void:
	_music_player.stop()
