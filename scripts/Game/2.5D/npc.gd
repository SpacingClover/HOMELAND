class_name NPC extends CharacterBody3D

@onready var navagent : NavigationAgent3D = $navagent

var speed : float = 3

var has_nav_target : bool = false

func _ready()->void:
	pick_random_target_vec()
	navagent.target_reached.connect(func()->void:await get_tree().create_timer(1).timeout;pick_random_target_vec())

func _physics_process(delta:float)->void:
	if has_nav_target:
		if navagent.distance_to_target() <= 0.5: has_nav_target = false
		velocity = (navagent.get_next_path_position() - global_position).normalized() * speed
	move_and_slide()
	velocity *= 0.85

func update_target_location(target_pos:Vector3)->void:
	Global.shooterscene.room3d.bake_navigation_mesh(true)
	await Global.shooterscene.room3d.bake_finished
	
	if navagent.is_target_reachable():
		DEV_OUTPUT.push_message("target set")
		navagent.target_position = target_pos
		has_nav_target = true
	else:
		DEV_OUTPUT.push_message("invalid target")

func pick_random_target_vec()->void:
	update_target_location(NavigationServer3D.region_get_random_point(Global.shooterscene.room3d.get_region_rid(),0,false))
