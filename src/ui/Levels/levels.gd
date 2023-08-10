extends CanvasLayer

@onready var container: HFlowContainer = $MarginContainer/Container
@onready var back_btn: Button = $Control/Back

var button_node := load("res://src/ui/Levels/level_button.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.can_pause = false
	for i in range(GameManager.GAME_DATA.TOTAL_LEVELS):
		var btn: LevelButton = button_node.instantiate()
		container.add_child(btn)
		btn.text = str(i + 1)
		btn.disable(GameManager.GAME_DATA.game_state.unlocked_levels < i)
		btn.pressed.connect(func(): level_selected(i))
	
	if not SoundController.bgmPlayer.playing:
		SoundController.play_music(GameManager.bgm.menu)
	
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_QUAD)
	var pos = $MarginContainer.position.y
	tween.tween_property($MarginContainer, "position:y", pos + GameManager.PIXEL_UNIT / 2, 1)
	tween.tween_property($MarginContainer, "position:y", pos - GameManager.PIXEL_UNIT / 2, 1)


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_btn_pressed()
		return
	
	var relevant_action: bool = false
		
	if container.get_child(0).has_focus() and (event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up")):
		back_btn.grab_focus()
		return
	
	for action in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		if not event.is_action_pressed(action):
			continue
		relevant_action = true
		for btn in container.get_children():
			if btn.has_focus():
				return
	if relevant_action:
		container.get_child(0).grab_focus()


func level_selected(index: int):
	GameManager.GAME_DATA.game_state = {current_level = index, zen_mode = false}
	get_tree().change_scene_to_packed(load("res://src/game.tscn"))


func _on_back_btn_pressed():
	get_tree().change_scene_to_packed(load("res://src/ui/Menu/menu.tscn"))
