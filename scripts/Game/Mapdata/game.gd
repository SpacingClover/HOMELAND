class_name GameData extends Resource

@export_category("Map Data")
@export var cities : Array[City]
@export var current_city : City
@export var current_room : Room
@export var city_connections_register : CityConnectionsRegister = CityConnectionsRegister.new() ## in mapview editor, add option to create cityconnection on city, which adds it to the register

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

func _init(being_generated:bool=false)->void:
	
	await Global.get_tree().process_frame
	await Global.get_tree().process_frame
	
	index_cities()
	#city_connections_register.update_refs()
	
	if demo:
		return
	
	var datetime : Dictionary = Time.get_date_dict_from_system()
	last_accessed_date = str(datetime.day)+"-"+str(datetime.month)+"-"+str(datetime.year)
	
	if not being_generated:
		return
	
	first_starting = true

func open()->void:
	
	
	PopUps.tutorial_enabled = tutorial_enabled
	
	for city : City in cities:
		if not city.validated: city.validate_city()
	
	if first_starting:
		if not startcity:
			startcity = cities[0]
		current_city = startcity
		if not startroom:
			startroom = current_city.rooms[0]
		current_room = startroom
	
	Global.set_new_city(cities.find(current_city),current_city.rooms.find(current_room),true)
	first_starting = false

func index_cities()->void:
	for i : int in cities.size():
		cities[i].index = i

func create_new_city()->City:
	var newcity : City = await City.new()
	cities.append(newcity)
	var breakloop : bool
	for i : int in 1000: #1000 maximum iterations before it just gives up
		breakloop = true
		for city : City in cities:
			if city != newcity and city.coords == newcity.coords:
				breakloop = false
		if breakloop:
			break
		else:
			newcity.coords += Vector2i(randi_range(0,1),randi_range(0,1))
	index_cities()
	return newcity

func remove_city(city:City)->void:
	cities.remove_at(city.index)
	index_cities()

func save()->GameData:
	#city_connections_register.update_indecies()
	return self
