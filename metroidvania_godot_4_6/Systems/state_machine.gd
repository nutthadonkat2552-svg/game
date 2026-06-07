class_name StateMachine
extends Node

signal state_changed(previous_state: StringName, next_state: StringName)

## Lightweight state machine used by actors that keep their state logic in one script.
## This keeps transitions explicit while avoiding a large file tree for simple states.

@export var initial_state: StringName = &"idle"

var current_state: StringName
var previous_state: StringName
var state_time: float = 0.0


func _ready() -> void:
	current_state = initial_state
	previous_state = &""


func physics_tick(delta: float) -> void:
	state_time += delta


func transition_to(next_state: StringName) -> void:
	if next_state == current_state:
		return

	previous_state = current_state
	current_state = next_state
	state_time = 0.0
	state_changed.emit(previous_state, current_state)


func is_state(state: StringName) -> bool:
	return current_state == state
