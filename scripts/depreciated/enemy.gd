extends CharacterBody2D

@onready var nav : NavigationAgent2D = $nav
@onready var raycast : RayCast2D = $ray
@onready var sprite : Sprite2D = $body

func _physics_process(_delta:float)->void:
	if velocity:
		sprite.flip_h = velocity.x < 0
	
	move_and_slide()

func shoot(hit_from_right:bool)->void:
	hide()
