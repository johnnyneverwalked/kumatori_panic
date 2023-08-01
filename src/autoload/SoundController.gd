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
	set_music_volume(60)

	sfxPlayer = AudioStreamPlayer.new()
	sfxPlayer.bus = "SFX"
	set_sound_volume(75)
	
	add_child(bgmPlayer)
	add_child(sfxPlayer)
	
	sfxPlayer.finished.connect(_on_sound_finished)

func play_sound(sfx: AudioStream, clear: bool = true): _play(sfxPlayer, sfx, clear)
func play_music(bgm: AudioStream = null, clear: bool = true): _play(bgmPlayer, bgm, clear)
func _play(player: AudioStreamPlayer, stream: AudioStream, clear: bool = false):
	if not clear: # we create a tmp player for parallel audio
		var tmp_player := player.duplicate(15)
		player.pitch_scale = 1
		tmp_player.stream = stream
		tmp_player.finished.connect(func(): tmp_player.queue_free())
		add_child(tmp_player)
		tmp_player.play()
		return
	player.stop()
	player.stream = stream
	player.play()
	
func set_sound_volume(percentage: float): _set_volume(sfxPlayer, percentage)
func set_music_volume(percentage: float): _set_volume(bgmPlayer, percentage)
func _set_volume(player: AudioStreamPlayer, percentage: float):
	if not percentage:
		player.volume_db = -80
		return
	if percentage < 1:
		percentage *= 100
	player.volume_db = 10 * log(percentage / 100) / log(10)
	emit_signal("volume_changed")

func clean_players():
	for node in get_children():
		if not [bgmPlayer, sfxPlayer].has(node):
			node.queue_free()

func _on_sound_finished():
	sfxPlayer.pitch_scale = 1
	emit_signal("sound_fininshed")

