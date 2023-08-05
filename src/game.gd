extends Node2D

@onready var grass: TileMap = $Grass
@onready var bg: TextureRect = $Bg
@onready var camera: Camera2D = GameManager.cam
@onready var nest: Node2D = $Nest
@onready var timer := $EggTimer

@onready var stage_lbl: Label = $ui/MarginContainer/VBoxContainer/Stage
@onready var collected_lbl: Label = $ui/MarginContainer/VBoxContainer/Collected
@onready var dialog: Window = $ui/Dialog
@onready var zen_dialog: Window = $ui/zen_dialog
@onready var zen_dialog_btn: Button = $ui/zen_dialog/MarginContainer/VBoxContainer/HBoxContainer/ok

@export var zen_mode: bool

var chic_node = load("res://src/game/Chic/chic.tscn")
var bear_node = load("res://src/game/Bear/bear.tscn")
var bear: Bear
var bounds

var locked: bool
var level_start_time: int
var grid:= Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.can_pause = true
	SoundController.play_music(GameManager.bgm.main2)
	randomize()
	
	if GameManager.GAME_DATA.game_state.zen_mode_played or not zen_mode:
		zen_dialog.queue_free()
	if zen_mode:
		dialog.queue_free()
		timer.visible = false
		$Coop.modulate.a = 0
		stage_lbl.visible = false

		if is_instance_valid(zen_dialog) and false:
			GameManager.GAME_DATA.game_state.zen_mode_played = true
			zen_dialog.popup_centered()
			zen_dialog_btn.grab_focus()
			zen_dialog_btn.pressed.connect(func(): 
				zen_dialog.hide()
				zen_dialog.queue_free()
			)
			await zen_dialog.visibility_changed

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
		timer.stop()
		if (won):
			gather_chics() 
			return
		
		await get_tree().create_timer(2).timeout
		leave_chics()
	)
	
	if zen_mode:
		generate_random_level()
	else:
		generate_scripted_level()

func _unhandled_input(event):
	if not locked and event.is_action_pressed("debug"):
		generate_random_level()

func _draw():
	if bounds != null:
		var rect = Rect2(bounds.position, bounds.size + Vector2.DOWN * GameManager.PIXEL_UNIT / 2)
		draw_rect(rect, GameManager.chic_outline_color, false, 4.0)


func generate_scripted_level():
	GameManager.can_pause = false
	locked = true
	
	var level: Image = load(GameManager.GAME_DATA.levels_folder_path + "test" + ".png").get_image()
	
	grid = Vector2(level.get_size())
	bounds = null
	queue_redraw()
	
	var contents: Array = []
	for y in grid.y:
		for x in grid.x:
			var pixel_color:Color = level.get_pixel(x, y)

			if pixel_color.is_equal_approx(Color.BLACK):
				contents.append(null)
				continue
	
			for color in GameManager.chic_colors.keys():
				if pixel_color.is_equal_approx(GameManager.chic_colors[color]):
					contents.append(color)
					break
	
	bear = GameManager.generate_level(self, grid, contents, grass, nest, bear)
	handle_post_level_generation()


func generate_random_level():
	GameManager.can_pause = false
	locked = true
	
#	grid = Vector2(
#		randi_range(GameManager.GAME_DATA.settings.zen_mode.min_grid.x, GameManager.GAME_DATA.settings.zen_mode.max_grid.x),
#		randi_range(GameManager.GAME_DATA.settings.zen_mode.min_grid.y, GameManager.GAME_DATA.settings.zen_mode.max_grid.y),
#	)
	grid = Vector2(max(3, grid.x + 1), max(3, grid.y + 1))
	if grid == Vector2.ONE * 9:
		_on_cancel_pressed()
		return
	bounds = null
	queue_redraw()
	
	var contents: Array = []
	
	# ChatGPT shenannigans for this one:
	# The first part of the formula calculates the color count based on the larger dimension (max(x, y)) just like before.
	# The second part of the formula calculates the color count based on the smaller dimension (min(x, y)), and we subtract 2 to avoid double counting the overlapping colors between the larger and smaller dimensions.
	# Finally we add the results of the two parts to get the total color count while ensuring the maximum color count is 6.
	# Finally we substract 1 because the color index is zero based.
	var available_colors: int = min(2 + floor((max(grid.x, grid.y) - 3) / 2.0), 6) + min(2 + floor((min(grid.x, grid.y) - 3) / 2.0), 6) - 2
	
	var grid_size = grid.y * grid.x
	
	# Add the bear
	contents.append(null)
	
	# Add 3 chics for each available color to ensure variety
	for color in range(available_colors):
		for _i in range(3):
			contents.append(color)
			
	# fill the rest of board with random chics
	if grid_size > contents.size():
		for _i in range(contents.size(), grid_size):
			contents.append(randi_range(0, available_colors - 1))
	
	var reshuffle = true
	# shuffle the grid until it is not in a winning state
	while reshuffle:
		randomize()
		contents.shuffle()
		bear = GameManager.generate_level(self, grid, contents, grass, nest, bear)
		reshuffle = GameManager.is_winning_board(grass, nest)

	handle_post_level_generation()
	

func handle_post_level_generation():
	bear.place_chic.connect(place_chic)
	bear.unlock.connect(func():
		if GameManager.is_winning_board(grass, nest):
			GameManager.game_over.emit(true)
	)
	bounds = bear.bounds
	
	await get_tree().create_timer(.5).timeout
	locked = false
	bear.locked = false
	bear.disable_inputs = false
	queue_redraw()
	level_start_time = Time.get_ticks_msec()
	GameManager.can_pause = true


func place_chic(chic: Chic):
	if chic:
		nest.add_child(chic)

func gather_chics():
	var total_level_time: float = (Time.get_ticks_msec() - level_start_time) / 1000.0
	GameManager.GAME_DATA.save_level_time(grid, total_level_time)
	var tween = get_tree().create_tween().set_parallel(true)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_SINE)
	tween.pause()
	SoundController.sfxPlayer.pitch_scale = 1.5
	SoundController.play_sound(GameManager.sfx.chic_flying, false)
	var i: int = 0
	for chic in nest.get_children():
		chic.sprite.play("walk")
		chic.scale.x = -1
		chic.z_index = 3
		chic.z_as_relative = false
		tween.tween_property(chic, "global_position", $Coop.global_position + Vector2.DOWN * GameManager.PIXEL_UNIT * 1.25, 1).set_delay(.05 * i)
		tween.tween_property(chic.shadow, "visible", false, 0).set_delay(.05 * i)
		tween.tween_property(chic, "scale", Vector2.ZERO, .75).set_delay(.5 + .05 * i)

		i += 1
	tween.play()
	
	if zen_mode:
		create_tween()\
			.tween_property($Coop, "modulate:a", 1.0, .5)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
	
	tween.finished.connect(func(): 
		if not GameManager.GAME_DATA.game_state.has("total_chics"):
			GameManager.GAME_DATA.game_state.total_chics = 0
		GameManager.GAME_DATA.game_state.total_chics += grid.x * grid.y - 1
		collected_lbl.text = collected_lbl.text.split(": ")[0] + ": " + str(GameManager.GAME_DATA.game_state.total_chics)
		if zen_mode:
			create_tween()\
				.tween_property($Coop, "modulate:a", 0.0, .5)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN)
			generate_random_level()
			return
		show_win_lose_dialog(true)
	)

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
		tween.tween_property(chic, "global_position:x", dir * randi_range(0, screen_coords.x * 2) / 2.0, 1.5)
		tween.tween_property(chic.shadow, "visible", false, 0)
		tween.tween_property(chic, "global_position:y", -screen_coords.y, 1.5)
	tween.finished.connect(func(): show_win_lose_dialog(false))

func show_win_lose_dialog(won: bool):
	if not is_instance_valid(dialog):
		return
	var label: Label = $ui/Dialog/MarginContainer/VBoxContainer/Label
	var ok_btn: Button = $ui/Dialog/MarginContainer/VBoxContainer/HBoxContainer/ok
	var cancel_btn: Button = $ui/Dialog/MarginContainer/VBoxContainer/HBoxContainer/cancel
	
	if not won:
		label.text = "OH no, time's up! \n the chics have ran away!"
		cancel_btn.text = "Exit level"
		ok_btn.grab_focus()
	else:
		label.text = "HOORAY! \n the chics are back in the coop. \n how nice!"
		cancel_btn.text = "Next level"
		cancel_btn.grab_focus()
		
	dialog.popup_centered()

func restart():
	$ui/Dialog.hide()
	
	if not zen_mode:
		generate_scripted_level()
		$EggTimer.start()
		if not SoundController.bgmPlayer.playing:
			SoundController.play_music(GameManager.bgm.main2)
		return
	
	generate_random_level()
	if not SoundController.bgmPlayer.playing:
		SoundController.play_music(GameManager.bgm.main2)


func _on_ok_pressed():
	restart()


func _on_cancel_pressed():
	SoundController.bgmPlayer.stop()
	get_tree().change_scene_to_packed(load("res://src/start.tscn"))


func _on_export_pressed():
	var level = Image.create(grid.x, grid.y, false, Image.FORMAT_RGBA8)
	var normalised_cell: Vector2 = grass.get_used_rect().position
	for x in grid.x:
		for y in grid.y:
			var world_pos = (Vector2(x, y) + normalised_cell) * GameManager.PIXEL_UNIT * 2 + grass.global_position + Vector2.ONE * GameManager.PIXEL_UNIT
			if bear.global_position == world_pos:
				level.set_pixel(x, y, Color.BLACK)
				continue
			for chic in nest.get_children():
				if chic is Chic and chic.global_position == world_pos:
					level.set_pixel(x, y, GameManager.chic_colors[chic.color])

	level.save_png("res://src/resources/levels/" + str(grid.x) + "_" + str(grid.y) + ".png")
