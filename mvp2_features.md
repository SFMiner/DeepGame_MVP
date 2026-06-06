# MVP2 Feature List — Basic RPG

## Foundation
- **TileMapLayer** background tileset with **NavigationRegion2D** / baked NavMesh for 2D pathfinding; replace direct-vector enemy movement with NavigationAgent2D
- **PlayerData Resource**: canonical serializable container for all player state (class, level, XP, base stats, equipment slots, inventory, gold, dungeon depth) — prerequisite for save/load, class system, and equipment slots
- **Splash screen** with main menu: New Game, Load Game, Settings, Quit

## Combat System Overhaul
- **Deliberate melee attack** (dedicated input key, e.g. Z):
  - Attack has a windup phase (animation frames) before the strike frame
  - At the strike frame: damage is dealt and incoming enemy contact damage is blocked
  - If an enemy enters melee range and lands a hit during the windup (before the strike frame), the player's attack is canceled and interrupted; the player takes the hit normally
  - Player no longer deals damage by bumping; deliberate attack replaces bump-combat as primary player offense
- **Ranged attack** (dedicated input key, e.g. X): one basic ranged attack per character
- **Unified Projectile system**: ProjectileData Resource parameterized by damage, speed, range, visual (color or sprite), and pierce flag — used by player ranged attacks, enemy projectiles, and magic spells interchangeably
- **Status effects**: poisoned (damage over time), slowed (speed reduction), stunned (no actions for duration)
- **Knockback** on hit: velocity impulse away from attacker
- **Critical hits**: chance-based, configurable damage multiplier

## Magic System
- **Mana stat** added to CharacterStats
- **SpellData Resource**: damage, element type, mana_cost, cooldown, projectile parameters (reuses Projectile system)
- **Magic hotbar**: assignable spell slots (e.g. 1–3 keys)
- Damaging spells fire via the unified Projectile system

## Class System
- **Character appearance selector**: swap player spritesheet / animation set cosmetically before class selection
- **CharacterClass Resource**: class_name, stat modifiers, level-up table (stat gains per level), starting abilities, available spells
- **Class selection screen** between splash and game start
- **Level-up progression** variable by class

## Equipment Overhaul
- **Equipment slots**: weapon, armor, accessory (minimum)
- **Swap equipment**: equipping to an occupied slot returns old item to inventory
- **Drop equipment**: from inventory or equipped slot; spawns ItemPickup at player position
- **Expanded item types**: bow (enables ranged attack), staff (enables magic), shield (defense + block chance), rings/accessories
- **GUI inventory panel**: slot-based or icon-grid layout replacing current numbered text list
- Item tooltip on hover/select

## World Design Primitives
- **Doors**: locked (require key item in inventory), unlocked (E to open), level-transition variant
- **Chests**: single-use, loot-table driven, E to open, spawns ItemPickup(s) on open
- **Switches and pressure plates**: toggle linked doors or objects on activation
- **Destructible objects**: barrels/crates take damage and break, chance to drop loot
- **Interactable signs/noticeboards**: E to read, display text popup (no dialogue system needed)
- **Traps**: floor spikes (damage on contact), dart traps (fire projectile on proximity trigger)
- **Healing fountains / rest spots**: restore HP, single-use or cooldown-gated
- **Portals / level exits**: transition trigger to next dungeon depth
- **Environmental hazards**: water, lava, or void tiles that deal damage or block movement (via TileMapLayer custom data layer)
- **Fog of war**: unexplored tiles hidden; explored-but-not-visible tiles darkened; light radius around player
- **Enemy spawn markers**: used by procedural generator to place enemies by type and tier

## NPC & Dialogue System
- **DialogueData Resource**: sequence of entries (speaker, text, choices array)
- **NPC.gd**: E to interact, triggers dialogue panel
- **Dialogue HUD panel**: speaker name, scrolling text, choice buttons
- **Merchant NPC**: shop panel, buy/sell items from loot tables, uses gold currency
- **Quest-giver NPC**: delivers quest text, sets GameState flags; actual quest tracking deferred to a future quest system

## Economy
- **Gold currency** tracked in PlayerData
- Gold dropped by enemies (chance-based, scaled by enemy tier)
- get_coin SFX on gold pickup
- Item `value` field wired to merchant buy/sell pricing

## Procedural Generation (Roguelike)
- **Dungeon generator**: room-and-corridor layout written to TileMapLayer (BSP or simple room-placement)
- **LootTable Resource**: weighted ItemData entries; used by chests, destructibles, and enemy drops
- **Enemy spawn tables**: weighted by enemy category and dungeon depth
- Dungeon depth tracked in PlayerData/GameState; increments on level exit

## Level Progression
- Level exit portal loads next procedurally generated dungeon
- PlayerData persists across scene transitions via autoload or GameState
- On player death: return to main menu (roguelike permadeath); Load Game restores last save

## Audio
- **MusicManager autoload**: plays and crossfades between tracks; switches automatically between exploration and combat themes based on EventBus signals (enemy aggro / all_enemies_defeated)
- Music assets (loopable): `assets/sound/music/main_theme`, `assets/sound/music/combat_theme`
- SFX assets wired to EventBus events:
  - `assets/sound/sfx/male_hurt` → player damage (male character)
  - `assets/sound/sfx/female_hurt` → player damage (female character)
  - `assets/sound/sfx/weapon_striking_flesh` → melee damage_dealt
  - `assets/sound/sfx/slime_movement` → slime enemy movement
  - `assets/sound/sfx/get_coin` → gold pickup

## Save / Load
- **SaveData**: serializes full PlayerData + GameState flags to `user://` as JSON or Resource
- Load Game restores PlayerData and generates dungeon at saved depth
- Auto-save on level transition
- Optional: 1–3 named save slots

## Quality of Life
- **Pause menu** (Esc): Resume, Save, Quit to Main Menu
- **Minimap**: explored room layout displayed in HUD corner
- **Settings**: master volume, music volume, SFX volume, fullscreen toggle
- **Keybinding help overlay**
