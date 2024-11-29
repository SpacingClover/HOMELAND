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

func load_room_interior(room:Room,player_to_box:Box=null,player_from_box:Box=null)->void:
	
	var is_constructing_room : bool = true
	
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
		is_constructing_room = false
	else:
		room3d = RoomInterior3D.new(room)
	
	root.add_child(room3d)
	
	var topos : Vector3 = player_to_box.global_coords
	if player_from_box:
		topos = lerp(topos,player_from_box.global_coords,0.49)
	
	player.position = topos
	player.position.y -= 1
	
	if is_constructing_room and not room3d.is_node_ready():
		await room3d.room_constructed
	room3d.give_player_camera_info(player)

func reset()->void:
	room3d.queue_free()
	for child : Node3D in root.get_children():
		child.queue_free()
	room3d = null
