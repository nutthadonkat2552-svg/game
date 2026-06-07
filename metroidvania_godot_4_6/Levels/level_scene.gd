class_name LevelScene
extends Node2D

## Node-based level runner.
## Edit level layout directly in each level_XX.tscn by moving/scaling Platform
## nodes, PlayerSpawn, EnemySpawns markers, and Goal.

const PLAYER_SCENE: PackedScene = preload("res://Player/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://Enemies/enemy.tscn")

@export var level_number: int = 1
@export var level_title: String = "Level"
@export_multiline var level_tip: String = ""
@export var camera_left: int = -200
@export var camera_top: int = -260
@export var camera_right: int = 2200
@export var camera_bottom: int = 760

var _player: Player


func _ready() -> void:
	_spawn_player()
	_spawn_enemies()
	_setup_goal()
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_to_level_select()


func _spawn_player() -> void:
	var spawn: Marker2D = get_node("PlayerSpawn") as Marker2D
	_player = PLAYER_SCENE.instantiate() as Player
	_player.global_position = spawn.global_position
	add_child(_player)

	var camera: Camera2D = _player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.limit_left = camera_left
		camera.limit_top = camera_top
		camera.limit_right = camera_right
		camera.limit_bottom = camera_bottom


func _spawn_enemies() -> void:
	var spawns: Node = get_node_or_null("EnemySpawns")
	if spawns == null:
		return

	for child: Node in spawns.get_children():
		if child is Marker2D:
			var marker: Marker2D = child as Marker2D
			var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
			enemy.global_position = marker.global_position
			add_child(enemy)


func _setup_goal() -> void:
	var goal: Area2D = get_node("Goal") as Area2D
	goal.body_entered.connect(_on_goal_body_entered)


func _build_ui() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.name = "LevelUI"
	add_child(canvas)

	var top_bar: HBoxContainer = HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_left = 20.0
	top_bar.offset_top = 20.0
	top_bar.offset_right = -20.0
	top_bar.offset_bottom = 92.0
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.add_child(top_bar)

	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_bar.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(box)

	var title: Label = Label.new()
	title.text = "Level %02d - %s" % [level_number, level_title]
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)

	var tip: Label = Label.new()
	tip.text = level_tip
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(tip)

	var menu_button: Button = Button.new()
	menu_button.text = "Level Select"
	menu_button.custom_minimum_size = Vector2(140.0, 42.0)
	menu_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu_button.pressed.connect(_go_to_level_select)
	top_bar.add_child(menu_button)


func _on_goal_body_entered(body: Node2D) -> void:
	if body is Player:
		_go_to_level_select()


func _go_to_level_select() -> void:
	get_tree().change_scene_to_file("res://UI/level_select.tscn")
