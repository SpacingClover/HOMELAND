class_name Player extends CharacterBody2D

@onready var sprite : Sprite2D = $body
@onready var legs : Sprite2D = $legs
@onready var muzzleflash : Sprite2D = $muzzleflash
@onready var camera : Camera2D = $Camera2D

var tweenx : Tween
var tweeny : Tween
var walkingtween : Tween
var world : CharacterBody2D
var mouseproxy : Marker2D

var getting_mouse : bool = false
var facing_left : bool = false
var facing_up : bool = false
var adjusting : bool = false
var moving : bool = false
var running : bool = false
var camera_no_adjust : bool = false
var camera_shaking : bool = false

var angle : int = 6
var left_limit : float = 0
var right_limit : float = 0
var top_limit : float = 0
var lower_limit : float = 0

var camera_pos_unclamped : Vector2
var camera_shake_pos : Vector2

func _ready()->void:
	Global.player = self
	Global.current_room = Global.current_region.rooms[0]
	world = get_parent().get_child(0)

func _input(event)->void:
	if event.is_action_pressed(&"click"):
		_shoot(Global.local_mouse_pos)
		
	elif event is InputEventMouseMotion and getting_mouse:
		mouse_motion()
	
	elif event.is_action_pressed(&"shift"):
		running = true
		
	elif event.is_action_released(&"shift"):
		running = false
	
	elif event.is_action(&"motion"):
		walking()
	
func _physics_process(_delta)->void:
	move_and_slide()
	camera.position = camera_pos_unclamped
	#camera.global_position.x = clamp(camera.global_position.x,left_limit,right_limit)
	#camera.global_position.y = clamp(camera.global_position.y,top_limit,lower_limit)
	
	if camera_shaking:
		camera.position += camera_shake_pos

func start_walking()->void:
	moving = true
	legs.frame = 13
	walkingtween = create_tween()
	walkingtween.tween_property(legs,"frame",16,0.5)
	walkingtween.finished.connect(start_walking)

func flip_x()->void:
	var campos : Vector2 = camera.global_position
	scale.x = -scale.x
	camera.global_position = campos
	camera_pos_unclamped = camera.position
	adjust_camera_x(400)

func adjust_camera_x(to:float)->void:
	if not camera_no_adjust:
		if tweenx:
			tweenx.stop()
		tweenx = create_tween()
		#tweenx.tween_property(self,"camera_pos_unclamped:x",to,0.5)

func adjust_camera_y(to:float)->void:
	if not camera_no_adjust:
		if tweeny:
			tweeny.stop()
		tweeny = create_tween()
		#tweeny.tween_property(self,"camera_pos_unclamped:y",to,0.5)

func shake_camera()->void:
	if not camera_no_adjust and not camera_shaking:
		camera_shaking = true
		var tween : Tween = create_tween()
		tween.set_parallel(false)
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.set_ease(Tween.EASE_OUT)
		var gotopos : float = 100 * (-1 if randi_range(-1,1) < 0 else 1)
		tween.tween_property(self,"camera_shake_pos:x",gotopos,0.05)
		tween.tween_property(self,"camera_shake_pos:x",0,0.5)
		
		await tween.finished
		camera_shaking = false

func _shoot(coords:Vector2,object:Node2D=null)->void:
	print(position)
	var flash : Flash = Global.flash.instantiate()
	world.add_child(flash)
	flash.flash(coords)
	muzzleflash.position = flashcoords[angle][0] + Vector2(0,-127.384)
	muzzleflash.rotation_degrees = flashcoords[angle][1]
	muzzleflash.frame = randi_range(0,3)
	muzzleflash.show()
	
	var obj : PhysicsBody2D = Global.player_controlling.interacting_with
	if obj and obj.has_method(&"shoot"):
		obj.shoot(coords < global_position)
	
	$Timer.start()
	await $Timer.timeout
	muzzleflash.hide()

func mouse_motion()->void:
	var mousepos : Vector2 = Global.local_mouse_pos
	angle = clamp((get_angle_to(mousepos)*10)/1.5,-6,6)
	
	if mousepos.x < global_position.x:
		if not facing_left:
			flip_x()
			facing_left = true
	elif facing_left:
		flip_x()
		facing_left = false
	
	if mousepos.y < sprite.global_position.y - 50:
		if not facing_up:
			facing_up = true
			adjust_camera_y(-300)
	elif facing_up and mousepos.y > global_position.y - 50:
		facing_up = false
		adjust_camera_y(100)
	
	angle += 6
	if facing_left:
		angle = 12-angle
	sprite.frame = angle

func walking()->void:
	var vel : Vector2 = Input.get_vector(&"a",&"d",&"w",&"s") * 600

	if vel == Vector2.ZERO:
		moving = false
		if walkingtween:
			walkingtween.stop()
			walkingtween = null
		legs.frame = 13
	
	elif not moving and not walkingtween:
		start_walking()
		
	if running:
		vel *= 2
	velocity = vel
	
	#Global.world3D.move_player_marker(Vector3(position.x,0,position.y))

var flashcoords : Array = [
	[Vector2(-10,-379),-90],
	[Vector2(15,-353),-90],
	[Vector2(42,-328),-90],
	[Vector2(328,-113),0],
	[Vector2(353,-88),0],
	[Vector2(379,-62),0],
	[Vector2(379,-36),0],
	[Vector2(353,-11),0],
	[Vector2(328,14),0],
	[Vector2(113,302),90],
	[Vector2(87,302),90],
	[Vector2(62,328),90],
	[Vector2(36,353),90]
]
