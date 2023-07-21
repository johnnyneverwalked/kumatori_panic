extends Node

signal sound_fininshed
signal volume_changed

var bgmPlayer: AudioStreamPlayer
var sfxPlayer: AudioStreamPlayer

var swapping_tracks: bool
var current_track: int = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	bgmPlayer = AudioStreamPlayer.new()
	bgmPlayer.bus = "BGM"
#	set_volume(bgmPlayer, .6)

	sfxPlayer = AudioStreamPlayer.new()
	sfxPlayer.bus = "SFX"
#	set_volume(sfxPlayer, .75)
	
	add_child(bgmPlayer)
	add_child(sfxPlayer)
	
	sfxPlayer.connect("finished", self._on_sound_finished)

func play_sound(sfx: AudioStream, clear: bool = false): _play(sfxPlayer, sfx, clear)
func play_music(bgm: AudioStream = null, clear: bool = false): _play(bgmPlayer, bgm, clear)
func _play(player: AudioStreamPlayer, stream: AudioStream, clear: bool = false):
	if clear:
		player.stop()
	player.stream = stream
	player.play()
	
func set_sound_volume(percentage: float): _set_volume(sfxPlayer, percentage)
func set_music_volume(percentage: float): _set_volume(bgmPlayer, percentage)
func _set_volume(player: AudioStreamPlayer, percentage: float):
	if not percentage:
		player.volume_db = -80
		return
	player.volume_db = 10 * log(percentage / 100) / log(10)
	emit_signal("volume_changed")

func _on_sound_finished():
	sfxPlayer.pitch_scale = 1
	emit_signal("sound_fininshed")

