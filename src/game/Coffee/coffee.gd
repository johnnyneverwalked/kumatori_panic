extends Node2D

@onready var smoke: Line2D = $Line2D

var time: float = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	smoke.clear_points()
	for point in range(20):
		smoke.add_point(Vector2(0, -point * 3))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
	if time > 1000:
		time -= 1000
	for point in smoke.get_point_count():
		smoke.set_point_position(
			point, 
			Vector2(
				1 * sin(point + time * 2),
				smoke.get_point_position(point).y
			)
		)
