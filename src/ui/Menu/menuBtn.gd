extends Button

@export var tween_duration: float = .3


func _on_focus_entered():
	var tween = create_tween().set_parallel()\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", GameManager.PIXEL_UNIT * 4, tween_duration)
	tween.tween_property($ProgressBar, "value", 100, tween_duration)


func _on_focus_exited():
	var tween = create_tween().set_parallel()\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", 0, tween_duration)
	tween.tween_property($ProgressBar, "value", 0, tween_duration)


func _on_button_down():
	var tween = create_tween().set_parallel()\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * .95, tween_duration)


func _on_button_up():
	var tween = create_tween().set_parallel()\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, tween_duration)


func _on_mouse_entered():
	if has_focus():
		_on_focus_entered()
		return
	grab_focus()
