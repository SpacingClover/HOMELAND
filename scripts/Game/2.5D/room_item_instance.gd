class_name RoomItemInstance extends RigidBody3D

@export var is_interactable : bool
@export var is_openable : bool
@export var item_id : int

@onready var nav_ob : NavigationObstacle3D = get_node_or_null(^"NavigationObstacle3D")
@onready var animplayer : AnimationPlayer = get_node_or_null(^"AnimationPlayer")

func _init()->void:
	pass

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
	if Global.is_level_editor_mode_enabled and Global.titlescreen.editorgui.interiorview:
		set_collision_layer_value(1,true)

func _process(delta:float)->void:
	if nav_ob:
		update_obstacle()
		var arr : Array[Vector2]
		for vertex : Vector3 in nav_ob.vertices:
			arr.append(Vector2(vertex.z,vertex.x))

var original_points : Array[Vector3]

func update_obstacle()->void:
	if not nav_ob: return
	
	for i : int in nav_ob.vertices.size():
		nav_ob.vertices[i] = original_points[i] * global_transform.basis.inverse()
		nav_ob.vertices[i] *= 2
