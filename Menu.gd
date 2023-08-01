extends Control


@onready var bear: Bear = $Bear
@onready var chic: Chic = $Chics/Chic
@onready var logo: Sprite2D = $Logo
@onready var labels: VBoxContainer = $CanvasLayer/MarginContainer/Labels
@onready var nest: Node2D = $Chics
@onready var controls: VBoxContainer = $CanvasLayer/MarginContainer/Controls
@onready var container: MarginContainer = $CanvasLayer/MarginContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	bear.set_held_chic(chic)
	bear.hand_L.position = Vector2(-5, 2)
	bear.hand_R.position = Vector2(5, 2)

	animate()


func animate():
	var screen_coords = get_viewport_rect().size / GameManager.cam.zoom
	logo.position = screen_coords / 2
	logo.scale = Vector2.ZERO
	bear.scale = Vector2.ZERO
	nest.scale = Vector2.ZERO
	container.scale = Vector2.ZERO
	
	await get_tree().create_timer(.5).timeout
	var start_tween = create_tween().set_parallel().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
	
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
	get_tree().change_scene_to_packed(load("res://src/game.tscn"))


func _on_zen_mode_pressed():
	pass # Replace with function body.


func _on_how_to_pressed():
	pass # Replace with function body.


func _on_settings_pressed():
	pass # Replace with function body.


func _on_credits_pressed():
	pass # Replace with function body.
