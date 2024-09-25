class_name wallend extends StaticBody2D

@onready var sprite : Sprite2D = $BackBufferCopy/spriteback
@onready var overlay : Sprite2D = $overlay/spritefront
@onready var door : Sprite2D = $door
@onready var tpbox : Area2D = $tp_box

var open : bool = false

var direction : Vector3i
var box_ref : City.Box
var type : int

func set_type(type:int)->void:
	match type:
		City.Box.OPEN:
			open_door()
			door.frame = 5
			sprite.frame = 1
			overlay.get_parent().hide()
		City.Box.DOOR:
			close_door()
			door.frame = 0
			sprite.frame = 1
			overlay.get_parent().hide()
		City.Box.WALL:
			door.hide()
			door.frame = 5
			sprite.frame = 0
			overlay.get_parent().hide()
		City.Box.HOLE:
			door.hide()
			sprite.frame = 2
			overlay.get_parent().hide()

func shoot(x)->void:
	pass

func action()->void:
	if type > 7: #if is door
		if open:
			close_door()
		else:
			open_door()

func open_door()->void:
	open = true
	if Global.current_region.get_box_at(box_ref.coords+direction):
		var tween : Tween = create_tween()
		tween.tween_property($door,"frame",5,0.5)
		overlay.get_parent().show()
		set_box_door_state(Vector3i.ZERO,direction,City.Box.OPEN,box_ref)
		set_box_door_state(box_ref.coords+direction,-direction,City.Box.OPEN)
		tpbox.body_entered.connect(body_in)

func close_door()->void:
	open = false
	if Global.current_region.get_box_at(box_ref.coords+direction):
		var tween : Tween = create_tween()
		tween.tween_property($door,"frame",0,0.5)
		overlay.get_parent().hide()
		set_box_door_state(Vector3i.ZERO,direction,City.Box.DOOR,box_ref)
		set_box_door_state(box_ref.coords+direction,-direction,City.Box.DOOR)
		tpbox.body_entered.disconnect(body_in)

func _ready()->void:
	position.x -= 8
	set_type(type)

func body_in(body:PhysicsBody2D)->void:
	if body is Player and not Global.tilemap.room_just_loaded:
		var next_room : City.Room = Global.current_region.get_room_at(box_ref.coords + direction)
		var next_box : City.Box = Global.current_region.get_box_at(box_ref.coords + direction)
		
		if not next_box or not next_box.has_opposite_doorway(direction):
			return
		
		var playerdisp : Vector2 = Vector2(direction.z,abs(direction.x)+direction.y) * 100
		#body.global_position = position
		if next_room:
			Global.current_room = next_room

func set_box_door_state(boxcoord:Vector3i,door_direction:Vector3i,to:int,box:City.Box=null)->void:
	if not box:
		box = Global.current_region.get_box_at(boxcoord)
		
	match door_direction:
		City.LEFT:
			box.door_left = to
		City.RIGHT:
			box.door_right = to
		City.TOP:
			box.door_top = to
		City.BOTTOM:
			box.door_bottom = to
		City.UP:
			box.door_up = to
		City.DOWN:
			box.door_down = to
