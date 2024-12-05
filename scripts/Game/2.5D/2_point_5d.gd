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

func _ready()->void:
	root.position = Vector3.ZERO
	entities_root.position = Vector3.ZERO

func load_room_interior(room:Room,make_current:bool=false)->void:	
	if make_current:
		if room3d and is_instance_valid(room3d):
			var room_has_entities : bool = false
			for child : Node3D in room3d.get_children():
				if child is NPC:
					room_has_entities = true
			
			if room_has_entities:
				#room3d_rooms_buffer.append(room3d)
				root.remove_child(room3d)
				room_buffer_root.add_child(room3d)
			else:
				room3d.save_room_objects()
				room3d.queue_free()
		
		root.position = Vector3.ZERO
		entities_root.position = Vector3.ZERO
		
		if room.is_loaded:
			room3d = room.roominterior
			room_buffer_root.remove_child(room3d)
		else:
			room3d = RoomInterior3D.new(room)
		
		root.add_child(room3d)
	else:
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
		await get_tree().create_timer(0.1).timeout
		##if previous room is in buffer, handle unloading
		if fromroom and fromroom.roominterior.get_parent() == room_buffer_root:
			DEV_OUTPUT.push_message("room is in buffer")
			var buffer_room_has_npcs : bool = false
			for child : Node3D in fromroom.roominterior.get_children():
				if child is NPC or child is Player3D:
					DEV_OUTPUT.push_message("room has npcs")
					buffer_room_has_npcs = true
					break
			if not buffer_room_has_npcs:
				DEV_OUTPUT.push_message("unloading room")
				fromroom.roominterior.queue_free()

func reset()->void:
	if room3d and is_instance_valid(room3d):
		room3d.queue_free()
	for child : Node3D in root.get_children():
		child.queue_free()
	room3d = null
