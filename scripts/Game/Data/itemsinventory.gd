class_name ItemsInventory extends Resource

@export var inventoryitems : Array[InventoryItem]
@export var gridsize : Vector2i

func _init(size:Vector2i=Vector2i.ZERO)->void:
	gridsize = size

func add_item(item:InventoryItem)->void:
	for inventoryitem : InventoryItem in inventoryitems:
		if inventoryitem.position == item.position and inventoryitem != item:
			item.position = Vector2i(randi_range(0,gridsize.x-1),randi_range(0,gridsize.y-1))
	inventoryitems.append(item)

func remove_item(item:InventoryItem)->void:
	var idx : int = inventoryitems.find(item)
	if idx != -1: inventoryitems.remove_at(idx)

func remove_item_by_inventory_item_idx(idx:int)->void:
	for inventoryitem : InventoryItem in inventoryitems:
		if inventoryitem.inventoryitemid == idx:
			inventoryitems.remove_at(inventoryitems.find(inventoryitem))
			return

func has_item_of_type(type_id:int)->bool:
	for item : InventoryItem in inventoryitems:
		if item.item_id == type_id:
			return true
	return false

func has_item_of_type_with_data(type_id:int,data:Array)->bool:
	for item : InventoryItem in inventoryitems:
		if item.item_id == type_id:
			if not item.extra_data.size() >= data.size(): continue
			if item.extra_data[0] == data[0]: return true
	return false
