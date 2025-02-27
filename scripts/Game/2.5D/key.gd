class_name KeyInstance extends GrabbableItemInstance

@export var key_type : int

func pass_args(args:Array=[0])->void:
	key_type = args[0]

func _ready()->void:
	$sprite.frame = key_type

func get_data()->RoomItem:
	return RoomItem.new(item_id,position,rotation,[key_type])

func interact()->void:
	#Global.player.DEBUG_inventory.append(get_data())
	Global.player.DEBUG_add_item_to_inventory(self)
	queue_free()

static func get_key_color(type:int)->Color:
	var img : Image = load("res://visuals/spritesheets/items/keys.png")
	var color : Color = img.get_pixel(1,type*4)
	return color
