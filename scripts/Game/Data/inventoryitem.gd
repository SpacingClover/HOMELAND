class_name InventoryItem extends Resource

@export var inventoryitemid : int
@export var position : Vector2
@export var item_id : int

func _init(id:int=-1,itemid:int=-1,pos:Vector2=Vector2.ZERO)->void:
	inventoryitemid = id
	position = pos
	item_id = itemid
