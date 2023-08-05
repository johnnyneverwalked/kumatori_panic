extends CharacterBody2D

class_name Chic

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var shadow: Sprite2D = $Shadow

@export var color: GameManager.Colors: set = set_chic_color
@export var shadowed: bool = true: set = set_chic_shadow

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("chic", true)
	color = color
	shadowed = shadowed
#	sprite.frame = get_index() * 2
	sprite.material.set_shader_parameter("outline_color", GameManager.chic_outline_color)
	sprite.material.set_shader_parameter("blink_interval", randf_range(3.0, 5.0))
	sprite.material.set_shader_parameter("can_blink", true)
	
	sprite.scale = Vector2.ZERO
	create_tween()\
		.tween_property(sprite, "scale", Vector2.ONE, .25)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)

func fly():
	sprite.get_node("Wing").visible = true
	sprite.get_node("Wing2").visible = true
	animation.play("walk")
	sprite.play("walk")

func set_chic_color(_color: GameManager.Colors = GameManager.Colors.WHITE):
	color = _color
	if not sprite:
		return
	sprite.material.set_shader_parameter("swap_color", GameManager.chic_colors.get(color))

func set_chic_shadow(_shadowed: bool):
	if shadow:
		shadow.visible = _shadowed
	shadowed = _shadowed
