class_name City extends Resource

static var LEFT : Vector3i   = Vector3i(0,0,-1)
static var RIGHT : Vector3i  = Vector3i(0,0,1)
static var TOP : Vector3i    = Vector3i(-1,0,0)
static var BOTTOM : Vector3i = Vector3i(1,0,0)
static var UP : Vector3i     = Vector3i(0,1,0)
static var DOWN : Vector3i   = Vector3i(0,-1,0)
static var DIRECTIONS : Array[Vector3i]:
	get: return [LEFT,RIGHT,TOP,BOTTOM,UP,DOWN]

static var UNTOUCHED : int = 0
static var REFUGEES  : int = 1
static var RESISTANCE_OCCUPIED : int = 2
static var GROUND_CONTESTED : int = 4
static var INVADERS_OCCUPIED : int = 8
static var MASS_EXECUTION : int = 16
static var BEING_BOMBED : int = 32
static var RUBBLE : int = 64
static var CORPSE_TOWN : int = 128

static var TOWN : int = 0
static var CITY : int = 1
static var METROPOLIS : int = 2
static var WATERWAYS : int = 4
static var TUNNELS : int = 8
static var MINES : int = 16
#some underground areas will have mutants

@export_category("City Data")
@export var state : int = UNTOUCHED
@export var type  : int = TOWN
@export var coords : Vector2i
@export var name : String
@export_category("Rooms Data")
@export var rooms : Array[Room]
@export var exits : Array[CityExit]
@export_category("Meta Data")
@export var validated : bool = false

var mapvisual : CityMarker3D

var index : int

func _init(being_generated:bool=false)->void:
	await Global.get_tree().process_frame
	var idx : int = 0
	update_indecies()

func enter_city()->void:
	if mapvisual:
		mapvisual.mark_current()

func exit_city()->void:
	if mapvisual:
		mapvisual.mark_normal()

func validate_city()->void:
	var idx : int = 0
	for room : Room in rooms:
		if not room or not is_instance_valid(room):
			delete_room(null,idx)
		idx += 1
	for room : Room in rooms:
		if not room.validated:
			room.validate(self)
	update_indecies()
	count_exits()
	validated = true

func create_room(size:Vector3i=Vector3i(1,1,1),pos:Vector3i=Vector3i(1,1,1))->Room:
	var room : Room = Room.new(size,pos,true)
	rooms.append(room)
	return room

func create_feature(size:Vector3i=Vector3i(1,1,1),pos:Vector3i=Vector3i(1,1,1))->Feature:
	var feature : Feature = Feature.new(Vector3i(1,1,1),Vector3i(1,1,1),true)
	rooms.append(feature)
	return feature

func create_city_exit(size:Vector3i=Vector3i(1,1,1),pos:Vector3i=Vector3i(1,1,1),dir:Vector3i=Vector3i.ZERO)->CityExit:
	var exit : CityExit = CityExit.new(size,pos,true,dir)
	rooms.append(exit)
	exits.append(exit)
	return exit

func count_exits()->void:
	exits.clear()
	for room : Room in rooms:
		if room is CityExit:
			exits.append(room)

func delete_room(room:Room=null,idx:int=-1)->void:
	if room and idx == -1:
		idx = room.index
	
	rooms.remove_at(idx)
	if room is Feature:
		if room is CityExit:
			exits.remove_at(idx)
			##handle removing cityexit
	
	update_indecies()

func update_indecies()->void:
	var idx : int = 0
	for room : Room in rooms:
		room.index = idx
		idx += 1
	
func remove_doubles()->void:
	var adjacient_rooms : Array[Room]
	var checkroom : Room
	var shuffledboxes : Array[Box]
	for room : Room in rooms:
		adjacient_rooms.clear()
		shuffledboxes.clear()
		shuffledboxes.append_array(room.boxes)
		shuffledboxes.shuffle()
		for box : Box in shuffledboxes:
			for dir : Vector3i in City.DIRECTIONS:
				if box.has_doorway(dir):
					checkroom = get_room_at(box.coords + dir)
					if adjacient_rooms.has(checkroom):
						box.set_door(dir,Box.WALL)
						get_box_at(box.coords + dir).set_door(-dir,Box.WALL)
					else:
						adjacient_rooms.append(checkroom)
			box.validated = true

func get_box_at(boxcoord:Vector3i)->Box:
	for room : Room in rooms:
		for box : Box in room.boxes:
			if box.coords == boxcoord:
				return box
	return null

func get_room_at(boxcoord:Vector3i)->Room:
	for room : Room in rooms:
		for box : Box in room.boxes:
			if box.coords == boxcoord:
				return room
	return null

func clear_visuals()->void:
	for room : Room in rooms:
		room.delete_room_visual()
		room.delete_room_interior()
		room.is_loaded = false

func check_for_adjacient_doors()->void:
	for room : Room in rooms:
		room.check_for_adjacient_doors(self)

func get_rooms_as_astar()->AStar3D:
	var astar : AStar3D = AStar3D.new()
	for room : Room in rooms:
		astar.add_point(room.index,room.coords)
	for room : Room in rooms:
		var connections : Array[int] = room.get_room_connections(self)
		for connection : int in connections:
			astar.connect_points(room.index,connection)
	return astar

func get_city_string()->String:
	if name != &"": return name
	return r"City " + str(index)
