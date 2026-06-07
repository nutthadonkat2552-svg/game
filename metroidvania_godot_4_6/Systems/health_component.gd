class_name HealthComponent
extends Node

signal health_changed(current_health: int, max_health: int)
signal damaged(amount: int, source: Node)
signal healed(amount: int)
signal died

## Reusable health model for player, enemies, bosses, and hazards.

@export var max_health: int = 5
@export var start_full: bool = true

var current_health: int
var is_dead: bool = false


func _ready() -> void:
	current_health = max_health if start_full else clamp(current_health, 0, max_health)
	health_changed.emit(current_health, max_health)


func take_damage(amount: int, source: Node = null) -> bool:
	if is_dead or amount <= 0:
		return false

	current_health = max(current_health - amount, 0)
	damaged.emit(amount, source)
	health_changed.emit(current_health, max_health)

	if current_health == 0:
		is_dead = true
		died.emit()

	return true


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	var old_health: int = current_health
	current_health = min(current_health + amount, max_health)
	if current_health != old_health:
		healed.emit(current_health - old_health)
		health_changed.emit(current_health, max_health)


func restore_full() -> void:
	is_dead = false
	current_health = max_health
	health_changed.emit(current_health, max_health)


func get_save_data() -> Dictionary:
	return {
		"current_health": current_health,
		"max_health": max_health,
		"is_dead": is_dead,
	}


func load_save_data(data: Dictionary) -> void:
	max_health = int(data.get("max_health", max_health))
	current_health = clamp(int(data.get("current_health", max_health)), 0, max_health)
	is_dead = bool(data.get("is_dead", current_health <= 0))
	health_changed.emit(current_health, max_health)
