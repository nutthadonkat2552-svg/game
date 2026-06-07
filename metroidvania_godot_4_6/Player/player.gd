class_name Player
extends CharacterBody2D

## Hollow Knight-inspired controller:
## fast acceleration, crisp stops, variable jump height, coyote time, double jump,
## wall slide / wall jump, dash cooldown, melee hitbox, and invincibility frames.

@export_group("Movement")
@export var run_speed: float = 230.0
@export var ground_acceleration: float = 1800.0
@export var air_acceleration: float = 1350.0
@export var ground_friction: float = 2200.0
@export var air_friction: float = 550.0
@export var gravity: float = 1500.0
@export var fall_gravity_multiplier: float = 1.18
@export var max_fall_speed: float = 620.0

@export_group("Jumping")
@export var jump_velocity: float = -430.0
@export var jump_cut_multiplier: float = 0.42
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.12
@export var max_air_jumps: int = 1

@export_group("Dash")
@export var dash_speed: float = 520.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.42

@export_group("Wall")
@export var wall_slide_speed: float = 95.0
@export var wall_jump_velocity: Vector2 = Vector2(330.0, -390.0)
@export var wall_stick_time: float = 0.08

@export_group("Combat")
@export var attack_duration: float = 0.16
@export var attack_cooldown: float = 0.24

@export_group("Health")
@export var invincibility_duration: float = 0.9
@export var hurt_knockback_duration: float = 0.18

@onready var state_machine: StateMachine = $StateMachine
@onready var health_component: HealthComponent = $HealthComponent
@onready var attack_hitbox: DamageComponent = $FacingPivot/AttackHitbox
@onready var facing_pivot: Node2D = $FacingPivot
@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D

var input_direction: float = 0.0
var facing_direction: int = 1
var air_jumps_left: int
var is_invincible: bool = false

var _jump_buffer_timer: float = 0.0
var _coyote_timer: float = 0.0
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _attack_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0
var _hurt_timer: float = 0.0
var _wall_stick_timer: float = 0.0


func _ready() -> void:
	air_jumps_left = max_air_jumps
	attack_hitbox.deactivate()
	camera.make_current()
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_read_input()
	state_machine.physics_tick(delta)

	match state_machine.current_state:
		&"dash":
			_process_dash(delta)
		&"hurt":
			_process_hurt(delta)
		_:
			_process_locomotion(delta)
			_process_jump_requests()
			_process_dash_request()
			_process_attack_request()
			_update_locomotion_state()

	move_and_slide()
	_update_after_move()
	_update_visuals()


# -----------------------------
# Input
# -----------------------------
func _read_input() -> void:
	input_direction = Input.get_axis("move_left", "move_right")

	if not is_zero_approx(input_direction):
		facing_direction = sign(input_direction)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time

	if Input.is_action_just_pressed("attack"):
		_attack_cooldown_timer = max(_attack_cooldown_timer, 0.0)


# -----------------------------
# Movement
# -----------------------------
func _process_locomotion(delta: float) -> void:
	_apply_horizontal_movement(delta)
	_apply_gravity(delta)

	if _can_wall_slide():
		velocity.y = min(velocity.y, wall_slide_speed)
		state_machine.transition_to(&"wall_slide")


func _apply_horizontal_movement(delta: float) -> void:
	var target_speed: float = input_direction * run_speed
	var acceleration: float = ground_acceleration if is_on_floor() else air_acceleration
	var friction: float = ground_friction if is_on_floor() else air_friction

	if is_zero_approx(input_direction):
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	var gravity_scale: float = fall_gravity_multiplier if velocity.y > 0.0 else 1.0
	velocity.y = min(velocity.y + gravity * gravity_scale * delta, max_fall_speed)


func _process_jump_requests() -> void:
	if _jump_buffer_timer <= 0.0:
		return

	if is_on_floor() or _coyote_timer > 0.0:
		_start_jump()
	elif _can_wall_jump():
		_start_wall_jump()
	elif air_jumps_left > 0:
		_start_double_jump()


func _start_jump() -> void:
	velocity.y = jump_velocity
	air_jumps_left = max_air_jumps
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	state_machine.transition_to(&"jump")


func _start_double_jump() -> void:
	velocity.y = jump_velocity * 0.92
	air_jumps_left -= 1
	_jump_buffer_timer = 0.0
	state_machine.transition_to(&"jump")


func _start_wall_jump() -> void:
	var wall_direction: float = get_wall_normal().x
	if wall_direction == 0.0:
		wall_direction = -facing_direction

	velocity.x = wall_jump_velocity.x * wall_direction
	velocity.y = wall_jump_velocity.y
	facing_direction = sign(wall_direction)
	_wall_stick_timer = wall_stick_time
	_jump_buffer_timer = 0.0
	state_machine.transition_to(&"jump")


func _process_dash_request() -> void:
	if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0.0:
		state_machine.transition_to(&"dash")
		_dash_timer = dash_duration
		_dash_cooldown_timer = dash_cooldown
		velocity = Vector2(dash_speed * facing_direction, 0.0)


func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity = Vector2(dash_speed * facing_direction, 0.0)

	if _dash_timer <= 0.0:
		state_machine.transition_to(&"fall" if not is_on_floor() else &"idle")


func _can_wall_slide() -> bool:
	return not is_on_floor() and is_on_wall_only() and velocity.y > 0.0 and not is_zero_approx(input_direction)


func _can_wall_jump() -> bool:
	return is_on_wall_only() or state_machine.is_state(&"wall_slide")


# -----------------------------
# Combat
# -----------------------------
func _process_attack_request() -> void:
	if Input.is_action_just_pressed("attack") and _attack_cooldown_timer <= 0.0:
		_attack_timer = attack_duration
		_attack_cooldown_timer = attack_cooldown
		attack_hitbox.activate()
		state_machine.transition_to(&"attack")


func _update_attack() -> void:
	if _attack_timer <= 0.0:
		attack_hitbox.deactivate()


# -----------------------------
# Health and damage
# -----------------------------
func _on_damaged(_amount: int, source: Node) -> void:
	if is_invincible:
		return

	is_invincible = true
	_hurt_timer = hurt_knockback_duration
	state_machine.transition_to(&"hurt")

	var knockback_direction: float = -facing_direction
	if source is Node2D:
		knockback_direction = sign(global_position.x - source.global_position.x)
		if knockback_direction == 0.0:
			knockback_direction = -facing_direction

	velocity = Vector2(260.0 * knockback_direction, -180.0)
	_start_invincibility()


func _process_hurt(delta: float) -> void:
	_hurt_timer -= delta
	_apply_gravity(delta)
	if _hurt_timer <= 0.0:
		state_machine.transition_to(&"fall" if not is_on_floor() else &"idle")


func _start_invincibility() -> void:
	var tween: Tween = create_tween()
	tween.set_loops(int(invincibility_duration / 0.1))
	tween.tween_property(sprite, "modulate:a", 0.35, 0.05)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.05)
	await get_tree().create_timer(invincibility_duration).timeout
	is_invincible = false
	sprite.modulate.a = 1.0


func _on_died() -> void:
	set_physics_process(false)
	attack_hitbox.deactivate()
	sprite.modulate = Color(1.0, 0.25, 0.25)


func apply_knockback(knockback: Vector2) -> void:
	velocity = knockback


# -----------------------------
# State updates and save data
# -----------------------------
func _update_locomotion_state() -> void:
	if state_machine.is_state(&"attack") and _attack_timer > 0.0:
		return

	if is_on_floor():
		state_machine.transition_to(&"run" if absf(velocity.x) > 8.0 else &"idle")
	elif velocity.y < 0.0:
		state_machine.transition_to(&"jump")
	else:
		state_machine.transition_to(&"fall")


func _update_after_move() -> void:
	if is_on_floor():
		air_jumps_left = max_air_jumps
		_coyote_timer = coyote_time
	elif _coyote_timer > 0.0:
		pass

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


func _update_timers(delta: float) -> void:
	_jump_buffer_timer = max(_jump_buffer_timer - delta, 0.0)
	_coyote_timer = max(_coyote_timer - delta, 0.0)
	_dash_cooldown_timer = max(_dash_cooldown_timer - delta, 0.0)
	_attack_cooldown_timer = max(_attack_cooldown_timer - delta, 0.0)
	_attack_timer = max(_attack_timer - delta, 0.0)
	_wall_stick_timer = max(_wall_stick_timer - delta, 0.0)
	_update_attack()


func _update_visuals() -> void:
	facing_pivot.scale.x = facing_direction
	sprite.flip_h = facing_direction < 0


func get_save_data() -> Dictionary:
	return {
		"scene_path": scene_file_path,
		"global_position": global_position,
		"health": health_component.get_save_data(),
		"air_jumps_left": air_jumps_left,
	}


func load_save_data(data: Dictionary) -> void:
	global_position = data.get("global_position", global_position)
	if data.has("health"):
		health_component.load_save_data(data["health"])
	air_jumps_left = int(data.get("air_jumps_left", max_air_jumps))
