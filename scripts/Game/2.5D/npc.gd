class_name NPC extends CharacterBody3D

@onready var navagent : NavigationAgent3D = $navagent
var path_between_rooms : PackedInt64Array
var path_between_rooms_index : int
var is_navigating_between_rooms : bool = false

var speed : float = 3

var has_nav_target : bool = false

var inside_room : RoomInstance3D
var inside_city : City

func _ready()->void:
	pass

func _physics_process(delta:float)->void:
	if has_nav_target:
		if navagent.distance_to_target() <= 0.5: has_nav_target = false; DEV_OUTPUT.push_message("reached target")
		velocity = (navagent.get_next_path_position() - global_position).normalized() * speed
	move_and_collide(velocity*delta)
	velocity *= 0.85

func update_target_location(target_pos:Vector3)->void:
	Global.shooterscene.room3d.bake_navigation_mesh(true)
	await Global.shooterscene.room3d.bake_finished
	
	if navagent.is_target_reachable():
		navagent.target_position = target_pos
		has_nav_target = true

func pick_random_target_vec()->void:
	update_target_location(NavigationServer3D.region_get_random_point(Global.shooterscene.room3d.get_region_rid(),0,false))

func go_to_target_in_room(from:int,room:int,target:Vector3=Vector3.ZERO)->void:
	var astar : AStar3D = Global.current_region.get_rooms_as_astar()
	path_between_rooms = astar.get_id_path(from,room)
	path_between_rooms_index = -1
	is_navigating_between_rooms = true
	entered_room()

func entered_room()->void:  ##############call every time the npc enters a room##############
	if is_navigating_between_rooms:
		path_between_rooms_index += 1
		var door_coords : Vector3 = inside_room.get_door_leads_to_room(path_between_rooms[path_between_rooms_index],inside_city)
		update_target_location(door_coords)
		####YOU HAVE TO MAKE IT SO THAT OTHER ROOMS CAN BE LOADED THAT PLAYER IS NOT INSIDE OF
		####THEN YOU HAVE TO MAKE IT SO THE NPCS CAN DETECT DOORS
		####WHEN NPC DETECTS DOOR, IF IT IS ON PATH THROUGH IT, IT OPENS IT AND GOES THROUGH
		####WHEN NPC ENTERS ROOM, IT CALLS ENTERED ROOM
