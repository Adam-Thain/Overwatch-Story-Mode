extends KinematicBody

var health = 200

func _ready():
	pass

func _process(_delta):
	if health <= 0:
		queue_free()
		print("Eliminated Enemy")
