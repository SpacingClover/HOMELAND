class_name NPC extends CharacterBody3D
##class used by npcs of all kinds
##only extend if you are adding new behavior

enum MAINSTATES{
	IDLE,
	COMBAT,
	DEAD
}

enum MOVEMENTSTATES{
	IDLE,
	MOVE_TO_POS,
	MOVE_TO_ENTITY
}

enum COMBATMODES{
	MELEE,
	GUN
}

## own components
@onready var area : Area3D = $area ## detect targets and interactables
@onready var entityarea : Area3D = $entityarea ## detect entities
@onready var shotcast : RayCast3D = $shottrace ## detect where shot goes
var navagent : NavigationAgent3D
var updatestatetimer : Timer
var attack_cooldown_timer : Timer

## object references
var target_enemy : Node3D
var target_object : Node3D
var inside_room : Room
var inside_city : City

## stats
var speed : float = 2

## npc state tracking
var path_between_rooms : PackedInt64Array
var path_between_rooms_index : int
var target_room : int

var mainstate : MAINSTATES = MAINSTATES.IDLE
var movementstate : MOVEMENTSTATES = MOVEMENTSTATES.IDLE
var combatmode : COMBATMODES = COMBATMODES.GUN

var has_nav_target : bool = false
var is_navigating_between_rooms : bool = false
var attack_cooldown : bool = false

func _init()->void:
	if not navagent:
		navagent = NavigationAgent3D.new()
		navagent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_EDGECENTERED
		add_child(navagent)
	if not updatestatetimer:
		updatestatetimer = Timer.new()
		updatestatetimer.autostart = true
		add_child(updatestatetimer)
	if not attack_cooldown_timer:
		attack_cooldown_timer = Timer.new()
		attack_cooldown_timer.one_shot = true
		add_child(attack_cooldown_timer)

func _ready()->void:
	area.area_entered.connect(area_entered_area)
	entityarea.body_entered.connect(body_entered_area)
	updatestatetimer.timeout.connect(pick_state)
	attack_cooldown_timer.timeout.connect(set.bind(&"attack_cooldown",false))
	inside_city = Global.current_region
	inside_room = get_parent().roomdata

func _physics_process(delta:float)->void:
	if movementstate != MOVEMENTSTATES.IDLE:
		if navagent.distance_to_target() <= 0.5:
			has_nav_target = false
			movementstate = MOVEMENTSTATES.IDLE
		else:
			velocity = navagent.get_next_path_position()
			velocity -= global_position
			velocity.y = 0
			velocity = velocity.normalized() * speed
	move_and_collide(velocity*delta)
	velocity *= 0.85

func _process(delta:float)->void:
	pass

var state_process_mutex : bool = false
func pick_state()->void:
	if state_process_mutex:
		return
	match mainstate:
		MAINSTATES.IDLE:
			pass
		MAINSTATES.COMBAT:
			match combatmode:
				COMBATMODES.MELEE:
					match movementstate:
						MOVEMENTSTATES.IDLE:
							update_target_object(target_enemy)
						MOVEMENTSTATES.MOVE_TO_ENTITY:
							update_target_object(target_enemy)
					if not attack_cooldown:
						try_attack_melee()
				COMBATMODES.GUN:
					match movementstate:
						MOVEMENTSTATES.IDLE:
							if target_enemy.inside_room != inside_room: ##give player inside_room property
								pathfind_between_rooms_to_room(target_enemy.inside_room.index,target_enemy.global_position)
							elif has_shot_at_target(target_enemy):
								if not attack_cooldown:
									shoot_at_target(target_enemy)
							else:
								var pos : Vector3 = await find_pos_can_see_target(target_enemy)
								DEV_OUTPUT.push_message(str(pos))
								if pos != global_position:
									update_target_location(pos)
								else:
									shoot_at_target(target_enemy) #shooting anyway
						MOVEMENTSTATES.MOVE_TO_ENTITY:
							pass
						MOVEMENTSTATES.MOVE_TO_POS:
							pass
		MAINSTATES.DEAD:
			pass

## combat ##

func find_pos_can_see_target(target:Node3D)->Vector3: #if cannot find pos, return current position of NPC
	state_process_mutex = true
	if not inside_room.roominterior.is_baking():
		inside_room.roominterior.bake_navigation_mesh()
	await inside_room.roominterior.bake_finished

	var targetpos : Vector3 = target.global_position
	if target is Player3D: targetpos.y += 1
	
	var points_see_target : Array[Vector3]
	
	for i : int in 100:
		var pos : Vector3 = NavigationServer3D.region_get_random_point(inside_room.roominterior.get_region_rid(),0,true)
		var cast_results : Dictionary = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(pos+Vector3(0,shotcast.global_position.y,0),targetpos,shotcast.collision_mask))
		if cast_results.collider == target:
			points_see_target.append(pos)
	
	var best_point : Vector3 #point that takes the least time to walk to
	var best_path_length : float = 999999
	if points_see_target.size() > 0:
		best_point = points_see_target[0]
	else:
		state_process_mutex = false
		return global_position
	
	for point : Vector3 in points_see_target:
		
		var navpath : PackedVector3Array = NavigationServer3D.map_get_path(inside_room.roominterior.get_region_rid(),global_position,point,true,1)
		var path_length : float = 0
		for i : int in navpath.size():
			if i + 1 >= navpath.size(): break
			path_length += navpath[i].distance_to(navpath[i+1])
		
		if path_length < best_path_length:
			best_point = point
			best_path_length = path_length
			
	state_process_mutex = false
	return best_point

func private_aim_shotcast_at_pos(pos:Vector3,cap_length:bool=true)->void:
	shotcast.target_position = Vector3.FORWARD
	shotcast.look_at(pos)
	shotcast.target_position *= shotcast.global_position.distance_to(pos) if cap_length else 99999
	shotcast.force_raycast_update()

func has_shot_at_target(target:Node3D)->bool:
	var targetpos : Vector3 = target.global_position
	if target is Player3D: targetpos.y += 1
	private_aim_shotcast_at_pos(targetpos)
	return shotcast.get_collider() == target

func shoot_at_target(target:Node3D)->void:
	var targetpos : Vector3 = target.global_position
	if target is Player3D: targetpos.y += 1
	private_aim_shotcast_at_pos(targetpos,false)
	
	await get_tree().create_timer(0.2).timeout #replace with a relevant shot delay
	
	Flash3D.new(shotcast.get_collision_point()) #physics should be applied to hit object, so it gets pushed
	attack_cooldown = true
	attack_cooldown_timer.start(1) #replace with the gun's real reload time

func try_attack_melee()->void:
	if not target_enemy:
		return
	
	if global_position.distance_to(target_enemy.global_position) < 0.75:
		attack_cooldown = true
		attack_cooldown_timer.start(0.5)
		DEV_OUTPUT.push_message(r"stab")

## navigation ##

func update_target_object(object:Node3D)->void:
	var targetpos : Vector3 = object.global_position
	if object is Door3D: targetpos -= -Vector3(object.direction.z,object.direction.y,-object.direction.x)/4
	private_update_target_location(targetpos)
	target_object = object
	check_if_target_object_inside_area()
	movementstate = MOVEMENTSTATES.MOVE_TO_ENTITY

func update_target_location(pos:Vector3)->void:
	private_update_target_location(pos)
	movementstate = MOVEMENTSTATES.MOVE_TO_POS

func private_update_target_location(target_pos:Vector3)->void:
	Global.shooterscene.room3d.bake_navigation_mesh(true)
	await Global.shooterscene.room3d.bake_finished
	
	navagent.target_position = target_pos
	if navagent.is_target_reachable():
		has_nav_target = true
	else:
		if mainstate == MAINSTATES.COMBAT and movementstate == MOVEMENTSTATES.MOVE_TO_ENTITY and target_enemy == Global.player and target_object == Global.player:
			pathfind_between_rooms_to_room(Global.current_room.index,Global.player.position)

func go_to_room(target_room_idx:int)->void:
	var door : Door3D = inside_room.roominterior.get_door_leads_to_room(target_room_idx,Global.current_region)
	if door:
		update_target_object(door)

func pick_random_target_vec()->void:
	private_update_target_location(NavigationServer3D.region_get_random_point(inside_room.roominterior.get_region_rid(),0,false))

func pathfind_between_rooms_to_room(room:int,target:Vector3=Vector3.ZERO)->void:
	var astar : AStar3D = inside_city.get_rooms_as_astar()
	path_between_rooms = astar.get_id_path(inside_room.index,room)
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
			return
		if path_between_rooms.size() == 0:
			movementstate = MOVEMENTSTATES.IDLE
			return
		go_to_room(path_between_rooms[path_between_rooms_index])
		

## utility ##

func area_entered_area(col_area:Area3D)->void:
	if target_object and target_object is Door3D and col_area.get_parent() == target_object:
		if not target_object.is_open:
			target_object.open()
		target_object.send_entity_through_door(self)
		has_nav_target = false
		target_object = null

func body_entered_area(col_body:PhysicsBody3D)->void:
	if col_body is Player3D and col_body == Global.player and inside_room == Global.current_room:
		DEV_OUTPUT.push_message(r"target player")
		target_enemy = col_body
		mainstate = MAINSTATES.COMBAT
		
		
		#update_target_object(col_body)
		#movementstate = MOVEMENTSTATES.MOVE_TO_ENTITY

func check_if_target_object_inside_area()->void:
	for body : Area3D in area.get_overlapping_areas():
		if body.get_parent() == target_object:
			area_entered_area(body)
