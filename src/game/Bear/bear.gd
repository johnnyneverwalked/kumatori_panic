extends CharacterBody2D

class_name Bear

signal place_chic(chic)
signal unlock

@export var chic: Chic: set = set_held_chic
@export var demo: bool: set = set_demo

@onready var body: AnimatedSprite2D = $Body
@onready var hands: Node2D = $Hands
@onready var hand_L: Sprite2D = $Hands/HandL
@onready var hand_R: Sprite2D = $Hands/HandR
@onready var holding: Node2D = $Hands/Holding
@onready var pickupDetector: Node2D = $PickupDetector
@onready var lock_timer: Timer = $LockTimer
@onready var indicator: Sprite2D = $Indicator
@onready var indicator_inner: Sprite2D = $Indicator/IndicatorInner
@onready var sweat: GPUParticles2D = $Sweat

const PICKUP_SPEED = .2
var HAND_POSITIONS: Dictionary = {
	
}

var pd: Dictionary = {
	
}

var locked: bool
var moving: bool
var bounds: Rect2
var hands_position: Vector2 = Vector2.UP: set = set_hands_position

var sweat_timeout: float = randf_range(2.0, 10.0)

func _ready():
	var cardinal_dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	# fix shader params for left hand to be seen from the "outslide"
	hand_L.material.set_shader_parameter("fill_color", GameManager.bear_colors.skin_light)
	hand_L.material.set_shader_parameter("swap_color", GameManager.bear_colors.skin_dark)
	
	body.material.set_shader_parameter("outline_color", GameManager.chic_outline_color)
	hand_L.material.set_shader_parameter("outline_color", GameManager.chic_outline_color)
	hand_R.material.set_shader_parameter("outline_color", GameManager.chic_outline_color)
	
	# set default hand placement positions and rotations
	HAND_POSITIONS[Vector2.ZERO] = {pos = Vector2.ZERO * GameManager.PIXEL_UNIT / 2, rot = 0}
	HAND_POSITIONS[Vector2.UP] = {pos = Vector2.UP * GameManager.PIXEL_UNIT, rot = 0}
	HAND_POSITIONS[Vector2.DOWN] = {pos = Vector2.DOWN * GameManager.PIXEL_UNIT / 2, rot = 180}
	HAND_POSITIONS[Vector2.LEFT] = {pos = Vector2.LEFT * GameManager.PIXEL_UNIT / 2, rot = 90}
	HAND_POSITIONS[Vector2.RIGHT] = {pos = Vector2.RIGHT * GameManager.PIXEL_UNIT / 2, rot = 90}
	
	hands_position = Vector2.LEFT
	
	body.scale = Vector2.ZERO
	get_tree().create_tween()\
		.tween_property(body, "scale", Vector2.ONE, .25)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)
	
	for i in cardinal_dirs.size():
		pd[cardinal_dirs[i]] = pickupDetector.get_child(i)
		pd[cardinal_dirs[i]].position = cardinal_dirs[i] * GameManager.PIXEL_UNIT * 2
	
	# connect the lock timer to unlock the node on timeout
	lock_timer.timeout.connect(func(): 
		locked = false
		unlock.emit()
	)
	
	GameManager.game_over.connect(func(_won: bool):
		set_hands_position(Vector2.ZERO if _won else Vector2.DOWN)
		locked = true
		lock_timer.stop()
		if chic:
			holding.remove_child(chic)
			place_chic.emit(chic)
			chic.global_position = holding.global_position
		
		body.play("happy" if _won else "sad")
	)
	
	var tween = get_tree().create_tween().set_loops().bind_node(self)\
		.set_trans(Tween.TRANS_CIRC)\
		.set_ease(Tween.EASE_IN_OUT)
	
	
	tween.tween_property(indicator, "scale", indicator.scale * 1.2, .5)
	tween.tween_property(indicator, "scale", indicator.scale, .5)


func _input(_event):
	if demo:
		return
	if Input.is_action_just_pressed("pick"):
		if pd[hands_position].has_overlapping_bodies() and pd[hands_position].get_overlapping_bodies()[0] is Chic:
			chic = pd[hands_position].get_overlapping_bodies()[0]
		else:
			place_chic_back(pd[hands_position].global_position)
	


func _process(delta):
	if demo:
		return
		
	indicator_inner.visible = Input.is_action_pressed("hold")
	
	move(Input.get_vector("move_left", "move_right", "move_up", "move_down").round())
	
	if Input.is_action_just_pressed("look_left") or InputBuffer.is_action_press_buffered("look_left"):
		set_hands_position(Vector2.LEFT)
	elif  Input.is_action_just_pressed("look_right") or InputBuffer.is_action_press_buffered("look_right"):
		set_hands_position(Vector2.RIGHT)
	elif  Input.is_action_just_pressed("look_up") or InputBuffer.is_action_press_buffered("look_up"):
		set_hands_position(Vector2.UP)
	elif  Input.is_action_just_pressed("look_down") or InputBuffer.is_action_press_buffered("look_down"):
		set_hands_position(Vector2.DOWN)
	
	if locked:
		return
		
	if sweat_timeout <= 0:
		sweat_timeout = randf_range(5.0, 15.0)
		sweat.emitting = true
	sweat_timeout -= delta


func set_hands_position(pos: Vector2 = Vector2.ZERO):
	if pos == hands_position or not HAND_POSITIONS.has(pos):
		return
	hands_position = pos
	
	#animate hand movement
	var tween = get_tree().create_tween().set_parallel(true)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(hands, "position", HAND_POSITIONS.get(pos).pos + body.position, PICKUP_SPEED)
	tween.tween_property(indicator, "position", pos * GameManager.PIXEL_UNIT * 2, PICKUP_SPEED)

	# rotate paws to be oriented correctly
	hand_L.rotation_degrees =  HAND_POSITIONS.get(pos).rot
	hand_R.rotation_degrees =  HAND_POSITIONS.get(pos).rot
	
	# "turn around" paws based on orientation
	hands.scale.x = (-1 if pos == Vector2.LEFT else 1) * abs(scale.y)
	hand_L.material.set_shader_parameter("fill_color", Color.WHITE if pos == Vector2.DOWN or pos == Vector2.ZERO else GameManager.bear_colors.skin_light)
	holding.z_index = 1 if pos == Vector2.DOWN else 0
	
	# set chicken detector to the correct position
#	pd.position = pos * GameManager.PIXEL_UNIT * 2
	indicator.visible = pos != Vector2.ZERO
#	lock(PICKUP_SPEED / 2)
	
	
func lock(timeout: float = 0, add_to_existing: bool = false):
	locked = true
	lock_timer.start(timeout + (lock_timer.time_left if add_to_existing else 0.0))


func move(dir: Vector2 = Vector2.ZERO):
	if locked or not [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN].has(dir):
		return
	
	var pos = global_position + dir * GameManager.PIXEL_UNIT * 2
	if is_out_of_bounds(pos):
		return
	
	moving = true

	pd[dir].position = dir * GameManager.PIXEL_UNIT * 2
	if pd[dir].has_overlapping_bodies() and pd[dir].get_overlapping_bodies()[0] is Chic:
		var target_chic = pd[dir].get_overlapping_bodies()[0]
		if Input.is_action_pressed("hold") and chic:
			get_tree().create_tween()\
				.tween_property(target_chic, "global_position", global_position, PICKUP_SPEED)\
				.set_trans(Tween.TRANS_CIRC)\
				.set_ease(Tween.EASE_IN_OUT)
		else:
			set_held_chic(target_chic)
	
	var tween = get_tree().create_tween()\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", global_position + dir * GameManager.PIXEL_UNIT * 2, PICKUP_SPEED)
	
#	hands_position = dir
	
	moving = false
	lock(PICKUP_SPEED)


func set_held_chic(_chic: Chic):
	if locked:
		return
	

	if chic and _chic:
		# swap currently holding with the one we try to hold
		place_chic_back(global_position if moving else pd[hands_position].global_position)
		
	chic = _chic
	if not chic:
		return
	
	# add new chic to our hands
	chic.get_parent().remove_child(chic)
	holding.add_child(chic)
	SoundController.play_sound(GameManager.sfx.chic_jump)
	
	# prevent janky movement due to node2D swapping
	chic.global_position = global_position if moving else pd[hands_position].global_position
	chic.z_as_relative = true
	chic.z_index = 0
	chic.collision_layer = 1
	
	get_tree().create_tween()\
		.tween_property(chic, "position", Vector2.ZERO, PICKUP_SPEED)\
#		.tween_property(chic, "global_position", holding.global_position, PICKUP_SPEED)\
		.set_trans(Tween.TRANS_CIRC)\
		.set_ease(Tween.EASE_IN_OUT)
	
	# animation lock to prevent buggy positions
	lock(PICKUP_SPEED)


func place_chic_back(pos: Vector2):
	if locked or not chic or is_out_of_bounds(pos):
		return
	
	holding.remove_child(chic)
	place_chic.emit(chic)
	SoundController.play_sound(GameManager.sfx.chic_jump)
	
	# prevent janky movement due to node2D swapping
	chic.global_position = holding.global_position
	chic.collision_layer = 2
	chic.z_as_relative = false
	chic.z_index = 2
	
	var tween = get_tree().create_tween()
	tween.tween_property(chic, "global_position", pos, PICKUP_SPEED)\
		.set_trans(Tween.TRANS_CIRC)\
		.set_ease(Tween.EASE_IN_OUT)
	
	var prev_chic = chic
	chic = null
	
	tween.finished.connect(func():
		prev_chic.z_index = 1
	)
	
	# animation lock to prevent buggy positions
	lock(PICKUP_SPEED)

func is_out_of_bounds(pos: Vector2):
	return bounds == null or pos == null or not bounds.has_point(pos)

func set_demo(_demo: bool):
	demo = _demo
	indicator.visible = indicator.visible and not demo
	
