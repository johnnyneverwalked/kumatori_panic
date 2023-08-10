extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$CanvasLayer/Control/Back.grab_focus()
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_QUAD)
	var pos = $CanvasLayer/Label.position.y
	tween.tween_property($CanvasLayer/Label, "position:y", pos + GameManager.PIXEL_UNIT / 2, 1)
	tween.tween_property($CanvasLayer/Label, "position:y", pos - GameManager.PIXEL_UNIT / 2, 1)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_btn_pressed()

func _on_back_btn_pressed():
	SoundController.bgmPlayer.stop()
	get_tree().change_scene_to_packed(load("res://src/ui/Menu/menu.tscn"))
