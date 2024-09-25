class_name Door3D extends Node3D

static var CLOSED      : int = 0
static var OPENIN      : int = 1
static var OPENOUT     : int = 2
static var UNHINGEDIN  : int = 3
static var UNHINGEDOUT : int = 4

@onready var area : Area3D = $area
@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var lock_icon : Sprite3D = $Armature/Skeleton3D/BoneAttachment3D/lock_icon
@onready var doorframe : MeshInstance3D = $Plane
@onready var doormesh : MeshInstance3D = $Armature/Skeleton3D/Plane_001

var box : Box

var direction : Vector3i

var state : int

var lock_id : int = Box.NO_LOCK

signal player_near_door
signal door_interacted
signal door_opened
signal tried_to_open_failed
signal door_closed

var is_open : bool:
	get: return not state == CLOSED
var locked : bool = false
var coyote_collision : bool = true #dont let the door detect the player for a moment after initializing

var is_victory_door : bool = false

func manual_init(door_box:Box,dir:Vector3i,starting_state:int,victory_door:bool=false)->void:
	state = starting_state
	box = door_box
	direction = dir
	is_victory_door = victory_door
	
	box.doorinstances.append(Box.Door3DInstanceReference.new(self,direction))
	
	embedded_tutorial_setup()

func _ready()->void:	
	area.body_entered.connect(body_entered)
	area.body_exited.connect(body_exited)
	anim.animation_finished.connect(parse_overlapping_bodies)
	
	handle_lock_icon()
	if is_victory_door:
		$Armature/Skeleton3D/Plane_001.material_override.albedo_color = Color.GREEN
	
	match state:
		CLOSED:
			pass
		OPENIN:
			anim.play(&"dooropenfront")
			anim.seek(INF,true)
		OPENOUT:
			anim.play(&"dooropenback")
			anim.seek(INF,true)
		UNHINGEDIN:
			anim.play(&"doorfalldownfront")
			anim.seek(INF,true)
		UNHINGEDOUT:
			anim.play(&"doorfalldownback")
			anim.seek(INF,true)
	
	set_opacity(true)
	
	var timer : Timer = Timer.new()
	add_child(timer)
	timer.start(0.1)
	
	await timer.timeout
	timer.queue_free()
	coyote_collision = false

func toggle_door()->void:
	if is_open:
		close()
	else:
		open()
		
	door_interacted.emit()

func open()->void: # any non-opening cases must return
	if is_victory_door and Global.current_region.get_room_at(box.coords).nextcity == -2:
		return
	
	var adj_box : Box = Global.current_region.get_box_at(box.coords + direction)
	var corresponding_locked : bool = false
	if adj_box: corresponding_locked = adj_box.has_locked_door(-direction)
	
	if lock_id != Box.NO_LOCK:
		var haskey : bool = false
		for item : RoomItem in Global.player.DEBUG_inventory:
			if item.extra_data[0] == lock_id:
				haskey = true
		if not haskey:
			return
	elif corresponding_locked:
		var haskey : bool = false
		var adj_box_lock_id : int = Global.current_region.get_box_at(box.coords + direction).get_lock(-direction)
		for item : RoomItem in Global.player.DEBUG_inventory:
			if item.extra_data[0] == adj_box_lock_id:
				haskey = true
		if not haskey:
			return
	
	var nextbox : Box = Global.current_region.get_box_at(box.coords+direction)
	if nextbox and nextbox.has_opposite_doorway(direction) and nextbox.state != Box.RUBBLE:
		anim.play(&"dooropenfront")
		state = OPENIN
		box.set_door(direction,Box.OPEN)
		nextbox.set_door(-direction,Box.OPEN_OUT)
	elif is_victory_door:
		anim.play(&"dooropenfront")
		state = OPENIN
	else:
		tried_to_open_failed.emit()
		return
		
	door_opened.emit()

func close()->void:
	if state == OPENIN:
		anim.play_backwards(&"dooropenfront")
	elif state == OPENOUT:
		anim.play_backwards(&"dooropenback")
	state = CLOSED
	box.set_door(direction,Box.DOOR)
	
	var nextbox : Box = Global.current_region.get_box_at(box.coords+direction)
	if nextbox and nextbox.has_opposite_doorway(direction):
		nextbox.set_door(-direction,Box.DOOR)
		
	door_closed.emit()

func parse_overlapping_bodies(_x:StringName)->void:
	for body : PhysicsBody3D in area.get_overlapping_bodies():
		body_entered(body)

func body_entered(body:PhysicsBody3D)->void:
	if body is Player3D and not coyote_collision:
		player_near_door.emit()
		
		if is_open:
			
			if not is_victory_door:
				var nextroom : Room = Global.current_region.get_room_at(box.coords+direction)
				var nextbox : Box = Global.current_region.get_box_at(box.coords+direction)
				if nextroom and nextbox:
					Global.enter_room(nextroom,nextbox,box)
			else:
				var exit : CityExit = Global.current_region.get_room_at(box.coords)
				if exit.nextcity >= 0 and exit.corresponding_exit >= 0:
					var nextcity : City = Global.current_game.cities[exit.nextcity]
					var nextexit : CityExit = nextcity.exits[exit.corresponding_exit]
					var nextexitroomsidx : int = nextcity.rooms.find(nextexit)
					Global.set_new_city(exit.nextcity,nextexitroomsidx)
				
				elif exit.nextcity == -1:
					Global.return_to_titlescreen()
				
				elif exit.nextcity == -2:
					return

func body_exited(body:PhysicsBody3D)->void:
	pass

func set_opacity(is_init:bool=false)->void:
	for mesh : MeshInstance3D in [$Plane,$Plane_002,$Armature/Skeleton3D/Plane_001]:
		if direction.x > 0:
			mesh.material_override.depth_draw_mode = StandardMaterial3D.DEPTH_DRAW_DISABLED
			mesh.material_override.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA_HASH
			mesh.material_override.albedo_color.a = 0.4
			#mesh.transparency = 0.5
		else:
			pass
			#mesh.transparency = 0
				

func embedded_tutorial_setup()->void:
	if not Tutorials.tutorial_enabled:
		return
		
	if Tutorials.next_tutorial_popup <= Global.TUTORIAL.INTERACT_DOOR:
		player_near_door.connect(Tutorials.call_tutorial.bind(Global.TUTORIAL.INTERACT_DOOR),CONNECT_ONE_SHOT)
	elif Tutorials.tutorial_enabled and Tutorials.next_tutorial_popup == Global.TUTORIAL.MOVE_ROOM:
		var call : Callable = Tutorials.call_tutorial.bind(Global.TUTORIAL.MOVE_ROOM)
		door_interacted.connect(call,CONNECT_ONE_SHOT)
		Global.tutorial_called.connect(func(which:int)->void:if(which)==Global.TUTORIAL.MOVE_ROOM:tried_to_open_failed.disconnect(call))

func handle_lock_icon()->void:
	var adj_box : Box = Global.current_region.get_box_at(box.coords + direction)
	var corresponding_locked : bool = false
	if adj_box: corresponding_locked = adj_box.has_locked_door(-direction)
	
	if corresponding_locked: ##if connected to locked door
		var color : Color
		color = KeyInstance.get_key_color(adj_box.get_lock(-direction))
		if direction == City.BOTTOM:
			color.a = 0.5
		lock_icon.modulate = color
		lock_icon.show()
	elif lock_id != Box.NO_LOCK: ##if connected isnt locked, but this one is
		var color : Color
		color = KeyInstance.get_key_color(lock_id)
		if direction == City.BOTTOM:
			color.a = 0.5
		lock_icon.modulate = color
		lock_icon.show()
	else: ##no locks to speak of
		lock_icon.hide()

func set_transparency(to:float)->void:
	doormesh.transparency = to
	doorframe.transparency = to
	lock_icon.transparency = to

func _exit_tree()->void:
	var ref : Box.Door3DInstanceReference = box.get_door_instance(direction)
	var idx : int = box.doorinstances.find(ref)
	box.doorinstances.remove_at(idx)
