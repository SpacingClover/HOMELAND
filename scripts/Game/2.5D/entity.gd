class_name Entity extends CharacterBody3D

enum MAINSTATES{
	IDLE,
	COMBAT,
	DEAD,
	DEBUGSTATE
}

enum MOVEMENTSTATES{
	IDLE,
	MOVE_TO_POS,
	MOVE_TO_ENTITY
}

enum COMBATMODES{
	NONE,
	MELEE,
	GUN
}

enum{
	OROTOF_CIVILIAN,
	OROTOF_RESISTANCE,
	OROTOF_GOVERNMENT,
	OROTOF_WITCHES,
	UNDERGROUND_MONSTER,
	CAMTO_GOVERNMENT,
	RAKATLAND_GOVERNMENT,
	FACTIONS_SIZE
}

enum{
	FRIENDLY,
	NEUTRAL,
	ENEMY
}

static var faction_relations_data : Array ## Array[Array[int]]

static func _static_init()->void:
	private_create_default_faction_relation_data()
	for i : int in faction_relations_data.size():
		print(faction_relations_data[i])

static func private_create_default_faction_relation_data()->void:
	
	var template_int_array : Array[int]
	template_int_array.resize(FACTIONS_SIZE)
	
	faction_relations_data.clear()
	faction_relations_data.resize(FACTIONS_SIZE)
	for i : int in faction_relations_data.size():
		faction_relations_data[i] = template_int_array.duplicate()
	
	## orotof civilian
	faction_relations_data[OROTOF_CIVILIAN][OROTOF_CIVILIAN] = FRIENDLY
	faction_relations_data[OROTOF_CIVILIAN][OROTOF_RESISTANCE] = FRIENDLY
	faction_relations_data[OROTOF_CIVILIAN][OROTOF_GOVERNMENT] = NEUTRAL
	faction_relations_data[OROTOF_CIVILIAN][OROTOF_WITCHES] = FRIENDLY
	faction_relations_data[OROTOF_CIVILIAN][UNDERGROUND_MONSTER] = ENEMY
	faction_relations_data[OROTOF_CIVILIAN][CAMTO_GOVERNMENT] = ENEMY
	faction_relations_data[OROTOF_CIVILIAN][RAKATLAND_GOVERNMENT] = NEUTRAL
	
	## orotof resistance
	faction_relations_data[OROTOF_RESISTANCE][OROTOF_CIVILIAN] = FRIENDLY
	faction_relations_data[OROTOF_RESISTANCE][OROTOF_RESISTANCE] = FRIENDLY
	faction_relations_data[OROTOF_RESISTANCE][OROTOF_GOVERNMENT] = NEUTRAL ## dynamic ## ITS COMPLICATED ## would they fight camto together?
	faction_relations_data[OROTOF_RESISTANCE][OROTOF_WITCHES] = NEUTRAL ## dynamic ## ITS COMPLICATED
	faction_relations_data[OROTOF_RESISTANCE][UNDERGROUND_MONSTER] = ENEMY
	faction_relations_data[OROTOF_RESISTANCE][CAMTO_GOVERNMENT] = ENEMY
	faction_relations_data[OROTOF_RESISTANCE][RAKATLAND_GOVERNMENT] = NEUTRAL
	
	## orotof government
	faction_relations_data[OROTOF_GOVERNMENT][OROTOF_CIVILIAN] = NEUTRAL
	faction_relations_data[OROTOF_GOVERNMENT][OROTOF_RESISTANCE] = ENEMY
	faction_relations_data[OROTOF_GOVERNMENT][OROTOF_GOVERNMENT] = FRIENDLY
	faction_relations_data[OROTOF_GOVERNMENT][OROTOF_WITCHES] = ENEMY
	faction_relations_data[OROTOF_GOVERNMENT][UNDERGROUND_MONSTER] = ENEMY
	faction_relations_data[OROTOF_GOVERNMENT][CAMTO_GOVERNMENT] = ENEMY ##
	faction_relations_data[OROTOF_GOVERNMENT][RAKATLAND_GOVERNMENT] = NEUTRAL
	
	## orotof witches
	faction_relations_data[OROTOF_WITCHES][OROTOF_CIVILIAN] = FRIENDLY
	faction_relations_data[OROTOF_WITCHES][OROTOF_RESISTANCE] = FRIENDLY
	faction_relations_data[OROTOF_WITCHES][OROTOF_GOVERNMENT] = NEUTRAL ## keeps the government away
	faction_relations_data[OROTOF_WITCHES][OROTOF_WITCHES] = FRIENDLY
	faction_relations_data[OROTOF_WITCHES][UNDERGROUND_MONSTER] = NEUTRAL ## theyre chill
	faction_relations_data[OROTOF_WITCHES][CAMTO_GOVERNMENT] = ENEMY
	faction_relations_data[OROTOF_WITCHES][RAKATLAND_GOVERNMENT] = ENEMY
	
	## underground monster
	faction_relations_data[UNDERGROUND_MONSTER][OROTOF_CIVILIAN] = ENEMY
	faction_relations_data[UNDERGROUND_MONSTER][OROTOF_RESISTANCE] = ENEMY
	faction_relations_data[UNDERGROUND_MONSTER][OROTOF_GOVERNMENT] = ENEMY
	faction_relations_data[UNDERGROUND_MONSTER][OROTOF_WITCHES] = NEUTRAL
	faction_relations_data[UNDERGROUND_MONSTER][UNDERGROUND_MONSTER] = ENEMY
	faction_relations_data[UNDERGROUND_MONSTER][CAMTO_GOVERNMENT] = ENEMY
	faction_relations_data[UNDERGROUND_MONSTER][RAKATLAND_GOVERNMENT] = ENEMY
	
	## camto government
	faction_relations_data[CAMTO_GOVERNMENT][OROTOF_CIVILIAN] = ENEMY
	faction_relations_data[CAMTO_GOVERNMENT][OROTOF_RESISTANCE] = ENEMY
	faction_relations_data[CAMTO_GOVERNMENT][OROTOF_GOVERNMENT] = ENEMY
	faction_relations_data[CAMTO_GOVERNMENT][OROTOF_WITCHES] = ENEMY
	faction_relations_data[CAMTO_GOVERNMENT][UNDERGROUND_MONSTER] = ENEMY
	faction_relations_data[CAMTO_GOVERNMENT][CAMTO_GOVERNMENT] = FRIENDLY
	faction_relations_data[CAMTO_GOVERNMENT][RAKATLAND_GOVERNMENT] = NEUTRAL
	
	## rakatland government
	faction_relations_data[RAKATLAND_GOVERNMENT][OROTOF_CIVILIAN] = NEUTRAL
	faction_relations_data[RAKATLAND_GOVERNMENT][OROTOF_RESISTANCE] = NEUTRAL
	faction_relations_data[RAKATLAND_GOVERNMENT][OROTOF_GOVERNMENT] = NEUTRAL
	faction_relations_data[RAKATLAND_GOVERNMENT][OROTOF_WITCHES] = NEUTRAL
	faction_relations_data[RAKATLAND_GOVERNMENT][UNDERGROUND_MONSTER] = NEUTRAL
	faction_relations_data[RAKATLAND_GOVERNMENT][CAMTO_GOVERNMENT] = NEUTRAL
	faction_relations_data[RAKATLAND_GOVERNMENT][RAKATLAND_GOVERNMENT] = FRIENDLY

static func get_faction_relation(own_faction:int,other_faction:int)->int:
	if own_faction >= faction_relations_data.size():
		return NEUTRAL
	if other_faction >= faction_relations_data[own_faction].size():
		return NEUTRAL
	return faction_relations_data[own_faction][other_faction]

static func get_faction_string(faction_idx:int)->StringName: #this will have to be extended to include different names that different groups call each faction
	match faction_idx:
		OROTOF_CIVILIAN:
			return &"Civilian"
		OROTOF_RESISTANCE:
			return &"Resistance"
		OROTOF_GOVERNMENT:
			return &"Orotov"
		OROTOF_WITCHES:
			return &"Witches"
		UNDERGROUND_MONSTER:
			return &"Monster"
		CAMTO_GOVERNMENT:
			return &"Camto"
		RAKATLAND_GOVERNMENT:
			return &"Rakatland"
		_:
			return &"ERROR INVALID FACTION"

@onready var sprite : Sprite3D = $body
@onready var legs   : Sprite3D = $legs

## object references
var target_enemy : Node3D
var target_object : Node3D
var inside_room : Room
var inside_city : City

## states
var mainstate : MAINSTATES = MAINSTATES.DEBUGSTATE
var movementstate : MOVEMENTSTATES = MOVEMENTSTATES.IDLE
var combatmode : COMBATMODES = COMBATMODES.GUN

##relations
var faction : int = OROTOF_CIVILIAN

##loadstate
var active : bool = true

func shoot_and_get_data()->AttackResponse:
	mainstate = MAINSTATES.DEAD
	sprite.frame = 6
	legs.hide()
	DEV_OUTPUT.push_message(r"died")
	return AttackResponse.new(true,true)

func melee_and_get_data()->AttackResponse:
	mainstate = MAINSTATES.DEAD
	sprite.frame = 6
	legs.hide()
	DEV_OUTPUT.push_message(r"died")
	return AttackResponse.new(true,true)

func get_data()->RoomEntity:
	return RoomEntity.new(faction,position,mainstate != MAINSTATES.DEAD)

func entered_room()->void:
	pass

func exited_room()->void:
	pass

class AttackResponse extends Resource:
	var hit : bool
	var killed : bool
	func _init(hit_:bool,killed_:bool)->void:
		hit = hit_
		killed = killed_
