extends Resource
class_name GameData

signal colorblind_toggled(val)

const data_file_path = "user://data.sv"

const save_file_path = "user://user_data.sv"
const settings_file_path = "user://user_sett.sv"
const levels_folder_path = "res://src/resources/levels/"

const MIN_GRID_SIZE: Vector2 = Vector2.ONE * 3
const MAX_GRID_SIZE: Vector2 = Vector2.ONE * 8

const DEFAULT_STATE = {
	current_level = -1,
	unlocked_levels = 0,
	total_chics = 0,
	zen_mode_locked = true,
	zen_mode_played = false
}

const DEFAULT_SETTINGS = {
	music_volume = 50,
	sound_volume = 50,
	colorblind = false,
	zen_mode = {
		min_grid = Vector2.ONE * 3,
		max_grid = MAX_GRID_SIZE
	},
	screen_size = 0
}

var game_state: Dictionary = DEFAULT_STATE.duplicate(true): set = set_game_state
var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true): set = set_settings

func save_level_time(_grid: Vector2, time_in_sec: float):
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

func save_settings():
	var file = FileAccess.open(settings_file_path, FileAccess.WRITE)
	file.store_var(settings)
	file.close()


func load_settings():
	if not FileAccess.file_exists(settings_file_path):
		return
	var file = FileAccess.open(settings_file_path, FileAccess.READ)
	
	set_settings(file.get_var(true))
	file.close()
		
	SoundController.set_music_volume(settings.music_volume)
	SoundController.set_sound_volume(settings.sound_volume)

func delete_save_data():
	DirAccess.remove_absolute(save_file_path)


func reset_game_state():
	game_state = DEFAULT_STATE

func reset_settings():
	game_state = DEFAULT_STATE

func set_game_state(state: Dictionary):
	game_state = state

func set_settings(new: Dictionary):
	for key in new.keys():
		settings[key] = new[key]
	if new.has("colorblind"):
		colorblind_toggled.emit(new.colorblind)
	if new.has("screen_size"):
		GameManager.set_screen_size(new.screen_size)

	
