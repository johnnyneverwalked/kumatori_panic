extends Node2D

signal return_to_menu

@export var back_btn: Button

@onready var grass: TileMap = $Grass
@onready var nest: Node2D = $Nest
@onready var ui: CanvasLayer = $CanvasLayer
@onready var controls: VBoxContainer = $CanvasLayer/Text/Controls
@onready var lbl: RichTextLabel = $CanvasLayer/Text/Label


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
		delay = 4, 
		text = "[center]Help Bear gather up all of his fluffy friends by matching chickens of the same color.[/center]"
	},
	{
		delay = 3, 
		text = "[center]Be careful! If the time runs out they will run away.[/center]"
	},
	{
		delay = 4, 
		text = "[center]You can look around by using the [%action%].[/center]",
		action = func(is_keyboard: bool): return "ARROW keys" if is_keyboard else "RIGHT STICK"
	},
	{delay = 1, method = "set_hands_position", args = [Vector2.DOWN]},
	{delay = .5, method = "set_hands_position", args = [Vector2.LEFT]},
	{delay = .5, method = "set_hands_position", args = [Vector2.UP]},
	{delay = .5, method = "set_hands_position", args = [Vector2.RIGHT]},
	{
		delay = 1, 
		text = "[center]Press [%action%] to pick up a chick[/center]",
		action = func(is_keyboard: bool): return "SPACE" if is_keyboard else "A or R1"
	},
	{delay = 1, method = "pickup", args = []},
	{
		delay = 1, 
		text = "[center]Press [%action%] again to put it back down[/center]",
		action = func(is_keyboard: bool): return "SPACE" if is_keyboard else "A or R1"
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
		text = "[center]You can move bear with [%action%][/center]",
		action = func(is_keyboard: bool): return "WASD" if is_keyboard else "LEFT STICK"
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
		text = "[center]You can hold [%action%] to pick it up instead.[/center]",
		action = func(is_keyboard: bool): return "SHIFT" if is_keyboard else "X or L1"
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
		text = "[center]The goal is to group all the same colored chicks together.[/center]"
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

	bear = GameManager.generate_level(self, Vector2.ONE * 3, grid_contents[0], grass, nest, bear)
	bear.place_chic.connect(place_chic)
	bounds = bear.bounds
	queue_redraw()
	
	for _step in tutorial_steps:
		var step = _step.duplicate(true)
		if step.has("text"):
			if step.has("action") and step.action is Callable and step.text.contains("%action%"):
				step.text = step.text.replace("%action%", step.get("action").call(not Input.get_connected_joypads().size()))
			tutorial_tween.tween_property(lbl, "text", step.text, 0).set_delay(step.delay)
			continue
		if not step.has("target"):
			step.target = bear
		var callable = step.target.get(step.method)
		tutorial_tween.tween_callback(callable.bindv(step.args)).set_delay(step.delay)
	
	tutorial_tween.play()
	
	tutorial_tween.finished.connect(func(): 
		bear = GameManager.generate_level(self, Vector2.ONE * 3, grid_contents[1], grass, nest, bear)
		bounds = bear.bounds
		queue_redraw()
		bear.place_chic.connect(place_chic)
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
