extends CharacterBody2D

class_name Chic

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var color: GameManager.Colors: set = set_chic_color

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("chic", true)
	color = color
	sprite.frame = get_index() * 2
	sprite.material.set_shader_parameter("outline_color", GameManager.chic_outline_color)


func set_chic_color(_color: GameManager.Colors = GameManager.Colors.WHITE):
	color = _color
	if not sprite:
		return
	sprite.material.set_shader_parameter("swap_color", GameManager.chic_colors.get(color))
