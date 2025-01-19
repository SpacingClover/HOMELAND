class_name ConnectionResponse extends Resource

var city : City
var room : Room

func _init(city_:City=null,room_:Room=null)->void:
	city = city_
	room = room_
