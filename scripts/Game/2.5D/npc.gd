class_name NPC extends CharacterBody3D

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

## own components
@onready var area : Area3D = $area ## detect targets and interactables
@onready var entityarea : Area3D = $entityarea ## detect entities
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

var has_nav_target : bool = false
var is_navigating_between_rooms : bool = false
var attack_cooldown : bool = false

func _init()->void:
	navagent = NavigationAgent3D.new()
	navagent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_EDGECENTERED
	add_child(navagent)
	updatestatetimer = Timer.new()
	updatestatetimer.wait_time = 0.5
	updatestatetimer.autostart = true
	add_child(updatestatetimer)
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
		if navagent.distance_to_target() <= 0.5: has_nav_target = false
		velocity = navagent.get_next_path_position()
		velocity -= global_position
		velocity.y = 0
		velocity = velocity.normalized() * speed
	move_and_collide(velocity*delta)
	velocity *= 0.85

func _process(delta:float)->void:
	pass

func pick_state()->void:
	match mainstate:
		MAINSTATES.IDLE:
			pass
		MAINSTATES.COMBAT:
			match movementstate:
				MOVEMENTSTATES.MOVE_TO_ENTITY:
					update_target_object(target_enemy)
			if not attack_cooldown:
				attack()
				
		MAINSTATES.DEAD:
			pass

func attack()->void:
	if not target_enemy:
		return
	
	if global_position.distance_to(target_enemy.global_position) < 0.75:
		attack_cooldown = true
		attack_cooldown_timer.start()
		DEV_OUTPUT.push_message(r"stab")

## navigation ##

func update_target_object(object:Node3D)->void:
	var targetpos : Vector3 = object.global_position
	if object is Door3D: targetpos -= -Vector3(object.direction.z,object.direction.y,-object.direction.x)/4
	update_target_location(targetpos)
	target_object = object
	check_if_target_object_inside_area()

func update_target_location(target_pos:Vector3)->void:
	Global.shooterscene.room3d.bake_navigation_mesh(true)
	await Global.shooterscene.room3d.bake_finished
	
	navagent.target_position = target_pos
	if navagent.is_target_reachable():
		has_nav_target = true
	else:
		if mainstate == MAINSTATES.COMBAT and movementstate == MOVEMENTSTATES.MOVE_TO_ENTITY and target_enemy == Global.player and target_object == Global.player:
			DEV_OUTPUT.push_message(r"update path")
			pathfind_between_rooms_to_room(Global.current_room.index,Global.player.position)

func go_to_room(target_room_idx:int)->void:
	var door : Door3D = inside_room.roominterior.get_door_leads_to_room(target_room_idx,Global.current_region)
	if door:
		update_target_object(door)

func pick_random_target_vec()->void:
	update_target_location(NavigationServer3D.region_get_random_point(inside_room.roominterior.get_region_rid(),0,false))

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
		update_target_object(col_body)
		movementstate = MOVEMENTSTATES.MOVE_TO_ENTITY
		mainstate = MAINSTATES.COMBAT
		target_enemy = col_body

func check_if_target_object_inside_area()->void:
	for body : Area3D in area.get_overlapping_areas():
		if body.get_parent() == target_object:
			area_entered_area(body)
