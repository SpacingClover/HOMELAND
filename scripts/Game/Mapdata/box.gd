class_name Box extends Resource

static var NONE : int = 1
static var WALL : int = 2
static var HOLE : int = 4
static var DOOR : int = 8
static var OPEN : int = 16
static var OPEN_OUT : int = 32
static var CITY_EXIT_DOOR : int = 64

static var NO_LOCK : int = -1

static var DEFAULT : int = 0
static var RUBBLE  : int = 1

static var brown : Color = Color(&"B36900")
static var red : Color = Color(&"FF2700")

var x : int:
	get:return coords.x
var y : int:
	get:return coords.y
var z : int:
	get:return coords.z
var global_coords : Vector3:
	get:return Vector3(-2*z,2*y,2*x)
var doors : Array[int]:
	get: return [door_right,door_left,door_top,door_bottom,door_up,door_down]

@export var coords : Vector3i
@export var door_right  : int = NONE
@export var door_left   : int = NONE
@export var door_top    : int = NONE
@export var door_bottom : int = NONE
@export var door_up     : int = NONE
@export var door_down   : int = NONE
@export var state       : int = DEFAULT
@export var validated : bool = false

@export var lock_right  : int = NO_LOCK
@export var lock_left   : int = NO_LOCK
@export var lock_top    : int = NO_LOCK
@export var lock_bottom : int = NO_LOCK
@export var lock_up     : int = NO_LOCK
@export var lock_down   : int = NO_LOCK

var boxvisual : MeshInstance3D
var doorvisuals : Array[DoorVisualReference] ##3d view icons
var doorinstances : Array[Door3DInstanceReference] ##2.5d view doors

func _init(pos:Vector3i=Vector3i.ZERO)->void:
	coords = pos

func get_room()->Room:
	return Global.get_room_has_coord(coords)

func get_door(direction:Vector3i)->int:
	match direction:
		City.LEFT:   return door_right
		City.RIGHT:  return door_left
		City.TOP:    return door_top
		City.BOTTOM: return door_bottom
		City.UP:     return door_up
		City.DOWN:   return door_down
	return NONE

func set_door(direction:Vector3i,to:int)->void:
	match direction:
		City.LEFT:   door_right  = to
		City.RIGHT:  door_left   = to
		City.TOP:    door_top    = to
		City.BOTTOM: door_bottom = to
		City.UP:     door_up     = to
		City.DOWN:   door_down   = to

func get_lock(direction:Vector3i)->int:
	match direction:
		City.LEFT:   return lock_right
		City.RIGHT:  return lock_left
		City.TOP:    return lock_top
		City.BOTTOM: return lock_bottom
		City.UP:     return lock_up
		City.DOWN:   return lock_down
	return NO_LOCK

func set_lock(direction:Vector3i,to:int)->void:
	match direction:
		City.LEFT:   lock_right  = to
		City.RIGHT:  lock_left   = to
		City.TOP:    lock_top    = to
		City.BOTTOM: lock_bottom = to
		City.UP:     lock_up     = to
		City.DOWN:   lock_down   = to

func has_doorway(direction:Vector3i,exclude_holes:bool=true,exclude_city_exit:bool=true)->bool:
	var checkval : int = WALL if not exclude_holes else HOLE
	var door : int = get_door(direction)
	#return door > checkval and door < CITY_EXIT_DOOR
	if door > checkval:
		if exclude_city_exit:
			if door < CITY_EXIT_DOOR:
				return true
		else:
			return true
			
	return false

func has_locked_door(direction:Vector3i)->bool:
	return get_lock(direction) != NO_LOCK

func has_opposite_doorway(direction:Vector3i,exclude_holes:bool=false)->bool:
	return has_doorway(-direction,exclude_holes)

func set_boxvisual_reference(mesh:MeshInstance3D)->void:
	boxvisual = mesh

func add_door_reference(mesh:MeshInstance3D,dir:Vector3i)->void:
	print(mesh)
	doorvisuals.append(DoorVisualReference.new(mesh,dir))

func get_door_reference(dir:Vector3i)->MeshInstance3D:
	for dvref : DoorVisualReference in doorvisuals:
		if dvref.is_direction(dir):
			var ref : MeshInstance3D = dvref.doorvisual
			return ref
	return null

func set_door_color(dir:Vector3i,color:Color)->void:
	var doormesh : MeshInstance3D = get_door_reference(dir)
	if not doormesh:
		print("returned")
		return
	var tween : Tween = Global.create_tween()
	tween.tween_property(doormesh.material_override,"albedo_color",color,0.1)
	await tween.finished
	print()

func remove_door_reference(mesh:MeshInstance3D=null,dir:Vector3i=Vector3i.ZERO)->void:
	var pos : int = 0
	for dvref : DoorVisualReference in doorvisuals:
		if dir != Vector3i.ZERO and dvref.is_direction(dir):
			dvref.doorvisual.queue_free()
			doorvisuals.remove_at(pos)
			return
		if mesh != null and dvref.doorvisual == mesh:
			dvref.doorvisual.queue_free()
			doorvisuals.remove_at(pos)
			return
		pos += 1

func delete_box_visual()->void:
	boxvisual.queue_free()

func delete_door_visual(dir:Vector3i)->void:
	if dir.length() != 1:
		return
	var mesh : MeshInstance3D = get_door_reference(dir)
	if mesh:
		remove_door_reference(mesh,dir)
		mesh.queue_free()

func get_door_instance(dir:Vector3i)->Door3DInstanceReference:
	for dinst_ref : Door3DInstanceReference in doorinstances:
		if dinst_ref.is_direction(dir):
			return dinst_ref
	return null

func check_for_adjacient_doors(city_ref:City)->Array[int]:
	var door : int
	var adjbox : Box
	var adjacient_rooms : Array[int]
	for dir : Vector3i in City.DIRECTIONS:
		door = get_door(dir)
		if door >= CITY_EXIT_DOOR: ## wall has recognized id
			continue
		if door > WALL: ## wall is of a door type
			adjbox = city_ref.get_box_at(coords+dir)
			if adjbox and adjbox.has_doorway(-dir):
				if adjbox.state != Box.RUBBLE and state != Box.RUBBLE:
					set_door_color(dir,red)
					adjbox.set_door_color(-dir,red)
					adjacient_rooms.append(city_ref.get_room_at(adjbox.coords).index)##
					return adjacient_rooms
				else:
					adjbox.set_door_color(-dir,brown)
					if adjbox.get_door(-dir) == OPEN or adjbox.get_door(-dir) == OPEN_OUT:
						adjbox.set_door(-dir,DOOR)
						if city_ref.get_room_at(adjbox.coords) == Global.current_room:
							adjbox.get_door_instance(-dir).door3dinstance.close()
							adjbox.get_door_instance(-dir).door3dinstance.handle_lock_icon()
							
			set_door_color(dir,brown)
			if get_door(dir) == OPEN or get_door(dir) == OPEN_OUT:
				set_door(dir,DOOR)
				if city_ref.get_room_at(coords) == Global.current_room:
					get_door_instance(dir).door3dinstance.close()
					get_door_instance(dir).door3dinstance.handle_lock_icon()
	return []

class DoorVisualReference extends RefCounted:
	var doorvisual : MeshInstance3D:
		set(x): doorvisual = x
		get: return doorvisual
	var direction : Vector3i
	func _init(mesh:MeshInstance3D,dir:Vector3i)->void:
		doorvisual = mesh
		#doorvisual.tree_exiting.connect(func()->void:
			#print("o");breakpoint)
		direction = dir
	func is_direction(dir:Vector3i)->bool:
		return direction == dir

class Door3DInstanceReference extends RefCounted:
	var door3dinstance : Door3D
	var direction : Vector3i
	func _init(door:Door3D,dir:Vector3i)->void:
		door3dinstance = door
		direction = dir
	func is_direction(dir:Vector3i)->bool:
		return direction == dir
