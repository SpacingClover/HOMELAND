class_name InventoryItem2DInstance extends StaticBody2D

var item_id : int
var inventoryitemid : int

func _init(data:InventoryItem)->void:
	item_id = data.item_id
	inventoryitemid = data.inventoryitemid
	pass
	## initialize visuals

func get_data()->InventoryItem:
	return InventoryItem.new(item_id,inventoryitemid,position/150)
