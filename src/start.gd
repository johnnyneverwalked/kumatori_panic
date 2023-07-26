extends Node2D

@onready var bear: Bear = $Bear
@onready var chic := $Chic
@onready var chics := $Chics

const chic_node := preload("res://src/game/Chic/chic.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	bear.set_held_chic(chic)
	bear.set_hands_position(Vector2.RIGHT)
	bear.demo = true
	bear.body.speed_scale = 3
	
	var screen_coords = get_viewport_rect().size / GameManager.cam.zoom
	
	for i in range(100):
		var new_chic = chic_node.instantiate()
		new_chic.color = randi_range(0, GameManager.Colors.size() - 1)
		await get_tree().create_timer(.025).timeout
		chics.add_child(new_chic)
		new_chic.sprite.play("walk")
		new_chic.scale.x = -1
		new_chic.global_position = Vector2(-screen_coords.x / 1.5, randi_range(bear.global_position.y - screen_coords.y / 1.75, bear.global_position.y))
		if not chics.get_child_count() % 25:
			new_chic.global_position.y = bear.global_position.y
		pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	bear.velocity = Vector2.RIGHT * 125
	bear.move_and_slide()
	for _chic in chics.get_children():
		_chic.velocity = Vector2.RIGHT * 75
		_chic.move_and_slide()
