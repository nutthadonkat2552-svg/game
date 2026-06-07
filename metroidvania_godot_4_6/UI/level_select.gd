extends Control

## Simple level-select menu. Buttons load individual level scenes so friends can
## test or edit a specific tutorial step without playing from the start.

const LEVELS: Array[Dictionary] = [
	{"name": "01 First Steps", "path": "res://Levels/level_01.tscn"},
	{"name": "02 Jump Control", "path": "res://Levels/level_02.tscn"},
	{"name": "03 Double Jump", "path": "res://Levels/level_03.tscn"},
	{"name": "04 Dash Gap", "path": "res://Levels/level_04.tscn"},
	{"name": "05 Wall Work", "path": "res://Levels/level_05.tscn"},
	{"name": "06 First Enemy", "path": "res://Levels/level_06.tscn"},
	{"name": "07 Slash Angles", "path": "res://Levels/level_07.tscn"},
	{"name": "08 Pogo Bridge", "path": "res://Levels/level_08.tscn"},
	{"name": "09 Mixed Route", "path": "res://Levels/level_09.tscn"},
	{"name": "10 Final Trial", "path": "res://Levels/level_10.tscn"},
]

var grid: GridContainer


func _ready() -> void:
	grid = get_node("Center/Panel/Margin/VBox/ScrollContainer/LevelGrid") as GridContainer
	_update_grid_columns()
	for level_data: Dictionary in LEVELS:
		var button: Button = Button.new()
		button.text = str(level_data["name"])
		button.custom_minimum_size = Vector2(220.0, 58.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_load_level.bind(str(level_data["path"])))
		grid.add_child(button)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and grid != null:
		_update_grid_columns()


func _update_grid_columns() -> void:
	if grid == null:
		return

	var width: float = get_viewport_rect().size.x
	if width < 720.0:
		grid.columns = 1
	elif width < 1080.0:
		grid.columns = 2
	else:
		grid.columns = 3


func _load_level(path: String) -> void:
	get_tree().change_scene_to_file(path)
