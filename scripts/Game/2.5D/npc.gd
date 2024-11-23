class_name NPC extends CharacterBody3D

@onready var navagent : NavigationAgent3D = $navagent

var speed : float = 3

var has_nav_target : bool = false

func _physics_process(delta:float)->void:
	if has_nav_target:
		if navagent.distance_to_target() <= 0.5: has_nav_target = false
		velocity = (navagent.get_next_path_position() - global_position).normalized() * speed
		move_and_slide()

func update_target_location(target_pos:Vector3)->void:
	Global.shooterscene.room3d.bake_navigation_mesh(true)
	await Global.shooterscene.room3d.bake_finished
	navagent.target_position = target_pos
	has_nav_target = true
	
	##########################################################################
	await get_tree().create_timer(1).timeout
	DEV_OUTPUT.push_message(str(navagent.get_current_navigation_path().size()))
	##########################################################################
