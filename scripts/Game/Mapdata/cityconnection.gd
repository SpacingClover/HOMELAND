class_name CityConnection extends Resource

@export var cityA : City
@export var roomA : Room
@export var cityB : City
@export var roomB : Room
var connection_id : String = r"<<"+Global.create_random_name(4)+r">>"

func _init(city:City=null,room:Room=null)->void:
	if not city: return
	connect_city(city,room)
	
func connect_city(city:City,room:Room)->void:
	if cityA:
		cityB = city
		roomB = room
	else:
		cityA = city
		roomA = room
		
func get_corresponding(city:City,room:Room=null)->ConnectionResponse:
	if cityA == city and (roomA == room or room == null):
		return ConnectionResponse.new(cityB,roomB)
	elif cityB == city and (roomB == room or room == null):
		return ConnectionResponse.new(cityA,roomA)
	return null
	
func has_city(city:City)->bool:
	return cityA == city or cityB == city
	
func is_open()->bool:
	return cityA == null or cityB == null
		
func get_index()->int:
	return Global.current_game.city_connections_register.connections.find(self)
	
func get_connection_string()->String:
	return connection_id + &":  " + cityA.get_city_string() + &"  CityExit " + str(roomA.index)
