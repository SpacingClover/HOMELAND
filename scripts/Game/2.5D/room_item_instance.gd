@tool
class_name RoomItemInstance extends RigidBody3D

@export var is_interactable : bool
@export var is_openable : bool
@export var item_id : int

@onready var nav_ob : NavigationObstacle3D = get_node_or_null(^"NavigationObstacle3D")
@onready var animplayer : AnimationPlayer = get_node_or_null(^"AnimationPlayer")

func pass_args(args:Array=[])->void:
	pass

func interact()->void:
	if not is_interactable: return

func get_data()->RoomItem:
	return RoomItem.new(item_id,position,rotation,[])

func _ready()->void:
	if nav_ob:
		original_points.append_array(nav_ob.vertices)
	update_obstacle()

func _process(delta:float)->void:
	update_obstacle()

var original_points : Array[Vector3]

func update_obstacle()->void:
	if not nav_ob: return
	
	for i : int in nav_ob.vertices.size():
		nav_ob.vertices[i] = original_points[i] * global_transform.basis.inverse()
