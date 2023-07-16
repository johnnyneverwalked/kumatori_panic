extends Node2D


@onready var bear: Bear = $Bear

# Called when the node enters the scene tree for the first time.
func _ready():
	bear.place_chic.connect(func(chic):
		if chic and chic is Chic:
			$Nest.add_child(chic)
	)
	
	for chic in $Nest.get_children():
		chic.color = randi_range(0, GameManager.Colors.size())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
