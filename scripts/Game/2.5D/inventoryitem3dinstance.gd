class_name InventoryItem3DInstance extends GrabbableItemInstance

var inventoryitemid : int

func pass_args(args:Array=[])->void:
	inventoryitemid = args[0]
	## initialize visuals

func get_data()->RoomItem:
	return RoomItem.new(item_id,position,rotation,[inventoryitemid])

func get_inventoryitem_data()->InventoryItem:
	return InventoryItem.new(inventoryitemid,Vector2.ZERO)
