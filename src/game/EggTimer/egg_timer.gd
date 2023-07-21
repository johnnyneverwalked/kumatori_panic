extends Node2D

signal timeout

@export var time: int = 15
@export var alert_at: int = 10
@export var restart: bool = false
@export var autostart: bool = false

@onready var timer: Timer = $Timer
@onready var sprite: AnimatedSprite2D = $EggTimer
@onready var timeLbl: Label = $EggTimer/Time
@onready var animationP: AnimationPlayer = $AnimationPlayer

var elapsed_time: int

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.timeout.connect(func(): 
		elapsed_time -= 1
		update_time(elapsed_time)
		if not elapsed_time:
			elapsed_time = time
			timer.stop()
			timeout.emit()
	)
	timeout.connect(func():
		# stop animated timer
		sprite.stop()
		
		# jump
		animationP.play("timeout")
		await get_tree().create_timer(.3).timeout
		
		SoundController.play_sound(GameManager.sfx.rooster)
		
		# vibrate
		var tween = get_tree().create_tween().set_loops(25)
		tween.tween_property(sprite, "rotation_degrees", 15, 1.0 / 60.0)
		tween.tween_property(sprite, "rotation_degrees", 0, 1.0 / 60.0)
		tween.tween_property(sprite, "rotation_degrees", -15, 1.0 / 60.0)
		tween.tween_property(sprite, "rotation_degrees", 0, 1.0 / 60.0)
		
		# fall
		await get_tree().create_timer(1.2).timeout
		animationP.play_backwards("timeout")
		if restart:
			await animationP.animation_finished
			start()
	)
	if autostart:
		start()

func update_time(current: float = 0):
	timeLbl.text = ("0" if current < 10 else "") + str(current)
	if current == alert_at:
		AudioServer.playback_speed_scale = 4
		SoundController.play_sound(GameManager.sfx.clock_tick)
		await SoundController.sound_fininshed
		AudioServer.playback_speed_scale = 1
		

func start():
	timer.stop()
	update_time(time)
	elapsed_time = time
	timer.start(1)
	sprite.play()

func stop():
	timer.stop()
	sprite.stop()

func pause_time(paused: bool = true):
	timer.paused = paused
	paused = paused
