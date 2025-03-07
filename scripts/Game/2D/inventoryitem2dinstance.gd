class_name InventoryItem2DInstance extends StaticBody2D

var inventoryitemid : int
var item_id : int
var extra_data : Array

func _init(data:InventoryItem)->void:
	inventoryitemid = data.inventoryitemid
	item_id = data.item_id
	extra_data = data.extra_data
	pass
	## initialize visuals

func get_data()->InventoryItem:
	return InventoryItem.new(inventoryitemid,item_id,position,extra_data)
