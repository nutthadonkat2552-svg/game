class_name DamageComponent
extends Area2D

signal hit_target(target: Node)

## Area-based damage source.
## Put this on attack hitboxes, enemy touch zones, spikes, or projectiles.

@export var damage: int = 1
@export var knockback_force: Vector2 = Vector2(220.0, -120.0)
@export var enabled_on_ready: bool = true
@export var one_hit_per_activation: bool = true

var _hit_bodies: Array[Node] = []


func _ready() -> void:
	monitoring = enabled_on_ready
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func activate() -> void:
	_hit_bodies.clear()
	monitoring = true


func deactivate() -> void:
	monitoring = false
	_hit_bodies.clear()


func _on_area_entered(area: Area2D) -> void:
	var target: Node = area.owner
	_try_damage_target(target)


func _on_body_entered(body: Node2D) -> void:
	_try_damage_target(body)


func _try_damage_target(target: Node) -> void:
	if target == null or (one_hit_per_activation and target in _hit_bodies):
		return

	var health: HealthComponent = target.get_node_or_null("HealthComponent") as HealthComponent
	if health == null:
		return

	_hit_bodies.append(target)
	health.take_damage(damage, owner)
	hit_target.emit(target)

	if target.has_method("apply_knockback"):
		var target_node: Node2D = target as Node2D
		if target_node == null:
			return

		var direction: float = sign(target_node.global_position.x - global_position.x)
		if direction == 0.0:
			direction = 1.0
		target.apply_knockback(Vector2(knockback_force.x * direction, knockback_force.y))
