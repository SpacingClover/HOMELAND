class_name GameData extends Resource

@export_category("Map Data")
@export var cities : Array[City]
@export var current_city : City
@export var current_room : Room

@export_subgroup("Starting Location")
@export var startcity : City
@export var startroom : Room

@export_category("Player Data")
@export var health : int = 50
@export var position : Vector3 = Vector3.ZERO

@export_category("UI Data")
@export_subgroup("World_3D")
@export var current_axis : int = 0

@export_category("Meta Data")
@export var game_name : String = "untitled"
@export var demo : bool = false
@export var tutorial_enabled : bool = false
@export var first_starting : bool = true
@export var door_entry_opening : bool = false
@export var first_created_date : String
@export var last_accessed_date : String
@export_multiline var description : String
@export_subgroup("Ignore But Keep")

func _init(being_generated:bool=false)->void:
	
	if demo:
		return
	
	var datetime : Dictionary = Time.get_date_dict_from_system()
	last_accessed_date = str(datetime.day)+"-"+str(datetime.month)+"-"+str(datetime.year)
	
	if not being_generated:
		return
	
	first_starting = true
	##for city generation
	#first create all the cities, and use astar to connect the closest ones
	#use this, and the city size, to place the cityexits in appropriate places along the edges of each city
	#give each exit the corresponding city idx
	#give each exit the corresponding exit idx
	
	#generate features, and fill in rooms to connect all features and exits
	#validate city HERE
	#depending on circumstances, break some connections, create rubble
	#place npcs
	#place loot / items

func open()->void:
	
	PopUps.tutorial_enabled = tutorial_enabled
	
	for city : City in cities:
		if not city.validated: city.validate_city()
	
	if first_starting:
		if not startcity: startcity = cities[0]
		current_city = startcity
		if not startroom: startroom = current_city.rooms[0]
		current_room = startroom
	
	Global.set_new_city(cities.find(current_city),current_city.rooms.find(current_room),true)
	first_starting = false
