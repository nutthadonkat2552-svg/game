class_name LevelBuilder
extends Node2D

## Builds playable tutorial/challenge levels from compact layout data.
## Each level scene sets only level_index. This keeps ten levels easy to tune
## while preserving separate scene files for level select and team handoff.

const PLAYER_SCENE: PackedScene = preload("res://Player/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://Enemies/enemy.tscn")
const BLOCK_TEXTURE: Texture2D = preload("res://Assets/block_placeholder.svg")

@export_range(1, 10) var level_index: int = 1

var _goal_area: Area2D
var _player: Player


func _ready() -> void:
	var data: Dictionary = _get_level_data(level_index)
	name = "Level%02d" % level_index
	_build_world(data)
	_spawn_player(data)
	_spawn_enemies(data)
	_build_goal(data)
	_build_ui(data)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://UI/level_select.tscn")


# -----------------------------
# Scene building
# -----------------------------
func _build_world(data: Dictionary) -> void:
	var world: Node2D = Node2D.new()
	world.name = "World"
	add_child(world)

	var platforms: Array = data["platforms"]
	for platform_value in platforms:
		var platform_data: Dictionary = platform_value
		var platform_name: String = str(platform_data["name"])
		var platform_position: Vector2 = platform_data["position"]
		var platform_size: Vector2 = platform_data["size"]
		var platform: StaticBody2D = _create_platform(platform_name, platform_position, platform_size)
		world.add_child(platform)


func _spawn_player(data: Dictionary) -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	var player_spawn: Vector2 = data["player_spawn"]
	_player.position = player_spawn
	add_child(_player)

	var camera: Camera2D = _player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.limit_left = int(data.get("camera_left", -200))
		camera.limit_top = int(data.get("camera_top", -260))
		camera.limit_right = int(data.get("camera_right", 2200))
		camera.limit_bottom = int(data.get("camera_bottom", 760))


func _spawn_enemies(data: Dictionary) -> void:
	var enemy_positions: Array = data["enemies"]
	for enemy_position_value in enemy_positions:
		var enemy_position: Vector2 = enemy_position_value
		var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
		enemy.position = enemy_position
		add_child(enemy)


func _build_goal(data: Dictionary) -> void:
	_goal_area = Area2D.new()
	_goal_area.name = "Goal"
	var goal_position: Vector2 = data["goal"]
	_goal_area.position = goal_position
	_goal_area.collision_layer = 0
	_goal_area.collision_mask = 2
	_goal_area.body_entered.connect(_on_goal_body_entered)
	add_child(_goal_area)

	var shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(46.0, 80.0)
	shape.shape = rectangle
	_goal_area.add_child(shape)

	var marker: Polygon2D = Polygon2D.new()
	marker.name = "GoalMarker"
	marker.polygon = PackedVector2Array([
		Vector2(-23.0, -40.0),
		Vector2(23.0, -40.0),
		Vector2(23.0, 40.0),
		Vector2(-23.0, 40.0),
	])
	marker.color = Color(0.95, 0.86, 0.25, 0.72)
	_goal_area.add_child(marker)


func _build_ui(data: Dictionary) -> void:
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
	title.text = "Level %02d - %s" % [level_index, str(data["title"])]
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(title)

	var instructions: Label = Label.new()
	instructions.text = str(data["tip"])
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(instructions)

	var menu_button: Button = Button.new()
	menu_button.text = "Level Select"
	menu_button.custom_minimum_size = Vector2(140.0, 42.0)
	menu_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu_button.pressed.connect(_go_to_level_select)
	top_bar.add_child(menu_button)


func _create_platform(platform_name: String, platform_position: Vector2, platform_size: Vector2) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.name = platform_name
	body.position = platform_position
	body.collision_layer = 1
	body.collision_mask = 0

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = BLOCK_TEXTURE
	sprite.scale = Vector2(platform_size.x / 64.0, platform_size.y / 64.0)
	body.add_child(sprite)

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = platform_size
	collision.shape = shape
	body.add_child(collision)

	return body


func _on_goal_body_entered(body: Node2D) -> void:
	if body is Player:
		_go_to_level_select()


func _go_to_level_select() -> void:
	get_tree().change_scene_to_file("res://UI/level_select.tscn")


# -----------------------------
# Level layouts
# -----------------------------
func _platform(platform_name: String, platform_position: Vector2, platform_size: Vector2) -> Dictionary:
	return {
		"name": platform_name,
		"position": platform_position,
		"size": platform_size,
	}


func _get_level_data(index: int) -> Dictionary:
	var levels: Array[Dictionary] = [
		{
			"title": "First Steps",
			"tip": "Move right, jump over the gap, then touch the yellow goal marker.",
			"player_spawn": Vector2(80, 320),
			"goal": Vector2(1040, 292),
			"enemies": [],
			"platforms": [
				_platform("StartFloor", Vector2(260, 360), Vector2(520, 40)),
				_platform("GapLanding", Vector2(820, 360), Vector2(500, 40)),
			],
		},
		{
			"title": "Jump Control",
			"tip": "Tap jump for a short hop. Hold jump for a higher jump.",
			"player_spawn": Vector2(80, 320),
			"goal": Vector2(1160, 176),
			"enemies": [],
			"platforms": [
				_platform("Floor", Vector2(280, 360), Vector2(560, 40)),
				_platform("LowHop", Vector2(620, 308), Vector2(170, 24)),
				_platform("MidHop", Vector2(860, 252), Vector2(170, 24)),
				_platform("HighHop", Vector2(1120, 220), Vector2(220, 24)),
			],
		},
		{
			"title": "Double Jump",
			"tip": "Press jump again in the air to double jump across wider gaps.",
			"player_spawn": Vector2(80, 320),
			"goal": Vector2(1230, 172),
			"enemies": [],
			"platforms": [
				_platform("Start", Vector2(220, 360), Vector2(440, 40)),
				_platform("IslandA", Vector2(610, 300), Vector2(160, 24)),
				_platform("IslandB", Vector2(900, 250), Vector2(160, 24)),
				_platform("GoalPlatform", Vector2(1220, 215), Vector2(260, 24)),
			],
		},
		{
			"title": "Dash Gap",
			"tip": "Press Shift to dash across the long gap.",
			"player_spawn": Vector2(80, 320),
			"goal": Vector2(1310, 292),
			"enemies": [],
			"platforms": [
				_platform("Start", Vector2(230, 360), Vector2(460, 40)),
				_platform("TinySafe", Vector2(690, 335), Vector2(90, 24)),
				_platform("Landing", Vector2(1120, 360), Vector2(520, 40)),
			],
		},
		{
			"title": "Wall Work",
			"tip": "Slide on the wall, then press jump to wall jump up the shaft.",
			"player_spawn": Vector2(120, 510),
			"goal": Vector2(600, 132),
			"enemies": [],
			"camera_bottom": 820,
			"platforms": [
				_platform("Bottom", Vector2(280, 560), Vector2(560, 40)),
				_platform("LeftTower", Vector2(310, 400), Vector2(40, 280)),
				_platform("RightTower", Vector2(430, 355), Vector2(40, 370)),
				_platform("TopExit", Vector2(610, 178), Vector2(300, 24)),
			],
		},
		{
			"title": "First Enemy",
			"tip": "Press J or left mouse to attack. Watch the enemy attack timing.",
			"player_spawn": Vector2(80, 320),
			"goal": Vector2(1180, 292),
			"enemies": [Vector2(650, 320)],
			"platforms": [
				_platform("Arena", Vector2(620, 360), Vector2(1180, 40)),
				_platform("LeftWall", Vector2(20, 250), Vector2(40, 260)),
				_platform("RightWall", Vector2(1220, 250), Vector2(40, 260)),
			],
		},
		{
			"title": "Slash Angles",
			"tip": "Hold W and attack to slash up. Hold S and attack to slash down.",
			"player_spawn": Vector2(80, 320),
			"goal": Vector2(1260, 160),
			"enemies": [Vector2(520, 320), Vector2(940, 190)],
			"platforms": [
				_platform("Floor", Vector2(420, 360), Vector2(820, 40)),
				_platform("HighEnemy", Vector2(940, 260), Vector2(220, 24)),
				_platform("GoalPlatform", Vector2(1260, 205), Vector2(220, 24)),
			],
		},
		{
			"title": "Pogo Bridge",
			"tip": "Down slash an enemy while airborne to pogo upward across the gap.",
			"player_spawn": Vector2(80, 320),
			"goal": Vector2(1300, 292),
			"enemies": [Vector2(610, 325), Vector2(850, 325)],
			"platforms": [
				_platform("Start", Vector2(230, 360), Vector2(460, 40)),
				_platform("EnemyBridgeA", Vector2(610, 365), Vector2(130, 24)),
				_platform("EnemyBridgeB", Vector2(850, 365), Vector2(130, 24)),
				_platform("Landing", Vector2(1220, 360), Vector2(420, 40)),
			],
		},
		{
			"title": "Mixed Route",
			"tip": "Chain run, jump, double jump, dash, and wall jump together.",
			"player_spawn": Vector2(80, 450),
			"goal": Vector2(1390, 120),
			"enemies": [Vector2(700, 430), Vector2(1160, 250)],
			"camera_bottom": 820,
			"camera_right": 1600,
			"platforms": [
				_platform("Start", Vector2(260, 490), Vector2(520, 40)),
				_platform("DashIsland", Vector2(650, 430), Vector2(220, 24)),
				_platform("WallLeft", Vector2(870, 330), Vector2(40, 260)),
				_platform("WallRight", Vector2(1040, 270), Vector2(40, 340)),
				_platform("UpperFight", Vector2(1210, 290), Vector2(340, 24)),
				_platform("GoalPlatform", Vector2(1420, 165), Vector2(260, 24)),
			],
		},
		{
			"title": "Final Trial",
			"tip": "Final test: movement control, dash, wall jump, angle attacks, and enemy AI.",
			"player_spawn": Vector2(80, 510),
			"goal": Vector2(1720, 108),
			"enemies": [Vector2(560, 510), Vector2(980, 330), Vector2(1380, 190)],
			"camera_bottom": 860,
			"camera_right": 1900,
			"platforms": [
				_platform("Start", Vector2(280, 560), Vector2(560, 40)),
				_platform("CombatFloor", Vector2(620, 560), Vector2(260, 40)),
				_platform("DashIsland", Vector2(910, 485), Vector2(150, 24)),
				_platform("WallLeft", Vector2(1100, 370), Vector2(40, 300)),
				_platform("WallRight", Vector2(1270, 315), Vector2(40, 380)),
				_platform("HighCombat", Vector2(1430, 230), Vector2(360, 24)),
				_platform("LastJump", Vector2(1690, 155), Vector2(260, 24)),
			],
		},
	]

	return levels[clamp(index - 1, 0, levels.size() - 1)]
