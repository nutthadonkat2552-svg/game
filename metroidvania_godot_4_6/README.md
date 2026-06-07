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
│  └─ AttackHitbox (DamageComponent / Area2D)
│     └─ CollisionShape2D
└─ Camera2D
```

### `Enemies/enemy.tscn`

```text
Enemy (CharacterBody2D, group: enemies)
├─ Sprite2D
├─ CollisionShape2D
├─ StateMachine (Systems/state_machine.gd)
├─ HealthComponent (Systems/health_component.gd)
├─ ContactDamage (DamageComponent / Area2D)
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
| `jump` | Space, W |
| `dash` | Shift |
| `attack` | Left Mouse Button, J |

To edit them manually in Godot:

1. Open `Project > Project Settings > Input Map`.
2. Add each action exactly as named above.
3. Assign the listed keyboard or mouse events.
4. Keep the action names lowercase because the scripts reference them directly.

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
- Enemy values are exported in `Enemies/enemy.gd`, including patrol speed, chase speed, detection range, and attack/contact range.
- `HealthComponent` and `DamageComponent` are reusable on bosses, breakable objects, hazards, and projectiles.
- Every actor exposes `get_save_data()` and `load_save_data()` as the hook points for a future global save manager.

## Replacing Placeholder Images

Colored placeholder images are included in `Assets/`:

- `player_placeholder.svg`
- `enemy_placeholder.svg`
- `block_placeholder.svg`

To replace them:

1. Copy your `.png` or `.svg` image into the `Assets/` folder.
2. Open the scene, such as `Player/player.tscn`.
3. Click `Sprite2D`.
4. In the Inspector, drag your image into the `Texture` property.
5. Resize the sprite or collision shape if needed.
