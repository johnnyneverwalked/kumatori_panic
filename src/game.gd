extends Node2D

@onready var grass: TileMap = $Grass

var chic_node = load("res://src/game/Chic/chic.tscn")
var bear_node = load("res://src/game/Bear/bear.tscn")
var bear: Bear

var locked: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	var grid := Vector2(randi_range(3, 12), randi_range(3, 7))	
	
	generate_level(Vector2.ONE * 8)

func _unhandled_input(event):
	if not locked and event.is_action("debug"):
		generate_level(Vector2.ONE * 3)


func generate_level(grid: Vector2 = Vector2.ZERO):
	locked = true
	if not (grid.x > 0 and grid.y > 0):
		grid = Vector2(randi_range(3,9), randi_range(3, 7))
		
	for chic in $Nest.get_children():
		chic.queue_free()
		
	if bear: 
		bear.queue_free()
	
		
	grass.place_cells(grid)
	var cells = grass.get_used_cells(0)
	cells.append_array(grass.get_used_cells(1))
	
	var bear_position = cells[randi_range(0, cells.size() - 1)]
	
	for cell in cells:
		var world_pos = Vector2(cell) * GameManager.PIXEL_UNIT * 2 + grass.global_position + Vector2.ONE * GameManager.PIXEL_UNIT
		
		if cell == bear_position:
			bear = bear_node.instantiate()
			add_child(bear)	
			bear.place_chic.connect(func(chic):
				if chic and chic is Chic:
					$Nest.add_child(chic)
			)
			bear.global_position = world_pos
			continue
			
		var chic = chic_node.instantiate()
		chic.color = randi_range(0, GameManager.Colors.size() - 1)
		$Nest.add_child(chic)
		chic.global_position = world_pos
		await get_tree().create_timer(.01).timeout
	
	await get_tree().create_timer(max(.01, .5 - cells.size() * .01)).timeout
	locked = false
