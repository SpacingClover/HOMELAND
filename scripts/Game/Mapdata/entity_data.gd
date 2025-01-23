class_name RoomEntity extends Resource

@export var position : Vector3
@export var faction : int
@export var alive : bool

func _init(faction_:int=-1,pos:Vector3=Vector3.ZERO,alive_:bool=true)->void:
	position = pos
	faction = faction_
	alive = alive_

func create_entity(city:City=null,room:Room=null,active:bool=true)->NPC:
	var npc : NPC = ResourceLoader.load("res://scenes/tscn/npc.tscn").instantiate()
	npc.mainstate = Entity.MAINSTATES.IDLE if alive else Entity.MAINSTATES.DEAD
	npc.active = active
	npc.inside_city = city
	npc.inside_room = room
	npc.position = position
	npc.ready.connect(npc.configure.bind(faction))
	return npc
