class_name PlayerView extends Node3D

@onready var root : Node3D = $root
@onready var entities_root : Node3D = $entities
@onready var room_buffer_root : Node3D = $room_buffer_root

var player : Player3D:
	get: return Global.player

var room3d : RoomInterior3D
var camera : Camera3D:
	get: return player.camera
var viewport : GameView

func load_room_interior(room:Room,make_current:bool=false)->void:
	if make_current:
		##handle old room
		if room3d:
			move_room_to_buffer(room3d)
		
		##handle new room
		if room.is_loaded:
			take_room_from_buffer(room.roominterior)
		else:
			room3d = RoomInterior3D.new(room)
			root.add_child(room3d)
		
		##handle adjacient rooms
		for roomindex : int in room.get_room_connections(Global.current_region):
			load_room_interior(Global.current_region.rooms[roomindex])
		clean_room_buffer()
		
	elif not room.is_loaded:
		var buffroom : RoomInterior3D = RoomInterior3D.new(room)
		room_buffer_root.add_child(buffroom)

func send_entity_to_room(entity:Node3D,room:Room,tobox:Box=null,frombox:Box=null,fromroom:Room=null)->void:
	var is_constructing_room : bool = false
	if not room.is_loaded:
		is_constructing_room = true
	load_room_interior(room,entity is Player3D)
	
	var topos : Vector3 = tobox.global_coords
	if frombox: topos = lerp(topos,frombox.global_coords,0.49)
	
	if not entity is Player3D:
		entity.get_parent().remove_child(entity)
		room.roominterior.add_child(entity)
	entity.global_position = topos + room.roominterior.get_parent().global_position 
	entity.global_position.y -= 1
	
	entity.entered_room()
	
	if entity is Player3D:
		if is_constructing_room and not room3d.is_node_ready():
			await room3d.room_constructed
		room3d.give_player_camera_info(player)
	else:
		if can_unload_room(fromroom):
			await get_tree().process_frame #has to await twice to get the next frame, because function is initiated via physics frame
			await get_tree().process_frame
			fromroom.roominterior.unload_room()

func can_unload_room(room:Room)->bool:
	if room and room.is_loaded and room != Global.current_room:
		for child : Node3D in room.roominterior.get_children():
			if child is NPC or child is Player3D:
				return false
	return true

func clean_room_buffer()->void:
	for bufferroom : RoomInterior3D in room_buffer_root.get_children():
		if can_unload_room(bufferroom.roomdata):
			bufferroom.unload_room()

func reset()->void:
	if room3d and is_instance_valid(room3d):
		room3d.queue_free()
	for child : Node3D in root.get_children():
		child.queue_free()
	room3d = null

func move_room_to_buffer(roominterior:RoomInterior3D)->void:
	root.remove_child(room3d)
	room_buffer_root.add_child(room3d)

func take_room_from_buffer(roominterior:RoomInterior3D)->void:
	room3d = roominterior
	room_buffer_root.remove_child(room3d)
	root.add_child(room3d)
	
