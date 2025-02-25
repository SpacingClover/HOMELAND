class_name InventoryItem extends Resource

@export var item_id : int
@export var inventoryitemid : int
@export var position : Vector2
@export var extra_data : Array

func _init(id:int=-1,rid:int=-1,pos:Vector2=Vector2.ZERO,args:Array=[])->void:
	item_id = id
	inventoryitemid = rid
	position = pos
	extra_data = args
	
