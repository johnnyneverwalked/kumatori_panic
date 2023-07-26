extends Control

@export var pause_text: String = "PAUSED II": set = set_pause_text

# Called when the node enters the scene tree for the first time.
func _ready():
	set_pause_text(pause_text)

func set_pause_text(text: String):
	pause_text = text
	$Margin/PauseLabel.text = text
