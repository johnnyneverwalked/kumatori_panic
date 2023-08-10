extends Resource
class_name GameData

signal colorblind_toggled(val)
signal zen_mode_unlocked

const data_file_path = "user://data.sv"

const save_file_path = "user://user_data.sv"
const settings_file_path = "user://user_sett.sv"
const levels_folder_path = "res://src/resources/levels/"

const MIN_GRID_SIZE: Vector2 = Vector2.ONE * 3
const MAX_GRID_SIZE: Vector2 = Vector2.ONE * 8

const LEVEL_TIMES = {
  '0': 30, # '8.71',
  '1': 30, # '21.70',
  '2': 45, # '25.68',
  '3': 45, # '36.81',
  '4': 60, # '44.36',
  '5': 60, # '57.30',
  '6': 120, # '76.42',
  '7': 120, # '117.75',
  '8': 120, # '119.12',
  '9': 120, # '106.47',
  '10': 120, # '103.38',
  '11': 120, # '118.15',
  '12': 150, # '111.95',
  '13': 150, # '108.45',
  '14': 150, # '119.07',
  '15': 150, # '138.18',
  '16': 240, # '144.99',
  '17': 240, # '212.03',
  '18': 300, # '219.03',
  '19': 300, # '253.61'
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

const TOTAL_LEVELS: int = 20

var game_state: Dictionary = DEFAULT_STATE.duplicate(true): set = set_game_state
var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true): set = set_settings

func save_level_time(_grid, time_in_sec: float):
	var file = FileAccess.open(data_file_path, FileAccess.READ_WRITE if FileAccess.file_exists(data_file_path) else FileAccess.WRITE)
	var grid = str(_grid)
	var str_data = file.get_as_text()
	var data = JSON.parse_string(str_data) if str_data != null and str_data.length() else {}
	
	if not data is Dictionary:
		data = {}
	if not data.has(grid):
		data[grid] = []
		
	data[grid].append("%.2f" % time_in_sec)
	
	file.store_string(JSON.stringify(data, "  "))
	file.close()

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
	if game_state.zen_mode_locked and game_state.unlocked_levels >= 1:
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
	
