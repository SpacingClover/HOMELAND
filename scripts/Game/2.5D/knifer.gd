class_name Knifer extends CharacterBody3D

var state : int
enum States{
	idle,
	chasing,
	fighting,
	dead
}

func _init()->void:
	velocity = Vector3(0,-1,0)

func _process(delta:float)->void:
	move_and_slide()

class smth:
	pass
