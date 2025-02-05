class_name RoomEntity extends Resource

@export var position : Vector3
@export var faction : int
@export var alive : bool
@export var health : int

func _init(faction_:int=-1,pos:Vector3=Vector3.ZERO,alive_:bool=true,health_:int=10)->void:
	position = pos
	faction = faction_
	alive = alive_
	health = health_

func create_entity(city:City=null,room:Room=null,active:bool=true)->Entity:
	var npc : NPC = ResourceLoader.load("res://scenes/tscn/npc.tscn").instantiate()
	npc.mainstate = Entity.MAINSTATES.IDLE if alive else Entity.MAINSTATES.DEAD
	npc.active = active
	npc.inside_city = city
	npc.inside_room = room
	npc.position = position
	npc.health = health
	npc.ready.connect(npc.configure.bind(faction))
	return npc
