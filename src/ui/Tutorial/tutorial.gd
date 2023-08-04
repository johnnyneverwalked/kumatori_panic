extends Node2D

signal return_to_menu

@export var back_btn: Button

@onready var grass: TileMap = $Grass
@onready var nest: Node2D = $Nest
@onready var ui: CanvasLayer = $CanvasLayer
@onready var controls: VBoxContainer = $CanvasLayer/Text/Controls
@onready var lbl: RichTextLabel = $CanvasLayer/Text/Label

var chic_node = load("res://src/game/Chic/chic.tscn")
var bear_node = load("res://src/game/Bear/bear.tscn")
var bear: Bear
var bounds: Rect2
var tutorial_tween: Tween
var completed: bool

var tutorial_steps: Array[Dictionary] = [
	{
		delay = .5, 
		text = "[center]Oh dear! Looks like the baby chicks have fled the coop.[/center]"
	},
	{
		delay = 3, 
		text = "[center]It's up to Bear to return them home.[/center]"
	},
	{
		delay = 3, 
		text = "[center]Help Bear gather up all of his fluffy friends by matching chickens of the same color.[/center]"
	},
	{
		delay = 3, 
		text = "[center]Be careful! If the time runs out they will run away.[/center]"
	},
	{
		delay = 5, 
		text = "[center]You can look around by using the ARROW keys.[/center]"
	},
	{delay = 1, method = "set_hands_position", args = [Vector2.DOWN]},
	{delay = .5, method = "set_hands_position", args = [Vector2.LEFT]},
	{delay = .5, method = "set_hands_position", args = [Vector2.UP]},
	{delay = .5, method = "set_hands_position", args = [Vector2.RIGHT]},
	{
		delay = 1, 
		text = "[center]Press [SPACE] to pick up a chick[/center]"
	},
	{delay = 1, method = "pickup", args = []},
	{
		delay = 1, 
		text = "[center]Press [SPACE] again to put it back down[/center]"
	},
	{delay = 1, method = "pickup", args = []},
	{
		delay = 2, 
		text = "[center]This way you can also swap the chick you are holding[/center]"
	},
	{delay = 1, method = "pickup", args = []},
	{delay = 1, method = "set_hands_position", args = [Vector2.DOWN]},
	{delay = 1, method = "pickup", args = []},
	{delay = 1, method = "pickup", args = []},
	{delay = .5, method = "set_hands_position", args = [Vector2.RIGHT]},
	{
		delay = 1, 
		text = "[center]You can move bear with [WASD][/center]"
	},
	{delay = 2, method = "move", args = [Vector2.RIGHT]},
	{delay = .5, method = "move", args = [Vector2.LEFT]},
	{
		delay = 1, 
		text = "[center]Moving to a square with a chick will cause it to swap places with bear[/center]"
	},
	{delay = 3, method = "move", args = [Vector2.LEFT]},
	{delay = .5, method = "move", args = [Vector2.RIGHT]},
	{
		delay = 1, 
		text = "[center]You can hold [SHIFT] to pick it up instead.[/center]"
	},
	{delay = 2, method = "move", args = [Vector2.LEFT, true]},
	{
		delay = 1, 
		text = "[center]If you do, bear will drop the chick it currently holds.[/center]"
	},
	{delay = 3, method = "move", args = [Vector2.RIGHT, true]},
	{delay = 1, method = "pickup", args = []},
	{
		delay = 1, 
		text = "[center]The goal is to group all the same colored chics together.[/center]"
	},
	{
		delay = 4, 
		text = "[center]Like this![/center]"
	},
	{delay = 2, method = "set_hands_position", args = [Vector2.UP]},
	{delay = .5, method = "pickup", args = []},
	{delay = .5, method = "set_hands_position", args = [Vector2.DOWN]},
	{delay = .5, method = "pickup", args = []},
	{delay = .5, method = "set_hands_position", args = [Vector2.UP]},
	{delay = .5, method = "pickup", args = []},
	{
		delay = 2, 
		text = "[center]Careful though, diagonals do not count[/center]"
	}, 
	{
		delay = 2, 
		text = "[center]Go ahead, try it![/center]"
	},
]

var grid_contents: Array = [
	[
		GameManager.Colors.RED,
		GameManager.Colors.YELLOW,
		GameManager.Colors.RED,
		GameManager.Colors.RED,
		null,
		GameManager.Colors.YELLOW,
		GameManager.Colors.YELLOW,
		GameManager.Colors.RED,
		GameManager.Colors.YELLOW,
	],
	[
		null,
		GameManager.Colors.YELLOW,
		GameManager.Colors.RED,
		GameManager.Colors.RED,
		GameManager.Colors.YELLOW,
		GameManager.Colors.RED,
		GameManager.Colors.YELLOW,
		GameManager.Colors.RED,
		GameManager.Colors.YELLOW,
	],
]

# Called when the node enters the scene tree for the first time.
func _ready():
	completed = false
	if tutorial_tween != null:
		tutorial_tween.kill()

	tutorial_tween = create_tween()
	tutorial_tween.stop()

	generate_level(grid_contents[0])

	
	for _step in tutorial_steps:
		var step = _step.duplicate(true)
		if step.has("text"):
			tutorial_tween.tween_property(lbl, "text", step.text, 0).set_delay(step.delay)
			continue
		if not step.has("target"):
			step.target = bear
		var callable = step.target.get(step.method)
		tutorial_tween.tween_callback(callable.bindv(step.args)).set_delay(step.delay)
	
	tutorial_tween.play()
	
	tutorial_tween.finished.connect(func(): 
		generate_level(grid_contents[1])
		bear.disable_inputs = false
		controls.visible = true
		bear.unlock.connect(func():
			if not GameManager.is_winning_board(grass, nest):
				return
			GameManager.game_over.emit(true)
			completed = true
			lbl.text = "[center]Congratulations! You are now ready. press [ESC] to return to the main menu[/center]"
		)
	)
	
func generate_level(contents: Array):
	for node in nest.get_children():
		node.queue_free()
	if bear != null:
		bear.queue_free()
		bear = null
	
	var chic: Chic
	var grid: Vector2 = Vector2.ONE * 3
	grass.place_cells(grid)
	
	bounds = Rect2(grass.get_used_rect())
	bounds.position = bounds.position * GameManager.PIXEL_UNIT * 2 + grass.global_position
	bounds.size = bounds.size * GameManager.PIXEL_UNIT * 2
	
	var normalised_cell: Vector2 = grass.get_used_rect().position
	var cells = grass.get_used_cells(0)
	cells.append_array(grass.get_used_cells(1))
	queue_redraw()

	
	for index in contents.size():
		var color = contents[index]
		var pos = Vector2(index % int(grid.x), floor(index / grid.y)) + normalised_cell
		if not color:
			bear = bear_node.instantiate()
			bear.disable_inputs = true
			bear.bounds = bounds
			bear.place_chic.connect(place_chic)
			bear.locked = false
			_place_at(pos, bear, self)
			continue
		chic = chic_node.instantiate()
		chic.color = color
		_place_at(pos, chic, nest)

func _place_at(pos: Vector2, entity, parent):
	var world_pos = Vector2(pos) * GameManager.PIXEL_UNIT * 2 + grass.global_position + Vector2.ONE * GameManager.PIXEL_UNIT
	parent.add_child(entity)
	entity.global_position = world_pos

func place_chic(chic: Chic):
	if not chic:
		return
	nest.add_child(chic)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		return_to_menu.emit()


func _process(_delta):
	if ui.visible != visible:
		ui.visible = visible
	if not visible and tutorial_tween != null and tutorial_tween.is_valid():
		tutorial_tween.stop()

func _draw():
	if bounds != null:
		var rect = Rect2(bounds.position, bounds.size + Vector2.DOWN * GameManager.PIXEL_UNIT / 2)
		draw_rect(rect, GameManager.chic_outline_color, false, 4.0)
