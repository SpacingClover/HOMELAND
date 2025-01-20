class_name RoomEntity extends Resource

@export var position : Vector3
@export var faction : int

func _init(faction_:int,pos:Vector3)->void:
	position = pos
	faction = faction_

func create_entity(city:City,room:Room)->NPC:
	var npc : NPC = NPC.new()
	npc.inside_city = city
	npc.inside_room = room
	npc.ready.connect(npc.configure.bind(faction))
	npc.tree_entered.connect(npc.set.bind("global_position",position))
	return npc
