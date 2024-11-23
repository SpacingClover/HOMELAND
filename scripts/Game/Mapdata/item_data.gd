class_name RoomItem extends Resource

const SCN_PATH : String = "res://scenes/scn/"
const SCN : String = ".scn"

static var item_ids : PackedStringArray = PackedStringArray([
	"pot",     #0
	"table",   #1
	"stool",   #2
	"wardrobe",#3
	"endtable",#4
	"rug",     #5
	"",        #6 painting
	"",        #7 calandar
	"",        #8 window
	"corpse",  #9
	"key",     #10
	"static_npc" #11
])

enum{
	LOAD_VERSION_BASIC ## uses the original enumerated loading system, which is hard to extend, impossible to mod, and easy to break
	#next load version should use ids (maybe RIDs) registered with a dictionary
}

enum{
	ITEMSET_FURNITURE
}

@export var load_version : int = LOAD_VERSION_BASIC
@export var itemset : int = ITEMSET_FURNITURE
@export var type : int
@export var position : Vector3
@export var rotation : Vector3
@export var extra_data : Array

func _init(type_:int=0,pos:Vector3=Vector3.ZERO,rot:Vector3=Vector3.ZERO,extradata:Array=[])->void:
	type = type_
	position = pos
	rotation = rot
	extra_data = extradata

func create_instance()->RoomItemInstance:
	var obj : RoomItemInstance
	obj = load(SCN_PATH+get_item_name_by_id(type)+SCN).instantiate()
	obj.position = position
	obj.rotation = rotation
	obj.item_id = type
	obj.pass_args(extra_data)
	
	return obj

static func get_item_name_by_id(id:int)->String:
	var name : String
	if id >= 0 and id < item_ids.size():
		name = item_ids[id]
	else:
		name = ""
	return name
