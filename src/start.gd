extends Node2D

@onready var bear: Bear = $Bear
@onready var chic := $Chic
@onready var chics := $Chics

const chic_node := preload("res://src/game/Chic/chic.tscn")

var locked: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	$Logo.scale = Vector2.ZERO
	$Title.visible = false
	
	await get_tree().create_timer(5).timeout
	SoundController.play_sound(GameManager.sfx.block)
	
	var tween = create_tween()\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_property($Title, "visible", true, 0)
	tween.tween_property($Logo, "scale", Vector2.ONE * .1, .75).set_delay(.5)
	
	await get_tree().create_timer(.5).timeout
	SoundController.play_sound(GameManager.sfx.collect)
	
	await tween.finished
	
	bear.set_held_chic(chic)
	bear.set_hands_position(Vector2.RIGHT)
	bear.demo = true
	bear.body.speed_scale = 3
	SoundController.play_sound(GameManager.sfx.chic_jump_looped, false)
	
	var screen_coords = get_viewport_rect().size / GameManager.cam.zoom
	await get_tree().create_timer(1.5).timeout
	for i in range(200):
		var new_chic: Chic = chic_node.instantiate()
		new_chic.color = randi_range(0, GameManager.Colors.size() - 1)
		new_chic.demo = true
		await get_tree().create_timer(.001).timeout
		chics.add_child(new_chic)
		new_chic.shadow.visible = false
		new_chic.sprite.play("walk")
		new_chic.animation.play("walk") if randi() % 2 else new_chic.animation.play_backwards("walk")
		new_chic.sprite.speed_scale = 2
		new_chic.scale.x = -1
		new_chic.global_position = Vector2(
			-screen_coords.x / 1.5 - GameManager.PIXEL_UNIT, 
			randi_range(bear.global_position.y - screen_coords.y / 1.1, bear.global_position.y)
		)

		new_chic.collision_mask = 1
		
		if i == 6:
			SoundController.play_sound(GameManager.sfx.chic_jump_looped, false)
	
	await get_tree().create_timer(1).timeout
	fade_out()

func _input(event):
	for action in [
		"ui_accept",
		"ui_cancel"
	]:
		if event.is_action_pressed(action) and not locked:
			fade_out()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	bear.velocity = Vector2.RIGHT * 125
	if bear.demo:
		bear.move_and_slide()
	for _chic in chics.get_children():
		_chic.velocity = Vector2.RIGHT * 200
		_chic.move_and_slide()

func fade_out():
	locked = true
	var tween = create_tween()
	tween.tween_property($ColorRectTop, "color:a", 1, .5)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): 
		SoundController.clean_players()
		await get_tree().create_timer(.1).timeout
		get_tree().change_scene_to_packed(load("res://src/ui/Menu/menu.tscn"))
	)
