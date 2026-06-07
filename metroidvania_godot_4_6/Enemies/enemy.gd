class_name Enemy
extends CharacterBody2D

## Simple patrol/chase enemy.
## Navigation is intentionally platformer-friendly: it turns around at walls,
## patrols ledges, chases the player on the same platform, and attacks in beats.

@export var patrol_speed: float = 70.0
@export var chase_speed: float = 130.0
@export var acceleration: float = 900.0
@export var gravity: float = 1400.0
@export var max_fall_speed: float = 520.0

@export_group("AI")
@export var detection_range: float = 280.0
@export var lose_interest_range: float = 390.0
@export var vertical_detection_tolerance: float = 80.0
@export var attack_range: float = 42.0
@export var attack_windup_time: float = 0.22
@export var attack_active_time: float = 0.12
@export var attack_recovery_time: float = 0.28
@export var attack_cooldown: float = 0.7

@export_group("Combat")
@export var contact_damage: int = 1

@onready var state_machine: StateMachine = $StateMachine
@onready var health_component: HealthComponent = $HealthComponent
@onready var attack_hitbox: DamageComponent = $AttackHitbox
@onready var sprite: Sprite2D = $Sprite2D
@onready var wall_check: RayCast2D = $WallCheck
@onready var floor_check: RayCast2D = $FloorCheck

var facing_direction: int = -1
var target: Player
var _attack_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0
var _has_activated_attack: bool = false


func _ready() -> void:
	attack_hitbox.damage = contact_damage
	attack_hitbox.deactivate()
	health_component.died.connect(_on_died)
	_find_player()


func _physics_process(delta: float) -> void:
	if target == null:
		_find_player()

	state_machine.physics_tick(delta)
	_update_timers(delta)
	_update_state()
	_apply_gravity(delta)

	match state_machine.current_state:
		&"chase":
			_process_chase(delta)
		&"attack":
			_process_attack(delta)
		&"dead":
			velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		_:
			_process_patrol(delta)

	move_and_slide()
	_update_checks_and_visuals()


# -----------------------------
# State decisions
# -----------------------------
func _update_state() -> void:
	if health_component.is_dead:
		state_machine.transition_to(&"dead")
		return

	if target == null:
		state_machine.transition_to(&"patrol")
		return

	if state_machine.is_state(&"attack"):
		return

	var horizontal_distance: float = absf(target.global_position.x - global_position.x)
	var vertical_distance: float = absf(target.global_position.y - global_position.y)
	var can_notice_player: bool = horizontal_distance <= detection_range and vertical_distance <= vertical_detection_tolerance
	var should_keep_chasing: bool = horizontal_distance <= lose_interest_range and vertical_distance <= vertical_detection_tolerance

	if horizontal_distance <= attack_range and vertical_distance <= vertical_detection_tolerance and _attack_cooldown_timer <= 0.0:
		_start_attack()
	elif can_notice_player or (state_machine.is_state(&"chase") and should_keep_chasing):
		state_machine.transition_to(&"chase")
	else:
		state_machine.transition_to(&"patrol")


# -----------------------------
# Movement
# -----------------------------
func _process_patrol(delta: float) -> void:
	if _should_turn_around():
		_flip()

	var target_speed: float = patrol_speed * facing_direction
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)


func _process_chase(delta: float) -> void:
	if target == null:
		return

	facing_direction = int(sign(target.global_position.x - global_position.x))
	if facing_direction == 0:
		facing_direction = 1

	var target_speed: float = chase_speed * facing_direction
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)

	if _should_turn_around():
		velocity.x = 0.0


func _process_attack(delta: float) -> void:
	_attack_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)

	if _attack_timer <= attack_recovery_time + attack_active_time and not _has_activated_attack:
		_has_activated_attack = true
		sprite.modulate = Color(1.0, 0.32, 0.28)
		attack_hitbox.activate()

	if _attack_timer <= attack_recovery_time:
		sprite.modulate = Color(1.0, 0.75, 0.55)
		attack_hitbox.deactivate()

	if _attack_timer <= 0.0:
		sprite.modulate = Color.WHITE
		state_machine.transition_to(&"chase" if _can_chase_target() else &"patrol")


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = min(velocity.y + gravity * delta, max_fall_speed)


func _should_turn_around() -> bool:
	return is_on_floor() and (wall_check.is_colliding() or not floor_check.is_colliding())


func _flip() -> void:
	facing_direction *= -1
	_update_checks_and_visuals()


# -----------------------------
# Attack flow
# -----------------------------
func _start_attack() -> void:
	_face_target()
	_attack_timer = attack_windup_time + attack_active_time + attack_recovery_time
	_attack_cooldown_timer = attack_cooldown
	_has_activated_attack = false
	sprite.modulate = Color(1.0, 0.92, 0.35)
	attack_hitbox.deactivate()
	state_machine.transition_to(&"attack")


func _can_chase_target() -> bool:
	if target == null:
		return false

	var horizontal_distance: float = absf(target.global_position.x - global_position.x)
	var vertical_distance: float = absf(target.global_position.y - global_position.y)
	return horizontal_distance <= lose_interest_range and vertical_distance <= vertical_detection_tolerance


func _face_target() -> void:
	if target == null:
		return

	facing_direction = int(sign(target.global_position.x - global_position.x))
	if facing_direction == 0:
		facing_direction = 1
	_update_checks_and_visuals()


func _update_timers(delta: float) -> void:
	_attack_cooldown_timer = max(_attack_cooldown_timer - delta, 0.0)


# -----------------------------
# Damage and save data
# -----------------------------
func _on_died() -> void:
	state_machine.transition_to(&"dead")
	attack_hitbox.deactivate()
	collision_layer = 0
	collision_mask = 1
	sprite.modulate = Color(0.45, 0.45, 0.45)
	queue_free.call_deferred()


func apply_knockback(knockback: Vector2) -> void:
	velocity = knockback


func get_save_data() -> Dictionary:
	return {
		"scene_path": scene_file_path,
		"global_position": global_position,
		"health": health_component.get_save_data(),
		"facing_direction": facing_direction,
	}


func load_save_data(data: Dictionary) -> void:
	global_position = data.get("global_position", global_position)
	if data.has("health"):
		health_component.load_save_data(data["health"])
	facing_direction = int(data.get("facing_direction", facing_direction))
	_update_checks_and_visuals()


func _find_player() -> void:
	target = get_tree().get_first_node_in_group("player") as Player


func _update_checks_and_visuals() -> void:
	sprite.flip_h = facing_direction < 0
	attack_hitbox.position.x = 22.0 * facing_direction
	wall_check.target_position.x = 18.0 * facing_direction
	floor_check.position.x = 14.0 * facing_direction
