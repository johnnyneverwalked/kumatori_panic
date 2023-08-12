extends Control


@onready var bear: Bear = $Bear
@onready var chic: Chic = $Chics/Chic
@onready var logo: Sprite2D = $Logo
@onready var labels: VBoxContainer = $CanvasLayer/Container/Labels
@onready var nest: Node2D = $Chics
@onready var controls: VBoxContainer = $CanvasLayer/Container/Controls
@onready var back_btn_container: MarginContainer = $CanvasLayer/Back
@onready var back_btn: Button = $CanvasLayer/Back/Control/BackBtn
@onready var credits: VBoxContainer = $CanvasLayer/Credits
@onready var settings: CanvasLayer = $Settings
@onready var tutorial: Node2D = $Tutorial
@onready var container: MarginContainer = $CanvasLayer/Container

var showing_credits: bool
var credits_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	SoundController.clean_players()
	GameManager.can_pause = false
	$Dots.visible = true
	var zen_mode: Button = controls.get_node("ZenMode")
	zen_mode.text = "zen mode" if not GameManager.GAME_DATA.game_state.zen_mode_locked else "[locked]"
	zen_mode.disabled = GameManager.GAME_DATA.game_state.zen_mode_locked
	
	
	bear.set_held_chic(chic)
	bear.hand_L.position = Vector2(-5, 2)
	bear.hand_R.position = Vector2(5, 2)
	credits_tween = create_tween()
	credits_tween.stop()
	animate(GameManager.GAME_DATA.game_state.skip_intro)
	
	GameManager.GAME_DATA.game_state = {skip_intro = true}


func animate(skip_logo: bool = false):
	var screen_coords = get_viewport_rect().size / GameManager.cam.zoom
	bear.scale = Vector2.ZERO
	nest.scale = Vector2.ZERO
	container.scale = Vector2.ZERO
	var start_tween: Tween
	
	if not skip_logo:
		SoundController.bgmPlayer.stop()
		logo.position = screen_coords / 2
		logo.scale = Vector2.ZERO
		
		await get_tree().create_timer(.5).timeout
		start_tween = create_tween().set_parallel().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
		
		start_tween.tween_property(logo, "scale", Vector2.ONE * 8, 1)
		start_tween.tween_property(logo, "rotation_degrees", 360 * 5, 1)
		
		get_tree().create_timer(.5).timeout.connect(func(): SoundController.play_sound(GameManager.sfx.explosion))
		await start_tween.finished
		start_tween.kill()
		
		start_tween = create_tween().set_parallel().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		start_tween.tween_property(logo, "scale", Vector2.ONE * 3, 1).set_delay(.25)
		start_tween.tween_property(logo, "position", Vector2.ONE * 64, 1).set_delay(.25)
		
		get_tree().create_timer(.25).timeout.connect(func(): SoundController.play_sound(GameManager.sfx.chic_jump))
		await start_tween.finished
		start_tween.kill()
	
	if not SoundController.bgmPlayer.playing:
		SoundController.play_music(GameManager.bgm.menu)
	
	start_tween = create_tween()
	
	logo.rotation_degrees = 0
	start_tween.tween_property(container, "scale", Vector2.ONE, .5).set_trans(Tween.TRANS_ELASTIC)
	start_tween.tween_property(nest, "scale", Vector2.ONE, .5).set_trans(Tween.TRANS_ELASTIC)
	start_tween.tween_property(bear, "scale", Vector2.ONE * 4, .5).set_trans(Tween.TRANS_ELASTIC)
	
	
	var tween_rot = create_tween().set_loops()\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	
	tween_rot.tween_property(logo, "rotation_degrees", 10, 1)
	tween_rot.tween_property(logo, "rotation_degrees", -10, 1)
	
	await get_tree().create_timer(.5).timeout
	var logo_position: Vector2 = logo.position
	var tween_pos = create_tween().set_loops()\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	tween_pos.tween_property(logo, "position", logo_position + Vector2.DOWN * GameManager.PIXEL_UNIT / 2, 1)
	tween_pos.tween_property(logo, "position", logo_position + Vector2.UP * GameManager.PIXEL_UNIT / 2, 1)
	
	var label_tween = create_tween().set_loops()\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	label_tween.tween_property(labels, "position", labels.position + Vector2.DOWN * GameManager.PIXEL_UNIT / 4, 1)
	label_tween.tween_property(labels, "position", labels.position + Vector2.UP * GameManager.PIXEL_UNIT / 4, 1)


func _unhandled_input(event):
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		if not (back_btn.disabled or back_btn.has_focus()):
			back_btn.grab_focus()
			return
		
		var is_focused: bool = false
		var buttons: Array = controls.get_children()
		for btn in buttons:
			is_focused = btn.has_focus()
			if is_focused:
				break
		if not is_focused:
			buttons[0].grab_focus()


func _on_quit_pressed():
	GameManager.notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _on_play_pressed():
	get_tree().change_scene_to_packed(load("res://src/ui/Levels/levels.tscn"))


func _on_zen_mode_pressed():
	GameManager.GAME_DATA.game_state = {zen_mode = true}
	get_tree().change_scene_to_packed(load("res://src/game.tscn"))


func _on_how_to_pressed():
	container.visible = false
	logo.visible = false
	bear.visible = false
	nest.visible = false
	$Dots.visible = false
	
	tutorial.process_mode = Node.PROCESS_MODE_ALWAYS
	tutorial._ready()
	tutorial.visible = true
	back_btn_container.visible = true
	back_btn.disabled = false


func _on_settings_pressed():
	settings.visible = true


func _on_credits_pressed():
	container.visible = false
	logo.visible = false
	bear.visible = false
	nest.visible = false
	
	credits.process_mode = Node.PROCESS_MODE_ALWAYS
	var screen_coords = get_viewport_rect().size
	credits.position.y = screen_coords.y
	credits_tween.kill()
	credits_tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	
	credits_tween.tween_property(credits, "position:y", -credits.size.y - screen_coords.y / 2, 30)
	credits_tween.finished.connect(func(): 
		if showing_credits:
			_on_back_btn_pressed()
	)
	
	credits.visible = true
	back_btn_container.visible = true
	back_btn.disabled = false
	showing_credits = true


func _on_back_btn_pressed():
	
	# Settings
	if settings.has_method("_on_back_pressed"):
		settings._on_back_pressed()
	else:
		settings.visible = false
	
	# Credits
	
	credits.visible = false
	credits.process_mode = Node.PROCESS_MODE_DISABLED
	showing_credits = false
	credits_tween.stop()
	
	#Tutorial
	
	tutorial.visible = false
	get_tree().create_timer(.1).timeout.connect(func(): tutorial.process_mode = Node.PROCESS_MODE_DISABLED)
	
	$Dots.visible = true
	
	# Menu
	
	container.visible = true
	logo.visible = true
	bear.visible = true
	nest.visible = true
	back_btn_container.visible = false
	back_btn.disabled = true
	
	animate(true)
