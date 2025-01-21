class_name RoomEntity extends Resource

@export var position : Vector3
@export var faction : int

func _init(faction_:int,pos:Vector3)->void:
	position = pos
	faction = faction_

func create_entity(city:City,room:Room)->NPC:
	var npc : NPC = ResourceLoader.load("res://scenes/tscn/npc.tscn").instantiate()
	npc.inside_city = city
	npc.inside_room = room
	npc.position = position
	npc.ready.connect(npc.configure.bind(faction))
	return npc
