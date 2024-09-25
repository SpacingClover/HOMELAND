class_name RoomItemInstance extends RigidBody3D

@export var is_interactable : bool
@export var is_openable : bool
@export var item_id : int

@onready var animplayer : AnimationPlayer = get_node_or_null("AnimationPlayer")

func pass_args(args:Array=[])->void:
	pass

func interact()->void:
	if not is_interactable: return

func get_data()->RoomItem:
	return RoomItem.new(item_id,position,rotation,[])
