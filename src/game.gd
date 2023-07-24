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
	if not locked and event.is_action_pressed("debug"):
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
			bear.place_chic.connect(place_chic)
			bear.unlock.connect(check_board)
			bear.global_position = world_pos
			continue
			
		var chic = chic_node.instantiate()
		chic.color = randi_range(0, GameManager.Colors.size() - 1)
		$Nest.add_child(chic)
		chic.global_position = world_pos
		await get_tree().create_timer(.01).timeout
		
		var lbl = Label.new()
		lbl.text = str(Vector2(grass.local_to_map(grass.to_local(chic.global_position))))
		lbl.scale = .5 * Vector2.ONE
		chic.add_child(lbl)
	
	await get_tree().create_timer(max(.01, .5 - cells.size() * .01)).timeout
	locked = false

func place_chic(chic: Chic):
	if not chic:
		return
	$Nest.add_child(chic)

func check_board():
	# the total found color groups in the map
	var groups: int = 0
	
	# the colors based on chic positions
	var color_map: Dictionary = {}
	
	# the total unique chic colors
	var colors: Array[int] = []
	
	# The number of chics in the map
	var total_chics = grass.get_used_rect().size.x * grass.get_used_rect().size.y - 1
	
	for chic in $Nest.get_children():
		color_map[Vector2(grass.local_to_map(grass.to_local(chic.global_position)))] = chic.color
		if not colors.has(chic.color):
			colors.append(chic.color)
	
	var check_pos: Vector2 = color_map.keys()[0]
	
	# check validity only if the bear is not holding a chic
	var recheck: bool = total_chics == color_map.size()
	while recheck:
		color_map = GameManager.flood_fill(color_map, check_pos)

		# every time we flood fill a color we increment groups 
		groups += 1
		recheck = false
		
		# only continue checking if there are unvisited positions
		for pos in color_map.keys():
			if color_map[pos] == -1:
				continue
			check_pos = pos
			recheck = true
			break

	# If all the chics are on the ground and all same colored ones are grouped together we win
	print_debug("WINNIG STATE: ", str(groups == colors.size()))
