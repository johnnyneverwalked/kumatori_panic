extends CanvasLayer

@onready var play_btn: Button = $PauseOverlay/MenuContainer/Play
@onready var settings_btn: Button = $PauseOverlay/MenuContainer/Settings
@onready var main_menu_btn: Button = $PauseOverlay/MenuContainer/MainMenu
@onready var exit_btn: Button = $PauseOverlay/MenuContainer/Exit
@onready var settings: CanvasLayer = $Settings

# Called when the node enters the scene tree for the first time.
func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	settings.settings_hidden.connect(func(): play_btn.grab_focus())


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		unpause()


func _process(_delta):
	if not visible:
		visible = true
		play_btn.grab_focus()
		SoundController.bgmPlayer.stream_paused = true
		

func unpause():
	SoundController.play_sound(GameManager.sfx.pause)
	await get_tree().create_timer(.25).timeout
	visible = false
	settings.visible = false
	SoundController.bgmPlayer.stream_paused = false
	get_tree().paused = false

func _on_play_button_up():
	unpause()


func _on_exit_button_up():
	GameManager.notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _on_main_menu_button_up():
	unpause()
	await get_tree().create_timer(.25).timeout
	SoundController.bgmPlayer.stop()
	get_tree().change_scene_to_packed(load("res://src/ui/Menu/menu.tscn"))


func _on_levels_button_up():
	unpause()
	await get_tree().create_timer(.25).timeout
	SoundController.bgmPlayer.stop()
	get_tree().change_scene_to_packed(load("res://src/ui/Levels/levels.tscn"))


func _on_settings_button_up():
	settings.visible = true
