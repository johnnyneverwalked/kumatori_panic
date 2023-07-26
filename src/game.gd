extends Node2D

@onready var grass: TileMap = $Grass
@onready var bg: TextureRect = $Bg
@onready var camera: Camera2D = GameManager.cam
@onready var nest: Node2D = $Nest

var chic_node = load("res://src/game/Chic/chic.tscn")
var bear_node = load("res://src/game/Bear/bear.tscn")
var bear: Bear
var bounds

var locked: bool
var grid:= Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	SoundController.play_music(GameManager.bgm.main)
	randomize()
	var tween = get_tree().create_tween().set_loops()\
	.set_trans(Tween.TRANS_SINE)\
	.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		bg, 
		"global_position", 
		Vector2(
			bg.global_position.x, 
			-get_viewport_rect().size.y / (camera.zoom.y * 2.0)
		),
		60
	).set_delay(15)
	tween.tween_property(
		bg, 
		"global_position", 
		bg.global_position, 
		60
	).set_delay(15)
	
	GameManager.game_over.connect(func(won):
		if (won):
			gather_chics() 
			return
		
		await get_tree().create_timer(2).timeout
		leave_chics()
	)
	
	generate_level(Vector2.ONE * 8)

func _unhandled_input(event):
	if not locked and event.is_action_pressed("debug"):
		generate_level()


func generate_level(_grid: Vector2 = Vector2.ZERO):
	locked = true

	if not (_grid.x > 0 and _grid.y > 0):
		_grid = Vector2(randi_range(3, 8), randi_range(3, 8))
	grid = _grid
	
	var available_colors: int = min(GameManager.Colors.size() - 1, max(1, floor((grid.x + grid.y) / 3 - .5)))
		
	for chic in nest.get_children():
		chic.queue_free()
		
	if bear: 
		bear.queue_free()
	
	bounds = null
	queue_redraw()
	
		
	grass.place_cells(grid)
	
	bounds = Rect2(grass.get_used_rect())
	bounds.position = bounds.position * GameManager.PIXEL_UNIT * 2 + grass.global_position
	bounds.size = bounds.size * GameManager.PIXEL_UNIT * 2
	queue_redraw()
	
	var cells = grass.get_used_cells(0)
	cells.append_array(grass.get_used_cells(1))
	
	
	var bear_position = cells[randi_range(0, cells.size() - 1)]
	
	for cell in cells:
		var world_pos = Vector2(cell) * GameManager.PIXEL_UNIT * 2 + grass.global_position + Vector2.ONE * GameManager.PIXEL_UNIT
		
		if cell == bear_position:
			bear = bear_node.instantiate()
			bear.bounds = bounds
			bear.locked = true
			add_child(bear)	
			bear.place_chic.connect(place_chic)
			bear.unlock.connect(check_board)
			bear.global_position = world_pos
			continue
			
		var chic = chic_node.instantiate()
		chic.color = randi_range(0, available_colors)
		nest.add_child(chic)
		chic.global_position = world_pos
		await get_tree().create_timer(.01).timeout
	
	await get_tree().create_timer(max(.01, .5 - cells.size() * .01)).timeout
	locked = false
	bear.locked = false
	queue_redraw()

func place_chic(chic: Chic):
	if not chic:
		return
	nest.add_child(chic)

func gather_chics():
	pass

func leave_chics():
	var dir: int
	var screen_coords = get_viewport_rect().size / GameManager.cam.zoom
	var tween = get_tree().create_tween().set_parallel(true)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_SINE)
	SoundController.sfxPlayer.pitch_scale = 1.5
	SoundController.play_sound(GameManager.sfx.chic_flying, false)
	for chic in nest.get_children():
		randomize()
		dir = 1 if randi() % 2 else -1
		chic.fly()
		chic.scale.x = -dir
		chic.z_index = 3
		chic.z_as_relative = false
		tween.tween_property(chic, "global_position:x", dir * randi_range(0, screen_coords.x * 2) / 2, 1.5)
		tween.tween_property(chic, "global_position:y", -screen_coords.y, 1.5)

func check_board():
	# the total found color groups in the map
	var groups: int = 0
	
	# the colors based on chic positions
	var color_map: Dictionary = {}
	
	# the total unique chic colors
	var colors: Array[int] = []
	
	# The number of chics in the map
	var total_chics = grass.get_used_rect().size.x * grass.get_used_rect().size.y - 1
	
	for chic in nest.get_children():
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
	var winning: bool = groups == colors.size()

func _draw():
	if bounds != null:
		var rect = Rect2(bounds.position, bounds.size + Vector2.DOWN * GameManager.PIXEL_UNIT / 2)
		draw_rect(rect, GameManager.chic_outline_color, false, 4.0)

		
