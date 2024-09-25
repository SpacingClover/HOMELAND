class_name ScriptListOrder extends Resource
	
@export var items : Array[ScriptListItem]

func log_itemlist(itemlist:ItemList=null)->void:
	items.clear()
	for i : int in range(itemlist.item_count):
		items.append(ScriptListItem.new(i,itemlist.get_item_text(i)))

func has_item(name:String=&"")->bool:
	for item : ScriptListItem in items:
		if item.text == name:
			return true
	return false
