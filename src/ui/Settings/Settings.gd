extends CanvasLayer

signal settings_hidden

@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/music/music_slider
@onready var sound_slider: HSlider = $MarginContainer/VBoxContainer/sound/sound_slider
@onready var colorblind_toggle: CheckButton = $MarginContainer/VBoxContainer/cb_mode/CheckButton
@onready var zen_min: OptionButton = $MarginContainer/VBoxContainer/zen_mode/min_size/OptionButton
@onready var zen_max: OptionButton = $MarginContainer/VBoxContainer/zen_mode/max_size/OptionButton
@onready var screen_size: OptionButton = $MarginContainer/VBoxContainer/screen_size/screen_options
@onready var back_btn: Button = $MarginContainer2/Control/Back

# Called when the node enters the scene tree for the first time.
func _ready():
	music_slider.set_value_no_signal(GameManager.GAME_DATA.settings.music_volume)
	sound_slider.set_value_no_signal(GameManager.GAME_DATA.settings.sound_volume)
	colorblind_toggle.set_pressed_no_signal(GameManager.GAME_DATA.settings.colorblind)
	screen_size.selected = GameManager.GAME_DATA.settings.screen_size
	
	
	zen_min.clear()
	zen_max.clear()
	for size in range(GameManager.GAME_DATA.MIN_GRID_SIZE.x, GameManager.GAME_DATA.MAX_GRID_SIZE.x + 1):
		zen_min.add_item(str(Vector2.ONE * size), size)
		zen_max.add_item(str(Vector2.ONE * size), size)
	zen_min.selected = (GameManager.GAME_DATA.settings.zen_mode_min_grid.x - GameManager.GAME_DATA.MIN_GRID_SIZE.x)
	zen_max.selected = (GameManager.GAME_DATA.settings.zen_mode_max_grid.x - GameManager.GAME_DATA.MIN_GRID_SIZE.x)

	
	music_slider.value_changed.connect(func(val): GameManager.GAME_DATA.settings = {music_volume = val})
	sound_slider.value_changed.connect(func(val): 
		GameManager.GAME_DATA.settings = {sound_volume = val}
		SoundController.play_sound(GameManager.sfx.chic_jump)
	)
	
	colorblind_toggle.pressed.connect(func(): GameManager.GAME_DATA.settings = {colorblind = colorblind_toggle.button_pressed})
	screen_size.item_selected.connect(func(val): GameManager.GAME_DATA.settings = {screen_size = val})
	
	zen_min.item_selected.connect(func(val): 
		var size = zen_min.get_item_id(val)
		GameManager.GAME_DATA.settings = {zen_mode_min_grid = Vector2.ONE * size}
		if GameManager.GAME_DATA.settings.zen_mode_max_grid.x < size:
			GameManager.GAME_DATA.settings = {zen_mode_max_grid = Vector2.ONE * size}
			zen_max.select(val)
		print_debug(GameManager.GAME_DATA.settings)
	)
	zen_max.item_selected.connect(func(val): 
		var selected_size = zen_max.get_item_id(val)
		var size = max(selected_size, GameManager.GAME_DATA.settings.zen_mode_min_grid.x)
		GameManager.GAME_DATA.settings = {zen_mode_max_grid = Vector2.ONE * size}
		if size != selected_size:
			zen_max.selected = zen_max.get_item_index(size)
	)
	
	visibility_changed.connect(func():
		if visible:
			music_slider.grab_focus()
	)
	music_slider.grab_focus()
	

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel") and visible:
		_on_back_pressed()
		get_viewport().set_input_as_handled()
		

func _on_reset_pressed():
	GameManager.GAME_DATA.reset_settings()
	GameManager.GAME_DATA.reset_state()
	
	GameManager.GAME_DATA.delete_state()
	GameManager.GAME_DATA.delete_settings()
	
	SoundController.bgmPlayer.stop()
	get_tree().change_scene_to_packed(load("res://src/ui/Menu/menu.tscn"))


func _on_back_pressed():
	GameManager.GAME_DATA.save_settings()
	visible = false
	settings_hidden.emit()
