extends CharacterBody2D

class_name Chic

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var color: GameManager.Colors: set = set_chic_color

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("chic", true)
	color = color
#	sprite.frame = get_index() * 2
	sprite.material.set_shader_parameter("outline_color", GameManager.chic_outline_color)
	sprite.material.set_shader_parameter("blink_interval", randf_range(3.0, 5.0))
	sprite.material.set_shader_parameter("can_blink", true)
	
	sprite.scale = Vector2.ZERO
	get_tree().create_tween()\
		.tween_property(sprite, "scale", Vector2.ONE, .25)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)


func set_chic_color(_color: GameManager.Colors = GameManager.Colors.WHITE):
	color = _color
	if not sprite:
		return
	sprite.material.set_shader_parameter("swap_color", GameManager.chic_colors.get(color))
