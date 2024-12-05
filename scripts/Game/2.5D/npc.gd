class_name NPC extends CharacterBody3D

@onready var area : Area3D = $area
@onready var navagent : NavigationAgent3D = $navagent
var path_between_rooms : PackedInt64Array
var path_between_rooms_index : int
var is_navigating_between_rooms : bool = false
var target_object : Node3D
var target_room : int
var navigation_current_global_offset : Vector3
var local_nav_started_in_buffer : bool = false

var speed : float = 3

var has_nav_target : bool = false

var inside_room : Room
var inside_city : City

func _init()->void:
	pass

func _ready()->void:
	area.area_entered.connect(area_entered_area)
	inside_city = Global.current_region
	inside_room = get_parent().roomdata

func _physics_process(delta:float)->void:
	if has_nav_target:
		if navagent.distance_to_target() <= 0.5: has_nav_target = false
		velocity = navagent.get_next_path_position()
		velocity -= global_position
		print(velocity)
		velocity.y = 0
		velocity = velocity.normalized() * speed
	move_and_collide(velocity*delta)
	velocity *= 0.85

func update_target_object(object:Node3D)->void:
	var targetpos : Vector3 = object.global_position
	targetpos -= -Vector3(object.direction.z,object.direction.y,-object.direction.x)/4
	update_target_location(targetpos)
	target_object = object
	check_if_target_object_inside_area()

func update_target_location(target_pos:Vector3)->void:
	Global.shooterscene.room3d.bake_navigation_mesh(true)
	await Global.shooterscene.room3d.bake_finished
	
	navagent.target_position = target_pos
	if navagent.is_target_reachable():
		navigation_current_global_offset = inside_room.roominterior.global_position
		local_nav_started_in_buffer = not inside_room == Global.current_room
		has_nav_target = true
	else:
		DEV_OUTPUT.push_message("target unreachable")

func go_to_room(target_room_idx:int)->void:
	var door : Door3D = inside_room.roominterior.get_door_leads_to_room(target_room_idx,Global.current_region)
	if door: update_target_object(door)

func pick_random_target_vec()->void:
	update_target_location(NavigationServer3D.region_get_random_point(inside_room.roominterior.get_region_rid(),0,false))

func pathfind_between_rooms_to_room(room:int,target:Vector3=Vector3.ZERO)->void:
	var astar : AStar3D = inside_city.get_rooms_as_astar()
	path_between_rooms = astar.get_id_path(inside_room.index,room)
	DEV_OUTPUT.push_message(str(path_between_rooms))
	path_between_rooms_index = 0
	target_room = room
	is_navigating_between_rooms = true
	entered_room()

func entered_room()->void:  ##############call every time the npc enters a room##############
	await get_tree().create_timer(0.1).timeout
	inside_room = get_parent().roomdata
	if is_navigating_between_rooms:
		path_between_rooms_index += 1
		if inside_room.index == target_room:
			is_navigating_between_rooms = false
			pick_random_target_vec()
			return
		go_to_room(path_between_rooms[path_between_rooms_index])
		

func area_entered_area(col_area:Area3D)->void:
	if target_object and target_object is Door3D and col_area.get_parent() == target_object:
		if not target_object.is_open:
			target_object.open()
		target_object.send_entity_through_door(self)
		has_nav_target = false
		target_object = null

func check_if_target_object_inside_area()->void:
	for body : Node3D in area.get_overlapping_bodies():
		if body == target_object:
			for child : Node3D in body.get_children():
				if child is Area3D:
					area_entered_area(child)
