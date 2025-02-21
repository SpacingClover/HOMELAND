class_name ItemsInventory extends Resource

@export var inventoryitems : Array[InventoryItem]

func add_item(item:InventoryItem)->void:
	inventoryitems.append(item)

func remove_item(item:InventoryItem)->void:
	inventoryitems.remove_at(inventoryitems.find(item))
