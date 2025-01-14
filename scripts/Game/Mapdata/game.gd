class_name GameData extends Resource

@export_category("Map Data")
@export var cities : Array[City]
@export var current_city : City
@export var current_room : Room
@export var city_connections_register : CityConnectionsRegister ## in mapview editor, add option to create cityconnection on city, which adds it to the register

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
	
	index_cities()
	
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

class CityConnectionsRegister extends Resource:
	@export var connections : Array[CityConnection]
	var connection_id : String = Global.create_random_name(4)
	func _init()->void:
		if Global.current_game.cities.is_empty():
			DEV_OUTPUT.push_message(r"ERROR CITYCONNECTIONSREGISTER LOADED BEFORE CITIES")
			print(r"ERROR CITYCONNECTIONSREGISTER LOADED BEFORE CITIES")
			breakpoint
		update_refs()
	func create_new_connection(fromcity:City)->void:
		connections.append(CityConnection.new(fromcity))
	func get_corresponding(city:City,room:Room)->ConnectionResponse:
		for connection : CityConnection in connections:
			var response : ConnectionResponse = connection.get_corresponding(city,room)
			if response:
				return response
		return null
	func update_indecies()->void:
		for connection : CityConnection in connections:
			connection.update_indecies()
	func update_refs()->void:
		for connection : CityConnection in connections:
			connection.update_refs()

class CityConnection extends Resource:
	@export var cityA_idx : int = -1
	@export var roomA_idx : int = -1
	@export var cityB_idx : int = -1
	@export var roomB_idx : int = -1
	var cityA : City
	var roomA : Room
	var cityB : City
	var roomB : Room
	func _init(city:City)->void:
		connect_city(city)
	func connect_city(city:City)->void:
		if cityA:
			cityB = city
			cityB_idx = city.index
		else:
			cityA = cityA
			cityA_idx = city.index
	func get_corresponding(city:City,room:Room)->ConnectionResponse:
		if cityA == city and roomA == room:
			return ConnectionResponse.new(cityA,roomA)
		elif cityB == city and roomB == room:
			return ConnectionResponse.new(cityB,roomB)
		return null
	func update_indecies()->void:
		if cityA:
			cityA_idx = cityA.index
			if roomA:
				roomA_idx = roomA.index
			else:
				roomA_idx = -1
		else:
			cityA_idx = -1
			roomA_idx = -1
		if cityB:
			cityB_idx = cityB.index
			if roomB:
				roomB_idx = roomB.index
			else:
				roomB_idx = -1
		else:
			cityB_idx = -1
			roomB_idx = -1
	func update_refs()->void:
		if cityA_idx != -1:
			cityA = Global.current_game.cities[cityA_idx]
			if roomA_idx != -1:
				roomA = cityA.rooms[roomA_idx]
			else:
				roomA = null
		else:
			cityA = null
			roomA = null
		if cityB_idx != -1:
			cityB = Global.current_game.cities[cityB_idx]
			if roomB_idx != -1:
				roomB = cityB.rooms[roomB_idx]
			else:
				roomB = null
		else:
			cityB = null
			roomB = null

class ConnectionResponse extends Resource:
	var city : City
	var room : Room
	func _init(city_:City,room_:Room)->void:
		city = city_
		room = room_
