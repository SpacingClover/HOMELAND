class_name PlayerView extends Node3D

@onready var root : Node3D = $root
@onready var entities_root : Node3D = $entities

var player : Player3D:
	get: return Global.player

var room3d : RoomInterior3D
var loaded_rooms : Array[RoomInterior3D]
var camera : Camera3D:
	get: return player.camera
var viewport : GameView

func _ready()->void:
	root.position = Vector3.ZERO
	entities_root.position = Vector3.ZERO

func load_room_interior(room:Room,player_to_box:Box=null,player_from_box:Box=null)->void:
	
	if room3d:
		room3d.save_room_objects()
	
	root.position = Vector3.ZERO
	entities_root.position = Vector3.ZERO
	
	if room3d or is_instance_valid(room3d):
		room3d.queue_free()
	
	room3d = RoomInterior3D.new(room)
	root.add_child(room3d)
	
	var topos : Vector3 = player_to_box.global_coords
	if player_from_box:
		topos = lerp(topos,player_from_box.global_coords,0.49)
	
	if not player.is_inside_tree():
		await player.tree_entered
	
	player.position = topos
	player.position.y -= 1

func reset()->void:
	room3d.queue_free()
	for child : Node3D in root.get_children():
		child.queue_free()
	room3d = null
