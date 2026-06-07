# Godot 4.6 Metroidvania Starter

This is a save-ready 2D Metroidvania controller scaffold for Godot 4.6 using GDScript and `CharacterBody2D`.

## Scene Tree Structure

### `Player/player.tscn`

```text
Player (CharacterBody2D, group: player)
├─ Sprite2D
├─ CollisionShape2D
├─ StateMachine (Systems/state_machine.gd)
├─ HealthComponent (Systems/health_component.gd)
├─ FacingPivot (Node2D)
│  ├─ ForwardAttackHitbox (DamageComponent / Area2D)
│  │  └─ CollisionShape2D
│  ├─ UpAttackHitbox (DamageComponent / Area2D)
│  │  └─ CollisionShape2D
│  ├─ DownAttackHitbox (DamageComponent / Area2D)
│  │  └─ CollisionShape2D
│  ├─ AttackEffect (Sprite2D)
│  └─ DashEffect (Sprite2D)
└─ Camera2D
```

### `Enemies/enemy.tscn`

```text
Enemy (CharacterBody2D, group: enemies)
├─ Sprite2D
├─ CollisionShape2D
├─ StateMachine (Systems/state_machine.gd)
├─ HealthComponent (Systems/health_component.gd)
├─ AttackHitbox (DamageComponent / Area2D)
│  └─ CollisionShape2D
├─ WallCheck (RayCast2D)
└─ FloorCheck (RayCast2D)
```

### `Levels/level_01.tscn`

```text
Level01 (Node2D)
├─ World (Node2D)
│  ├─ Floor (StaticBody2D)
│  ├─ LeftWall (StaticBody2D)
│  ├─ RightWall (StaticBody2D)
│  ├─ PlatformA (StaticBody2D)
│  └─ PlatformB (StaticBody2D)
├─ Player (instance of Player/player.tscn)
└─ Enemy (instance of Enemies/enemy.tscn)
```

## Input Map Setup

The included `project.godot` already defines these actions:

| Action | Keyboard / Mouse |
| --- | --- |
| `move_left` | A, Left Arrow |
| `move_right` | D, Right Arrow |
| `move_up` | W, Up Arrow |
| `move_down` | S, Down Arrow |
| `jump` | Space, W |
| `dash` | Shift |
| `attack` | Left Mouse Button, J |

To edit them manually in Godot:

1. Open `Project > Project Settings > Input Map`.
2. Add each action exactly as named above.
3. Assign the listed keyboard or mouse events.
4. Keep the action names lowercase because the scripts reference them directly.

## Player Moveset

- Run: hold `A/D` or `Left/Right Arrow`.
- Jump: press `Space` or `W`.
- Variable jump: release jump early for a shorter jump.
- Double jump: press jump again in the air.
- Dash: press `Shift`.
- Wall grab: hold movement toward a wall while airborne.
- Wall slide: keep holding toward the wall, then hold `S` or `Down Arrow`.
- Wall jump: while grabbing a wall, press jump to launch mostly upward.
- Forward attack: press `J` or left mouse button.
- Up attack: hold `W` or `Up Arrow`, then press attack.
- Down attack: hold `S` or `Down Arrow`, then press attack.
- Down attack pogo: hit an enemy with down attack while airborne to bounce upward.

## Editing Levels

Levels are normal Godot scenes, so you can edit layout with visible nodes in the editor.

Open any scene from `Levels/level_01.tscn` to `Levels/level_10.tscn`.

- Move platforms by selecting nodes under `World`.
- Resize platforms by scaling those platform nodes.
- Move the player start by moving `PlayerSpawn`.
- Add enemies by duplicating a `Marker2D` under `EnemySpawns`.
- Move the yellow finish marker by moving `Goal`.
- Edit the title, tip, and camera limits on the root `LevelXX` node in the Inspector.

`Levels/platform.tscn` is the reusable platform node used by all levels.

## Importing Into Godot

1. Open Godot 4.6.
2. Click `Import`.
3. Choose the `metroidvania_godot_4_6` folder.
4. Select `project.godot`.
5. Click `Import & Edit`.
6. Open `Levels/level_01.tscn`.
7. Press `F5` to run the project.

## Tuning Notes

- Player movement values are exported in `Player/player.gd`, so you can tune speed, acceleration, gravity, jump cut, dash duration, and wall jump in the Inspector.
- Enemy values are exported in `Enemies/enemy.gd`, including patrol speed, chase speed, detection range, vertical detection tolerance, attack range, windup time, active time, recovery time, and cooldown.
- `HealthComponent` and `DamageComponent` are reusable on bosses, breakable objects, hazards, and projectiles.
- Every actor exposes `get_save_data()` and `load_save_data()` as the hook points for a future global save manager.

## Replacing Placeholder Images

Colored placeholder images are included in `Assets/`:

- `player_placeholder.svg`
- `enemy_placeholder.svg`
- `block_placeholder.svg`
- `slash_effect.svg`
- `dash_effect.svg`

To replace them:

1. Copy your `.png` or `.svg` image into the `Assets/` folder.
2. Open the scene, such as `Player/player.tscn`.
3. Click `Sprite2D`.
4. In the Inspector, drag your image into the `Texture` property.
5. Resize the sprite or collision shape if needed.
