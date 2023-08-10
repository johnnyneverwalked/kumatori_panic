extends TextureButton
class_name LevelButton

@onready var label: Label = $Label

@export var text: String: set = set_text

var tween: Tween
# Called when the node enters the scene tree for the first time.
func _ready():
	tween = create_tween()
	tween.stop()
	
	mouse_entered.connect(grab_focus)
	mouse_exited.connect(release_focus)
	

func disable(val: bool):
	disabled = val
	$Label.visible = not val

func set_text(_text: String):
	text = _text
	label.text = text


func _on_focus_entered():
	tween.kill()
	tween = create_tween()\
		.set_parallel()\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(label, "modulate:a", 1, .3)
	tween.tween_property(self, "scale", Vector2.ONE * 1.5, .3)


func _on_focus_exited():
	tween.kill()
	tween = create_tween()\
		.set_parallel()\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(label, "modulate:a", .8, .3)
	tween.tween_property(self, "scale", Vector2.ONE, .3)


func _on_pressed():
	tween.kill()
	tween = create_tween()\
		.set_parallel()\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
	
	tween.tween_property(self, "scale", Vector2.ZERO, .3)
