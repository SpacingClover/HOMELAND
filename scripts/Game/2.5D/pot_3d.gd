class_name Pot3D extends RoomItemInstance

func _ready()->void:
	$plant.frame = randi_range(0,3)

func damage(amount:int)->void:
	shatter()

func shatter()->void:
	$plant.hide()
	var tween : Tween = create_tween()
	tween.tween_property($sprite,"frame",3,0.5)
