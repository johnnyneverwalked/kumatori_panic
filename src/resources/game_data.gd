extends Resource
class_name GameData

signal colorblind_toggled(val)
signal zen_mode_unlocked

const save_file_path = "user://user_data.sv"
const settings_file_path = "user://user_sett.sv"
const levels_folder_path = "res://src/resources/levels/"

const MIN_GRID_SIZE: Vector2 = Vector2.ONE * 3
const MAX_GRID_SIZE: Vector2 = Vector2.ONE * 8

const TOTAL_LEVELS: int = 20
const LEVEL_TIMES = {
  '0': 30, 
  '1': 30, 
  '2': 45,
  '3': 45,
  '4': 60,
  '5': 60,
  '6': 120, 
  '7': 120,
  '8': 120,
  '9': 120,
  '10': 120,
  '11': 120,
  '12': 150,
  '13': 150,
  '14': 150,
  '15': 150,
  '16': 240, 
  '17': 240, 
  '18': 300, 
  '19': 300,
}

const DEFAULT_STATE = {
	current_level = 0,
	unlocked_levels = 0,
	total_chics = 0,
	zen_mode_locked = true,
	zen_mode_played = false,
	zen_mode = false,
	skip_intro = false
}

const DEFAULT_SETTINGS = {
	music_volume = 50,
	sound_volume = 50,
	colorblind = false,
	zen_mode_min_grid = MIN_GRID_SIZE,
	zen_mode_max_grid = MAX_GRID_SIZE,
	screen_size = 0
}


var game_state: Dictionary = DEFAULT_STATE.duplicate(true): set = set_game_state
var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true): set = set_settings


func save_state():
	var state = game_state.duplicate(true)
	state.erase("current_level")
	state.erase("zen_mode")
	state.erase("skip_intro")
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if not file:
		return
	file.store_var(state)
	file.close()

func load_state():
	if not FileAccess.file_exists(save_file_path):
		return
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	
	set_game_state(file.get_var())
	file.close()
		
	SoundController.set_music_volume(settings.music_volume)
	SoundController.set_sound_volume(settings.sound_volume)

func delete_state():
	DirAccess.remove_absolute(save_file_path)


func reset_state():
	game_state = DEFAULT_STATE


func set_game_state(state: Dictionary):
	for key in state.keys():
		game_state[key] = state[key]
	if game_state.unlocked_levels < game_state.current_level:
		game_state.unlocked_levels = game_state.current_level
	if game_state.zen_mode_locked and game_state.unlocked_levels >= 5:
		game_state.zen_mode_locked = false
		zen_mode_unlocked.emit()


func save_settings():
	var file = FileAccess.open(settings_file_path, FileAccess.WRITE)
	if not file:
		return
	file.store_var(settings)
	file.close()


func load_settings():
	if not FileAccess.file_exists(settings_file_path):
		return
	var file = FileAccess.open(settings_file_path, FileAccess.READ)
	
	set_settings(file.get_var())
	file.close()
		
	SoundController.set_music_volume(settings.music_volume)
	SoundController.set_sound_volume(settings.sound_volume)


func delete_settings():
	DirAccess.remove_absolute(settings_file_path)


func reset_settings():
	settings = DEFAULT_SETTINGS


func set_settings(new: Dictionary):
	for key in new.keys():
		settings[key] = new[key]

	if new.has("colorblind"):
		colorblind_toggled.emit(new.colorblind)
	if new.has("screen_size"):
		GameManager.set_screen_size(new.screen_size)
	if new.has("music_volume"):
		SoundController.set_music_volume(new.music_volume)
	if new.has("sound_volume"):
		SoundController.set_sound_volume(new.sound_volume)
	
