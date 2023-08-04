extends Node2D

@onready var grass: TileMap = $Grass
@onready var bg: TextureRect = $Bg
@onready var camera: Camera2D = GameManager.cam
@onready var nest: Node2D = $Nest
@onready var timer := $EggTimer

var chic_node = load("res://src/game/Chic/chic.tscn")
var bear_node = load("res://src/game/Bear/bear.tscn")
var bear: Bear
var bounds

var locked: bool
var grid:= Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	SoundController.play_music(GameManager.bgm.main2)
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
		timer.stop()
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

func _draw():
	if bounds != null:
		var rect = Rect2(bounds.position, bounds.size + Vector2.DOWN * GameManager.PIXEL_UNIT / 2)
		draw_rect(rect, GameManager.chic_outline_color, false, 4.0)

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
			bear.unlock.connect(func():
				if GameManager.is_winning_board(grass, nest):
					GameManager.game_over.emit(true)
			)
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
	tween.finished.connect(func(): show_win_lose_dialog(true))

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
		tween.tween_property(chic.shadow, "visible", false, 0)
		tween.tween_property(chic, "global_position:y", -screen_coords.y, 1.5)
	tween.finished.connect(func(): show_win_lose_dialog(false))

func show_win_lose_dialog(won: bool):
	var dialog: Window = $ui/Dialog
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
	generate_level(grid)
	$EggTimer.start()
	if not SoundController.bgmPlayer.playing:
		SoundController.play_music(GameManager.bgm.main2)


func _on_ok_pressed():
	restart()


func _on_cancel_pressed():
	SoundController.bgmPlayer.stop()
	get_tree().change_scene_to_packed(load("res://src/ui/Menu/menu.tscn"))
