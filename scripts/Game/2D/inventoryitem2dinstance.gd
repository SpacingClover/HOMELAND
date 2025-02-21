class_name InventoryItem2DInstance extends StaticBody2D

var inventoryitemid : int

func _init(data:InventoryItem)->void:
	inventoryitemid = data.inventoryitemid
	pass
	## initialize visuals

func get_data()->InventoryItem:
	return InventoryItem.new(inventoryitemid,position)
