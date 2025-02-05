class_name Room extends Resource

static var ONEBYONE : Vector3i   = Vector3i(1,1,1)
static var ONEBYTWO : Vector3i   = Vector3i(1,1,2)
static var ONEBYTHREE : Vector3i = Vector3i(1,1,3)
static var TWOBYTWO : Vector3i   = Vector3i(2,1,2)

@export_category("Contents")
@export var items : Array[RoomItem]
@export var entities : Array[RoomEntity]
@export_category("Box Data")
@export var boxes : Array[Box]
@export_category("Transform")
@export var coords : Vector3i
@export var scale : Vector3i
@export var original_coords : Vector3i
@export_category("Meta Data")
@export var validated : bool = false
@export var original_coords_set : bool = false:
	set(x):
		original_coords_set = x
		if not x:
			original_coords = coords
			original_coords_set = true

var roomvisual : RoomInstance3D
var roominterior : RoomInterior3D
var index : int
var is_loaded : bool = false:
	set(x): is_loaded = x

func _init(size:Vector3i=Vector3i.ZERO,pos:Vector3i=Vector3i.ZERO,being_generated:bool=false)->void:
	if being_generated:
		boxes.clear()
		coords = pos
		scale = size
		for x : int in range(size.x):
			for y : int in range(size.y):
				for z : int in range(size.z):
					boxes.append(Box.new(Vector3i(pos.x+x,pos.y+y,pos.z+z)))
		boxes.reverse()
		original_coords = coords
		original_coords_set = true

func validate(city_ref:City)->void:
	if not validated:
		scale = abs(scale)
		if scale.x == 0:scale.x = 1
		if scale.y == 0:scale.y = 1
		if scale.z == 0:scale.z = 1
		var prod : int = abs(scale.x * scale.y * scale.z)
		if prod != boxes.size():
			_init(scale,coords,true)
		validated = true
		for box : Box in boxes:
			for dir : Vector3i in City.DIRECTIONS:
				if city_ref.get_room_at(box.coords+dir) == self:
					box.set_door(dir,Box.NONE)
				else:
					box.set_door(dir,Box.WALL)
		index = city_ref.rooms.find(self)
	

func add_to_position(add:Vector3i)->void:
	for box : Box in boxes:
		box.coords += add
	coords += add

func get_room_center()->Vector3:
	var center : Vector3 = Vector3.ZERO
	for box : Box in boxes:
		center += Vector3(box.coords)
	center /= len(boxes)
	return center

#global accuracy is not garunteed
func get_x_min()->int:
	var result : int = boxes[0].x
	for box : Box in boxes:
		if box.x < result:
			result = box.x
	return result
func get_x_max()->int:
	var result : int = boxes[0].x
	for box : Box in boxes:
		if box.x > result:
			result = box.x
	return result
func get_y_min()->int:
	var result : int = boxes[0].y
	for box : Box in boxes:
		if box.y < result:
			result = box.y
	return result
func get_y_max()->int:
	var result : int = boxes[0].y
	for box : Box in boxes:
		if box.y > result:
			result = box.y
	return result
func get_z_min()->int:
	var result : int = boxes[0].z
	for box : Box in boxes:
		if box.z < result:
			result = box.z
	return result
func get_z_max()->int:
	var result : int = boxes[0].z
	for box : Box in boxes:
		if box.z > result:
			result = box.z
	return result
func get_min_in_direction(dir:Vector3i)->int:
	if dir.x != 0:
		return get_x_min()
	elif dir.y != 0:
		return get_y_min()
	elif dir.z != 0:
		return get_z_min()
	return 0
func get_max_in_direction(dir:Vector3i)->int:
	if dir.x != 0:
		return get_x_max()
	elif dir.y != 0:
		return get_y_max()
	elif dir.z != 0:
		return get_z_max()
	return 0
func get_furthest_in_direction(dir:Vector3i)->int:
	if dir.x < 0 or dir.y < 0 or dir.z < 0:
		return get_min_in_direction(dir)
	else:
		return get_max_in_direction(dir)

func delete_room_visual()->void:
	var pos : int = 0
	for roomvisref : RoomInstance3D in Global.world3D.rooms_3D:
		if roomvisref == roomvisual:
			Global.world3D.rooms_3D.remove_at(pos)
			break
		pos += 1
	if roomvisual and is_instance_valid(roomvisual):
		roomvisual.queue_free()
	roomvisual = null

func delete_room_interior()->void:
	var pos : int = 0
	if is_loaded and roominterior and is_instance_valid(roominterior):
		if self == Global.current_room:
			Global.shooterscene.room3d = null
		roominterior.queue_free()
		roominterior = null

func check_for_adjacient_doors(city_ref:City)->void:
	for box : Box in boxes:
		box.check_for_adjacient_doors(city_ref)
	if Global.current_room == self and Global.current_room.is_loaded and Global.current_room.roominterior and is_instance_valid(Global.shooterscene) and Global.shooterscene.room3d and is_instance_valid(Global.shooterscene.room3d):
		for door : Door3D in Global.shooterscene.room3d.doors:
			door.handle_lock_icon()

func get_room_connections(city_ref:City)->Array[int]:
	var adjacient_rooms : Array[int]
	for box : Box in boxes:
		adjacient_rooms.append_array(box.check_for_adjacient_doors(city_ref))
	return adjacient_rooms
