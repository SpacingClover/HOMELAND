class_name Corpse extends RoomItemInstance

enum{
	ENEMY
}

enum{
	CHEST_SHOT,
	STOMACH_SHOT,
	FACE_SHOT,
	LEG_SHOT,
	PELVIS_EXPLODED,
	FACE_EXPLODED
}

var team : int = ENEMY
var blood_frame : int = CHEST_SHOT

#func pass_args(args:Array=[])->void:
	#team = args[0]
	#blood_frame = args[1]

func get_data()->RoomItem:
	return RoomItem.new(item_id,position,rotation,[team,blood_frame])
