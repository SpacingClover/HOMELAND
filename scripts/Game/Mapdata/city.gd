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

func _init(being_generated:bool=false)->void:
	await Global.get_tree().process_frame
	var idx : int = 0
	for room : Room in rooms:
		room.index = idx
		idx += 1

func enter_city()->void:
	if mapvisual:
		mapvisual.mark_current()

func exit_city()->void:
	if mapvisual:
		mapvisual.mark_normal()

func validate_city()->void:
	for room : Room in rooms:
		if not room.validated:
			room.validate()
	set_doors() #this has gotta be changed #make it so only unvalidated rooms are affected
	remove_doubles() #not good at all
	count_exits()
	validated = true

func generate()->void:
	
	validate_city()

func create_room(size:Vector3i,pos:Vector3i)->void:
	rooms.append(Room.new(size,pos,true))

func create_city_exit(size:Vector3i,pos:Vector3i,dir:Vector3i)->void:
	rooms.append(CityExit.new(size,pos,true,dir))
	exits.append(rooms.back())

func count_exits()->void:
	exits.clear()
	for room : Room in rooms:
		if room is CityExit:
			exits.append(room)

func set_doors()->void: #this might need to be threaded
	for room : Room in rooms:
		for box : Box in room.boxes:
			for dir : Vector3i in DIRECTIONS:
				var set_to : int = configure_door(room,box,dir)
				if box.state == Box.RUBBLE and set_to >= Box.WALL:
					set_to = Box.HOLE
				if box.get_door(dir) < Box.CITY_EXIT_DOOR:
					box.set_door(dir,set_to)

func configure_door(from_room:Room,from_box:Box,dir:Vector3i)->int:
	var checkpos : Vector3i = from_box.coords + dir
	for to_room : Room in rooms:
		for to_box : Box in to_room.boxes:
			if to_box.coords == checkpos:
				if to_room == from_room:
					return Box.NONE
				else:
					return Box.DOOR
	return Box.WALL
	
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
