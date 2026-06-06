# MVP1 Implementation Plan — Basic RPG

## Overview

| # | Task | Priority | Status |
|---|------|----------|--------|
| 1 | Fix HUD duplication | Critical | Planned |
| 2 | Enemy death cleanup | Critical | Planned |
| 3 | Wire floating damage numbers | Critical | Planned |
| 4 | Player death stops movement | Critical | Planned |
| 5 | Game over overlay + restart | Must-Have | Planned |
| 6 | Win condition (all enemies cleared) | Must-Have | Planned |
| 7 | World item pickup (E key) | Must-Have | Planned |
| 8 | Inventory panel (I key) | Must-Have | Planned |

---

## Task 1: Fix HUD Duplication

**File:** `scenes/hud.tscn`
**Root cause:** `hud.tscn` has editor-placed UI children (MarginContainer, VBoxContainer, Labels, ProgressBars, EventLog) AND `HUD.gd._create_ui()` creates a second set programmatically. Both render simultaneously. Per AGENTS.md, the programmatic approach is correct — strip the .tscn nodes.

**Change:**
- Remove all child nodes from `hud.tscn` (lines 8–63). Keep only the bare CanvasLayer with script reference.
- Result: `HUD.gd._create_ui()` becomes the sole source of UI nodes.

**New file:**
```gd
[gd_scene load_steps=2 format=3 uid="uid://huds0000001"]

[ext_resource type="Script" uid="uid://hudsc00001" path="res://scripts/HUD.gd" id="1_hud"]

[node name="HUD" type="CanvasLayer"]
script = ExtResource("1_hud")
```

**Test:** Launch game. Only one set of HP/XP bars, labels, and event log should be visible (fixed pixel positions at top-left and bottom-left).

---

## Task 2: Enemy Death Cleanup

**File:** `scripts/Enemy.gd`
**Root cause:** `_on_stats_died()` sets `physics_process` off, disables collision, and hides the enemy — but the node remains in the scene tree and in the "enemies" group, which breaks win-condition counting and leaks nodes.

**Changes:**

### 2a. Add `_is_dead` flag (line 24 area):
```gdscript
var _is_dead: bool = false
```

### 2b. Update `_on_stats_died()` (line 230):
```gdscript
func _on_stats_died() -> void:
	_is_dead = true
	set_physics_process(false)
	_collision_shape.set_deferred("disabled", true)
	visible = false
	queue_free()
```
**Note:** `queue_free()` is deferred to end of frame. References to `stats` remain valid since `CharacterStats` is a separate Resource (not freed with the node). The `_attack_player` and `_check_combat_collisions` methods will not be called again because `set_physics_process(false)` stops `_physics_process` from running.

### 2c. Guard `_check_aggro()` (line 166):
Add early return so dead enemies don't re-aggro:
```gdscript
func _check_aggro() -> void:
	if _is_dead:
		return
	if enemy_category == Category.PASSIVE:
		return
	# ... rest unchanged
```

**Test:** Kill an enemy. Enemy disappears. No console errors. `get_tree().get_nodes_in_group("enemies")` no longer includes it after the frame.

---

## Task 3: Wire Floating Damage Numbers

**Three files changed in concert.**

### 3a. EventBus.gd — add world_position to damage_dealt:
```gdscript
signal damage_dealt(attacker_name: String, defender_name: String, damage: int, world_position: Vector2)
```
**Compatibility:** Existing connections with 3 params (e.g., HUD `_on_damage_dealt(attacker_name, defender_name, damage)`) still work — GDScript discards extra signal params.

### 3b. Update all emit sites:

**Player.gd line 60** — `_attack_enemy()`:
```gdscript
EventBus.damage_dealt.emit(stats.character_name, enemy.stats.character_name, actual, enemy.global_position)
```

**Enemy.gd line 83** — `_attack_player()`:
```gdscript
EventBus.damage_dealt.emit(stats.character_name, _player.stats.character_name, actual, _player.global_position)
```

**Projectile.gd** — `_on_body_entered()` (needs reading for exact line):
```gdscript
EventBus.damage_dealt.emit(attacker_name, body.stats.character_name, actual, body.global_position)
```

### 3c. Main.gd — wire spawn_floating_damage:
```gdscript
func _on_damage_dealt(attacker_name: String, defender_name: String, damage: int, world_position: Vector2) -> void:
	EventBus.combat_event.emit(attacker_name + " hit " + defender_name + " for " + str(damage))
	spawn_floating_damage(world_position, damage)
```

**Test:** Bump into an enemy. A floating damage number appears above them. Wait for a ranged enemy to fire a projectile — floating damage appears above the player when hit.

---

## Task 4: Player Death Stops Movement

**File:** `scripts/Player.gd`
**Root cause:** After `_on_stats_died()`, the player can still move around at 0 HP.

**Changes:**

### 4a. Add `_is_dead` flag (line 9 area):
```gdscript
var _is_dead: bool = false
```

### 4b. Guard `_physics_process` (line 24):
```gdscript
func _physics_process(delta: float) -> void:
	if _is_dead:
		velocity = Vector2.ZERO
		return  # skip movement, combat, everything
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# ... rest unchanged
```

### 4c. Set flag in `_on_stats_died()` (line 84):
```gdscript
func _on_stats_died() -> void:
	_is_dead = true
	EventBus.player_died.emit()
	EventBus.game_message.emit("Player has been defeated!")
```

**Test:** Die. Player stops moving. Collision with enemies stops (since they can't bump you when you're not moving).

---

## Task 5: Game Over Overlay + Restart

**File:** `scripts/HUD.gd`

### 5a. Add member variables for overlay nodes (after existing vars, line 14 area):
```gdscript
var _game_over_panel: Panel
var _game_over_label: Label
var _game_over_restart_button: Button
var _victory_panel: Panel
var _victory_label: Label
var _victory_restart_button: Button
```

### 5b. Add overlay creation at end of `_create_ui()` (after line 84):
```gdscript
	# --- Game Over Overlay ---
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

	# --- Victory Overlay ---
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
```

### 5c. Update `_on_player_died()` (line 99):
```gdscript
func _on_player_died() -> void:
	_add_log_entry("[color=red]YOU DIED[/color]")
	_game_over_panel.visible = true
```

### 5d. Add victory handler and restart:
```gdscript
func _on_all_enemies_defeated() -> void:
	_add_log_entry("[color=yellow]All enemies defeated![/color]")
	_victory_panel.visible = true

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
```

### 5e. Add signal connection in `_ready()` (after line 26):
```gdscript
	EventBus.all_enemies_defeated.connect(_on_all_enemies_defeated)
```

**Test:** Die → "YOU DIED" overlay appears with Restart button. Kill all enemies → "VICTORY" overlay with Play Again button. Buttons reload the scene.

---

## Task 6: Win Condition (All Enemies Cleared)

**File:** `scripts/EventBus.gd` — add signal:
```gdscript
signal all_enemies_defeated()
```

**File:** `scripts/Main.gd`

### 6a. Add tracking vars:
```gdscript
var _total_enemies: int = 0
var _enemies_defeated: int = 0
```

### 6b. `_ready()` — count enemies after they've all entered the tree:
```gdscript
func _ready() -> void:
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	# Count enemies on next idle frame (after all _ready() calls complete)
	call_deferred("_count_enemies")

func _count_enemies() -> void:
	_total_enemies = get_tree().get_nodes_in_group("enemies").size()
```

### 6c. `_on_enemy_defeated()` — check win condition:
```gdscript
func _on_enemy_defeated(enemy_name: String) -> void:
	EventBus.combat_event.emit(enemy_name + " was defeated!")
	_enemies_defeated += 1
	if _enemies_defeated >= _total_enemies and _total_enemies > 0:
		EventBus.all_enemies_defeated.emit()
```

**Test:** Kill all 3 enemies. Victory overlay appears. Verify `_total_enemies` = 3 from the `call_deferred` print if debugging.

---

## Task 7: World Item Pickup (E Key)

**New file:** `scripts/ItemPickup.gd`
```gdscript
class_name ItemPickup
extends Area2D

@export var item_data: ItemData

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body._nearby_items.append(self)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body._nearby_items.erase(self)
```

**New file:** `scenes/item_pickup.tscn`
```
[gd_scene load_steps=3 format=3 uid="uid://itmp0000001"]

[ext_resource type="Script" uid="uid://itmpkup01" path="res://scripts/ItemPickup.gd" id="1_script"]
[ext_resource type="Resource" uid="uid://hlthpot01" path="res://resources/health_potion.tres" id="2_item"]

[node name="ItemPickup" type="Area2D"]
script = ExtResource("1_script")
item_data = ExtResource("2_item")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_radius12")

[node name="Polygon2D" type="Polygon2D" parent="."]
color = Color(0.2, 1.0, 0.2, 1.0)
polygon = PackedVector2Array(0, -6, 6, 0, 0, 6, -6, 0)
```

**File:** `scripts/Player.gd`

### 7a. Add nearby items list (line 9 area):
```gdscript
var _nearby_items: Array[ItemPickup] = []
```

### 7b. Add interact check to `_physics_process` (after movement, before combat, line 28 area):
```gdscript
func _physics_process(delta: float) -> void:
	if _is_dead:
		velocity = Vector2.ZERO
		return
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	move_and_slide()

	if Input.is_action_just_pressed("interact"):
		_try_pickup_item()

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	# ... rest unchanged
```

### 7c. Add `_try_pickup_item()` method:
```gdscript
func _try_pickup_item() -> void:
	if _nearby_items.is_empty():
		return
	var pickup: ItemPickup = _nearby_items.pop_front()
	add_item(pickup.item_data)
	pickup.queue_free()
```

### 7d. Add `_nearby_items` as accessible by ItemPickup:
The `ItemPickup.gd` script accesses `body._nearby_items` directly. Make sure Player.gd doesn't prefix it with underscore for public access, or provide a method. Since GDScript doesn't enforce private, underscore vars ARE accessible from other scripts. This works but is a bit loose.

Alternative — use a shared group instead of the array approach. But the current approach is simple and works for MVP1.

**File:** `scenes/main.tscn` — add the health potion to the scene after Enemy3:
```
[node name="HealthPotion" parent="." instance=ExtResource("5_item_pickup")]
position = Vector2(0, -40)
```
(Add the ext_resource for the item_pickup.tscn in the header section.)

**Test:** Walk up to the green diamond. Press E. Health potion disappears. Event log shows "Picked up Health Potion" and "Used Health Potion: restored 25 HP". HP increases by 25.

---

## Task 8: Inventory Panel (I Key)

**File:** `scripts/HUD.gd`

### 8a. Add member variables (line 14 area):
```gdscript
var _inventory_panel: Panel
var _inventory_label: Label
var _inventory_open: bool = false
```

### 8b. Add inventory panel to `_create_ui()` (after the bottom panel, before overlays):
```gdscript
	_inventory_panel = Panel.new()
	_inventory_panel.position = Vector2(420, 10)
	_inventory_panel.size = Vector2(250, 200)
	_inventory_panel.modulate = Color(0, 0, 0, 0.7)
	_inventory_panel.visible = false
	add_child(_inventory_panel)

	_inventory_label = Label.new()
	_inventory_label.position = Vector2(10, 10)
	_inventory_label.size = Vector2(230, 180)
	_inventory_label.add_theme_color_override("font_color", Color.WHITE)
	_inventory_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_inventory_panel.add_child(_inventory_label)
```

### 8c. Add input handling in `_process()` or `_input()`:
```gdscript
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		_inventory_open = not _inventory_open
		_inventory_panel.visible = _inventory_open
		if _inventory_open:
			_refresh_inventory()

func _refresh_inventory() -> void:
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	var items: Array[ItemData] = player.get_inventory()
	if items.is_empty():
		_inventory_label.text = "[i]Inventory is empty[/i]"
		return
	var text: String = ""
	for item: ItemData in items:
		text += "[b]" + item.item_name + "[/b]\n"
		text += "  " + item.item_description + "\n"
	_inventory_label.text = text
```

### 8d. Also refresh on item pickup:
```gdscript
func _on_item_picked_up(item_name: String) -> void:
	_add_log_entry("Picked up " + item_name)
	if _inventory_open:
		_refresh_inventory()
```

**Test:** Press I. Inventory panel appears on right side. Pick up health potion (E key near potion). Press I again. Panel shows "Health Potion" with its description. Press I again, panel closes.

---

## Dependency Order

Tasks must be done in this order due to cross-file signal changes:

1. **EventBus.gd** — add `world_position` param to `damage_dealt`, add `all_enemies_defeated` signal
2. **Enemy.gd** — `_is_dead` flag, guard `_check_aggro`, `queue_free` in `_on_stats_died`, update `damage_dealt` emit
3. **Player.gd** — `_is_dead` flag, guard `_physics_process`, update `damage_dealt` emit, interact/pickup logic, `_nearby_items` array
4. **Projectile.gd** — update `damage_dealt` emit with world position
5. **hud.tscn** — strip child nodes
6. **HUD.gd** — game over overlay, victory overlay, restart button, inventory panel, input handling, new signal connections
7. **Main.gd** — wire floating damage, win condition tracking, deferred enemy count
8. **ItemPickup.gd** (new) — create script
9. **item_pickup.tscn** (new) — create scene
10. **main.tscn** — add HealthPotion node, add ext_resource for item_pickup.tscn

---

## Verification Checklist

After all changes, run these checks:

```pwsh
# Syntax check all scripts
& "C:\Users\seanm\Nextcloud2\Gamedev\Godot_v4.5-stable_win64.exe" --headless --script scripts/EventBus.gd --check-only
& "C:\Users\seanm\Nextcloud2\Gamedev\Godot_v4.5-stable_win64.exe" --headless --script scripts/GameState.gd --check-only
& "C:\Users\seanm\Nextcloud2\Gamedev\Godot_v4.5-stable_win64.exe" --headless --script scripts/CharacterStats.gd --check-only
& "C:\Users\seanm\Nextcloud2\Gamedev\Godot_v4.5-stable_win64.exe" --headless --script scripts/ItemData.gd --check-only
& "C:\Users\seanm\Nextcloud2\Gamedev\Godot_v4.5-stable_win64.exe" --headless --script scripts/Player.gd --check-only
& "C:\Users\seanm\Nextcloud2\Gamedev\Godot_v4.5-stable_win64.exe" --headless --script scripts/Enemy.gd --check-only
& "C:\Users\seanm\Nextcloud2\Gamedev\Godot_v4.5-stable_win64.exe" --headless --script scripts/HUD.gd --check-only
& "C:\Users\seanm\Nextcloud2\Gamedev\Godot_v4.5-stable_win64.exe" --headless --script scripts/Main.gd --check-only
& "C:\Users\seanm\Nextcloud2\Gamedev\Godot_v4.5-stable_win64.exe" --headless --script scripts/FloatingDamage.gd --check-only
& "C:\Users\seanm\Nextcloud2\Gamedev\Godot_v4.5-stable_win64.exe" --headless --script scripts/Projectile.gd --check-only
& "C:\Users\seanm\Nextcloud2\Gamedev\Godot_v4.5-stable_win64.exe" --headless --script scripts/ItemPickup.gd --check-only

# Full project load test (validates scenes, resources, and _ready() without rendering)
& "C:\Users\seanm\Nextcloud2\Gamedev\Godot_v4.5-stable_win64.exe" --headless --quit
```

**Play test expectations:**
1. HP/XP bars and event log appear once (no duplication)
2. WASD movement works
3. Bump into melee enemy → damage number floats up → enemy takes damage → event log shows combat
4. Kill enemy → it disappears → defeat counter increments → XP gained
5. Kill all 3 enemies → "VICTORY" overlay with "Play Again" button
6. Enemy kills player → player stops moving → "YOU DIED" overlay with "Restart" button
7. Walk to health potion (green diamond) → press E → potion disappears → HP restored → log shows pickup
8. Press I → inventory panel with listed items → press I again → panel closes
9. Ranged enemies fire projectiles → projectile hits player → damage number appears
