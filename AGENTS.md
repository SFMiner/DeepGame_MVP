# AGENTS.md - Basic RPG Project

## Project Overview
A foundational 2D Computer RPG (CRPG) prototype built in Godot 4.5 with GDScript 2.0. Features modular architecture with signal-driven event bus, custom Resource data classes, deliberate combat with windup/strike/recovery, ranged projectile enemies, magic spells, inventory/equipment system with grid UI, floating damage numbers, game-over/victory flow, and minimalist UI. Currently at **MVP2-Lite complete** (Phases A-H implemented).

**MVP2-Lite goals**: Deliberate melee/ranged/magic combat, equipment slots, class system, splash/menu flow, tilemap-based dungeon room, audio (music+SFX), permadeath toggle. See `mvp2_implementation_plan.md` for the full phased plan.

## Tech Stack
- Godot 4.5 (GL Compatibility renderer)
- GDScript 2.0 (strongly-typed)
- No external assets (procedural placeholders for sprites)

## Architecture
- **EventBus** (autoload): Global signal hub — 16 signals for decoupled communication
- **GameState** (autoload): Persistent dictionary for story/quest flags, defeat counter, permadeath toggle
- **MusicManager** (autoload): Plays and crossfades between exploration/combat music; plays SFX on events
- **CharacterStats**: Custom Resource for HP, Mana, Level, XP, Attack, Defense, Crit
- **ItemData**: Custom Resource for inventory items (CONSUMABLE, WEAPON, ARMOR, QUEST, BOW, STAFF, SHIELD, ACCESSORY enum)
- **PlayerData**: Custom Resource — canonical serializable container for all player state (name, class, level, base stats, equipment slots, inventory, gold, spells, dungeon depth, flags)
- **ProjectileData**: Custom Resource — unified projectile params (damage, speed, range, color, sprite, pierce, element)
- **StatusEffect**: Custom Resource — POISON/SLOW/STUN with duration, tick damage, speed multiplier
- **SpellData**: Custom Resource — spell name, mana cost, cooldown, ProjectileData ref, StatusEffect on-hit
- **CharacterClass**: Custom Resource — class name, stat-per-level, available_spells, sprite_set
- **Player.gd**: CharacterBody2D with CharacterStats, inventory array, item usage, is_dead guard
- **Enemy.gd**: CharacterBody2D with CharacterStats, 5-state FSM (IDLE, WANDERING, CHASING, FLEEING, KITING), melee/ranged/passive categories, is_dead guard + queue_free on death
- **HUD**: CanvasLayer — programmatic UI (HP/XP bars, event log, defeat counter, game-over/victory overlays, inventory panel)
- **Main.gd**: Scene controller — wires floating damage to damage_dealt, tracks win condition (all enemies defeated), deferred enemy counting
- **ItemPickup.gd**: Area2D pickup — tracks nearby player via body_entered/body_exited, exposes item_data
- **FloatingDamage.gd**: Label — floats upward, fades out, color-coded by damage amount (gold for crits)
- **Projectile.gd**: Area2D — fired by RANGED enemies, collides with Player, carries damage+attacker_name

## EventBus Signals (16 total)
| Signal | Params | Emitted By |
|--------|--------|------------|
| `player_hp_changed` | current_hp: int, max_hp: int | Player |
| `player_xp_changed` | current_xp: int, xp_to_next: int | Player |
| `player_leveled_up` | new_level: int | Player |
| `player_died` | — | Player |
| `player_mana_changed` | current_mana: int, max_mana: int | Player |
| `combat_event` | message: String | Main |
| `damage_dealt` | attacker_name, defender_name, damage: int, world_position: Vector2, is_crit: bool | Player, Enemy, Projectile |
| `item_picked_up` | item_name: String | Player |
| `game_message` | message: String | Player, Enemy |
| `enemy_defeated` | enemy_name: String | Player |
| `all_enemies_defeated` | — | Main |
| `status_applied` | target_name: String, effect_type: int | Player, Enemy |
| `gold_collected` | amount: int | Player, Enemy |
| `enemy_aggro_changed` | in_combat: bool | Enemy |

## Inventory & Item System
- **ItemData Resource**: 8 item types (CONSUMABLE=0, WEAPON=1, ARMOR=2, QUEST=3, BOW=4, STAFF=5, SHIELD=6, ACCESSORY=7). Fields: item_name, item_description, health_restore, attack_bonus, defense_bonus, value, equip_slot, block_chance, mana_bonus, max_hp_bonus.
- **Pickup**: Walk near green diamond → press E → `ItemPickup.body_entered` tracks nearby items in Player._nearby_items → `_try_pickup_item()` pops and calls add_item().
- **No auto-use on pickup**: Items go straight to inventory. Heal potions must be manually used.
- **Usage**: Press I for inventory panel → numbered list → press 1-9 to use item at that index.
  - CONSUMABLE: heals `health_restore` HP, removed from inventory.
  - WEAPON: adds `attack_bonus` to `stats.attack`, stays in inventory.
  - ARMOR: adds `defense_bonus` to `stats.defense`, stays in inventory.
  - QUEST: message only, stays in inventory.
- **World items** (main.tscn): Health Potion (0,-40), Iron Sword (60,-40), Leather Armor (-60,-40), Strange Key (120,-40).

## Combat Mechanics
- **MVP2-Lite deliberate combat**: Player uses Z for melee (windup 0.2s → strike 0.15s with damage arc + block incoming → recovery 0.3s), X for ranged, 1/2/3 for spells.
- **Melee cancel**: If hit during windup phase, attack cancels and player takes damage normally. Strike frame blocks all incoming damage.
- **Ranged enemies**: KITE state → maintain preferred distance → fire Projectile using ProjectileData.
- **Damage formula**: `maxi(1, attacker.attack - defender.defense)`. Minimum 1 damage. Crits multiply raw damage before defense.
- **Floating damage**: `Main.spawn_floating_damage()` wired to `damage_dealt` signal, spawns above hit target. Gold/yellow for crits.
- **Death**: `_is_dead` flag halts movement/combat. Enemy `queue_free()` after delay. Player shows "YOU DIED" overlay (permadeath: returns to main menu).
- **Victory**: `Main._on_enemy_defeated()` counts kills, emits `all_enemies_defeated` when all cleared, triggers VICTORY overlay.
- **Restart**: Both overlays have buttons calling `get_tree().reload_current_scene()`.

## Input Map (MVP2-Lite additions)
| Action | Key | Purpose |
|--------|-----|---------|
| `move_left/right/up/down` | WASD / Arrow Keys | Player movement |
| `interact` | E | Pick up items, interact with objects |
| `inventory` | I | Toggle inventory panel |
| `attack_melee` | Z | Deliberate melee attack (pending Phase E) |
| `attack_ranged` | X | Ranged attack, requires bow (pending Phase E) |
| `spell_1` | 1 | Cast equipped spell slot 1 (pending Phase G) |
| `spell_2` | 2 | Cast equipped spell slot 2 (pending Phase G) |
| `spell_3` | 3 | Cast equipped spell slot 3 (pending Phase G) |
| `pause` | Esc | Pause menu / Settings (pending Phase H) |

## Audio
- **MusicManager autoload**: Plays and crossfades between exploration (`rpg_funky_theme_1.ogg`) and combat (`rpg_battle_music_1.ogg`) music.
- **SFX**: Wired to EventBus events — sword strike on `damage_dealt`, coin on `item_picked_up`/`gold_collected`, hurt grunts (male/female by player sprite set) on player damage.
- **Source files**: `.mp3` files in `assets/sounds/` converted to `.ogg` via ffmpeg (`libvorbis -q:a 4`).
- Godot 4.5 uses audio buses "Master", "Music", "SFX" (default).

## Enemy State Machine
- **IDLE**: No movement. Checks aggro, transitions to WANDERING after interval.
- **WANDERING**: Random direction within `wander_range`. Checks aggro.
- **CHASING** (MELEE): Moves toward player at `chase_speed`. Bump-combat via `_check_combat_collisions`.
- **FLEEING**: Runs from player when HP <= `flee_hp_fraction`. Stops at `flee_distance * 2.0`.
- **KITING** (RANGED): Maintains `preferred_distance`. Fires projectiles at `fire_cooldown`.
- **Disengage**: Uses hysteresis — `dist_to_player > aggro_range * 2.0` to disengage.
- **State colors** via `_sprite.modulate`: IDLE=gray, WANDERING=light gray, CHASING=red, FLEEING=blue, KITING=orange.

## Coding Standards
- Tabs for indentation (never spaces)
- Type hints on all variables and functions
- PascalCase for class_name
- snake_case for variables, functions, signals
- Private members prefixed with `_`
- Constants in UPPER_SNAKE_CASE

## Commands
- Lint single script: `& "<godot_path>" --headless --script scripts/Name.gd --check-only`
- Run headless: `& "<godot_path>" --headless --quit` (validates scene loading + _ready() without rendering)

## Known Pitfalls & Solutions

### @onready Paths Fail on Instanced/Hand-Authored Scenes
**Problem:** `@onready var x = $Path/To/Node` and `%UniqueName` accessors silently return `null` when the parent scene is a PackedScene instanced into another scene, or when the .tscn was hand-authored rather than editor-saved. Nodes exist in the file but the path resolver can't see them at init time.
**Solution:** For UI nodes (CanvasLayer, HUD), create all child nodes programmatically in `_ready()` via `new()` + `add_child()`. This completely avoids scene-file path resolution issues.

### Shared Resource References Across Instances
**Problem:** Multiple enemies instanced from the same .tscn share a single `CharacterStats` Resource reference. Damage to one enemy affects all.
**Solution:** Call `stats = stats.duplicate() as CharacterStats` in the enemy's `_ready()` to give each instance its own copy.

### Bump-Combat Without Cooldown
**Problem:** `move_and_slide()` collisions fire every physics frame, causing instant-kill chains.
**Solution:** Use an `_attack_cooldown` timer (e.g. 0.5s) with `maxf(0.0, _attack_cooldown - delta)` and only attack when cooldown <= 0.

### Stray Characters Break Global Class Parsing
**Problem:** A single stray character in a `class_name` script (e.g., `d\t` before a line) causes Godot to fail parsing the entire global class cache, producing "Could not parse global class" errors that cascade to other scripts.
**Solution:** After any edit, run `--check-only` on the affected script immediately. The error message points to the exact file.

### Origin-Based Leash Causes Chase Flicker
**Problem:** When an enemy chase AI disengages based on `distance_to(origin)` (how far it has traveled from spawn), it creates a tight engage/disengage loop. The enemy chases the player, moves away from its spawn, hits the leash limit, goes IDLE, then immediately re-aggros because the player is still within aggro_range — resulting in rapid state flickering.
**Solution:** Disengage based on player distance (`dist_to_player > aggro_range * 2.0`) instead of origin distance. This uses hysteresis: engage at `aggro_range * 1.0`, disengage at `aggro_range * 2.0`, both relative to the player's current position.

### Panel.modulate Darkens All Child Nodes
**Problem:** Setting `Panel.modulate = Color(0, 0, 0, 0.7)` to create a semi-transparent background also darkens all child Controls (labels, buttons). Text becomes black-on-black and invisible. This is because `modulate` is inherited by children in the scene tree (multiplied).
**Solution:** Make UI labels/controls **siblings** of the background Panel, not children. Both are added as direct children of the same parent, positioned to overlap visually. The Panel serves as a backdrop only. This pattern is used for the HP/XP bars (vbox is sibling of top_panel) and the inventory panel (Label is sibling of _inventory_panel).

### Signal Signature Mismatch Causes Runtime Errors
**Problem:** Adding a parameter to an EventBus signal without updating ALL connected callbacks produces "Method expected N argument(s), but called with N+1" at runtime — non-fatal but spams console.
**Solution:** After changing any EventBus signal signature, grep for all `.connect(` and `.emit(` calls referencing that signal name, and update every method signature to match.

### RichTextLabel Under GL Compatibility Renderer
**Problem:** `RichTextLabel` with `bbcode_enabled = true` may fail to render text under the GL Compatibility renderer in Godot 4.5. Plain `Label` works reliably.
**Solution:** Prefer `Label` for simple inventory text. Use `RichTextLabel` only when BBCode coloring is essential (e.g., event log with colored entries). For inventory, use plain `Label` with newlines for formatting.

### Cached Resources Persist Across Scene Reloads
**Problem:** `get_tree().reload_current_scene()` reloads the scene but not the ResourceLoader's in-memory cache. If `CharacterStats` or other custom Resources are modified at runtime (level-up stat increases, equip bonuses), the cached Resource retains those modifications across restarts. This causes "ghost" stat carryover: damage/defense values from previous rounds, stale HP/XP, and `GameState.defeat_count` accumulation (autoloads also persist).
**Solution:** Three-part fix:
1. On restart, call `ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)` for each cached `.tres` file. This forces a fresh disk read, replacing the stale cache entry.
2. In `Player._ready()`, clone stats via `stats = stats.duplicate() as CharacterStats` (same pattern as enemy). Each game session operates on an independent copy, so runtime modifications never write back to the cached source.
3. Reset autoload state via `GameState.reset_all()`.

### Godot CLI Path
The Godot 4.5 executable is at `C:\Users\seanm\Nextcloud2\Gamedev\Godot_v4.5-stable_win64.exe`. Use `& "<path>" --headless` for all CLI operations.

## GDScript & Godot 4.5 Discoveries

### `maxi()` / `mini()` / `clampi()` — Built-in Integer Clamp Functions
**Discovery:** Godot 4.5 provides `maxi(a, b)`, `mini(a, b)`, and `clampi(value, min, max)` for integer clamping. These are integer-specific variants of `maxf()`/`minf()`/`clampf()` (float) and `max()`/`min()`/`clamp()` (type-flexible). Use the `i` variants when working with `int` values for clarity and performance. Used in `CharacterStats.take_damage()` (`maxi(1, amount - defense)`), `CharacterStats.heal()` (`mini(hp + amount, max_hp)`), and the `hp` setter (`clampi(value, 0, max_hp)`).

### Combat Damage Floors at 1, Not 0
**Discovery:** The damage formula `maxi(1, amount - defense)` creates a hard floor of 1. This means armor can never reduce damage to 0 — a character with 8 DEF still takes 1 damage from a 6-ATK enemy. If zero-damage soaking is desired, change to `maxi(0, ...)`. Keep in mind that 0-damage bumps still trigger attack cooldowns and engage combat signals.

### `queue_free()` Is Deferred
**Discovery:** `queue_free()` does not immediately remove a node. It marks the node for deletion at the end of the current frame. This means references to the node's properties (like `stats` which is a separate Resource) remain valid in the same call stack. Safe to call during signal handler chains like `take_damage() → hp setter → died.emit() → _on_stats_died() → queue_free()` — the caller can still access `enemy.stats.is_alive()` afterward.

### Signal Parameter Addition Is Backward-Compatible
**Discovery:** Adding a parameter to an EventBus signal (e.g., adding `world_position: Vector2` to `damage_dealt`) does NOT break existing connections that accept fewer parameters. Godot discards extra signal arguments — a callback expecting 3 params still works when the signal now emits 4. However, the reverse is a runtime error: a callback expecting MORE params than the signal emits will fail. Always update ALL emit sites to match the new signature.

### `.uid` Files Only for `.gd` Scripts
**Discovery:** Godot 4 stores UIDs differently by file type. `.gd` scripts get a companion `.uid` file (e.g., `Main.gd.uid`) containing just the UID string. `.tscn` scene files embed their UID directly in the `[gd_scene]` header. `.tres` resource files embed their UID inline in the `[gd_resource]` header. When creating new files, match the existing pattern for that file type.

### `call_deferred()` for Post-Init Counting
**Discovery:** When counting nodes in a group during `_ready()`, some nodes may not have completed their own `_ready()` yet. Use `call_deferred("_method_name")` to defer the check to the next idle frame, ensuring all nodes have entered the tree and set up their groups. Used in `Main._ready()` to count enemies: `call_deferred("_count_enemies")` → then `get_tree().get_nodes_in_group("enemies").size()`.

### `AnimatedSprite2D` Has `modulate`, Not `color`
**Discovery:** `Polygon2D.color` sets the fill color directly. `AnimatedSprite2D` (and all CanvasItem-derived sprite nodes) use the inherited `modulate` property instead. When converting from primitive shapes to sprites, replace all `.color =` assignments with `.modulate =`. Note that `modulate` multiplies the texture's existing colors — a white placeholder texture + `modulate = Color.RED` produces a red sprite. A red texture + `modulate = Color.BLUE` produces near-black.

### Proximity-Based Pickup with `body_entered`/`body_exited`
**Discovery:** Area2D `body_entered` and `body_exited` signals provide a clean pattern for proximity-based interactions without polling. The pickup appends itself to a `_nearby_items` array on the player, and the player pops the first item on E press. Using `Array.pop_front()` ensures FIFO pickup order if multiple items overlap. The Array accessed across scripts (underscore-prefixed `_nearby_items` is still accessible from ItemPickup since GDScript doesn't enforce true privacy).

### `CanvasLayer._input()` Works for Keyboard Events
**Discovery:** `_input(event)` on a CanvasLayer (or any Node in the scene tree) receives keyboard events regardless of the CanvasLayer's position in the tree. No special setup is needed — `event.is_action_pressed("inventory")` works directly. This is the standard way to handle global hotkeys in UI layers. The event propagates to all nodes by default; use `event.is_action_pressed()` (not `Input.is_action_just_pressed()`) inside `_input()`.

## Directory Structure
```
res://
  scripts/           - GDScript files (.gd)
	EventBus.gd          - Autoload: 16 global signals
	GameState.gd         - Autoload: persistent flags + defeat counter
	MusicManager.gd      - Autoload: music crossfade + SFX playback
	CharacterStats.gd    - Resource: HP, mana, XP, level-up, combat formulas, crit
	ItemData.gd          - Resource: 8 item types, stat bonuses, equip slot
	PlayerData.gd        - Resource: canonical player state container
	ProjectileData.gd    - Resource: unified projectile params
	StatusEffect.gd      - Resource: poison/slow/stun effects
	SpellData.gd         - Resource: spell name, mana cost, projectile + status
	CharacterClass.gd    - Resource: class stats, spells, sprite set
	Player.gd            - CharacterBody2D: movement, combat, inventory, is_dead
	Enemy.gd             - CharacterBody2D: 5-state FSM, projectile firing, is_dead
	Main.gd              - Node2D: floating damage spawning, win condition
	HUD.gd               - CanvasLayer: programmatic UI, overlays, inventory panel
	FloatingDamage.gd    - Label: animated damage numbers (gold for crits)
	Projectile.gd        - Area2D: ranged enemy projectile
	ItemPickup.gd        - Area2D: world item pickup detection
  scenes/            - Scene files (.tscn)
	main.tscn            - Entry point: player, 3 enemies, 4 item pickups, HUD
	player.tscn          - AnimatedSprite2D + Camera2D + CollisionShape2D
	enemy.tscn           - AnimatedSprite2D + CollisionShape2D
	hud.tscn             - Bare CanvasLayer (UI created programmatically)
	floating_damage.tscn - Label scene for damage numbers
	item_pickup.tscn     - Area2D with green diamond + CollisionShape2D
  resources/         - Custom Resource definitions (.tres)
	player_stats.tres    - CharacterStats: Hero (HP=100, mana=50, ATK=12, DEF=5)
	enemy_stats.tres     - CharacterStats: Slime (HP=30, ATK=6, DEF=2)
	health_potion.tres   - ItemData: CONSUMABLE, health_restore=25
	iron_sword.tres      - ItemData: WEAPON, attack_bonus=5
	leather_armor.tres   - ItemData: ARMOR, defense_bonus=3
	strange_key.tres     - ItemData: QUEST, value=5
	warrior_class.tres   - CharacterClass: Beastmaster (HP+12, ATK+3, DEF+2, mana+2)
	ranger_class.tres    - CharacterClass: Fox (HP+8, ATK+2, DEF+1, mana+4, crit+0.10)
	mage_class.tres      - CharacterClass: Sorcerer (HP+5, ATK+1, DEF+1, mana+8)
	rogue_class.tres     - CharacterClass: Swashbuckler (HP+6, ATK+2, DEF+1, mana+3, crit+0.15)
  addons/            - Godot plugins
```
