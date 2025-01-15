class_name CityConnectionsRegister extends Resource

@export var connections : Array[CityConnection]

func create_new_connection(fromcity:City,fromroom:Room)->void:
	connections.append(CityConnection.new(fromcity,fromroom))
	
func remove_whole_connection(withcity:City)->void:
	for connection : CityConnection in connections:
		if connection.has_city(withcity):
			connections.remove_at(connections.find(connection))
			return
			
func connection_exists(city:City,room:Room)->bool:
	return get_corresponding(city,room) != null
	
func get_corresponding(city:City,room:Room)->ConnectionResponse:
	for connection : CityConnection in connections:
		var response : ConnectionResponse = connection.get_corresponding(city,room)
		if response:
			return response
	return null
	
#func update_indecies()->void:
	#for connection : CityConnection in connections:
		#connection.update_indecies()
		#
#func update_refs()->void:
	#for connection : CityConnection in connections:
		#connection.update_refs()
		
func get_open_connections()->Array[CityConnection]:
	var array : Array[CityConnection]
	for connection : CityConnection in connections:
		if connection.is_open():
			array.append(connection)
	return array
	
func get_city_connections(city:City)->Array[ConnectionResponse]:
	var array : Array[ConnectionResponse]
	for connection : CityConnection in connections:
		if connection.has_city(city):
			array.append(connection.get_corresponding(city))
	return array
