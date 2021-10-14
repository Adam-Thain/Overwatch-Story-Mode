extends KinematicBody

# Declare member variables here.

# int
var jump = 5
var jumpNum = 0
var speed;
var crouch_speed = 20
var acceleration = 5
var blink_distance = 10
var damage = 100

# float
var default_move_speed = 4.0
var sprint_move_speed = 10
var crouch_move_speed = 1.5
var gravity = 9.8
var mouse_sensitivity = 0.1
var default_height = 1.5
var crouch_height = 0.5

# vector3
var direction = Vector3()
var velocity = Vector3()
var fall = Vector3()

# bool
var sprinting = false

#pointer
onready var head = $Head
onready var pcap = $CollisionShape
onready var bonker = $HeadBonker
onready var aimcast = $Head/Camera/AimCast
onready var muzzle = $Head/Gun/Muzzle

# Called when the node enters the scene tree for the first time.
func _ready():

	# Locks Cursor to the game window to ensure consistant aim
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x,deg2rad(-90),deg2rad(90))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):

	var head_bonked = false

	speed = default_move_speed

	direction = Vector3()
	
	# Head bonked on ceiling
	if bonker.is_colliding():
		head_bonked = true
	
	# Apply Gravity when in the air
	if not is_on_floor():
		fall.y -= gravity * delta

	# Shoot
	if Input.is_action_just_pressed("fire"):
		if aimcast.is_colliding():
			var bullet = get_world().direct_space_state
			var collision = bullet.intersect_ray(muzzle.global_transform.origin,aimcast.get_collision_point())
			if collision:
				var target = collision.collider
				if target.is_in_group("Enemy"):
					print(target.get_name() + " " + "is hit!")
					target.health -= damage

	# Single Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		if jumpNum == 0:
			fall.y = jump
			jumpNum = 1
			
	# Double Jump
	if Input.is_action_just_pressed("jump") and not is_on_floor():
		if jumpNum == 1:
			fall.y = jump
			jumpNum = 2

	if head_bonked:
		fall.y = -2

	if Input.is_action_pressed("ability_3"):
		speed = sprint_move_speed

	# Esc Key to exit game
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Crouching
	if Input.is_action_pressed("crouch"):
		pcap.shape.height -= crouch_speed * delta
		speed = crouch_move_speed
	elif not head_bonked:
		pcap.shape.height += crouch_speed * delta
		
	# Sets Upper and lower height limits based on crouching and standing
	pcap.shape.height = clamp(pcap.shape.height,crouch_height,default_height)

	# Forward Movement
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
		
		# Blink Forward
		if Input.is_action_just_pressed("ability_1"):
			translate(Vector3(0,0,-blink_distance))

	# Backward Movement
	elif Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
		
		# Blink Backward
		if Input.is_action_just_pressed("ability_1"):
			translate(Vector3(0,0,blink_distance))

	# Left Movement
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
		
		# Blink Left
		if Input.is_action_just_pressed("ability_1"):
			translate(Vector3(-blink_distance,0,0))

	# Right Movement
	elif Input.is_action_pressed("move_right"):
		direction += transform.basis.x
		
		# Blink Right
		if Input.is_action_just_pressed("ability_1"):
			translate(Vector3(blink_distance,0,0))

	direction = direction.normalized()
	velocity = velocity.linear_interpolate(direction * speed, acceleration * delta)
	velocity = move_and_slide(velocity, Vector3.UP)
	move_and_slide(fall, Vector3.UP,true)
	
	if is_on_floor():
		jumpNum = 0
