class_name ItemsInventory extends Resource

@export var inventoryitems : Array[InventoryItem]

func add_item(item:InventoryItem)->void:
	inventoryitems.append(item)

func remove_item(item:InventoryItem)->void:
	var idx : int = inventoryitems.find(item)
	if idx != -1: inventoryitems.remove_at(idx)

func remove_item_by_inventory_item_idx(idx:int)->void:
	for inventoryitem : InventoryItem in inventoryitems:
		if inventoryitem.inventoryitemid == idx:
			inventoryitems.remove_at(inventoryitems.find(inventoryitem))
			return
	DEV_OUTPUT.push_message("didnt remove")
