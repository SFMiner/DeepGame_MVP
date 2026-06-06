# MVP2-Lite Implementation Plan — Basic RPG

## Deliverable
A playable loop: Splash → Main Menu → Class Select → Dungeon room → combat with deliberate melee/ranged/magic, equipment slots, skeleton enemies, sounds, permadeath toggle.

---

## Phase A: Data Layer & Input Map
**7 new `.gd` files, 4 new `.tres` files, 2 modified**

| # | File | Action |
|---|------|--------|
| A1 | `scripts/PlayerData.gd` | **New** — `class_name PlayerData extends Resource`. Fields: `player_name`, `character_class_name`, `level`/`xp`/`xp_to_next`, `base_max_hp`/`base_attack`/`base_defense`/`base_mana`, `gold`, `equipment` dict (weapon/armor/accessory → ItemData or null), `inventory: Array[ItemData]`, `equipped_spells: Array[SpellData]`, `dungeon_depth`, `flags: Dictionary`. Methods: `serialize() -> Dictionary`, `static deserialize(data: Dictionary) -> PlayerData` |
| A2 | `scripts/ProjectileData.gd` | **New** — fields: `damage`, `speed`, `range`, `color`, `sprite_texture`, `size`, `pierce`, `element` |
| A3 | `scripts/StatusEffect.gd` | **New** — enum POISON/SLOW/STUN; fields: `effect_type`, `duration`, `damage_per_tick`, `speed_multiplier`, `tick_interval` |
| A4 | `scripts/SpellData.gd` | **New** — fields: `spell_name`, `mana_cost`, `cooldown`, `projectile_data: ProjectileData`, `status_effect: StatusEffect` |
| A5 | `scripts/CharacterClass.gd` | **New** — fields: `class_name`, `description`, `hp_per_level`/`attack_per_level`/`defense_per_level`/`mana_per_level`, `available_spells: Array[SpellData]`, `sprite_set` (Beastmaster/Fox/Sorcerer/Swashbuckler) |
| A6 | `resources/warrior_class.tres` | **New** — Beastmaster, HP+12/lvl, ATK+3/lvl, DEF+2/lvl, mana+2/lvl, 1 melee spell |
| A7 | `resources/ranger_class.tres` | **New** — Fox, HP+8, ATK+2, DEF+1, mana+4, bow-enabled, 1 ranged spell |
| A8 | `resources/mage_class.tres` | **New** — Sorcerer, HP+5, ATK+1, DEF+1, mana+8, 3 damage spells |
| A9 | `resources/rogue_class.tres` | **New** — Swashbuckler, HP+6, ATK+2, DEF+1, mana+3, high crit, 1 utility spell |
| A10 | `scripts/CharacterStats.gd` | **Modify** — add `mana`/`max_mana` with setter + `mana_changed` signal; add `crit_chance: float = 0.05`, `crit_multiplier: float = 2.0` |
| A11 | `scripts/EventBus.gd` | **Modify** — add signals: `mana_changed(current, max)`, `status_applied(target, type)`, `gold_collected(amount)`, `enemy_aggro_changed(in_combat: bool)` |
| A12 | `project.godot` | **Modify** — add input actions: `attack_melee`(Z), `attack_ranged`(X), `spell_1`(1), `spell_2`(2), `spell_3`(3), `pause`(Esc) |

---

## Phase B: Splash → Main Menu → Class Select
**3 new `.gd` files, 1 modified**

| # | File | Action |
|---|------|--------|
| B1 | `scripts/SplashScreen.gd` | **New** — Title "BASIC RPG" centered, "Press any key..." blinking; any key → `main_menu.tscn` |
| B2 | `scripts/MainMenu.gd` | **New** — Buttons: New Game, Load Game (stub), Settings, Quit; all UI programmatic |
| B3 | `scripts/ClassSelect.gd` | **New** — Left/right arrows cycle 4 character sprite previews (cosmetic); class list with name + description + stat modifiers; Confirm → creates PlayerData, stores in GameState, transitions to game scene |
| B4 | `project.godot` | **Modify** — `run/main_scene` → splash screen (or keep main.tscn as game scene, add scene transition logic) |

---

## Phase C: Audio System (ffmpeg convert + autoload + wiring)
**1 new `.gd` file, 7 audio files converted, 1 modified**

| # | File | Action |
|---|------|--------|
| C1 | Convert mp3 → ogg | `ffmpeg -i <src>.mp3 -c:a libvorbis -q:a 4 <dest>.ogg` for all 7 files into `assets/sounds/sfx/*.ogg` and `assets/sounds/music/*.ogg` |
| C2 | `scripts/MusicManager.gd` | **New** autoload — `play_music(track)`, `crossfade_to(track, duration)`, `play_sfx(path)`. Wire to EventBus: `enemy_aggro_changed(true)` → battle theme; `all_enemies_defeated` → exploration theme; `damage_dealt` → hurt SFX (male/female by player class); `item_picked_up` → coin SFX; `player_died` → silence/stop |
| C3 | `project.godot` | **Modify** — add `MusicManager` autoload |

---

## Phase D: TileMap + Navigation
**1 new `.gd` file, 2 scene modified, 1 script modified**

| # | File | Action |
|---|------|--------|
| D1 | `scenes/main.tscn` | **Modify** — Add `TileMapLayer` referencing `Tileset_grass (free demo).png` (16×16 tiles, 512×512 sheet = 32×32 grid). Add `NavigationRegion2D` child with baked NavMesh polygon covering walkable floor |
| D2 | `scripts/Main.gd` | **Modify** — `_ready()`: programmatically set TileMapLayer cells to create a ~20×15 test room (walls on perimeter, open floor interior, player spawn center, enemy spawn positions). This avoids editor tile-painting and keeps the map version-controlled in code |
| D3 | `scripts/Enemy.gd` | **Modify** — Replace direct `direction_to()` velocity in CHASING/KITING/FLEEING with `NavigationAgent2D` path following. Add enemy spawn position support |
| D4 | `scripts/Player.gd` | **Modify** — Remove bump-combat collision loop (lines 45-53 in `_physics_process()`) to clear the way for deliberate attack; keep movement working |

---

## Phase E: Combat System Overhaul
**1 new `.gd` file, 3 modified**

| # | File | Action |
|---|------|--------|
| E1 | `scripts/Player.gd` | **Major refactor** — Deliberate melee: Z → windup(0.2s, play "melee" anim) → strike frame(deal damage in arc, block incoming 0.15s) → recovery(0.3s). Cancel if hit during windup. Ranged: X → fire projectile (bow required). Add `_active_statuses`, `apply_status_effect()`, `_process_statuses()`, knockback velocity decay. Mana tracking. |
| E2 | `scripts/Projectile.gd` | **Modify** — Constructor takes `ProjectileData`; use `data.color`/`data.size` for Polygon2D visual or `data.sprite_texture` for Sprite2D; pierce flag skips `queue_free()` on hit; range-limited by `data.range` traveled |
| E3 | `scripts/Enemy.gd` | **Modify** — `_fire_projectile()` uses ProjectileData. Add knockback + `_active_statuses` processing. Add `@export var enemy_sprite_set: String = "slime"` to pick slime vs skeleton spritesheet |
| E4 | `scripts/SkeletonEnemy.gd` | **New** — Thin subclass of Enemy that overrides `_setup_animations()` to load skeleton spritesheets (128×128, same 4×4 grid pattern); set `enemy_sprite_set = "skeleton"` |
| E5 | Combat integration | `take_damage()` handles `is_crit` flag; knockback velocity impulse on hit; FloatingDamage gold for crits; `status_applied` signal; enemy death drops XP + chance of gold |

**Deliberate melee state timing:**
```
IDLE → Z press → WINDUP (0.20s, "melee" anim starts)
  → enemy hit during windup? → CANCEL, take damage, play "hit" anim, back to IDLE
  → windup complete → STRIKE (deal damage in front arc 40px, block all incoming for 0.15s)
  → RECOVERY (0.30s, cannot attack) → IDLE
Total: ~0.5s cycle, same as old bump-combat cooldown
```

---

## Phase F: Equipment & Inventory Overhaul
**2 modified, 4 new `.tres`**

| # | File | Action |
|---|------|--------|
| F1 | `scripts/ItemData.gd` | **Modify** — Add enum types: BOW, STAFF, SHIELD, ACCESSORY; add field `equip_slot: String`, `block_chance: float = 0.0`, `mana_bonus: int = 0`, `max_hp_bonus: int = 0` |
| F2 | `resources/short_bow.tres` | **New** — BOW, ATK+4, slot="weapon" |
| F3 | `resources/oak_staff.tres` | **New** — STAFF, ATK+2, mana+10, slot="weapon" |
| F4 | `resources/wooden_shield.tres` | **New** — SHIELD, DEF+3, block_chance=0.15, slot="armor" |
| F5 | `resources/ring_vitality.tres` | **New** — ACCESSORY, max_hp+20, slot="accessory" |
| F6 | `scripts/Player.gd` | **Modify** — `equip_item(index)` swaps to slot, returns old; `unequip_item(slot)` returns to inventory; `drop_item(slot/index)` spawns ItemPickup; `_recalc_stats()` sums base + equipment bonuses |
| F7 | `scripts/HUD.gd` | **Modify** — Replace text inventory with: (a) equipment panel (3 slots, left side), (b) inventory grid (right, 4-col), (c) spell hotbar row, (d) tooltip on hover. Click item → use/equip; click equipped → unequip. X button to drop |

---

## Phase G: Magic System
**1 modified, 3 new `.tres`**

| # | File | Action |
|---|------|--------|
| G1 | `resources/fireball_spell.tres` | **New** — damage=20, mana_cost=8, cooldown=1.5s, red projectile, burn/poison status |
| G2 | `resources/ice_shard_spell.tres` | **New** — damage=12, mana_cost=6, cooldown=1.0s, blue projectile, slow status |
| G3 | `resources/lightning_bolt_spell.tres` | **New** — damage=15, mana_cost=10, cooldown=2.0s, yellow projectile, stun status |
| G4 | `scripts/Player.gd` | **Modify** — `_equipped_spells` (3 slots from class); keys 1/2/3 → `cast_spell(index)`; staff required; mana check + deduction; creates Projectile from spell's ProjectileData; applies StatusEffect on hit |
| G5 | `scripts/HUD.gd` | **Modify** — Spell bar: show spell name, mana cost, cooldown fill; mana bar added next to HP/XP bars |

---

## Phase H: Permadeath Toggle & Settings
**1 new `.gd`, 2 modified**

| # | File | Action |
|---|------|--------|
| H1 | `scripts/Settings.gd` | **New** — Accessible from Main Menu + pause (Esc): Permadeath toggle (checkbox), volume sliders (master/music/SFX), fullscreen toggle |
| H2 | `scripts/GameState.gd` | **Modify** — Add `permadeath_enabled: bool = false`; `reset_all()` clears flags + defeat_count |
| H3 | `scripts/Main.gd` or `scripts/Player.gd` | **Modify** — On player death: if `GameState.permadeath_enabled` → return to Main Menu + `GameState.reset_all()`; else → show death overlay + restart button (current behavior) |

---

## Execution Order & Dependencies

```
Phase A (Data + Input) ............. [blocks B, D, E, F, G]
    ├── Phase B (Menus + Class) .... [blocks H]
    ├── Phase C (Audio) ............ [independent, can start immediately]
    ├── Phase D (TileMap + Nav) .... [blocks E]
    │       └── Phase E (Combat) ... [blocks G]
    │               └── Phase F (Equipment) [blocks G]
    │                       └── Phase G (Magic)
    └── Phase H (Permadeath) ....... [integrates with game over flow]
```

Parallel tracks:
- **Track 1**: A → B → H (menus & settings)
- **Track 2**: A → C (audio, independent)
- **Track 3**: A → D → E → F → G (core gameplay)

---

## File Count Summary

| Type | Count |
|------|-------|
| New `.gd` scripts | 13 |
| New `.tres` resources | 14 |
| Modified `.gd` scripts | 9 |
| Modified `.tscn` scenes | 1 |
| Modified `project.godot` | 1 |
| Audio conversion | 7 mp3 → ogg |

---

## Not in MVP2-Lite (deferred to full MVP2)
- Procedural dungeon generation (hand-authored room instead)
- NPC/Dialogue system
- Doors, chests, signs, traps, destructibles, healing fountains, portals
- Fog of war
- Save/Load (stubbed in menu)
- Minimap, keybinding help overlay
- Gold economy beyond basic enemy drops
- Full Settings panel with all volume sliders (just toggle + master)
