extends Node

signal game_over(won)

const PIXEL_UNIT: int = 16

const sfx: Dictionary = {
	rooster = preload("res://assets/audio/sfx/rooster.ogg"),
	pause = preload("res://assets/audio/sfx/pause.ogg"),
	block = preload("res://assets/audio/sfx/Block Break 1.ogg"),
	explosion = preload("res://assets/audio/sfx/explosion1.ogg"),
	collect = preload("res://assets/audio/sfx/Big Egg collect 1.ogg"),
	clock_tick = preload("res://assets/audio/sfx/clock_tick.ogg"),
	chic_jump = preload("res://assets/audio/sfx/Jump 1.ogg"),
	chic_flying = preload("res://assets/audio/sfx/flying.ogg"),
	chic_jump_looped = preload("res://assets/audio/sfx/Jump looped.ogg"),
}
const bgm: Dictionary = {
	main = preload("res://assets/audio/bgm/level_jingle.ogg"),
	main2 = preload("res://assets/audio/bgm/JDSherbert - Minigame Music Pack - Beach Vibes.ogg"),
	menu = preload("res://assets/audio/bgm/JDSherbert - Nostalgia Music Pack - Saturday Morning Cartoons.ogg")
}

enum Colors {WHITE, YELLOW, RED, BLUE, PINK, GREEN }

const chic_colors: Dictionary = {
	Colors.BLUE: Color("#11adc1"),
	Colors.YELLOW: Color("#f7e476"),
	Colors.RED: Color("#cb4d68"),
	Colors.PINK: Color("#f7a4c4"),
	Colors.GREEN: Color("#5bb361"),
	Colors.WHITE: Color.WHITE
}
const bear_colors: Dictionary = {
	skin_dark = Color("#72471c"),
	skin_light = Color("#b28146")
}

const grass_colors: Dictionary = {
	light = Color("#5bb361"),
	dark = Color("#1e8875")
}

const chic_outline_color: Color = Color("#393457")


var time_scale: float = 1: set = set_time_scale
var cam: Camera2D
var can_pause: bool = true

func _ready():
	SoundController.set_music_volume(1)
	SoundController.set_sound_volume(1)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var pause_node = load("res://src/ui/Pause/pause.tscn")
	add_sibling.call_deferred(pause_node.instantiate())
	
	cam = Camera2D.new()
	
	cam.enabled = true
	cam.zoom = Vector2.ONE * 3
	add_sibling.call_deferred(cam)
	
	randomize()

func _notification(what):
	
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			get_tree().quit() # default behavior
	
func _unhandled_input(event):
	if event.is_action("ui_cancel") and not get_tree().paused and can_pause:
		SoundController.play_sound(sfx.pause)
		get_tree().paused = true


func set_time_scale(_time_scale: float = 1):
	time_scale = clamp(_time_scale, .2, 1.0)
	Engine.time_scale = time_scale
	AudioServer.playback_speed_scale = 2.0 - time_scale

func flood_fill(color_map: Dictionary = {}, start: Vector2 = Vector2.ZERO, target_color: int = -1):
	
	if not color_map.has(start):
		return color_map
	
	var queue: Array[Vector2] = []
	var starting_color = color_map[start]
	queue.append(start)
	
	while not queue.is_empty():
		# paint current node with target color
		var curr = queue.pop_front()
		color_map[curr] = target_color
		
		# insert neighbors

		for n in [
			Vector2(curr.x - 1, curr.y),
			Vector2(curr.x + 1, curr.y),
			Vector2(curr.x, curr.y - 1),
			Vector2(curr.x, curr.y + 1),
		]:
			# we only visit neighbors of the same color we are checking
			if color_map.has(n) and color_map[n] == starting_color:
				queue.append(n)

	return color_map

func is_winning_board(grass: TileMap, nest: Node2D):
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
	
	return groups == colors.size()
