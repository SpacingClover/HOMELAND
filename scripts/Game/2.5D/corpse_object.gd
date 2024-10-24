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

func pass_args(args:Array=[])->void:
	if args.size() >= 1:
		team = args[0]
	else:
		team = 0
	if args.size() >= 2:
		blood_frame = args[1]
	else:
		blood_frame = 0

func _ready()->void:
	if team != 0:
		$body.texture = load("res://visuals/spritesheets/characters/ally-1.png")
		$body.hframes = 3
		$body.vframes = 3
		$body.frame = 6
	$blood.frame = blood_frame

func get_data()->RoomItem:
	return RoomItem.new(item_id,position,rotation,[team,blood_frame])
