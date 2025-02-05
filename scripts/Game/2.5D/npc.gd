class_name NPC extends Entity
##class used by npcs of all kinds
##only extend if you are adding new behavior

## own components
@onready var area : Area3D = $area ## detect targets and interactables
@onready var entityarea : Area3D = $entityarea ## detect entities
@onready var shotcast : RayCast3D = $shottrace ## detect where shot goes
var navagent : NavigationAgent3D
var updatestatetimer : Timer
var attack_cooldown_timer : Timer

## stats
var speed : float = 2

## npc state tracking
var path_between_rooms : PackedInt64Array
var path_between_rooms_index : int
var target_room : int

var has_nav_target : bool = false
var is_navigating_between_rooms : bool = false
var attack_cooldown : bool = false

func _init()->void:
	pass

func configure(faction_:int=0,weapon:int=COMBATMODES.GUN)->void:
	faction = faction_
	var tex : CompressedTexture2D
	match faction:
		OROTOF_CIVILIAN:      tex = load("res://visuals/spritesheets/characters/civilian.png")
		OROTOF_GOVERNMENT:    tex = load("res://visuals/spritesheets/characters/homeland_soldier-9.png")
		CAMTO_GOVERNMENT:     tex = load("res://visuals/spritesheets/characters/invading_soldier_9.png")
		OROTOF_RESISTANCE:    tex = load("res://visuals/spritesheets/characters/ally-1(1).png")
		RAKATLAND_GOVERNMENT: tex = load("res://visuals/spritesheets/characters/rakatland.png")
		_:                    tex = load("res://visuals/spritesheets/characters/default.png"); weapon = COMBATMODES.NONE
	sprite.texture = tex
	legs.texture = tex
	combatmode = weapon
	if faction == OROTOF_CIVILIAN:
		combatmode = COMBATMODES.NONE
	if faction == SCARY:
		combatmode = 100

func _ready()->void:
	inside_city = Global.current_region
	inside_room = get_parent().roomdata
	if active:
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
		DEV_OUTPUT.push_message(r"entity initialized active")
		area.area_entered.connect(area_entered_area)
		entityarea.body_entered.connect(body_entered_area)
		updatestatetimer.timeout.connect(pick_state)
		attack_cooldown_timer.timeout.connect(set.bind(&"attack_cooldown",false))
		await get_tree().create_timer(1).timeout
		entered_room()
	else:
		set_process(false)
		set_physics_process(false)

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
	if (target_enemy and target_enemy.mainstate == Entity.MAINSTATES.DEAD) or (target_enemy and not is_instance_valid(target_enemy)) or not target_enemy:
		target_enemy = null
		check_bodies_in_area()
	if state_process_mutex:
		return
	match mainstate:
		MAINSTATES.IDLE:
			check_bodies_in_area()
			match combatmode:
				COMBATMODES.NONE:
					match movementstate:
						MOVEMENTSTATES.IDLE:
							if target_enemy:
								go_to_cover_from_target(target_enemy)
		MAINSTATES.COMBAT:
			match combatmode:
				COMBATMODES.NONE:
					match movementstate:
						MOVEMENTSTATES.IDLE:
							if target_enemy:
								go_to_cover_from_target(target_enemy)
				COMBATMODES.MELEE:
					match movementstate:
						MOVEMENTSTATES.IDLE:
							update_target_object(target_enemy)
						MOVEMENTSTATES.MOVE_TO_ENTITY:
							update_target_object(target_enemy)
					if not attack_cooldown:
						try_attack_melee()
				COMBATMODES.GUN:
					handle_shooting_at_enemy()
		MAINSTATES.DEAD:
			set_physics_process(false)
		MAINSTATES.DEBUGSTATE:
			pass

## NPC relations ##

func react_to_entity(entity:PhysicsBody3D)->void:
	if target_enemy:
		return
	if entity.mainstate == MAINSTATES.DEAD:
		return
	if entity == self:
		return
	
	match get_faction_relation(get_faction(),entity.get_faction()):
		NEUTRAL:
			pass
		FRIENDLY:
			pass ##react to ally
		ENEMY:
			target_enemy = entity
			mainstate = MAINSTATES.COMBAT
			if target_enemy.combatmode > combatmode:
				go_to_cover_from_target(target_enemy)
			
	### needs behavior for running away

func get_faction()->int:
	return faction

## combat ##

func go_to_cover_from_target(target:Node3D)->void:
	var pos : Vector3 = await find_pos_cannot_see_target(target)
	if pos != global_position:
		update_target_location(pos)

func find_pos_can_see_target(target:Node3D)->Vector3: #if cannot find pos, return current position of NPC
	return await private_find_pos_can_or_cant_see_target(target)

func find_pos_cannot_see_target(target:Node3D)->Vector3:
	return await private_find_pos_can_or_cant_see_target(target,false)

func private_find_pos_can_or_cant_see_target(target:Node3D,checking_can_see:bool=true)->Vector3:
	state_process_mutex = true
	if not inside_room.roominterior.is_baking():
		inside_room.roominterior.bake_navigation_mesh()
	await inside_room.roominterior.bake_finished

	var targetpos : Vector3 = target.global_position
	if target is Player3D: targetpos.y += 1
	
	var points : Array[Vector3]
	
	for i : int in 100:
		var pos : Vector3 = NavigationServer3D.region_get_random_point(inside_room.roominterior.get_region_rid(),1,true)
		var ray_offset : Vector3 = ((targetpos - pos).rotated(Vector3.UP,deg_to_rad(90))/2)
		#var cast_results : Dictionary = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(pos,pos+ray_offset,32))
		
		var raycastnode : RayCast3D = RayCast3D.new()
		inside_room.roominterior.add_child(raycastnode)
		raycastnode.collision_mask = 32
		raycastnode.global_position = pos + Vector3(0,0.5,0)
		raycastnode.target_position = ray_offset# + Vector3(0,0.5,0)
		raycastnode.force_raycast_update()
		if raycastnode.is_colliding():
			if not checking_can_see:
				points.append(pos)
				raycastnode.debug_shape_custom_color = Color.RED
		elif checking_can_see:
			raycastnode.debug_shape_custom_color = Color.WHITE
			points.append(pos)
		raycastnode.queue_free()
	
	if points.is_empty():
		DEV_OUTPUT.push_message(r"didnt find")
		state_process_mutex = false
		return global_position
	else:
		DEV_OUTPUT.push_message(r"found point")
		state_process_mutex = false
		return points.pick_random()

func handle_shooting_at_enemy()->void:
	if not target_enemy: check_bodies_in_area(); return
	if not is_instance_valid(target_enemy): target_enemy = null; check_bodies_in_area(); return
	if target_enemy.inside_room != inside_room: ##give player inside_room property
		pathfind_between_rooms_to_room(target_enemy.inside_room.index,target_enemy.global_position)
	elif has_shot_at_target(target_enemy):
		if not attack_cooldown:
			shoot_at_target(target_enemy)
	else:
		var pos : Vector3 = await find_pos_can_see_target(target_enemy)
		if pos != global_position:
			update_target_location(pos)
		else:
			shoot_at_target(target_enemy) #shooting anyway

func private_aim_shotcast_at_pos(pos:Vector3,cap_length:bool=true)->void:
	shotcast.target_position = Vector3.FORWARD
	shotcast.look_at(pos)
	shotcast.target_position *= shotcast.global_position.distance_to(pos) if cap_length else 100
	shotcast.force_raycast_update()

func has_shot_at_target(target:Node3D)->bool:
	var targetpos : Vector3 = target.global_position
	#if target is Player3D: targetpos.y += 1
	targetpos.y += 0.67
	private_aim_shotcast_at_pos(targetpos)
	return shotcast.get_collider() == target

func shoot_at_target(target:Node3D)->void:
	var targetpos : Vector3 = target.global_position
	#if target is Player3D:
	targetpos.y += 0.67
	private_aim_shotcast_at_pos(targetpos,false)
	
	await get_tree().create_timer(randf_range(0.05,0.2)).timeout #replace with a relevant shot delay
	if mainstate == MAINSTATES.DEAD: return
	
	Flash3D.new(shotcast.get_collision_point()) #physics should be applied to hit object, so it gets pushed
	if shotcast.get_collider() is Entity:
		var shot_response : AttackResponse = shotcast.get_collider().shoot_and_get_data()
		if shot_response.killed:
			target_enemy = null
			movementstate = MOVEMENTSTATES.IDLE
			mainstate = MAINSTATES.IDLE
			##maybe it should look for a new target here
	attack_cooldown = true
	attack_cooldown_timer.start(1) #replace with the gun's real reload time

func try_attack_melee()->void:
	if not target_enemy:
		return
	
	if global_position.distance_to(target_enemy.global_position) < 0.75:
		attack_cooldown = true
		attack_cooldown_timer.start(0.5)
		var attack_response : AttackResponse = target_enemy.melee_and_get_data()
		if attack_response.killed:
			target_enemy = null
			movementstate = MOVEMENTSTATES.IDLE
			mainstate = MAINSTATES.IDLE
			##maybe it should look for a new target here

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
	inside_room.roominterior.entity_entered_room.emit(self)
	inside_room.roominterior.entity_entered_room.connect(react_to_entity)
	for child : Node in inside_room.roominterior.get_children():
		if child is Entity:
			react_to_entity(child)
	if is_navigating_between_rooms:
		path_between_rooms_index += 1
		if inside_room.index == target_room:
			is_navigating_between_rooms = false
			return
		if path_between_rooms.size() == 0:
			movementstate = MOVEMENTSTATES.IDLE
			return
		go_to_room(path_between_rooms[path_between_rooms_index])

func exited_room()->void:
	inside_room.roominterior.entity_entered_room.disconnect(react_to_entity)

## utility ##

func area_entered_area(col_area:Area3D)->void:
	if target_object and target_object is Door3D and col_area.get_parent() == target_object:
		if not target_object.is_open:
			target_object.open()
		target_object.send_entity_through_door(self)
		has_nav_target = false
		target_object = null

func check_bodies_in_area()->void:
	for body : PhysicsBody3D in entityarea.get_overlapping_bodies():
		body_entered_area(body)

func body_entered_area(col_body:PhysicsBody3D)->void:
	if col_body is Entity and col_body.inside_room == inside_room:
		react_to_entity(col_body)

func check_if_target_object_inside_area()->void:
	for body : Area3D in area.get_overlapping_areas():
		if body.get_parent() == target_object:
			area_entered_area(body)
