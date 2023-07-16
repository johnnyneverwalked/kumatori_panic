extends Node

const PIXEL_UNIT: int = 16

const sfx: Dictionary = {
	
}

enum Colors {WHITE, BLUE, YELLOW, RED, PINK, GREEN, }

const chic_colors: Dictionary = {
	Colors.BLUE: Color("#11adc1"),
	Colors.YELLOW: Color("#f7e476"),
	Colors.RED: Color("#cb4d68"),
	Colors.PINK: Color("#f7a4c4"),
	Colors.GREEN: Color("#5bb361"),
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
var first_time_load: bool = true

func _ready():
	SoundController.set_sound_volume(20)
	randomize()
	
func start_game():
	first_time_load = false

func set_time_scale(_time_scale: float = 1):
	time_scale = clamp(_time_scale, .2, 1.0)
	Engine.time_scale = time_scale
	AudioServer.playback_speed_scale = 2.0 - time_scale
