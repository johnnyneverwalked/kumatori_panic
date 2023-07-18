extends TileMap


# Called when the node enters the scene tree for the first time.
func _ready():
	position = GameManager.PIXEL_UNIT *Vector2.ONE
	place_cells(Vector2.ONE * 15)
	


func place_cells(grid_size: Vector2 = Vector2.ONE):
	
	for cell in get_used_cells(0):
		erase_cell(0, cell)
	for cell in get_used_cells(1):
		erase_cell(1, cell)
		
	randomize()
	
	for x in grid_size.x:
		for y in grid_size.y:
			var layer = 1 if int(x) % 2 == int(y) % 2 else 0
			var normalized_cell_position = Vector2(x, y) - Vector2.ONE - floor(grid_size / 2)
			
			set_cell(layer, normalized_cell_position, layer, Vector2(randi_range(0, 2), randi_range(0, 2)))
	
	if not get_used_cells(1).size():
		return
	
	var cell_material = get_cell_tile_data(1, get_used_cells(1)[0]).material
	cell_material.set_shader_parameter("invert_color", GameManager.grass_colors.dark)
	cell_material.set_shader_parameter("main_color", GameManager.grass_colors.light)
